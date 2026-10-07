import Foundation
import Network
import AppKit
import Combine
import iKeypadShared

/// Serves layouts and app state to paired iPads and runs their taps.
///
/// Every connection starts unauthenticated and receives only a ``DeckMessage/challenge``. It
/// becomes authenticated by pairing with the code shown in the menu or by proving a stored
/// token; only then does it receive layouts and app state, and only then are its taps run.
@MainActor
public final class DeckServer: ObservableObject {
    public static let shared = DeckServer(store: KeychainPairedDeviceStore(), hostId: HostIdentity.current, pairing: PairingWindow())

    static let protocolVersion = "2.1.0"

    let pairing: PairingWindow
    private let store: PairedDeviceStore
    private let hostId: String
    private var listener: NWListener?
    private var activeConnections: [NWConnection] = []
    private var receiveBuffers: [ObjectIdentifier: Data] = [:]
    private var nonces: [ObjectIdentifier: Data] = [:]
    private var authenticated: Set<ObjectIdentifier> = []
    private var cancellables = Set<AnyCancellable>()

    /// Paired iPads currently connected.
    @Published public private(set) var connectedClientsCount: Int = 0
    @Published private(set) var pairedDeviceCount: Int = 0

    init(store: PairedDeviceStore, hostId: String, pairing: PairingWindow) {
        self.store = store
        self.hostId = hostId
        self.pairing = pairing
        self.pairedDeviceCount = store.count

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
    /// The port actually being listened on, once the listener is ready.
    var listeningPort: UInt16? { listener?.port?.rawValue }

    public func start(port: UInt16 = 49200, serviceName: String? = "Sidekey") {
        do {
            let parameters = NWParameters.tcp
            // Port 0 lets the system pick a free port (tests use this; iPads find the Mac by Bonjour).
            self.listener = try NWListener(using: parameters, on: port == 0 ? .any : NWEndpoint.Port(rawValue: port)!)
            // Advertise via Bonjour for zero-config Wi-Fi & USB peer-to-peer detection. The TXT
            // record carries this Mac's id so a paired iPad reconnects only to it.
            if let serviceName {
                self.listener?.service = NWListener.Service(name: serviceName, type: "_sidekey._tcp",
                                                            txtRecord: NWTXTRecord(["hostId": hostId]))
            }

            self.listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("[Server] Listening on port \(port == 0 ? "chosen by the system" : String(port)), Bonjour service advertised (_sidekey._tcp).")
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
                    self.sendChallenge(over: connection)
                    self.receiveLoop(connection)
                case .failed, .cancelled:
                    print("[Server] Client disconnected: \(connection.endpoint)")
                    let id = ObjectIdentifier(connection)
                    self.activeConnections.removeAll { $0 === connection }
                    self.receiveBuffers.removeValue(forKey: id)
                    self.nonces.removeValue(forKey: id)
                    self.authenticated.remove(id)
                    self.authenticationChanged()
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
        let id = ObjectIdentifier(connection)
        switch message {
        case .pair(let code, let clientId, let clientName):
            handlePairing(code: code, clientId: clientId, clientName: clientName, from: connection)
            return
        case .authenticate(let clientId, let proof):
            handleAuthentication(clientId: clientId, proof: proof, from: connection)
            return
        case .executeAction(let keyId, _, _) where !authenticated.contains(id):
            send(message: .actionExecuted(keyId: keyId, success: false, errorMessage: "Pair this iPad with your Mac first."), over: connection)
            return
        default:
            guard authenticated.contains(id) else { return }
        }

        switch message {
        case .handshake(let clientName):
            print("[Server] Received handshake from \(clientName)")

        case .executeAction(let keyId, let profileId, let pinned):
            print("[Server] Tap on key \(keyId) (profile \(profileId ?? "-"), pinned \(pinned ?? false))")
            switch prepareTarget(forTapOn: keyId, in: profileId, pinned: pinned) {
            case .failure(let rejection):
                send(message: .actionExecuted(keyId: keyId, success: false, errorMessage: rejection.reason), over: connection)
            case .success(let target):
                fire(target.action, keyId: keyId, after: target.delay, over: connection)
            }

        case .ping:
            send(message: .pong, over: connection)

        default:
            break
        }
    }

    // MARK: - Pairing and authentication

    /// Start a connection's authentication with a fresh nonce.
    private func sendChallenge(over connection: NWConnection) {
        do {
            let nonce = try PairingCrypto.randomBytes(32)
            nonces[ObjectIdentifier(connection)] = nonce
            send(message: .challenge(nonce: nonce, hostId: hostId, hostName: Host.current().localizedName), over: connection)
        } catch {
            print("[Server] Could not create a challenge, closing connection: \(error)")
            connection.cancel()
        }
    }

    private func handlePairing(code: String, clientId: String, clientName: String, from connection: NWConnection) {
        switch pairing.attempt(code) {
        case .accepted:
            do {
                let token = try PairingCrypto.randomBytes(32)
                try store.save(token: token, for: clientId, name: clientName)
                pairedDeviceCount = store.count
                print("[Server] Paired with \(clientName)")
                send(message: .paired(token: token), over: connection)
                welcome(connection)
            } catch {
                print("[Server] Pairing failed to store the token: \(error)")
                send(message: .pairingFailed(reason: "The Mac couldn't save the pairing. Try again."), over: connection)
            }
        case .wrong:
            send(message: .pairingFailed(reason: "That code is wrong. Check the code in the Sidekey menu on your Mac."), over: connection)
        case .closed:
            send(message: .pairingFailed(reason: "Pairing isn't open. On your Mac, choose Pair iPad in the Sidekey menu to get a code."), over: connection)
        }
    }

    private func handleAuthentication(clientId: String, proof: Data, from connection: NWConnection) {
        guard let nonce = nonces[ObjectIdentifier(connection)],
              let token = store.token(for: clientId),
              PairingCrypto.verify(proof: proof, token: token, nonce: nonce) else {
            send(message: .authenticationFailed(reason: "This iPad isn't paired with this Mac. Pair again."), over: connection)
            return
        }
        welcome(connection)
    }

    /// Mark a connection authenticated and send it everything it needs to show the deck.
    private func welcome(_ connection: NWConnection) {
        let id = ObjectIdentifier(connection)
        nonces.removeValue(forKey: id)
        authenticated.insert(id)
        authenticationChanged()
        send(message: .handshakeAck(serverVersion: Self.protocolVersion, hostName: Host.current().localizedName), over: connection)
        send(message: .profileUpdated(profile: AppContextMonitor.shared.activeProfile), over: connection)
        if let context = AppContextMonitor.shared.currentContext() {
            send(message: .appContextUpdated(context: context), over: connection)
        }
    }

    private func authenticationChanged() {
        connectedClientsCount = authenticated.count
        AppContextMonitor.shared.setPolling(!authenticated.isEmpty)
    }

    /// Open the pairing window from the menu; the code shows there for ``PairingWindow/lifetime``.
    func openPairing() {
        do {
            try pairing.open()
        } catch {
            print("[Server] Could not open pairing: \(error)")
        }
    }

    /// Forget every paired iPad; they must pair again.
    func forgetPairedDevices() {
        do {
            try store.removeAll()
        } catch {
            print("[Server] Could not forget paired iPads: \(error)")
        }
        pairedDeviceCount = store.count
        for connection in activeConnections where authenticated.contains(ObjectIdentifier(connection)) {
            connection.cancel()
        }
    }

    /// A tap the Mac refuses to run, with the reason shown on the iPad.
    struct TapRejected: Error {
        let reason: String
    }

    /// The Mac's own action for a tapped key, and how long to wait before running it.
    struct TapTarget {
        let action: KeyAction
        let delay: TimeInterval
    }

    /// Decide whether a tap on key ``keyId`` of layout ``profileId`` may run and which action it
    /// runs, bringing a pinned layout's app forward first.
    ///
    /// The action always comes from the Mac's own layout, never from the client, so only the
    /// built-in layouts' actions can ever run.
    ///
    /// :returns: The key's action and the delay before firing (time for a pinned app to come
    ///     forward), or why the tap is rejected.
    private func prepareTarget(forTapOn keyId: String, in profileId: String?, pinned: Bool?) -> Result<TapTarget, TapRejected> {
        let monitor = AppContextMonitor.shared
        guard let profileId else {
            // Taps from builds before layout ids existed cannot be matched to a key.
            return .failure(TapRejected(reason: "Update Sidekey on your iPad."))
        }
        let profile: DeckProfile
        var delay: TimeInterval = 0
        if profileId == monitor.activeProfile.id {
            profile = monitor.activeProfile
        } else {
            guard pinned == true else {
                // The layout changed between the user seeing the key and tapping it.
                return .failure(TapRejected(reason: "Layout changed. Tap again."))
            }
            guard let pinnedProfile = monitor.profile(withId: profileId) else {
                return .failure(TapRejected(reason: "Pinned layout is no longer available. Unpin and try again."))
            }
            guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: pinnedProfile.appBundleIdentifier).first else {
                return .failure(TapRejected(reason: "\(pinnedProfile.appName) isn't running."))
            }
            app.activate()
            profile = pinnedProfile
            delay = 0.25
        }
        guard let key = profile.keys.first(where: { $0.id == keyId }) else {
            return .failure(TapRejected(reason: "Layout changed. Tap again."))
        }
        return .success(TapTarget(action: key.action, delay: delay))
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

    /// Send ``message`` to every authenticated iPad; unpaired connections never receive it.
    public func broadcast(message: DeckMessage) {
        for conn in activeConnections where authenticated.contains(ObjectIdentifier(conn)) {
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
