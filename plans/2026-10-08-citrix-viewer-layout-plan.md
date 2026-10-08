# Citrix Viewer Layout Implementation Plan

> **Historical.** This plan built the first, single 15-key design. Live testing replaced it with modes (see the spec's Modes section and `makeCitrixViewerProfiles()`), and Task View with Ctrl+Alt+Del. Keep this file as a record of how the first version was built.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 15-key Citrix Viewer layout that sends Windows shortcuts into a Citrix session,
as specified in `plans/2026-10-08-citrix-viewer-layout.md`.

**Architecture:**
- **Shared package:** a new `KeyAction.windowsHotkey`, rendered in Windows notation on the iPad.
- **Mac:** a pure `CitrixKeyMapper` turns a Windows hotkey into the Mac key chord that the user's
  Citrix keyboard settings expect, and `ActionDispatcher` posts that chord as real modifier
  key-down/key-up events.

**Tech Stack:** Swift 5.9, XCTest, CoreGraphics `CGEvent`, SwiftPM (shared and Mac), and Xcode for
the iPad tests.

## Global Constraints

- **Citrix settings assumed:** Ctrl via "⌘ Command (left) or ^ Control"; Alt via "⌘⌥ Command
  (left)-Option"; Win via ⌘ Command (right); F1-F12 sent with ⌥ Option.
- **Win key:** right ⌘ is key code `0x36` with device flag bit `0x10` added to `maskCommand`.
  This was verified live on 2026-10-08.
- **Compatibility:** iPad builds 3 and 4 cannot decode `windowsHotkey`; build 5 is required.
- **Code style:** docstrings use reStructuredText; fail loudly; no em dashes in docs.
- **Before each code commit:** run `/simplify`. Commit messages are in the imperative mood.

**Test commands:**
- Shared: `cd Packages/iKeypadShared && swift test`
- Mac: `cd iKeypadMac && swift test`
- iPad: `xcodebuild test -project iKeypadApp.xcodeproj -scheme iKeypad -destination 'id=EC53A0D0-DA65-433F-8E48-26F9E117FFD2' -derivedDataPath <scratchpad>/dd-sim`

---

### Task 1: `windowsHotkey` action and Windows-notation hint (shared)

**Files:**
- Modify: `Packages/iKeypadShared/Sources/iKeypadShared/Models.swift`. Add an enum after
  `KeyModifier`, add a case to `KeyAction`, and extend `shortcutHint`.
- Test: `Packages/iKeypadShared/Tests/iKeypadSharedTests/WindowsHotkeyTests.swift` (new)

**Interfaces:**
- **Produces:**
  - `public enum WindowsModifier: String, Codable, Equatable, Sendable { case ctrl, alt, shift, win }`
  - `KeyAction.windowsHotkey(key: String, modifiers: [WindowsModifier])`
  - `shortcutHint` returns Windows notation for this case.

- [ ] **Step 1: Write the failing tests**

```swift
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
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd Packages/iKeypadShared && swift test --filter WindowsHotkeyTests`

Expected: a compile error, "type 'KeyAction' has no member 'windowsHotkey'".

- [ ] **Step 3: Implement**

In `Models.swift`, after `KeyModifier`:

```swift
/// A modifier on a Windows keyboard, for shortcuts sent into a remote Windows session.
public enum WindowsModifier: String, Codable, Equatable, Sendable {
    case ctrl, alt, shift, win
}
```

In `KeyAction`, add a case after `hotkey`:

```swift
    /// A Windows shortcut such as Ctrl+S, for a remote Windows session. The key ``"win"`` is the
    /// Windows key pressed on its own. The Mac translates it to the keys its remote-desktop app
    /// expects (see ``CitrixKeyMapper`` on the Mac).
    case windowsHotkey(key: String, modifiers: [WindowsModifier])
```

Replace `shortcutHint` with:

```swift
    /// The keyboard shortcut this action sends: Mac menu notation (``⌃⌥⇧⌘`` then the key) for
    /// ``hotkey``, Windows notation (``Ctrl+Shift+M``) for ``windowsHotkey``.
    public var shortcutHint: String? {
        switch self {
        case .hotkey(let key, let modifiers):
            let order: [(KeyModifier, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
            let prefix = order.filter { modifiers.contains($0.0) }.map(\.1).joined()
            return prefix + Self.keyGlyph(key)
        case .windowsHotkey(let key, let modifiers):
            let order: [(WindowsModifier, String)] = [(.ctrl, "Ctrl"), (.alt, "Alt"), (.shift, "Shift"), (.win, "Win")]
            let names = order.filter { modifiers.contains($0.0) }.map(\.1)
            return (names + [Self.windowsKeyName(key)]).joined(separator: "+")
        default:
            return nil
        }
    }

    private static func windowsKeyName(_ key: String) -> String {
        switch key.lowercased() {
        case "win": return "Win"
        case "return", "enter": return "Enter"
        case "escape", "esc": return "Esc"
        case "tab": return "Tab"
        case "space": return "Space"
        case "delete", "backspace": return "Backspace"
        case "up": return "↑"
        case "down": return "↓"
        case "left": return "←"
        case "right": return "→"
        default: return key.uppercased()
        }
    }
```

- [ ] **Step 4: Run all shared tests**

Run: `cd Packages/iKeypadShared && swift test`

Expected: all pass. The Mac package will not compile until Task 3 handles the new case.

- [ ] **Step 5: Commit** after Task 3 makes the Mac compile. The Mac's switch in
  `ActionDispatcher.execute` is exhaustive, so Tasks 1 to 3 land as one green commit:
  "Add a Windows hotkey action for remote Windows sessions".

### Task 2: `CitrixKeyMapper` (Mac, pure)

**Files:**
- Create: `iKeypadMac/Sources/iKeypadMac/CitrixKeyMapper.swift`
- Test: `iKeypadMac/Tests/iKeypadMacDaemonTests/CitrixKeyMapperTests.swift` (new)

**Interfaces:**
- **Consumes:** `WindowsModifier`, and `ActionDispatcher.shared.keyCodeForString(_:) -> CGKeyCode?`.
- **Produces:**

```swift
struct KeyChord: Equatable {
    /// Modifier keys pressed in this order, released in reverse.
    let modifierKeys: [CGKeyCode]
    /// The main key, or nil when the chord is a modifier on its own (the Win key).
    let keyCode: CGKeyCode?
    /// Flags for every posted event while the modifiers are held, including device bits.
    let flags: CGEventFlags
}
enum CitrixKeyMapper {
    struct UnknownKey: Error, Equatable { let key: String }
    static func chord(key: String, modifiers: [WindowsModifier]) throws -> KeyChord
}
```

- [ ] **Step 1: Write the failing tests**

```swift
import XCTest
import CoreGraphics
import iKeypadShared
@testable import iKeypadMacDaemon

final class CitrixKeyMapperTests: XCTestCase {
    private let leftControl: CGKeyCode = 0x3B, leftShift: CGKeyCode = 0x38
    private let leftCommand: CGKeyCode = 0x37, leftOption: CGKeyCode = 0x3A, rightCommand: CGKeyCode = 0x36
    private let ctrlFlags = CGEventFlags(rawValue: CGEventFlags.maskControl.rawValue | 0x01)
    private let shiftFlags = CGEventFlags(rawValue: CGEventFlags.maskShift.rawValue | 0x02)
    private let altFlags = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | 0x08 | CGEventFlags.maskAlternate.rawValue | 0x20)
    private let winFlags = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | 0x10)

    func testCtrlIsControl() throws {
        XCTAssertEqual(try CitrixKeyMapper.chord(key: "s", modifiers: [.ctrl]),
                       KeyChord(modifierKeys: [leftControl], keyCode: 0x01, flags: ctrlFlags))
    }

    func testCtrlShiftKeepsWindowsOrder() throws {
        XCTAssertEqual(try CitrixKeyMapper.chord(key: "m", modifiers: [.shift, .ctrl]),
                       KeyChord(modifierKeys: [leftControl, leftShift], keyCode: 0x2E, flags: ctrlFlags.union(shiftFlags)))
    }

    func testAltIsLeftCommandPlusOption() throws {
        XCTAssertEqual(try CitrixKeyMapper.chord(key: "tab", modifiers: [.alt]),
                       KeyChord(modifierKeys: [leftCommand, leftOption], keyCode: 0x30, flags: altFlags))
    }

    func testFunctionKeysAddOption() throws {
        // Alt already holds Option, so it is not pressed twice.
        XCTAssertEqual(try CitrixKeyMapper.chord(key: "f4", modifiers: [.alt]),
                       KeyChord(modifierKeys: [leftCommand, leftOption], keyCode: 0x76, flags: altFlags))
        XCTAssertEqual(try CitrixKeyMapper.chord(key: "f2", modifiers: []),
                       KeyChord(modifierKeys: [leftOption], keyCode: 0x78,
                                flags: CGEventFlags(rawValue: CGEventFlags.maskAlternate.rawValue | 0x20)))
    }

    func testWinIsRightCommand() throws {
        XCTAssertEqual(try CitrixKeyMapper.chord(key: "l", modifiers: [.win]),
                       KeyChord(modifierKeys: [rightCommand], keyCode: 0x25, flags: winFlags))
    }

    func testWinAloneIsJustRightCommand() throws {
        XCTAssertEqual(try CitrixKeyMapper.chord(key: "win", modifiers: []),
                       KeyChord(modifierKeys: [rightCommand], keyCode: nil, flags: winFlags))
    }

    func testUnknownKeyThrows() {
        XCTAssertThrowsError(try CitrixKeyMapper.chord(key: "pageup", modifiers: [.ctrl])) { error in
            XCTAssertEqual(error as? CitrixKeyMapper.UnknownKey, CitrixKeyMapper.UnknownKey(key: "pageup"))
        }
    }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd iKeypadMac && swift test --filter CitrixKeyMapperTests`

Expected: a compile error, "cannot find 'CitrixKeyMapper' in scope".

- [ ] **Step 3: Implement** `CitrixKeyMapper.swift`:

```swift
import CoreGraphics
import iKeypadShared

/// A key press with the modifier keys held around it, as a real keyboard would send it.
struct KeyChord: Equatable {
    /// Modifier keys pressed in this order and released in reverse.
    let modifierKeys: [CGKeyCode]
    /// The main key, or ``nil`` when the chord is a modifier on its own (the Win key).
    let keyCode: CGKeyCode?
    /// Flags for every posted event while the modifiers are held, including the device bits
    /// that tell left and right keys apart (Citrix reads right Command as the Win key).
    let flags: CGEventFlags
}

/// Translates a Windows shortcut into the Mac keys Citrix Viewer turns back into it.
///
/// Assumes these Citrix Viewer keyboard settings: Control via "Command (left) or Control", Alt via
/// "Command (left)-Option", the Windows key via Command (right), and F1 to F12 sent with Option.
/// Other settings send the wrong keys.
enum CitrixKeyMapper {
    struct UnknownKey: Error, Equatable { let key: String }

    private struct Modifier {
        let keyCode: CGKeyCode
        let flags: UInt64
    }

    private static let control = Modifier(keyCode: 0x3B, flags: CGEventFlags.maskControl.rawValue | 0x01)
    private static let shift = Modifier(keyCode: 0x38, flags: CGEventFlags.maskShift.rawValue | 0x02)
    private static let leftCommand = Modifier(keyCode: 0x37, flags: CGEventFlags.maskCommand.rawValue | 0x08)
    private static let option = Modifier(keyCode: 0x3A, flags: CGEventFlags.maskAlternate.rawValue | 0x20)
    private static let rightCommand = Modifier(keyCode: 0x36, flags: CGEventFlags.maskCommand.rawValue | 0x10)

    /// The chord for a Windows shortcut.
    ///
    /// :param key: A layout key name such as ``"s"``, ``"f4"`` or ``"win"`` (the Win key alone).
    /// :param modifiers: Windows modifiers, in any order.
    /// :returns: Modifiers in Windows order (Ctrl, Alt, Shift, Win), then Option for F-keys.
    /// :raises UnknownKey: when ``key`` has no Mac key code.
    static func chord(key: String, modifiers: [WindowsModifier]) throws -> KeyChord {
        var held: [Modifier] = []
        if modifiers.contains(.ctrl) { held.append(control) }
        if modifiers.contains(.alt) { held += [leftCommand, option] }
        if modifiers.contains(.shift) { held.append(shift) }
        if modifiers.contains(.win) || key == "win" { held.append(rightCommand) }

        var keyCode: CGKeyCode?
        if key != "win" {
            guard let code = ActionDispatcher.shared.keyCodeForString(key) else { throw UnknownKey(key: key) }
            keyCode = code
            let isFunctionKey = key.count >= 2 && key.lowercased().hasPrefix("f") && Int(key.dropFirst()) != nil
            if isFunctionKey && !held.contains(where: { $0.keyCode == option.keyCode }) { held.append(option) }
        }
        let flags = held.reduce(UInt64(0)) { $0 | $1.flags }
        return KeyChord(modifierKeys: held.map(\.keyCode), keyCode: keyCode, flags: CGEventFlags(rawValue: flags))
    }
}
```

- [ ] **Step 4: Run** `cd iKeypadMac && swift test --filter CitrixKeyMapperTests`. Expected: 6 tests
  pass once Task 3's `execute` case exists. Do Task 3 Step 3 first if the build complains about
  an exhaustive switch.

### Task 3: Post chords from `ActionDispatcher` (Mac)

**Files:**
- Modify: `iKeypadMac/Sources/iKeypadMac/ActionDispatcher.swift`. Change `execute` and add
  `triggerChord`.
- Modify: `iKeypadMac/Tests/iKeypadMacDaemonTests/DeckServerCharacterizationTests.swift`. Extend
  `testEveryBuiltInHotkeyMapsToAKeyCode`.

**Interfaces:**
- **Consumes:** `CitrixKeyMapper.chord(key:modifiers:)` and `KeyChord`.

- [ ] **Step 1: Extend the failing test.** Replace the loop body of
  `testEveryBuiltInHotkeyMapsToAKeyCode` with:

```swift
                switch key.action {
                case .hotkey(let name, _):
                    XCTAssertNotNil(ActionDispatcher.shared.keyCodeForString(name), "\(profile.appName) › \(key.label) uses unknown key \"\(name)\"")
                case .windowsHotkey(let name, let modifiers):
                    XCTAssertNoThrow(try CitrixKeyMapper.chord(key: name, modifiers: modifiers), "\(profile.appName) › \(key.label) uses unknown key \"\(name)\"")
                default:
                    continue
                }
```

- [ ] **Step 2: Implement.** In `execute`, add after the `.hotkey` case:

```swift
        case .windowsHotkey(let key, let modifiers):
            do {
                return triggerChord(try CitrixKeyMapper.chord(key: key, modifiers: modifiers))
            } catch {
                return (false, "Unrecognized key character: \(key)")
            }
```

Add the method below `triggerHotkey`:

```swift
    /// Post a chord as a keyboard would: each modifier key down, the key, then modifiers up.
    ///
    /// Remote-desktop apps such as Citrix Viewer read the modifier keys themselves (including
    /// which side was pressed), so flags on the main key alone are not enough.
    private func triggerChord(_ chord: KeyChord) -> (Bool, String?) {
        guard AXIsProcessTrusted() else {
            return (false, "Allow Sidekey in System Settings › Privacy & Security › Accessibility on your Mac.")
        }
        let source = CGEventSource(stateID: .hidSystemState)
        func post(_ code: CGKeyCode, down: Bool, flags: CGEventFlags) -> Bool {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down) else { return false }
            event.flags = flags
            event.post(tap: .cghidEventTap)
            usleep(20_000)
            return true
        }
        var ok = chord.modifierKeys.allSatisfy { post($0, down: true, flags: chord.flags) }
        if let key = chord.keyCode {
            ok = ok && post(key, down: true, flags: chord.flags) && post(key, down: false, flags: chord.flags)
        }
        // Release in reverse even after a failure, so no modifier is left held down.
        for code in chord.modifierKeys.reversed() { ok = post(code, down: false, flags: []) && ok }
        return ok ? (true, nil) : (false, "Failed to create CGEvent keyboard events")
    }
```

- [ ] **Step 3: Run the Mac and shared suites**

Run: `cd Packages/iKeypadShared && swift test` and `cd iKeypadMac && swift test`.

Expected: everything passes, including `CitrixKeyMapperTests` and `WindowsHotkeyTests`.

- [ ] **Step 4: `/simplify`, then commit Tasks 1 to 3:** "Add a Windows hotkey action for
  remote Windows sessions".

### Task 4: The Citrix Viewer layout

**Files:**
- Modify: `Packages/iKeypadShared/Sources/iKeypadShared/PopularAppProfiles.swift`. Add
  `makeCitrixViewerProfile`.
- Modify: `Packages/iKeypadShared/Sources/iKeypadShared/DefaultProfiles.swift`. Register it after
  `makeChatGPTProfile()`.
- Test: `Packages/iKeypadShared/Tests/iKeypadSharedTests/WindowsHotkeyTests.swift`

- [ ] **Step 1: Write the failing test** in `WindowsHotkeyTests`:

```swift
    func testCitrixViewerLayout() throws {
        let citrix = try XCTUnwrap(DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "com.citrix.receiver.icaviewer.mac" })
        let expected: [(String, String)] = [
            ("Start", "Win"), ("Task View", "Win+Tab"), ("File Explorer", "Win+E"), ("Show Desktop", "Win+D"), ("Lock", "Win+L"),
            ("Switch App", "Alt+Tab"), ("Snap Left", "Win+←"), ("Snap Right", "Win+→"), ("Close App", "Alt+F4"), ("Save", "Ctrl+S"),
            ("New", "Ctrl+N"), ("New Email", "Ctrl+Shift+M"), ("Reply", "Ctrl+R"), ("Send", "Ctrl+Enter"), ("Undo", "Ctrl+Z"),
        ]
        XCTAssertEqual(citrix.keys.map(\.label), expected.map(\.0))
        XCTAssertEqual(citrix.keys.map { $0.action.shortcutHint }, expected.map(\.1))
        XCTAssertEqual(citrix.keys.filter(\.requiresConfirm).map(\.label), ["Lock", "Close App"])
    }
```

- [ ] **Step 2: Run it.** Expected: it fails, because `XCTUnwrap` finds nil.

- [ ] **Step 3: Implement.** Add to `PopularAppProfiles.swift`, inside the extension, following
  the file's existing `DeckProfile(...)` pattern. The keys in order, as (label, icon, key,
  modifiers, role, requiresConfirm):

