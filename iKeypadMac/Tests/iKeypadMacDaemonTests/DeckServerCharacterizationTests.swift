import XCTest
import AppKit
import Darwin
import iKeypadShared
@testable import iKeypadMacDaemon

/// Characterization tests: they pin how the Mac companion behaves today, over a real TCP
/// connection to ``DeckServer`` on a private, unadvertised port.
@MainActor
final class DeckServerCharacterizationTests: XCTestCase {
    private static let port: UInt16 = 49_298
    private static var started = false

    override func setUp() async throws {
        if !Self.started {
            DeckServer.shared.start(port: Self.port, serviceName: nil)
            Self.started = true
        }
    }

    /// Current behaviour: the active layout is sent as soon as a client connects, then again
    /// right after the handshake acknowledgement (a harmless duplicate).
    func testConnectAndHandshakeEachSendTheActiveProfile() async throws {
        let client = try await TestClient.connect(port: Self.port)
        try client.send(.handshake(clientName: "test"))

        let messages = try await client.receive(until: { $0.count >= 3 })
        let activeId = AppContextMonitor.shared.activeProfile.id
        XCTAssertEqual(messages.first, .profileUpdated(profile: AppContextMonitor.shared.activeProfile))
        guard let ackIndex = messages.firstIndex(where: { if case .handshakeAck = $0 { return true } else { return false } }) else {
            return XCTFail("no handshakeAck in \(messages)")
        }
        guard case .handshakeAck(let version, let host) = messages[ackIndex] else { return }
        XCTAssertEqual(version, "2.0.0")
        XCTAssertNotNil(host)
        guard ackIndex + 1 < messages.count, case .profileUpdated(let profile) = messages[ackIndex + 1] else {
            return XCTFail("expected profileUpdated right after handshakeAck in \(messages)")
        }
        XCTAssertEqual(profile.id, activeId)
    }

    func testTapOnAStaleLayoutIsRejected() async throws {
        let result = try await execute(profileId: "not-the-active-layout", pinned: false)
        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.error, "Layout changed. Tap again.")
    }

    func testPinnedTapOnAnUnknownLayoutIsRejected() async throws {
        let result = try await execute(profileId: "no-such-layout", pinned: true)
        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.error, "Pinned layout is no longer available. Unpin and try again.")
    }

    func testPinnedTapForAnAppThatIsNotRunningIsRejected() async throws {
        let vsCode = "com.microsoft.VSCode"
        try XCTSkipIf(!NSRunningApplication.runningApplications(withBundleIdentifier: vsCode).isEmpty,
                      "VS Code is running; this test needs it closed")
        try XCTSkipIf(AppContextMonitor.shared.activeProfile.id == vsCode, "VS Code is the active layout")
        let result = try await execute(profileId: vsCode, pinned: true)
        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.error, "VS Code isn't running.")
    }

    func testTapOnTheActiveLayoutRuns() async throws {
        let result = try await execute(profileId: AppContextMonitor.shared.activeProfile.id, pinned: false)
        XCTAssertEqual(result.success, true)
        XCTAssertNil(result.error)
    }

    /// Current behaviour: a tap without a layout id skips the stale-layout check entirely.
    func testTapWithoutALayoutIdRunsUnchecked() async throws {
        let result = try await execute(profileId: nil, pinned: nil)
        XCTAssertEqual(result.success, true)
    }

    func testPingIsAnsweredWithPong() async throws {
        let client = try await TestClient.connect(port: Self.port)
        try client.send(.ping)
        let messages = try await client.receive(until: { $0.contains(.pong) })
        XCTAssertTrue(messages.contains(.pong), "got \(messages)")
    }

    // MARK: - Helpers

    private func execute(profileId: String?, pinned: Bool?) async throws -> (success: Bool, error: String?) {
        let client = try await TestClient.connect(port: Self.port)
        try client.send(.executeAction(keyId: "probe", action: .none, profileId: profileId, pinned: pinned))
        let messages = try await client.receive(until: { $0.contains(where: Self.isProbeResult) })
        for message in messages {
            if case .actionExecuted("probe", let success, let error) = message { return (success, error) }
        }
        XCTFail("no actionExecuted reply in \(messages)")
        return (false, nil)
    }

    private static func isProbeResult(_ message: DeckMessage) -> Bool {
        if case .actionExecuted("probe", _, _) = message { return true }
        return false
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
        let data = try FramedMessageProtocol.encode(message)
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
