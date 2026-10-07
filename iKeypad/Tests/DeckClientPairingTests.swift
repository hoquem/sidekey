import XCTest
import iKeypadShared
@testable import iKeypad

/// How the iPad client reacts to the Mac's pairing and authentication messages.
@MainActor
final class DeckClientPairingTests: XCTestCase {
    private var credentials: InMemoryPairingCredentials!
    private var client: DeckClient!

    override func setUp() async throws {
        credentials = InMemoryPairingCredentials()
        client = DeckClient(credentials: credentials)
    }

    func testChallengeFromAnUnknownMacAsksForThePairingCode() {
        client.handleMessage(.challenge(nonce: Data([1]), hostId: "mac-1", hostName: "Studio Mac"))

        XCTAssertEqual(client.phase, .pairing(error: nil))
        XCTAssertEqual(client.hostName, "Studio Mac")
        XCTAssertFalse(client.isConnected)
    }

    func testChallengeFromThePairedMacDoesNotAskForACode() {
        credentials.save(token: Data(repeating: 1, count: 32), hostId: "mac-1", hostName: "Studio Mac")
        client.handleMessage(.challenge(nonce: Data([1]), hostId: "mac-1", hostName: "Studio Mac"))

        XCTAssertNotEqual(client.phase, .pairing(error: nil))
    }

    func testPairedTokenIsStoredForTheChallengingMac() {
        client.handleMessage(.challenge(nonce: Data([1]), hostId: "mac-1", hostName: "Studio Mac"))
        client.handleMessage(.paired(token: Data(repeating: 7, count: 32)))

        XCTAssertEqual(credentials.token(for: "mac-1"), Data(repeating: 7, count: 32))
        XCTAssertEqual(credentials.pairedHostId, "mac-1")
    }

    func testWrongCodeShowsTheMacsReason() {
        client.handleMessage(.challenge(nonce: Data([1]), hostId: "mac-1", hostName: nil))
        client.handleMessage(.pairingFailed(reason: "That code is wrong."))

        XCTAssertEqual(client.phase, .pairing(error: "That code is wrong."))
    }

    func testRejectedTokenIsForgottenAndPairingStartsAgain() {
        credentials.save(token: Data(repeating: 1, count: 32), hostId: "mac-1", hostName: "Studio Mac")
        client.handleMessage(.challenge(nonce: Data([1]), hostId: "mac-1", hostName: "Studio Mac"))
        client.handleMessage(.authenticationFailed(reason: "Pair again."))

        XCTAssertNil(credentials.token(for: "mac-1"))
        XCTAssertEqual(client.phase, .pairing(error: "Pair again."))
    }

    func testHandshakeAckMeansConnected() {
        client.handleMessage(.handshakeAck(serverVersion: "2.1.0", hostName: "Studio Mac"))

        XCTAssertTrue(client.isConnected)
        XCTAssertEqual(client.phase, .connected)
    }
}
