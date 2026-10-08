import XCTest
import Network
import iKeypadShared
@testable import iKeypad

/// Discovery must heal itself: a client left waiting to reconnect has to keep looking for its
/// Mac, however the previous search ended.
@MainActor
final class DeckClientReconnectTests: XCTestCase {
    private var client: DeckClient!

    override func setUp() async throws {
        client = DeckClient(credentials: InMemoryPairingCredentials())
    }

    override func tearDown() async throws {
        client.stop()
    }

    func testFailedBrowsingStartsAFreshSearch() async throws {
        let before = client.discoveryStarts
        // kDNSServiceErr_ServiceNotRunning: what a browse reports after iOS suspends the app.
        client.handleBrowserState(.failed(.dns(-65563)))

        try await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertEqual(client.discoveryStarts, before + 1)
    }

    func testBrowsingThatHasNotFailedIsLeftAlone() async throws {
        let before = client.discoveryStarts
        client.handleBrowserState(.ready)

        try await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertEqual(client.discoveryStarts, before)
    }

    func testAnIdleDisconnectedClientSearchesAgain() {
        let before = client.discoveryStarts
        client.restartDiscoveryIfIdle()

        XCTAssertEqual(client.discoveryStarts, before + 1)
    }

    func testAConnectedClientIsNotDisturbed() {
        client.handleMessage(.handshakeAck(serverVersion: "2.1.0", hostName: "Studio Mac"))
        let before = client.discoveryStarts
        client.restartDiscoveryIfIdle()

        XCTAssertEqual(client.discoveryStarts, before)
    }
}
