import XCTest
import UIKit
import iKeypadShared
@testable import iKeypad

/// Characterization tests: they pin how the iPad client reacts to messages from the Mac and to
/// taps today. Each test uses a fresh client with no network connection.
@MainActor
final class DeckClientCharacterizationTests: XCTestCase {
    private var client: DeckClient!

    override func setUp() async throws {
        client = DeckClient()
    }

    func testTapWhileDisconnectedShowsAnErrorAndSendsNothing() {
        let key = DeckKey(position: 0, label: "Run", action: .none)
        client.triggerKey(key)

        XCTAssertNil(client.keyFeedback[key.id])
        XCTAssertEqual(client.toast?.message, "Not connected to your Mac yet.")
        XCTAssertEqual(client.toast?.isError, true)
    }

    func testResultForAKeyThatIsNotPendingIsIgnored() {
        client.handleMessage(.actionExecuted(keyId: "unknown", success: false, errorMessage: "boom"))

        XCTAssertTrue(client.keyFeedback.isEmpty)
        XCTAssertNil(client.toast)
    }

    func testSuccessLightsThePendingKeyThenClears() async throws {
        client.setFeedback(.pending, for: "k", clearAfter: nil)
        client.handleMessage(.actionExecuted(keyId: "k", success: true, errorMessage: nil))

        XCTAssertEqual(client.keyFeedback["k"], .succeeded)
        XCTAssertNil(client.toast)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertNil(client.keyFeedback["k"], "success clears after 0.9 s")
    }

    func testFailureMarksTheKeyAndShowsTheMacsReason() {
        client.setFeedback(.pending, for: "k", clearAfter: nil)
        client.handleMessage(.actionExecuted(keyId: "k", success: false, errorMessage: "Needs permission"))

        XCTAssertEqual(client.keyFeedback["k"], .failed("Needs permission"))
        XCTAssertEqual(client.toast?.message, "Needs permission")
        XCTAssertEqual(client.toast?.isError, true)
    }

    func testFailureWithoutAReasonUsesAGenericMessage() {
        client.setFeedback(.pending, for: "k", clearAfter: nil)
        client.handleMessage(.actionExecuted(keyId: "k", success: false, errorMessage: nil))

        XCTAssertEqual(client.keyFeedback["k"], .failed("Your Mac couldn't run that key."))
    }

    func testHandshakeAckRecordsTheMacsName() {
        client.handleMessage(.handshakeAck(serverVersion: "2.0.0", hostName: "Studio Mac"))
        XCTAssertEqual(client.hostName, "Studio Mac")
    }

    func testAppIconIsCachedPerAppAndKeptOnTitleOnlyUpdates() throws {
        let png = try XCTUnwrap(Self.onePixelPNG())
        client.handleMessage(.appContextUpdated(context: Self.context("com.apple.Safari", title: "A", icon: png)))
        XCTAssertNotNil(client.appIcon)

        client.handleMessage(.appContextUpdated(context: Self.context("com.apple.Safari", title: "B", icon: nil)))
        XCTAssertNotNil(client.appIcon, "title-only update keeps the icon")
        XCTAssertEqual(client.appContext?.windowTitle, "B")

        client.handleMessage(.appContextUpdated(context: Self.context("com.apple.Terminal", title: "C", icon: nil)))
        XCTAssertNil(client.appIcon, "an app never seen with an icon has none")
        XCTAssertNotNil(client.cachedIcon(for: "com.apple.Safari"))
    }

    func testPinnedLayoutStaysWhileTheMacMovesOn() {
        let terminal = DefaultProfiles.makeTerminalProfile()
        let xcode = DefaultProfiles.makeXcodeProfile()
        client.handleMessage(.profileUpdated(profile: terminal))
        XCTAssertEqual(client.displayedProfile.id, terminal.id)

        client.togglePin()
        client.handleMessage(.profileUpdated(profile: xcode))
        XCTAssertEqual(client.currentProfile.id, xcode.id)
        XCTAssertEqual(client.displayedProfile.id, terminal.id)

        client.togglePin()
        XCTAssertEqual(client.displayedProfile.id, xcode.id)
    }

    // MARK: - Helpers

    private static func context(_ bundle: String, title: String, icon: Data?) -> AppContext {
        AppContext(bundleIdentifier: bundle, appName: bundle, windowTitle: title, iconPNG: icon,
                   accessibilityTrusted: true, chips: [])
    }

    private static func onePixelPNG() -> Data? {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).pngData { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