```swift
    /// Citrix Viewer (``com.citrix.receiver.icaviewer.mac``), the window of a Citrix session to a
    /// remote Windows desktop. Sidekey cannot see which Windows app is in front inside the
    /// session, so this one layout mixes Windows keys and Office keys. Shortcuts from Microsoft's
    /// "Keyboard shortcuts in Windows" and "Keyboard shortcuts for Outlook" (classic Outlook for
    /// New Email); Save and Undo are the standard Office shortcuts. Sent through
    /// ``CitrixKeyMapper`` on the Mac, which assumes the Citrix keyboard settings it documents.
    public static func makeCitrixViewerProfile() -> DeckProfile {
        let keys: [(String, String, String, [WindowsModifier], KeyRole, Bool)] = [
            ("Start", "square.grid.2x2", "win", [], .navigate, false),
            ("Task View", "rectangle.stack", "tab", [.win], .navigate, false),
            ("File Explorer", "folder", "e", [.win], .navigate, false),
            ("Show Desktop", "menubar.dock.rectangle", "d", [.win], .navigate, false),
            ("Lock", "lock", "l", [.win], .danger, true),
            ("Switch App", "arrow.left.arrow.right.square", "tab", [.alt], .navigate, false),
            ("Snap Left", "rectangle.lefthalf.filled", "left", [.win], .modify, false),
            ("Snap Right", "rectangle.righthalf.filled", "right", [.win], .modify, false),
            ("Close App", "xmark.square", "f4", [.alt], .danger, true),
            ("Save", "square.and.arrow.down", "s", [.ctrl], .run, false),
            ("New", "doc.badge.plus", "n", [.ctrl], .create, false),
            ("New Email", "square.and.pencil", "m", [.ctrl, .shift], .create, false),
            ("Reply", "arrowshape.turn.up.left", "r", [.ctrl], .create, false),
            ("Send", "paperplane", "return", [.ctrl], .run, false),
            ("Undo", "arrow.uturn.backward", "z", [.ctrl], .modify, false),
        ]
        return DeckProfile(
            id: "com.citrix.receiver.icaviewer.mac",
            appBundleIdentifier: "com.citrix.receiver.icaviewer.mac",
            appName: "Citrix Viewer",
            rows: 3,
            columns: 5,
            keys: keys.enumerated().map { index, key in
                DeckKey(position: index, label: key.0, iconSystemName: key.1,
                        action: .windowsHotkey(key: key.2, modifiers: key.3), role: key.4, requiresConfirm: key.5)
            }
        )
    }
```

