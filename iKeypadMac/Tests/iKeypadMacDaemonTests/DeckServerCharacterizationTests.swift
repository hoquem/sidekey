import XCTest
import AppKit
import Darwin
import iKeypadShared
@testable import iKeypadMacDaemon

/// Tests of the Mac companion over a real TCP connection to a ``DeckServer`` on a private,
/// unadvertised port, with an in-memory pairing store so the real Keychain is never touched.
@MainActor
final class DeckServerCharacterizationTests: XCTestCase {
    /// A free port chosen by the system, so the tests never collide with another app's sockets.
    private static var port: UInt16 = 0
    static let store = InMemoryPairedDeviceStore()
    static let pairing = PairingWindow()
    static let server = DeckServer(store: store, hostId: "test-host", pairing: pairing)
    private static var started = false
    static let clientId = "test-client"
    static let token = Data(repeating: 42, count: 32)

    override func setUp() async throws {
        if !Self.started {
            Self.server.start(port: 0, serviceName: nil)
            Self.started = true
            // The system assigns the port once the listener is ready; until then it reads 0 or nil.
            for _ in 0..<100 where (Self.server.listeningPort ?? 0) == 0 {
                try await Task.sleep(nanoseconds: 50_000_000)
            }
            Self.port = Self.server.listeningPort ?? 0
            XCTAssertNotEqual(Self.port, 0, "test server never started listening")
        }
        try Self.store.removeAll()
        try Self.store.save(token: Self.token, for: Self.clientId, name: "Test iPad")
        Self.pairing.close()
    }

    /// Connect and authenticate as the paired test iPad.
    private func pairedClient() async throws -> TestClient {
        let client = try await TestClient.connect(port: Self.port)
        let challenge = try await client.receive(until: { !$0.isEmpty })
        guard case .challenge(let nonce, "test-host", _) = challenge.first else {
            XCTFail("expected a challenge first, got \(challenge)")
            return client
        }
        try client.send(.authenticate(clientId: Self.clientId, proof: PairingCrypto.proof(token: Self.token, nonce: nonce)))
        return client
    }

    // MARK: - Pairing and authentication

    /// Security: an unpaired device gets a challenge and nothing else: no layout, no app context.
    func testUnauthenticatedClientReceivesOnlyAChallenge() async throws {
        let client = try await TestClient.connect(port: Self.port)
        // Wait for the challenge so the server has registered this connection before broadcasting.
        let first = try await client.receive(until: { !$0.isEmpty })
        guard case .challenge = first.first else { return XCTFail("expected a challenge, got \(first)") }
        try client.send(.handshake(clientName: "stranger"))
        try await Task.sleep(nanoseconds: 200_000_000)
        Self.server.broadcast(message: .profileUpdated(profile: AppContextMonitor.shared.activeProfile))
        let later = try await client.receive(until: { _ in false }, timeout: 0.8)
        XCTAssertEqual(first.count + later.count, 1, "unpaired client received \(first + later)")
    }

    /// Security: an unpaired device cannot press keys.
    func testUnauthenticatedTapIsRefusedAndNotRun() async throws {
        let marker = FileManager.default.temporaryDirectory.appendingPathComponent("sidekey-unpaired-\(UUID().uuidString)")
        try await withTestProfile(secondAction: .shellScript(command: "touch '\(marker.path)'")) { profile in
            let client = try await TestClient.connect(port: Self.port)
            try client.send(.executeAction(keyId: profile.keys[1].id, profileId: profile.id, pinned: false))
            let messages = try await client.receive(until: { $0.contains(where: Self.isResult(for: profile.keys[1].id)) })
            XCTAssertTrue(messages.contains(.actionExecuted(keyId: profile.keys[1].id, success: false, errorMessage: "Pair this device with your Mac first.")), "got \(messages)")
            try await Task.sleep(nanoseconds: 300_000_000)
            XCTAssertFalse(FileManager.default.fileExists(atPath: marker.path), "unpaired tap ran")
        }
    }

    func testPairedClientIsWelcomedWithVersionHostAndActiveProfile() async throws {
        let client = try await pairedClient()
        let messages = try await client.receive(until: { $0.count >= 2 })
        guard case .handshakeAck(let version, let host) = messages.first else {
            return XCTFail("expected handshakeAck first, got \(messages)")
        }
        XCTAssertEqual(version, "2.1.0")
        XCTAssertNotNil(host)
        XCTAssertEqual(messages[1], .profileUpdated(profile: AppContextMonitor.shared.activeProfile))
    }

