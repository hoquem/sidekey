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
            (.windowsHotkey(key: "forwarddelete", modifiers: [.alt, .ctrl]), "Ctrl+Alt+Del"),
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

    private let citrixBundle = "com.citrix.receiver.icaviewer.mac"

    func testCitrixViewerModesShareOneModeRowWithWindowsFirst() {
        let modes = DefaultProfiles.allDefaultProfiles().filter { $0.appBundleIdentifier == citrixBundle }
        XCTAssertEqual(modes.map(\.id), [citrixBundle, "\(citrixBundle).outlook", "\(citrixBundle).word",
                                          "\(citrixBundle).excel", "\(citrixBundle).more", "\(citrixBundle).teams",
                                          "\(citrixBundle).browser", "\(citrixBundle).vscode"])
        let rowModes = Array(modes.prefix(5))
        for mode in modes {
            // The More picker has three app keys; every other mode fills its ten slots.
            XCTAssertEqual(mode.keys.count, mode.id.hasSuffix(".more") ? 8 : 15, mode.id)
            let modeRow = mode.keys.filter { $0.position >= 10 }.sorted { $0.position < $1.position }
            XCTAssertEqual(modeRow.map(\.label), ["Windows", "Outlook", "Word", "Excel", "More"], mode.id)
            XCTAssertEqual(modeRow.map(\.action), rowModes.map { .switchProfile(profileId: $0.id) }, mode.id)
            XCTAssertEqual(modeRow.map(\.toggleChipId), rowModes.map { "mode.\($0.id)" }, mode.id)
        }
    }

    func testMoreOpensAPickerOfFurtherModes() throws {
        let more = try XCTUnwrap(DefaultProfiles.allDefaultProfiles().first { $0.id == "\(citrixBundle).more" })
        let picker = more.keys.filter { $0.position < 10 }.sorted { $0.position < $1.position }
        XCTAssertEqual(picker.map(\.label), ["Teams", "Browser", "VS Code"])
        XCTAssertEqual(picker.map(\.action), ["teams", "browser", "vscode"].map { .switchProfile(profileId: "\(citrixBundle).\($0)") })
    }

    func testCitrixModeKeys() throws {
        let expected: [String: [(String, String)]] = [
            citrixBundle: [("Start", "Win"), ("Ctrl+Alt+Del", "Ctrl+Alt+Del"), ("File Explorer", "Win+E"), ("Show Desktop", "Win+D"), ("Lock", "Win+L"),
                           ("Switch App", "Alt+Tab"), ("Snap Left", "Win+←"), ("Snap Right", "Win+→"), ("Close App", "Alt+F4"), ("Undo", "Ctrl+Z")],
            "\(citrixBundle).outlook": [("New Email", "Ctrl+Shift+M"), ("Reply", "Ctrl+R"), ("Reply All", "Ctrl+Shift+R"), ("Forward", "Ctrl+F"), ("Send", "Ctrl+Enter"),
                                        ("Mark Read", "Ctrl+Q"), ("Mark Unread", "Ctrl+U"), ("Delete", "Ctrl+D"), ("Mail", "Ctrl+1"), ("Calendar", "Ctrl+2")],
            "\(citrixBundle).word": [("Save", "Ctrl+S"), ("Undo", "Ctrl+Z"), ("Redo", "Ctrl+Y"), ("Bold", "Ctrl+B"), ("Italic", "Ctrl+I"),
                                     ("Underline", "Ctrl+U"), ("Bullets", "Ctrl+Shift+L"), ("Find", "Ctrl+F"), ("Comment", "Ctrl+Alt+M"), ("Track Changes", "Ctrl+Shift+E")],
            "\(citrixBundle).excel": [("Save", "Ctrl+S"), ("Undo", "Ctrl+Z"), ("AutoSum", "Alt+="), ("Fill Down", "Ctrl+D"), ("Format Cells", "Ctrl+1"),
                                      ("Filter", "Ctrl+Shift+L"), ("Insert Cells", "Ctrl+Shift+="), ("Delete Cells", "Ctrl+-"), ("Edit Cell", "F2"), ("Today's Date", "Ctrl+;")],
            "\(citrixBundle).teams": [("Mute", "Ctrl+Shift+M"), ("Video", "Ctrl+Shift+O"), ("Raise Hand", "Ctrl+Shift+K"), ("Share", "Ctrl+Shift+E"), ("Leave", "Ctrl+Shift+H"),
                                      ("Accept Call", "Ctrl+Shift+S"), ("Decline", "Ctrl+Shift+D"), ("New Chat", "Ctrl+N"), ("Search", "Ctrl+E"), ("Chat", "Ctrl+1")],
            "\(citrixBundle).browser": [("New Tab", "Ctrl+T"), ("Close Tab", "Ctrl+W"), ("Reopen Tab", "Ctrl+Shift+T"), ("Reload", "Ctrl+R"), ("Address Bar", "Ctrl+L"),
                                        ("Back", "Alt+←"), ("Forward", "Alt+→"), ("Next Tab", "Ctrl+Tab"), ("Prev Tab", "Ctrl+Shift+Tab"), ("Find", "Ctrl+F")],
            "\(citrixBundle).vscode": [("Command Palette", "Ctrl+Shift+P"), ("Quick Open", "Ctrl+P"), ("Terminal", "Ctrl+`"), ("Explorer", "Ctrl+Shift+E"), ("Search", "Ctrl+Shift+F"),
                                       ("Source Control", "Ctrl+Shift+G"), ("Comment", "Ctrl+/"), ("Save", "Ctrl+S"), ("Go to Definition", "F12"), ("Run", "F5")],
        ]
        let holds: [String: [String]] = [citrixBundle: ["Lock", "Close App"], "\(citrixBundle).teams": ["Leave"]]
        for (id, keys) in expected {
            let mode = try XCTUnwrap(DefaultProfiles.allDefaultProfiles().first { $0.id == id }, id)
            let top = mode.keys.filter { $0.position < 10 }.sorted { $0.position < $1.position }
            XCTAssertEqual(top.map(\.label), keys.map(\.0), id)
            XCTAssertEqual(top.map { $0.action.shortcutHint }, keys.map(\.1), id)
            XCTAssertEqual(mode.keys.filter(\.requiresConfirm).map(\.label), holds[id] ?? [], id)
        }
    }
}
