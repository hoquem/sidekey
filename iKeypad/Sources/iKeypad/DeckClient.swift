import Foundation
import Network
import Combine
import iKeypadShared
#if canImport(UIKit)
import UIKit
#endif

/// Where the link to the Mac stands, in the terms the user sees.
public enum ConnectionPhase: Equatable {
    /// No Mac found yet since ``since``.
    case searching(since: Date)
    /// Found a Mac and opening a connection to it.
    case connecting
    case connected
    /// Lost a Mac we were connected to and trying to get it back.
    case reconnecting
}

/// The visible result of tapping a key.
public enum KeyFeedback: Equatable {
    case pending
    case succeeded
    case failed(String)
}

/// A short message shown at the bottom of the deck, such as why a key failed.
public struct DeckToast: Equatable, Identifiable {
    public let id = UUID()
    public let message: String
    public let isError: Bool
}

@MainActor
public final class DeckClient: ObservableObject {
    public static let shared = DeckClient()

    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var phase: ConnectionPhase = .searching(since: Date())
    @Published public private(set) var isUSB: Bool = false
    @Published public private(set) var hostName: String?
    @Published public private(set) var currentProfile: DeckProfile = DefaultProfiles.makeDefaultFallbackProfile()
    @Published public private(set) var appContext: AppContext?
    @Published public private(set) var appIcon: UIImage?
    @Published public private(set) var keyFeedback: [String: KeyFeedback] = [:]
    @Published public private(set) var toast: DeckToast?
    /// A layout the user froze; it stays on screen while the Mac's focus moves elsewhere.
    @Published public private(set) var pinnedProfile: DeckProfile?

    /// The layout on screen: the pinned one if any, otherwise the Mac's frontmost app.
    public var displayedProfile: DeckProfile { pinnedProfile ?? currentProfile }

    private var iconCache: [String: UIImage] = [:]
    private static let pendingTimeout: Duration = .seconds(4)

    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var connectionIsWired = false
    /// Wired (USB) attempts that ended before becoming ready, reset once connected. A single
    /// failure is not conclusive (any attempt can stall while the host re-registers after a
    /// restart), so USB is only skipped after ``maxWiredFailures`` in a row.
    private var consecutiveWiredFailures = 0
    private static let maxWiredFailures = 2
    private var receiveBuffer = Data()

    /// Internal (not private) so tests can create isolated clients; the app uses ``shared``.
    init() {}

