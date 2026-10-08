import XCTest
@testable import iKeypadShared

final class WindowsHotkeyTests: XCTestCase {
    func testHintUsesWindowsNotation() {
        let cases: [(KeyAction, String)] = [
            (.windowsHotkey(key: "win", modifiers: []), "Win"),
            (.windowsHotkey(key: "tab", modifiers: [.win]), "Win+Tab"),
            (.windowsHotkey(key: "left", modifiers: [.win]), "Win+←"),
            (.windowsHotkey(key: "f4", modifiers: [.alt]), "Alt+F4"),
            (.windowsHotkey(key: "m", modifiers: [.shift, .ctrl]), "Ctrl+Shift+M"),
            (.windowsHotkey(key: "return", modifiers: [.ctrl]), "Ctrl+Enter"),
            (.windowsHotkey(key: "escape", modifiers: []), "Esc"),
        ]
        for (action, hint) in cases {
            XCTAssertEqual(action.shortcutHint, hint)
        }
    }

    func testWindowsHotkeySurvivesTheWire() throws {
        let key = DeckKey(position: 0, label: "Lock", action: .windowsHotkey(key: "l", modifiers: [.win]), requiresConfirm: true)
        let profile = DeckProfile(id: "p", appBundleIdentifier: "b", appName: "A", rows: 3, columns: 5, keys: [key])
        var buffer = try FramedMessageProtocol.encode(.profileUpdated(profile: profile))
        XCTAssertEqual(FramedMessageProtocol.decode(from: &buffer), .profileUpdated(profile: profile))
    }
}
