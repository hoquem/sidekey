import XCTest
import AppKit
import iKeypadShared
@testable import iKeypadMacDaemon

@MainActor
final class ShortcutInputTests: XCTestCase {
    func testAKeyPressBecomesALayoutShortcutInMenuOrder() {
        let code = ActionDispatcher.shared.keyCodeForString("n")!
        let recorded = ShortcutRecorder.shortcut(keyCode: code, flags: [.command, .shift, .control, .option])
        XCTAssertEqual(recorded?.key, "n")
        XCTAssertEqual(recorded?.modifiers, [.control, .option, .shift, .command])
    }

    func testAKeyALayoutCannotSendIsNotRecorded() {
        XCTAssertNil(ShortcutRecorder.shortcut(keyCode: 0x3F, flags: [.function]))
    }

    func testSystemShortcutsAreNamed() {
        XCTAssertEqual(SystemShortcuts.conflict(key: "tab", modifiers: [.command]), "macOS uses this for the app switcher.")
        XCTAssertEqual(SystemShortcuts.conflict(key: "space", modifiers: [.command]), "macOS uses this for Spotlight.")
        XCTAssertEqual(SystemShortcuts.conflict(key: "4", modifiers: [.shift, .command]), "macOS uses this for screenshots.")
        XCTAssertNil(SystemShortcuts.conflict(key: "n", modifiers: [.command]))
    }

    func testModifierOrderDoesNotMatterForConflicts() {
        XCTAssertEqual(SystemShortcuts.conflict(key: "q", modifiers: [.command, .control]),
                       SystemShortcuts.conflict(key: "q", modifiers: [.control, .command]))
    }

    func testShortcutListOutputIsOneNamePerLine() {
        XCTAssertEqual(AppleShortcuts.parse("Toggle Focus\nStart Timer\n\n"), ["Start Timer", "Toggle Focus"])
        XCTAssertEqual(AppleShortcuts.parse(""), [])
    }
}