    public func startDiscovery() {
        stop()

        let parameters = NWParameters()
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_sidekey._tcp", domain: nil)
        let browser = NWBrowser(for: descriptor, using: parameters)

        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if case .failed(let error) = state {
                    print("[Client] Bonjour browsing failed: \(error)")
                    self.showToast("Can't search the network: \(error.localizedDescription)", isError: true)
                }
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor [weak self] in
                guard let self = self, let result = results.first else { return }
                let wiredInterface = self.consecutiveWiredFailures >= Self.maxWiredFailures
                    ? nil
                    : result.interfaces.first { $0.type == .wiredEthernet }
                let wiredAvailable = wiredInterface != nil

                if self.isConnected {
                    // Already connected; only move a Wi-Fi connection onto USB once it appears.
                    guard wiredAvailable, !self.connectionIsWired else { return }
                    self.isConnected = false
                }
                // A pending attempt may target a stale Bonjour result from a host that has
                // since restarted; it can sit in .preparing indefinitely, so replace it.
                self.connection?.cancel()
                if self.phase != .reconnecting { self.phase = .connecting }
                self.connect(to: result.endpoint, via: wiredInterface)
            }
        }

        self.browser = browser
        browser.start(queue: .main)
    }

    /// Connect to the host.
    ///
    /// :param endpoint: Bonjour endpoint of the Mac host.
    /// :param interface: Pin the connection to this interface, typically the iPad's USB link to
    ///     the Mac (reported as ``wiredEthernet``). ``nil`` lets Network.framework choose, which
    ///     usually means Wi-Fi. Pin a specific interface rather than setting
    ///     ``requiredInterfaceType``: with a Bonjour endpoint the latter stalls in ``.preparing``.
    public func connect(to endpoint: NWEndpoint, via interface: NWInterface? = nil) {
        let parameters = NWParameters.tcp
        parameters.requiredInterface = interface
        let conn = NWConnection(to: endpoint, using: parameters)

        conn.stateUpdateHandler = { [weak self, weak conn] state in
            Task { @MainActor [weak self] in
                // Ignore late events from connections we have already replaced or cancelled;
                // acting on them would tear down the current, healthy connection.
                guard let self = self, let conn = conn, conn === self.connection else { return }
                switch state {
                case .ready:
                    self.isConnected = true
                    self.consecutiveWiredFailures = 0
                    // An unrestricted attempt may still have landed on USB; record the real path.
                    self.connectionIsWired = conn.currentPath?.usesInterfaceType(.wiredEthernet) ?? false
                    self.isUSB = self.connectionIsWired
                    self.phase = .connected
                    UIApplication.shared.isIdleTimerDisabled = true
                    #if os(iOS)
                    let deviceName = UIDevice.current.name
                    #else
                    let deviceName = Host.current().localizedName ?? "Client"
                    #endif
                    self.send(message: .handshake(clientName: deviceName))
                    self.receiveLoop()
                case .failed(let error):
                    self.handleDisconnection("Connection error: \(error.localizedDescription)")
                case .cancelled:
                    self.handleDisconnection("Disconnected")
                default:
                    break
                }
            }
        }

        self.connection = conn
        self.connectionIsWired = interface != nil
        conn.start(queue: .main)

        // Resolving a Bonjour endpoint can stall in .preparing when the host restarts and
        // re-registers its service mid-resolve, so give up and rediscover if not ready in time.
        Task { @MainActor [weak self, weak conn] in
            try? await Task.sleep(nanoseconds: Self.connectTimeoutNanoseconds)
            guard let self = self, let conn = conn, conn === self.connection, !self.isConnected else { return }
            self.handleDisconnection("Connection attempt timed out")
        }
    }

    private static let connectTimeoutNanoseconds: UInt64 = 5_000_000_000

    private func handleDisconnection(_ reason: String) {
        print("[Client] Disconnected: \(reason)")
        if connectionIsWired && !isConnected {
            consecutiveWiredFailures += 1
        }
        if isConnected || phase == .reconnecting || hostName != nil {
            phase = .reconnecting
        } else if case .searching = phase {
            // Keep the original start time so the setup hint appears on schedule.
        } else {
            phase = .searching(since: Date())
        }
        self.isConnected = false
        UIApplication.shared.isIdleTimerDisabled = false
        failPendingKeys("Lost the connection to your Mac.")
        let oldConnection = self.connection
        self.connection = nil
        oldConnection?.cancel()
        self.receiveBuffer.removeAll()
        // Retry discovery
        startDiscovery()
    }

    public func stop() {
        browser?.cancel()
        browser = nil
        connection?.cancel()
        connection = nil
        isConnected = false
    }

    private func receiveLoop() {
        guard let connection = self.connection else { return }

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self, weak connection] data, _, isComplete, error in
            Task { @MainActor [weak self] in
                guard let self = self, let connection = connection, connection === self.connection else { return }

                if let data = data, !data.isEmpty {
                    self.receiveBuffer.append(data)

                    while let message = FramedMessageProtocol.decode(from: &self.receiveBuffer) {
                        self.handleMessage(message)
                    }
                }

                if isComplete || error != nil {
                    self.handleDisconnection("Connection closed")
                } else {
                    self.receiveLoop()
                }
            }
        }
    }

    func handleMessage(_ message: DeckMessage) {
        switch message {
        case .profileUpdated(let profile):
            self.currentProfile = profile
            print("[Client] Received updated profile: \(profile.appName) (\(profile.keys.count) keys)")

        case .handshakeAck(let version, let hostName):
            print("[Client] Connected to host version \(version)")
            self.hostName = hostName

        case .appContextUpdated(let context):
            if let png = context.iconPNG, let image = UIImage(data: png) {
                iconCache[context.bundleIdentifier] = image
            }
            appIcon = iconCache[context.bundleIdentifier]
            appContext = context

        case .actionExecuted(let keyId, let success, let errorMessage):
            guard keyFeedback[keyId] != nil else { return }
            if success {
                setFeedback(.succeeded, for: keyId, clearAfter: .milliseconds(900))
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                let reason = errorMessage ?? "Your Mac couldn't run that key."
                setFeedback(.failed(reason), for: keyId, clearAfter: .seconds(3))
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                showToast(reason, isError: true)
            }

        case .handshake, .executeAction, .ping, .pong:
            break
        }
    }

    /// Send a key to the Mac and track its result.
    public func triggerKey(_ key: DeckKey) {
        guard isConnected else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            showToast("Not connected to your Mac yet.", isError: true)
            return
        }
        let profile = displayedProfile
        setFeedback(.pending, for: key.id, clearAfter: nil)
        send(message: .executeAction(keyId: key.id, profileId: profile.id, pinned: pinnedProfile != nil))
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.pendingTimeout)
            guard let self, self.keyFeedback[key.id] == .pending else { return }
            self.setFeedback(.failed("No reply from your Mac."), for: key.id, clearAfter: .seconds(3))
            self.showToast("No reply from your Mac.", isError: true)
        }
    }

    /// Icon last received for ``bundleIdentifier``, if any.
    public func cachedIcon(for bundleIdentifier: String) -> UIImage? {
        iconCache[bundleIdentifier]
    }

    /// Freeze the current layout on screen, or release a frozen one.
    public func togglePin() {
        pinnedProfile = pinnedProfile == nil ? currentProfile : nil
    }

    public func showToast(_ message: String, isError: Bool) {
        let toast = DeckToast(message: message, isError: isError)
        self.toast = toast
        UIAccessibility.post(notification: .announcement, argument: message)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3.5))
            if self?.toast?.id == toast.id { self?.toast = nil }
        }
    }

    func setFeedback(_ feedback: KeyFeedback, for keyId: String, clearAfter delay: Duration?) {
        keyFeedback[keyId] = feedback
        guard let delay else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            if self?.keyFeedback[keyId] == feedback { self?.keyFeedback[keyId] = nil }
        }
    }

    private func failPendingKeys(_ reason: String) {
        for (keyId, feedback) in keyFeedback where feedback == .pending {
            setFeedback(.failed(reason), for: keyId, clearAfter: .seconds(3))
        }
    }

    private func send(message: DeckMessage) {
        guard let connection = connection, isConnected else { return }
        do {
            let data = try FramedMessageProtocol.encode(message)
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("[Client] Error sending message: \(error)")
                }
            })
        } catch {
            print("[Client] Error encoding message: \(error)")
        }
    }
}