    func testWrongProofIsRefused() async throws {
        let client = try await TestClient.connect(port: Self.port)
        _ = try await client.receive(until: { !$0.isEmpty })
        try client.send(.authenticate(clientId: Self.clientId, proof: Data(repeating: 0, count: 32)))
        let messages = try await client.receive(until: { $0.contains(where: Self.isAuthFailure) })
        XCTAssertTrue(messages.contains(where: Self.isAuthFailure), "got \(messages)")
        XCTAssertFalse(messages.contains(where: { if case .profileUpdated = $0 { return true } else { return false } }))
    }

    func testPairingWithTheRightCodeIssuesATokenThatAuthenticates() async throws {
        try Self.pairing.open()
        let code = try XCTUnwrap(Self.pairing.code)
        let client = try await TestClient.connect(port: Self.port)
        _ = try await client.receive(until: { !$0.isEmpty })
        try client.send(.pair(code: code, clientId: "new-ipad", clientName: "New iPad"))
        let messages = try await client.receive(until: { $0.count >= 3 })
        guard case .paired(let token) = messages.first else { return XCTFail("expected paired first, got \(messages)") }
        XCTAssertEqual(token.count, 32)
        XCTAssertEqual(Self.store.token(for: "new-ipad"), token)
        XCTAssertFalse(Self.pairing.isOpen, "a used code must close the window")
        XCTAssertTrue(messages.contains(where: { if case .handshakeAck = $0 { return true } else { return false } }))
    }

    func testPairingWithAWrongCodeFails() async throws {
        try Self.pairing.open()
        let wrong = Self.pairing.code == "000000" ? "111111" : "000000"
        let client = try await TestClient.connect(port: Self.port)
        _ = try await client.receive(until: { !$0.isEmpty })
        try client.send(.pair(code: wrong, clientId: "x", clientName: "X"))
        let messages = try await client.receive(until: { $0.contains(where: Self.isPairFailure) })
        XCTAssertTrue(messages.contains(.pairingFailed(reason: "That code is wrong. Check the code in the Pair Device window on your Mac.")), "got \(messages)")
        XCTAssertNil(Self.store.token(for: "x"))
    }

    func testPairingWhenTheWindowIsClosedFails() async throws {
        let client = try await TestClient.connect(port: Self.port)
        _ = try await client.receive(until: { !$0.isEmpty })
        try client.send(.pair(code: "123456", clientId: "x", clientName: "X"))
        let messages = try await client.receive(until: { $0.contains(where: Self.isPairFailure) })
        XCTAssertTrue(messages.contains(.pairingFailed(reason: "Pairing isn't open. On your Mac, choose Pair Device in the Sidekey menu to get a code.")), "got \(messages)")
    }

    private static func isAuthFailure(_ m: DeckMessage) -> Bool { if case .authenticationFailed = m { return true }; return false }
    private static func isPairFailure(_ m: DeckMessage) -> Bool { if case .pairingFailed = m { return true }; return false }

