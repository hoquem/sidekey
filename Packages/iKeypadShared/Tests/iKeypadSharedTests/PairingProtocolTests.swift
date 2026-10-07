import XCTest
@testable import iKeypadShared

final class PairingProtocolTests: XCTestCase {
    func testPairingMessagesRoundTripThroughFraming() throws {
        let messages: [DeckMessage] = [
            .challenge(nonce: Data([1, 2, 3]), hostId: "host-1", hostName: "Studio Mac"),
            .pair(code: "123456", clientId: "ipad-1", clientName: "iPad"),
            .paired(token: Data(repeating: 7, count: 32)),
            .pairingFailed(reason: "Wrong code."),
            .authenticate(clientId: "ipad-1", proof: Data([9, 9])),
            .authenticationFailed(reason: "Pair again."),
        ]
        for message in messages {
            var buffer = try FramedMessageProtocol.encode(message)
            XCTAssertEqual(FramedMessageProtocol.decode(from: &buffer), message)
        }
    }

    func testProofDependsOnTokenAndNonce() {
        let token = Data(repeating: 1, count: 32)
        let nonce = Data(repeating: 2, count: 32)
        let proof = PairingCrypto.proof(token: token, nonce: nonce)

        XCTAssertEqual(proof, PairingCrypto.proof(token: token, nonce: nonce))
        XCTAssertNotEqual(proof, PairingCrypto.proof(token: Data(repeating: 3, count: 32), nonce: nonce))
        XCTAssertNotEqual(proof, PairingCrypto.proof(token: token, nonce: Data(repeating: 4, count: 32)))
        XCTAssertTrue(PairingCrypto.verify(proof: proof, token: token, nonce: nonce))
        XCTAssertFalse(PairingCrypto.verify(proof: Data(proof.reversed()), token: token, nonce: nonce))
    }

    func testRandomValuesAreFreshAndCodesAreSixDigits() throws {
        XCTAssertNotEqual(try PairingCrypto.randomBytes(32), try PairingCrypto.randomBytes(32))
        XCTAssertEqual(try PairingCrypto.randomBytes(32).count, 32)
        for _ in 0..<50 {
            let code = try PairingCrypto.pairingCode()
            XCTAssertEqual(code.count, 6)
            XCTAssertTrue(code.allSatisfy(\.isNumber))
        }
    }
}
