import XCTest
@testable import iKeypad

/// The "no Mac found" hint offers USB only on iPad.
final class SetupHintTests: XCTestCase {
    func testIPadHintOffersUSBAndWiFi() {
        let hint = NowControllingView.padSetupHint
        XCTAssertTrue(hint.contains("USB cable"))
        XCTAssertTrue(hint.contains("Wi-Fi"))
    }

    func testIPhoneHintOffersWiFiOnly() {
        let hint = NowControllingView.phoneSetupHint
        XCTAssertFalse(hint.contains("USB"))
        XCTAssertTrue(hint.contains("Wi-Fi"))
    }
}
