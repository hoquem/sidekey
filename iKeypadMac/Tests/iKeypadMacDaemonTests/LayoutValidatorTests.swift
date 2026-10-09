import XCTest
import iKeypadShared
@testable import iKeypadMacDaemon

final class LayoutValidatorTests: XCTestCase {
    private let builtIns = DefaultProfiles.allDefaultProfiles()
    private let zoom = "us.zoom.xos"
    private let citrix = "com.citrix.receiver.icaviewer.mac"

    private func key(_ action: KeyAction, label: String = "Key") -> SlotChange {
        .key(CustomKey(label: label, iconSystemName: nil, role: nil, requiresConfirm: false, action: action))
    }

    private func problem(_ slots: [Int: SlotChange], layoutId: String? = nil, bundle: String? = nil,
                         fileName: String? = nil, version: Int = 1) -> String? {
        let id = layoutId ?? zoom
        var c = LayoutCustomisation(layoutId: id, appBundleIdentifier: bundle ?? id, appName: "App", slots: slots)
        c.version = version
        return LayoutValidator.problem(in: c, fileName: fileName ?? "\(id).json", builtIns: builtIns)
    }

    func testAValidFileHasNoProblem() {
        XCTAssertNil(problem([
            0: key(.hotkey(key: "y", modifiers: [.option])),
            1: key(.windowsHotkey(key: "l", modifiers: [.win])),
            2: key(.runShortcut(name: "Toggle Focus")),
            3: .removed,
        ]))
    }

    func testShellActionsAreRejected() {
        XCTAssertEqual(problem([3: key(.shellScript(command: "touch /tmp/x"))]),
                       "Slot 3: this action type is not allowed in user layouts.")
    }

    func testAppleScriptIsRejected() {
        XCTAssertEqual(problem([0: key(.appleScript(script: "beep"))]),
                       "Slot 0: this action type is not allowed in user layouts.")
    }

    func testNoActionIsRejected() {
        XCTAssertEqual(problem([0: key(.none)]), "Slot 0: this action type is not allowed in user layouts.")
    }

    func testAnUnknownVersionIsRejected() {
        XCTAssertEqual(problem([:], version: 2), "Unsupported version 2; this Sidekey reads version 1.")
    }

    func testSlotsOutsideTheGridAreRejected() {
        XCTAssertEqual(problem([15: .removed]), "Slot 15 is outside 0 to 14.")
        XCTAssertEqual(problem([-1: .removed]), "Slot -1 is outside 0 to 14.")
    }

    func testLabelsMustBeOneToSixteenCharacters() {
        XCTAssertEqual(problem([0: key(.hotkey(key: "a", modifiers: []), label: " ")]), "Slot 0: label is empty.")
        XCTAssertEqual(problem([0: key(.hotkey(key: "a", modifiers: []), label: String(repeating: "x", count: 17))]),
                       "Slot 0: label is longer than 16 characters.")
        XCTAssertNil(problem([0: key(.hotkey(key: "a", modifiers: []), label: String(repeating: "x", count: 16))]))
    }

    func testUnknownKeysFailAtLoadNotAtTap() {
        XCTAssertEqual(problem([0: key(.hotkey(key: "banana", modifiers: [.command]))]), "Slot 0: unknown key \"banana\".")
        XCTAssertEqual(problem([0: key(.windowsHotkey(key: "banana", modifiers: [.ctrl]))]),
                       "Slot 0: unknown Windows key \"banana\".")
    }

    func testAShortcutNeedsAName() {
        XCTAssertEqual(problem([0: key(.runShortcut(name: "  "))]), "Slot 0: shortcut name is empty.")
    }

    func testSwitchingLayoutOnlyReachesModesOfTheSameApp() {
        XCTAssertNil(problem([0: key(.switchProfile(profileId: "\(citrix).more"))], layoutId: citrix))
        XCTAssertEqual(problem([0: key(.switchProfile(profileId: zoom))], layoutId: citrix),
                       "Slot 0: \"\(zoom)\" is not another mode of this app.")
    }

    func testLayoutIdsCannotEscapeTheFolder() {
        XCTAssertEqual(problem([:], layoutId: "../evil"), "Invalid layoutId \"../evil\".")
        XCTAssertEqual(problem([:], layoutId: ".hidden"), "Invalid layoutId \".hidden\".")
        XCTAssertEqual(problem([:], layoutId: ""), "Invalid layoutId \"\".")
    }

    func testTheFileNameMustMatchTheLayoutId() {
        XCTAssertEqual(problem([:], fileName: "other.json"), "File name must be \(zoom).json.")
    }

    func testANewAppLayoutCannotShadowABuiltInApp() {
        XCTAssertEqual(problem([:], layoutId: "my-zoom", bundle: zoom),
                       "Zoom already has a built-in layout; customise layout \(zoom) instead.")
    }

    func testANewAppNeedsABundleIdentifier() {
        XCTAssertEqual(problem([:], layoutId: "com.example.App", bundle: ""), "appBundleIdentifier is empty.")
    }
}