    func testTapOnAStaleLayoutIsRejected() async throws {
        let result = try await execute(keyId: "k", profileId: "not-the-active-layout", pinned: false)
        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.error, "Layout changed. Tap again.")
    }

    func testPinnedTapOnAnUnknownLayoutIsRejected() async throws {
        let result = try await execute(keyId: "k", profileId: "no-such-layout", pinned: true)
        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.error, "Pinned layout is no longer available. Unpin and try again.")
    }

    func testPinnedTapForAnAppThatIsNotRunningIsRejected() async throws {
        let vsCode = "com.microsoft.VSCode"
        try XCTSkipIf(!NSRunningApplication.runningApplications(withBundleIdentifier: vsCode).isEmpty,
                      "VS Code is running; this test needs it closed")
        try XCTSkipIf(AppContextMonitor.shared.activeProfile.id == vsCode, "VS Code is the active layout")
        let result = try await execute(keyId: "\(vsCode)#0", profileId: vsCode, pinned: true)
        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.error, "VS Code isn't running.")
    }

    func testTapOnTheActiveLayoutRuns() async throws {
        try await withTestProfile { profile in
            let result = try await self.execute(keyId: profile.keys[0].id, profileId: profile.id, pinned: false)
            XCTAssertEqual(result.success, true)
            XCTAssertNil(result.error)
        }
    }

    func testTappingAModeKeySwitchesTheLayout() async throws {
        let monitor = AppContextMonitor.shared
        let citrix = "com.citrix.receiver.icaviewer.mac"
        monitor.updateActiveApp(bundleId: citrix, appName: "Citrix Viewer")
        defer {
            _ = monitor.switchMode(to: citrix)
            let front = NSWorkspace.shared.frontmostApplication
            monitor.updateActiveApp(bundleId: front?.bundleIdentifier ?? "", appName: front?.localizedName ?? "")
        }
        let moreKey = try XCTUnwrap(monitor.activeProfile.keys.first { $0.label == "More" })
        let result = try await execute(keyId: moreKey.id, profileId: citrix, pinned: false)
        XCTAssertEqual(result.success, true)
        XCTAssertEqual(monitor.activeProfile.id, "\(citrix).more")
    }

    /// A tap must name a layout; without one the Mac cannot know which key's action to run.
    func testTapWithoutALayoutIdIsRejected() async throws {
        let result = try await execute(keyId: "anything", profileId: nil, pinned: nil)
        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.error, "Update Sidekey on this device.")
    }

    /// Security: the Mac runs the action from its own layout. An action smuggled into the tap by
    /// a client (here a shell command) must never run.
    func testClientSuppliedActionIsIgnored() async throws {
        let marker = FileManager.default.temporaryDirectory.appendingPathComponent("sidekey-pwned-\(UUID().uuidString)")
        try await withTestProfile { profile in
            let client = try await pairedClient()
            try client.sendRaw(#"{"executeAction":{"keyId":"\#(profile.keys[0].id)","action":{"shellScript":{"command":"touch \#(marker.path)"}},"profileId":"\#(profile.id)","pinned":false}}"#)
            let messages = try await client.receive(until: { $0.contains(where: Self.isResult(for: profile.keys[0].id)) })
            XCTAssertTrue(messages.contains(where: Self.isResult(for: profile.keys[0].id)), "no reply in \(messages)")
            try await Task.sleep(nanoseconds: 300_000_000)
            XCTAssertFalse(FileManager.default.fileExists(atPath: marker.path), "client-supplied shell command ran")
        }
    }

    func testTheMacRunsItsOwnActionForTheKey() async throws {
        let marker = FileManager.default.temporaryDirectory.appendingPathComponent("sidekey-own-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: marker) }
        try await withTestProfile(secondAction: .shellScript(command: "touch '\(marker.path)'")) { profile in
            let result = try await self.execute(keyId: profile.keys[1].id, profileId: profile.id, pinned: false)
            XCTAssertEqual(result.success, true)
            XCTAssertTrue(FileManager.default.fileExists(atPath: marker.path))
        }
    }

    func testUnknownKeyIsRejected() async throws {
        try await withTestProfile { profile in
            let result = try await self.execute(keyId: "\(profile.id)#99", profileId: profile.id, pinned: false)
            XCTAssertEqual(result.success, false)
            XCTAssertEqual(result.error, "Layout changed. Tap again.")
        }
    }

    func testPingIsAnsweredWithPong() async throws {
        let client = try await pairedClient()
        try client.send(.ping)
        let messages = try await client.receive(until: { $0.contains(.pong) })
        XCTAssertTrue(messages.contains(.pong), "got \(messages)")
    }

    // MARK: - Helpers

    private func execute(keyId: String, profileId: String?, pinned: Bool?) async throws -> (success: Bool, error: String?) {
        let client = try await pairedClient()
        try client.send(.executeAction(keyId: keyId, profileId: profileId, pinned: pinned))
        let messages = try await client.receive(until: { $0.contains(where: Self.isResult(for: keyId)) })
        for message in messages {
            if case .actionExecuted(keyId, let success, let error) = message { return (success, error) }
        }
        XCTFail("no actionExecuted reply in \(messages)")
        return (false, nil)
    }

    private static func isResult(for keyId: String) -> (DeckMessage) -> Bool {
        { message in
            if case .actionExecuted(keyId, _, _) = message { return true }
            return false
        }
    }

    /// Make a harmless test layout the active one for the duration of ``body``.
    private func withTestProfile(secondAction: KeyAction = .none,
                                 _ body: (DeckProfile) async throws -> Void) async throws {
        let monitor = AppContextMonitor.shared
        let original = monitor.activeProfile
        let profile = DeckProfile(id: "test.layout", appBundleIdentifier: "test.layout", appName: "Test", keys: [
            DeckKey(position: 0, label: "Nothing", action: .none),
            DeckKey(position: 1, label: "Second", action: secondAction),
        ])
        monitor.activeProfile = profile
        defer { monitor.activeProfile = original }
        try await body(profile)
    }
}

@MainActor
final class AppContextMonitorCharacterizationTests: XCTestCase {
    func testProfilesAreFoundByStableId() {
        let monitor = AppContextMonitor.shared
        XCTAssertEqual(monitor.profile(withId: "default")?.appName, "System")
        XCTAssertEqual(monitor.profile(withId: "com.apple.Terminal")?.appName, "Terminal")
        XCTAssertNil(monitor.profile(withId: "no-such-layout"))
    }

    func testActiveProfileFollowsTheFrontmostAppOrFallsBack() throws {
        let frontmost = try XCTUnwrap(NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
        let expected = AppContextMonitor.shared.profile(withId: frontmost)?.id ?? "default"
        XCTAssertEqual(AppContextMonitor.shared.activeProfile.id, expected)
    }

    func testModeKeysSwitchTheCitrixLayoutAndAreRemembered() throws {
        let monitor = AppContextMonitor.shared
        let citrix = "com.citrix.receiver.icaviewer.mac"
        defer {
            monitor.updateActiveApp(bundleId: citrix, appName: "Citrix Viewer")
            XCTAssertTrue(monitor.switchMode(to: citrix))
            let front = NSWorkspace.shared.frontmostApplication
            monitor.updateActiveApp(bundleId: front?.bundleIdentifier ?? "", appName: front?.localizedName ?? "")
        }
        monitor.updateActiveApp(bundleId: citrix, appName: "Citrix Viewer")
        XCTAssertEqual(monitor.activeProfile.id, citrix, "Windows mode first")

        XCTAssertTrue(monitor.switchMode(to: "\(citrix).outlook"))
        XCTAssertEqual(monitor.activeProfile.id, "\(citrix).outlook")

        monitor.updateActiveApp(bundleId: "com.apple.Terminal", appName: "Terminal")
        XCTAssertFalse(monitor.switchMode(to: "\(citrix).word"), "a mode of another app cannot be chosen")
        XCTAssertEqual(monitor.activeProfile.id, "com.apple.Terminal")

        monitor.updateActiveApp(bundleId: citrix, appName: "Citrix Viewer")
        XCTAssertEqual(monitor.activeProfile.id, "\(citrix).outlook", "the mode is remembered")
    }

    func testTheActiveModeIsAnnouncedAsALitChip() throws {
        let outlook = try XCTUnwrap(AppContextMonitor.shared.profile(withId: "com.citrix.receiver.icaviewer.mac.outlook"))
        let chip = try XCTUnwrap(AppContextMonitor.modeChip(for: outlook))
        XCTAssertEqual(chip.id, "mode.com.citrix.receiver.icaviewer.mac.outlook")
        XCTAssertEqual(chip.label, "Outlook mode")
        XCTAssertEqual(chip.tone, .warn, "attention tones light the bound key on the iPad")
        XCTAssertEqual(chip.isOn, true)
        let terminal = try XCTUnwrap(AppContextMonitor.shared.profile(withId: "com.apple.Terminal"))
        XCTAssertNil(AppContextMonitor.modeChip(for: terminal), "apps without modes get no chip")
    }

    func testCurrentContextDescribesTheFrontmostAppWithItsIcon() throws {
        let context = try XCTUnwrap(AppContextMonitor.shared.currentContext())
        XCTAssertEqual(context.bundleIdentifier, NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
        XCTAssertNotNil(context.iconPNG)
    }
}

/// A minimal blocking TCP client speaking the framed protocol.
private final class TestClient {
    private let fd: Int32
    private var buffer = Data()

    private init(fd: Int32) { self.fd = fd }
    deinit { close(fd) }

    /// Connect, retrying while the listener comes up.
    static func connect(port: UInt16) async throws -> TestClient {
        for _ in 0..<50 {
            let fd = socket(AF_INET, SOCK_STREAM, 0)
            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = port.bigEndian
            addr.sin_addr.s_addr = inet_addr("127.0.0.1")
            let ok = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            if ok == 0 {
                var timeout = timeval(tv_sec: 0, tv_usec: 100_000)
                setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                return TestClient(fd: fd)
            }
            close(fd)
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        throw NSError(domain: "TestClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "server never came up"])
    }

    func send(_ message: DeckMessage) throws {
        write(try FramedMessageProtocol.encode(message))
    }

    /// Send a hand-written JSON frame, as an older or hostile client might.
    func sendRaw(_ json: String) throws {
        let payload = Data(json.utf8)
        var length = UInt32(payload.count).bigEndian
        var frame = Data(bytes: &length, count: 4)
        frame.append(payload)
        write(frame)
    }

    private func write(_ data: Data) {
        _ = data.withUnsafeBytes { Darwin.send(fd, $0.baseAddress, data.count, 0) }
    }

    /// Receive messages until ``done`` holds or ``timeout`` passes, yielding to the main actor
    /// so the server can run.
    func receive(until done: ([DeckMessage]) -> Bool, timeout: TimeInterval = 3) async throws -> [DeckMessage] {
        var messages: [DeckMessage] = []
        let deadline = Date().addingTimeInterval(timeout)
        var chunk = [UInt8](repeating: 0, count: 65_536)
        while !done(messages), Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
            let n = recv(fd, &chunk, chunk.count, MSG_DONTWAIT)
            if n > 0 { buffer.append(contentsOf: chunk[0..<n]) }
            while let message = FramedMessageProtocol.decode(from: &buffer) { messages.append(message) }
        }
        return messages
    }
}


@MainActor
final class PairingWindowTests: XCTestCase {
    func testFiveWrongAttemptsCloseTheWindow() throws {
        let window = PairingWindow()
        try window.open()
        let wrong = window.code == "000000" ? "111111" : "000000"
        for _ in 0..<(PairingWindow.maxAttempts - 1) { XCTAssertEqual(window.attempt(wrong), .wrong) }
        XCTAssertEqual(window.attempt(wrong), .wrong)
        XCTAssertFalse(window.isOpen)
        XCTAssertEqual(window.attempt(wrong), .closed)
    }

    func testAnExpiredCodeIsRefused() throws {
        let window = PairingWindow()
        let start = Date()
        try window.open(now: start)
        let code = try XCTUnwrap(window.code)
        XCTAssertEqual(window.attempt(code, now: start.addingTimeInterval(PairingWindow.lifetime + 1)), .closed)
    }

    func testTheWindowClosesItselfWhenTheCodeExpires() async throws {
        let window = PairingWindow()
        try window.open(lifetime: 0.2)
        XCTAssertTrue(window.isOpen)
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertFalse(window.isOpen, "an expired code must disappear from the menu")
    }

    func testTheRightCodeIsAcceptedOnce() throws {
        let window = PairingWindow()
        try window.open()
        let code = try XCTUnwrap(window.code)
        XCTAssertEqual(window.attempt(code), .accepted)
        XCTAssertEqual(window.attempt(code), .closed)
    }
}

final class ActionDispatcherTests: XCTestCase {
    /// Every hotkey in every built-in layout must name a key the Mac can send; an unknown name
    /// would fail on the user's first tap with "Unrecognized key character".
    func testEveryBuiltInHotkeyMapsToAKeyCode() {
        for profile in DefaultProfiles.allDefaultProfiles() {
            for key in profile.keys {
                switch key.action {
                case .hotkey(let name, _):
                    XCTAssertNotNil(ActionDispatcher.shared.keyCodeForString(name), "\(profile.appName) › \(key.label) uses unknown key \"\(name)\"")
                case .windowsHotkey(let name, let modifiers):
                    XCTAssertNoThrow(try CitrixKeyMapper.chord(key: name, modifiers: modifiers), "\(profile.appName) › \(key.label) uses unknown key \"\(name)\"")
                default:
                    continue
                }
            }
        }
    }

    /// Every built-in key icon must be a real SF Symbol; an unknown name draws a blank key.
    func testEveryBuiltInIconIsAnSFSymbol() {
        for profile in DefaultProfiles.allDefaultProfiles() {
            for key in profile.keys {
                guard let icon = key.iconSystemName else { continue }
                XCTAssertNotNil(NSImage(systemSymbolName: icon, accessibilityDescription: nil), "\(profile.appName) › \(key.label) uses unknown icon \"\(icon)\"")
            }
        }
    }
}