In `DefaultProfiles.allDefaultProfiles()`, add `makeCitrixViewerProfile(),` after
`makeChatGPTProfile(),`.

- [ ] **Step 4: Run the shared and Mac tests.** Expected: everything passes, including the Mac
  checks that every icon is an SF Symbol and every key maps.
- [ ] **Step 5: `/simplify`, then commit:** "Add a Citrix Viewer layout for remote Windows desktops".

### Task 5: Build 5 locally and test live

- [ ] **Step 1:** Run the iPad tests with the xcodebuild command above. Expected: TEST SUCCEEDED.
- [ ] **Step 2:** Install both apps for testing:
  - **iPad:** install a Debug build with `devicectl`.
  - **Mac:** install a Developer ID build to /Applications, as earlier in the session.
- [ ] **Step 3:** With the user's permission and while they watch, bring Citrix to the front and
  tap each key, or post the same chords with a scratch script. Record each result.
  - Lock, Close App and Send are tried only where the user says it is safe.
  - If New Email does nothing (new Outlook), report it back; do not change it silently.

### Task 6: Docs and shipping (each step confirmed with the user)

- [ ] Bump the iPad build to 5 in `project.yml` (the `iKeypad` target's `CURRENT_PROJECT_VERSION`),
  and the Mac to `MARKETING_VERSION: "1.3.0"` / `CURRENT_PROJECT_VERSION: "5"`. Run `xcodegen generate`.
- [ ] Update the docs:
  - **README layouts table:** add a Citrix Viewer row (Start, Task View, File Explorer, Lock, New Email, Send).
  - **docs/support.html:** add a "Citrix Viewer" section with the four keyboard settings.
  - **appstore/metadata.md:** add Citrix Viewer to the app list.
  - **Release notes.**
- [ ] Fresh-subagent review of all outgoing text. Report the findings, then fix them.
- [ ] Upload iPad build 5 to TestFlight, and archive, notarize and publish Mac 1.3.0, only after
  the user confirms.
