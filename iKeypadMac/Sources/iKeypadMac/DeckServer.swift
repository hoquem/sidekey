import Foundation
import Network
import AppKit
import Combine
import iKeypadShared

@MainActor
public final class DeckServer: ObservableObject {
    public static let shared = DeckServer()

    private var listener: NWListener?
    private var activeConnections: [NWConnection] = []
    private var receiveBuffers: [ObjectIdentifier: Data] = [:]
    private var cancellables = Set<AnyCancellable>()

    @Published public private(set) var connectedClientsCount: Int = 0

    private init() {
        // Observe profile changes to broadcast
        AppContextMonitor.shared.$activeProfile
            .sink { [weak self] newProfile in
                self?.broadcast(message: .profileUpdated(profile: newProfile))
            }
            .store(in: &cancellables)

        AppContextMonitor.shared.contextChanges
            .sink { [weak self] context in
                self?.broadcast(message: .appContextUpdated(context: context))
            }
            .store(in: &cancellables)
    }

    /// Start listening for iPads.
    ///
    /// :param port: TCP port to listen on.
    /// :param serviceName: Bonjour name to advertise as ``_sidekey._tcp``, or ``nil`` to listen
    ///     without advertising (tests use this so iPads on the network never find them).
    public func start(port: UInt16 = 49200, serviceName: String? = "Sidekey") {
        do {
            let parameters = NWParameters.tcp
            self.listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            // Advertise via Bonjour for zero-config Wi-Fi & USB peer-to-peer detection
            if let serviceName {
                self.listener?.service = NWListener.Service(name: serviceName, type: "_sidekey._tcp")
            }

            self.listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("[Server] Listening on port \(port), Bonjour service advertised (_sidekey._tcp).")
                case .failed(let error):
                    print("[Server] Listener failed: \(error)")
                default:
                    break
                }
            }

            self.listener?.newConnectionHandler = { [weak self] connection in
                Task { @MainActor [weak self] in
                    self?.handleNewConnection(connection)
                }
            }

            self.listener?.start(queue: .main)
        } catch {
            print("[Server] Error creating listener: \(error)")
        }
    }

    private func handleNewConnection(_ connection: NWConnection) {
        let connId = ObjectIdentifier(connection)
        receiveBuffers[connId] = Data()

        connection.stateUpdateHandler = { [weak self, weak connection] state in
            Task { @MainActor [weak self, weak connection] in
                guard let self = self, let connection = connection else { return }
                switch state {
                case .ready:
                    print("[Server] Client connected from \(connection.endpoint)")
                    self.activeConnections.append(connection)
                    self.connectedClientsCount = self.activeConnections.count
                    AppContextMonitor.shared.setPolling(true)
                    // Send current active profile immediately
                    self.send(message: .profileUpdated(profile: AppContextMonitor.shared.activeProfile), over: connection)
                    self.receiveLoop(connection)
                case .failed, .cancelled:
                    print("[Server] Client disconnected: \(connection.endpoint)")
                    self.activeConnections.removeAll { $0 === connection }
                    self.receiveBuffers.removeValue(forKey: ObjectIdentifier(connection))
                    self.connectedClientsCount = self.activeConnections.count
                    AppContextMonitor.shared.setPolling(!self.activeConnections.isEmpty)
                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
    }

    private func receiveLoop(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self, weak connection] data, _, isComplete, error in
            Task { @MainActor [weak self, weak connection] in
                guard let self = self, let connection = connection else { return }

                if let data = data, !data.isEmpty {
                    let id = ObjectIdentifier(connection)
                    self.receiveBuffers[id, default: Data()].append(data)

                    while var buffer = self.receiveBuffers[id],
                          let message = FramedMessageProtocol.decode(from: &buffer) {
                        self.receiveBuffers[id] = buffer
                        self.handleMessage(message, from: connection)
                    }
                }

                if isComplete || error != nil {
                    connection.cancel()
                } else {
                    self.receiveLoop(connection)
                }
            }
        }
    }

    private func handleMessage(_ message: DeckMessage, from connection: NWConnection) {
        switch message {
        case .handshake(let clientName):
            print("[Server] Received handshake from \(clientName)")
            send(message: .handshakeAck(serverVersion: "2.0.0", hostName: Host.current().localizedName), over: connection)
            send(message: .profileUpdated(profile: AppContextMonitor.shared.activeProfile), over: connection)
            if let context = AppContextMonitor.shared.currentContext() {
                send(message: .appContextUpdated(context: context), over: connection)
            }

        case .executeAction(let keyId, let action, let profileId, let pinned):
            print("[Server] Executing action for key \(keyId): \(action) (profile \(profileId ?? "-"), pinned \(pinned ?? false))")
            switch prepareTarget(forTapOn: profileId, pinned: pinned) {
            case .failure(let rejection):
                send(message: .actionExecuted(keyId: keyId, success: false, errorMessage: rejection.reason), over: connection)
            case .success(let delay):
                fire(action, keyId: keyId, after: delay, over: connection)
            }

        case .ping:
            send(message: .pong, over: connection)

        default:
            break
        }
    }

    /// A tap the Mac refuses to run, with the reason shown on the iPad.
    struct TapRejected: Error {
        let reason: String
    }

    /// Decide whether a tap on layout ``profileId`` may run, bringing a pinned layout's app
    /// forward first.
    ///
    /// :returns: Seconds to wait before firing (time for a pinned app to come forward), or why
    ///     the tap is rejected. A tap without a layout id is not checked.
    private func prepareTarget(forTapOn profileId: String?, pinned: Bool?) -> Result<TimeInterval, TapRejected> {
        let monitor = AppContextMonitor.shared
        guard let profileId, profileId != monitor.activeProfile.id else { return .success(0) }
        guard pinned == true else {
            // The layout changed between the user seeing the key and tapping it.
            return .failure(TapRejected(reason: "Layout changed. Tap again."))
        }
        guard let pinnedProfile = monitor.profile(withId: profileId) else {
            return .failure(TapRejected(reason: "Pinned layout is no longer available. Unpin and try again."))
        }
        guard let target = NSRunningApplication.runningApplications(withBundleIdentifier: pinnedProfile.appBundleIdentifier).first else {
            return .failure(TapRejected(reason: "\(pinnedProfile.appName) isn't running."))
        }
        target.activate()
        return .success(0.25)
    }

    /// Run ``action`` off the main thread after ``delay`` and report the result to the iPad.
    private func fire(_ action: KeyAction, keyId: String, after delay: TimeInterval, over connection: NWConnection) {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + delay) {
            let result = ActionDispatcher.shared.execute(action: action)
            Task { @MainActor [weak self] in
                self?.send(message: .actionExecuted(keyId: keyId, success: result.success, errorMessage: result.error), over: connection)
            }
        }
    }

    public func broadcast(message: DeckMessage) {
        for conn in activeConnections {
            send(message: message, over: conn)
        }
    }

    private func send(message: DeckMessage, over connection: NWConnection) {
        do {
            let data = try FramedMessageProtocol.encode(message)
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("[Server] Send error: \(error)")
                }
            })
        } catch {
            print("[Server] Encode error: \(error)")
        }
    }
}
