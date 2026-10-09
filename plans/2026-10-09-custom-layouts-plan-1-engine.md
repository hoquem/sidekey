# Custom Layouts, Part 1 (Engine) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** User layout files in `~/Library/Application Support/Sidekey/Layouts/` change the keys Sidekey sends to the iPad, safely, with no editor yet.

**Architecture:** A shared file format (`LayoutCustomisation`) and a pure merge function (`LayoutResolver`) live in `Packages/iKeypadShared`. The Mac validates each file (`LayoutValidator`), reads and writes the folder (`UserLayoutStore`), and installs resolved layouts into `AppContextMonitor`, which already broadcasts the active layout to the iPad. Part 2 (`2026-10-09-custom-layouts-plan-2-editor.md`) adds the visual editor on top.

**Tech Stack:** Swift 5.9, SwiftUI/AppKit, XCTest, SwiftPM (tests), XcodeGen + xcodebuild (app target).

**Spec:** `plans/2026-10-09-custom-layouts-design.md` (amended in commit 3621101).

## Global Constraints

- macOS 13.0 deployment target (`project.yml`, `iKeypadMac/Package.swift`); iPadOS 16 for the shared package.
- No new dependencies. No new `KeyAction` cases: iPad builds 5 and 6 must decode every layout the Mac sends.
- The iPad app does not change in this work.
- User layouts may contain only `hotkey`, `windowsHotkey`, `runShortcut` and `switchProfile` actions.
- Label length: 1 to 16 characters. Slots: 0 to 14. File format `version`: 1.
- Doc comments follow the repo's style: `///` prose with `:param name:` and `:returns:` fields (see `AppContextMonitor.switchMode(to:)`).
- Commit messages: imperative one-line summary, why in the body when not obvious, ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. No `feat:` prefixes.
- Every task that adds a Mac source file ends with `xcodegen generate`, a `SidekeyMac` build, and the regenerated `iKeypadApp.xcodeproj/project.pbxproj` in the commit. SwiftPM passing does not prove the Xcode target builds.
- Work in the worktree `/Users/mahmud/projects/ikeypad-custom-layouts` (branch `custom-layouts`). All paths below are relative to it.

## Commands used throughout

```bash
# Shared package tests
(cd Packages/iKeypadShared && swift test --filter <TestClass>)
# Mac tests
(cd iKeypadMac && swift test --filter <TestClass>)
# Xcode app target (run after adding a Mac source file)
xcodegen generate && xcodebuild -project iKeypadApp.xcodeproj -scheme SidekeyMac -configuration Debug -destination 'platform=macOS' build 2>&1 | grep -E "error:|\*\* BUILD"
```

Expected for the build: `** BUILD SUCCEEDED **`.

## File map

| File | Status | Responsibility |
|---|---|---|
| `iKeypadMac/Sources/iKeypadMac/ActionDispatcher.swift` | Modify | Run Apple Shortcuts without a shell. |
| `iKeypadMac/Tests/iKeypadMacDaemonTests/ShortcutActionTests.swift` | Create | Proves a shortcut name never reaches a shell. |
| `Packages/iKeypadShared/Sources/iKeypadShared/LayoutCustomisation.swift` | Create | File format: `LayoutCustomisation`, `SlotChange`, `CustomKey`. |
| `Packages/iKeypadShared/Sources/iKeypadShared/LayoutResolver.swift` | Create | Base layout + customisation gives a `DeckProfile`. |
| `Packages/iKeypadShared/Tests/iKeypadSharedTests/LayoutResolverTests.swift` | Create | Merge rules and JSON format. |
| `iKeypadMac/Sources/iKeypadMac/LayoutValidator.swift` | Create | Load-time safety and sanity rules. |
| `iKeypadMac/Tests/iKeypadMacDaemonTests/LayoutValidatorTests.swift` | Create | One test per rule. |
| `iKeypadMac/Sources/iKeypadMac/UserLayoutStore.swift` | Create | Read, validate, save and delete files in one folder. |
| `iKeypadMac/Tests/iKeypadMacDaemonTests/UserLayoutStoreTests.swift` | Create | Disk behaviour in a temp folder. |
| `iKeypadMac/Sources/iKeypadMac/AppContextMonitor.swift` | Modify | Install, uninstall and reload user layouts. |
| `iKeypadMac/Tests/iKeypadMacDaemonTests/UserLayoutInstallTests.swift` | Create | Install semantics, security, regression. |
| `iKeypadMac/Sources/iKeypadMac/iKeypadMacApp.swift` | Modify | Load at launch; Reload Layouts and error items in the menu. |

---

### Task 1: Run Apple Shortcuts without a shell

Security prerequisite. Today `runShortcut` runs `zsh -c '/usr/bin/shortcuts run "<name>"'`, so a name with `"` or `$(...)` runs any command. User layouts make the name untrusted.

**Files:**
- Modify: `iKeypadMac/Sources/iKeypadMac/ActionDispatcher.swift:29-30` and `:110-130`
- Create: `iKeypadMac/Tests/iKeypadMacDaemonTests/ShortcutActionTests.swift`

**Interfaces:**
- Consumes: `ActionDispatcher.shared.execute(action:) -> (success: Bool, error: String?)` (unchanged).
- Produces: nothing new for later tasks; behaviour change only.

- [ ] **Step 1: Write the failing test**

`iKeypadMac/Tests/iKeypadMacDaemonTests/ShortcutActionTests.swift`:

```swift
import XCTest
import iKeypadShared
@testable import iKeypadMacDaemon

final class ShortcutActionTests: XCTestCase {
    /// Security: a shortcut name is untrusted text once users can write layouts. Quotes and
    /// command separators in it must reach the shortcuts tool as part of the name, never a shell.
    func testShortcutNameIsNeverRunByAShell() {
        let marker = FileManager.default.temporaryDirectory.appendingPathComponent("sidekey-shortcut-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: marker) }

        let result = ActionDispatcher.shared.execute(action: .runShortcut(name: "x\"; touch '\(marker.path)'; echo \""))

        XCTAssertFalse(FileManager.default.fileExists(atPath: marker.path), "the shortcut name ran as a shell command")
        XCTAssertFalse(result.success, "no shortcut has that name, so the run must fail")
    }

    /// A name that looks like an option is still a name.
    func testShortcutNameStartingWithADashIsNotAnOption() {
        let result = ActionDispatcher.shared.execute(action: .runShortcut(name: "-h"))
        XCTAssertFalse(result.success)
        XCTAssertFalse(result.error?.contains("USAGE") ?? false, "the name was read as --help")
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `(cd iKeypadMac && swift test --filter ShortcutActionTests)`
Expected: `testShortcutNameIsNeverRunByAShell` FAILS with "the shortcut name ran as a shell command" (and `result.success` is true, from the trailing `echo`).

- [ ] **Step 3: Implement**

In `ActionDispatcher.execute(action:)`, replace the `runShortcut` case:

```swift
        case .runShortcut(let name):
            return runShortcut(named: name)
```

Replace `executeShellScript(_:)` (lines 110-130) with:

```swift
    private func executeShellScript(_ command: String) -> (Bool, String?) {
        runProcess(URL(fileURLWithPath: "/bin/zsh"), arguments: ["-c", command])
    }

    /// Run the Apple Shortcut called ``name``. The name goes to the shortcuts tool as a single
    /// argument after ``--``, never through a shell: user layouts make it untrusted text.
    private func runShortcut(named name: String) -> (Bool, String?) {
        runProcess(URL(fileURLWithPath: "/usr/bin/shortcuts"), arguments: ["run", "--", name])
    }

    /// Run ``executable`` and wait for it.
    ///
    /// :returns: Success, or the tool's standard error (or exit code) when it fails.
    private func runProcess(_ executable: URL, arguments: [String]) -> (Bool, String?) {
        let task = Process()
        task.executableURL = executable
        task.arguments = arguments

        let pipe = Pipe()
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus != 0 {
                let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errMsg = String(data: errData, encoding: .utf8) ?? "Command failed with code \(task.terminationStatus)"
                return (false, errMsg)
            }
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `(cd iKeypadMac && swift test --filter ShortcutActionTests)`
Expected: 2 tests pass. Then the whole Mac suite: `(cd iKeypadMac && swift test 2>&1 | grep -E "Executed .* tests")`
Expected: `Executed N tests, with 0 failures` (N = 36 before this plan, plus 2).

- [ ] **Step 5: Build the app target and commit**

Run the Xcode build command. Expected: `** BUILD SUCCEEDED **`.

```bash
xcodegen generate
git add iKeypadMac/Sources/iKeypadMac/ActionDispatcher.swift iKeypadMac/Tests/iKeypadMacDaemonTests/ShortcutActionTests.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Run Apple Shortcuts without a shell

The shortcut name was interpolated into zsh -c, so quotes or \$(...) in
a name ran arbitrary commands. Not reachable in 1.3.0 (one built-in
name, and the iPad cannot send actions), but user layouts would make
the name untrusted.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Layout file format and resolver (shared)

**Files:**
- Create: `Packages/iKeypadShared/Sources/iKeypadShared/LayoutCustomisation.swift`
- Create: `Packages/iKeypadShared/Sources/iKeypadShared/LayoutResolver.swift`
- Create: `Packages/iKeypadShared/Tests/iKeypadSharedTests/LayoutResolverTests.swift`

**Interfaces:**
- Consumes: `DeckProfile`, `DeckKey`, `KeyAction`, `KeyRole` from `Models.swift`. `DeckProfile.init` derives key ids as `"<id>#<position>"`.
- Produces:
  - `public struct LayoutCustomisation: Codable, Equatable, Sendable { static let currentVersion = 1; var version: Int; var layoutId: String; var appBundleIdentifier: String; var appName: String; var slots: [Int: SlotChange]; init(layoutId:appBundleIdentifier:appName:slots:) }`
  - `public enum SlotChange: Codable, Equatable, Sendable { case key(CustomKey); case removed }`
  - `public struct CustomKey: Codable, Equatable, Sendable { var label: String; var iconSystemName: String?; var role: KeyRole?; var requiresConfirm: Bool; var action: KeyAction; init(label:iconSystemName:role:requiresConfirm:action:); init(_ key: DeckKey) }`
  - `public enum LayoutResolver { static func resolve(_ customisation: LayoutCustomisation, base: DeckProfile?) -> DeckProfile }`

- [ ] **Step 1: Write the failing tests**

`Packages/iKeypadShared/Tests/iKeypadSharedTests/LayoutResolverTests.swift`:

```swift
import XCTest
@testable import iKeypadShared

final class LayoutResolverTests: XCTestCase {
    private let base = DeckProfile(id: "us.zoom.xos", appBundleIdentifier: "us.zoom.xos", appName: "Zoom", keys: [
        DeckKey(position: 0, label: "Mute", iconSystemName: "mic", action: .hotkey(key: "a", modifiers: [.command, .shift]), role: .modify),
        DeckKey(position: 1, label: "Video", action: .hotkey(key: "v", modifiers: [.command, .shift]), role: .modify),
        DeckKey(position: 9, label: "End", action: .hotkey(key: "w", modifiers: [.command]), role: .danger, requiresConfirm: true),
    ])
    private let raiseHand = CustomKey(label: "Raise Hand", iconSystemName: "hand.raised", role: .run,
                                      requiresConfirm: false, action: .hotkey(key: "y", modifiers: [.option]))

    private func customisation(_ slots: [Int: SlotChange]) -> LayoutCustomisation {
        LayoutCustomisation(layoutId: "us.zoom.xos", appBundleIdentifier: "us.zoom.xos", appName: "Zoom", slots: slots)
    }

    func testUntouchedSlotsComeFromTheBase() {
        let layout = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        XCTAssertEqual(layout.keys.first { $0.position == 0 }, base.keys[0])
        XCTAssertEqual(layout.keys.first { $0.position == 9 }, base.keys[2])
    }

    func testAChangedSlotTakesTheUsersKey() {
        let layout = LayoutResolver.resolve(customisation([1: .key(raiseHand)]), base: base)
        let key = try! XCTUnwrap(layout.keys.first { $0.position == 1 })
        XCTAssertEqual(key.label, "Raise Hand")
        XCTAssertEqual(key.action, .hotkey(key: "y", modifiers: [.option]))
        XCTAssertEqual(key.role, .run)
    }

    func testARemovedSlotIsEmpty() {
        let layout = LayoutResolver.resolve(customisation([9: .removed]), base: base)
        XCTAssertNil(layout.keys.first { $0.position == 9 })
        XCTAssertEqual(layout.keys.count, 2)
    }

    func testKeyIdsStayStableSoPinnedTapsStillLand() {
        let layout = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        XCTAssertEqual(Set(layout.keys.map(\.id)), ["us.zoom.xos#0", "us.zoom.xos#1", "us.zoom.xos#4", "us.zoom.xos#9"])
    }

    func testANewAppStartsFromAnEmptyThreeByFiveLayout() {
        let new = LayoutCustomisation(layoutId: "com.example.App", appBundleIdentifier: "com.example.App", appName: "Example",
                                      slots: [0: .key(raiseHand)])
        let layout = LayoutResolver.resolve(new, base: nil)
        XCTAssertEqual(layout.id, "com.example.App")
        XCTAssertEqual(layout.appBundleIdentifier, "com.example.App")
        XCTAssertEqual(layout.appName, "Example")
        XCTAssertEqual([layout.rows, layout.columns], [3, 5])
        XCTAssertEqual(layout.keys.map(\.label), ["Raise Hand"])
    }

    /// A file cannot move a built-in layout to another app by naming a different bundle.
    func testTheBaseDecidesWhichAppALayoutBelongsTo() {
        var c = customisation([:])
        c.appBundleIdentifier = "com.example.Other"
        c.appName = "Other"
        let layout = LayoutResolver.resolve(c, base: base)
        XCTAssertEqual(layout.appBundleIdentifier, "us.zoom.xos")
        XCTAssertEqual(layout.appName, "Zoom")
    }

    /// The file format in the spec decodes, and encoding keeps "removed" as a plain string.
    func testTheSpecExampleDecodesAndRoundTrips() throws {
        let json = #"""
        {
          "version": 1,
          "layoutId": "us.zoom.xos",
          "appBundleIdentifier": "us.zoom.xos",
          "appName": "Zoom",
          "slots": {
            "4": { "key": { "label": "Raise Hand", "iconSystemName": "hand.raised",
                            "role": "run", "requiresConfirm": false,
                            "action": { "hotkey": { "key": "y", "modifiers": ["opt"] } } } },
            "9": "removed"
          }
        }
        """#
        let decoded = try JSONDecoder().decode(LayoutCustomisation.self, from: Data(json.utf8))
        XCTAssertEqual(decoded, customisation([4: .key(raiseHand), 9: .removed]))

        let encoded = try JSONEncoder().encode(decoded)
        XCTAssertTrue(String(decoding: encoded, as: UTF8.self).contains(#""9":"removed""#))
        XCTAssertEqual(try JSONDecoder().decode(LayoutCustomisation.self, from: encoded), decoded)
    }

    func testAnUnknownSlotWordIsAnError() {
        let json = #"{"version":1,"layoutId":"a","appBundleIdentifier":"a","appName":"A","slots":{"0":"gone"}}"#
        XCTAssertThrowsError(try JSONDecoder().decode(LayoutCustomisation.self, from: Data(json.utf8)))
    }

    func testCustomKeyCopiesADeckKey() {
        XCTAssertEqual(CustomKey(base.keys[2]), CustomKey(label: "End", iconSystemName: nil, role: .danger,
                                                         requiresConfirm: true, action: .hotkey(key: "w", modifiers: [.command])))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `(cd Packages/iKeypadShared && swift test --filter LayoutResolverTests)`
Expected: build FAILS with `cannot find 'CustomKey' in scope` (and `LayoutCustomisation`, `LayoutResolver`).

- [ ] **Step 3: Implement the format**

`Packages/iKeypadShared/Sources/iKeypadShared/LayoutCustomisation.swift`:

```swift
import Foundation

/// A user's changes to one layout, stored as ``<layoutId>.json`` in Sidekey's Layouts folder on
/// the Mac. Slots not listed keep the base layout's key: the built-in layout with the same id, or
/// nothing for an app Sidekey has no layout for. See ``LayoutResolver``.
public struct LayoutCustomisation: Codable, Equatable, Sendable {
    /// The only format this build reads; a file with another version is rejected, never guessed at.
    public static let currentVersion = 1

    public var version: Int
    /// The built-in layout's id, or the app's bundle id for an app with no built-in layout.
    public var layoutId: String
    public var appBundleIdentifier: String
    public var appName: String
    /// Changed slots by position, 0 to 14 in reading order of the 3 by 5 grid.
    public var slots: [Int: SlotChange]

    public init(layoutId: String, appBundleIdentifier: String, appName: String, slots: [Int: SlotChange] = [:]) {
        self.version = Self.currentVersion
        self.layoutId = layoutId
        self.appBundleIdentifier = appBundleIdentifier
        self.appName = appName
        self.slots = slots
    }
}

/// What the user did to one slot.
public enum SlotChange: Equatable, Sendable {
    /// Show this key instead of the base layout's.
    case key(CustomKey)
    /// Leave the slot empty even if the base layout has a key there.
    case removed
}

extension SlotChange: Codable {
    private enum CodingKeys: String, CodingKey { case key }
    private static let removedWord = "removed"

    // JSON: the string "removed", or {"key": {...}}.
    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let word = try? single.decode(String.self) {
            guard word == Self.removedWord else {
                throw DecodingError.dataCorruptedError(in: single, debugDescription: "Expected \"removed\" or a key, found \"\(word)\"")
            }
            self = .removed
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = .key(try container.decode(CustomKey.self, forKey: .key))
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .removed:
            var single = encoder.singleValueContainer()
            try single.encode(Self.removedWord)
        case .key(let key):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(key, forKey: .key)
        }
    }
}

/// A key the user made. Unlike ``DeckKey`` it has no id (derived from layout and slot), badge or
/// live toggle: those belong to built-in keys that read app state.
public struct CustomKey: Codable, Equatable, Sendable {
    public var label: String
    public var iconSystemName: String?
    public var role: KeyRole?
    /// Fire only after a press and hold, for disruptive keys.
    public var requiresConfirm: Bool
    public var action: KeyAction

    public init(label: String, iconSystemName: String?, role: KeyRole?, requiresConfirm: Bool, action: KeyAction) {
        self.label = label
        self.iconSystemName = iconSystemName
        self.role = role
        self.requiresConfirm = requiresConfirm
        self.action = action
    }

    /// The user-editable part of ``key``, for starting an edit from a built-in key.
    public init(_ key: DeckKey) {
        self.init(label: key.label, iconSystemName: key.iconSystemName, role: key.role,
                  requiresConfirm: key.requiresConfirm, action: key.action)
    }
}
```

- [ ] **Step 4: Implement the resolver**

`Packages/iKeypadShared/Sources/iKeypadShared/LayoutResolver.swift`:

```swift
import Foundation

/// Applies a user's ``LayoutCustomisation`` to a base layout. Pure: no disk, no UI.
public enum LayoutResolver {
    /// The layout the Mac registers for ``customisation``.
    ///
    /// :param customisation: The user's changes.
    /// :param base: The built-in layout with the same id, or ``nil`` for an app with none. When
    ///     present it decides the app, name and grid size, so a file cannot move a built-in
    ///     layout to another app.
    /// :returns: The base's keys with the changed slots replaced or removed. Key ids are derived
    ///     by ``DeckProfile`` from the layout id and slot, so they match the built-in ones.
    public static func resolve(_ customisation: LayoutCustomisation, base: DeckProfile?) -> DeckProfile {
        var keys = Dictionary((base?.keys ?? []).map { ($0.position, $0) }, uniquingKeysWith: { first, _ in first })
        for (position, change) in customisation.slots {
            switch change {
            case .removed:
                keys[position] = nil
            case .key(let custom):
                keys[position] = DeckKey(position: position, label: custom.label, iconSystemName: custom.iconSystemName,
                                         action: custom.action, role: custom.role, requiresConfirm: custom.requiresConfirm)
            }
        }
        return DeckProfile(
            id: customisation.layoutId,
            appBundleIdentifier: base?.appBundleIdentifier ?? customisation.appBundleIdentifier,
            appName: base?.appName ?? customisation.appName,
            rows: base?.rows ?? 3,
            columns: base?.columns ?? 5,
            keys: keys.values.sorted { $0.position < $1.position }
        )
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `(cd Packages/iKeypadShared && swift test --filter LayoutResolverTests)`
Expected: 9 tests pass. Then the whole shared suite: `(cd Packages/iKeypadShared && swift test 2>&1 | grep -E "Executed .* tests")`, expected 0 failures.

- [ ] **Step 6: Commit**

The shared package is compiled into the Xcode targets through the package reference, so no `xcodegen` is needed for new files here; still run the Xcode build command to be sure. Expected: `** BUILD SUCCEEDED **`.

```bash
git add Packages/iKeypadShared/Sources/iKeypadShared/LayoutCustomisation.swift Packages/iKeypadShared/Sources/iKeypadShared/LayoutResolver.swift Packages/iKeypadShared/Tests/iKeypadSharedTests/LayoutResolverTests.swift
git commit -m "Add the user layout file format and resolver

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Validate layout files on the Mac

**Files:**
- Create: `iKeypadMac/Sources/iKeypadMac/LayoutValidator.swift`
- Create: `iKeypadMac/Tests/iKeypadMacDaemonTests/LayoutValidatorTests.swift`

**Interfaces:**
- Consumes: Task 2 types; `ActionDispatcher.shared.keyCodeForString(_:) -> CGKeyCode?` (internal); `CitrixKeyMapper.chord(key:modifiers:) throws -> KeyChord`.
- Produces: `enum LayoutValidator { static let maxLabelLength = 16; static func problem(in: LayoutCustomisation, fileName: String, builtIns: [DeckProfile]) -> String? }`. `nil` means safe to install.

- [ ] **Step 1: Write the failing tests**

`iKeypadMac/Tests/iKeypadMacDaemonTests/LayoutValidatorTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `(cd iKeypadMac && swift test --filter LayoutValidatorTests)`
Expected: build FAILS with `cannot find 'LayoutValidator' in scope`.

- [ ] **Step 3: Implement**

`iKeypadMac/Sources/iKeypadMac/LayoutValidator.swift`:

```swift
import Foundation
import iKeypadShared

/// Decides whether a user layout file is safe to install. Runs on every load, not only in the
/// editor, because layout files can be edited by hand or tampered with. Sidekey holds the
/// Accessibility and Apple Events permissions, so a user layout may only send keys or run the
/// user's own Apple Shortcuts: never a shell command or an AppleScript.
enum LayoutValidator {
    static let maxLabelLength = 16
    static let slots = 0..<15

    /// The first problem with ``customisation``, or ``nil`` when it is safe to install.
    ///
    /// :param customisation: The decoded file.
    /// :param fileName: The file's name, which must be ``<layoutId>.json``.
    /// :param builtIns: Sidekey's built-in layouts, to find the app a layout belongs to and its modes.
    /// :returns: A sentence for the user, naming the slot when the problem is in one.
    static func problem(in customisation: LayoutCustomisation, fileName: String, builtIns: [DeckProfile]) -> String? {
        let c = customisation
        guard c.version == LayoutCustomisation.currentVersion else {
            return "Unsupported version \(c.version); this Sidekey reads version \(LayoutCustomisation.currentVersion)."
        }
        guard !c.layoutId.isEmpty, !c.layoutId.contains("/"), !c.layoutId.hasPrefix(".") else {
            return "Invalid layoutId \"\(c.layoutId)\"."
        }
        guard fileName == "\(c.layoutId).json" else { return "File name must be \(c.layoutId).json." }

        let base = builtIns.first { $0.id == c.layoutId }
        if base == nil {
            guard !c.appBundleIdentifier.isEmpty else { return "appBundleIdentifier is empty." }
            if let app = builtIns.first(where: { $0.appBundleIdentifier == c.appBundleIdentifier }) {
                return "\(app.appName) already has a built-in layout; customise layout \(app.id) instead."
            }
        }
        let bundle = base?.appBundleIdentifier ?? c.appBundleIdentifier
        let modeIds = Set(builtIns.filter { $0.appBundleIdentifier == bundle }.map(\.id))

        for position in c.slots.keys.sorted() {
            guard slots.contains(position) else { return "Slot \(position) is outside 0 to 14." }
            guard case .key(let key) = c.slots[position] else { continue }
            if let problem = problem(in: key, modeIds: modeIds) { return "Slot \(position): \(problem)" }
        }
        return nil
    }

    private static func problem(in key: CustomKey, modeIds: Set<String>) -> String? {
        if key.label.trimmingCharacters(in: .whitespaces).isEmpty { return "label is empty." }
        if key.label.count > maxLabelLength { return "label is longer than \(maxLabelLength) characters." }
        switch key.action {
        case .hotkey(let name, _):
            return ActionDispatcher.shared.keyCodeForString(name) == nil ? "unknown key \"\(name)\"." : nil
        case .windowsHotkey(let name, let modifiers):
            return (try? CitrixKeyMapper.chord(key: name, modifiers: modifiers)) == nil ? "unknown Windows key \"\(name)\"." : nil
        case .runShortcut(let name):
            return name.trimmingCharacters(in: .whitespaces).isEmpty ? "shortcut name is empty." : nil
        case .switchProfile(let id):
            return modeIds.contains(id) ? nil : "\"\(id)\" is not another mode of this app."
        case .shellScript, .appleScript, .none:
            return "this action type is not allowed in user layouts."
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `(cd iKeypadMac && swift test --filter LayoutValidatorTests)`
Expected: 14 tests pass.

- [ ] **Step 5: Build the app target and commit**

Run the Xcode build command. Expected: `** BUILD SUCCEEDED **`.

```bash
git add iKeypadMac/Sources/iKeypadMac/LayoutValidator.swift iKeypadMac/Tests/iKeypadMacDaemonTests/LayoutValidatorTests.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Validate user layout files before they load

Only key, Windows key, Apple Shortcut and mode-switch actions pass, so a
tampered file cannot use Sidekey's permissions to run commands.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Store layout files in a folder

**Files:**
- Create: `iKeypadMac/Sources/iKeypadMac/UserLayoutStore.swift`
- Create: `iKeypadMac/Tests/iKeypadMacDaemonTests/UserLayoutStoreTests.swift`

**Interfaces:**
- Consumes: Task 2 types; `LayoutValidator.problem(in:fileName:builtIns:)`.
- Produces:
  - `struct LayoutFileError: Equatable { let fileName: String; let reason: String }`
  - `struct UserLayoutStore { let directory: URL; static var defaultDirectory: URL; func loadAll(builtIns: [DeckProfile]) -> (customisations: [LayoutCustomisation], errors: [LayoutFileError]); func save(_: LayoutCustomisation) throws; func delete(layoutId: String) throws }`

- [ ] **Step 1: Write the failing tests**

`iKeypadMac/Tests/iKeypadMacDaemonTests/UserLayoutStoreTests.swift`:

```swift
import XCTest
import iKeypadShared
@testable import iKeypadMacDaemon

final class UserLayoutStoreTests: XCTestCase {
    private var directory: URL!
    private var store: UserLayoutStore!
    private let builtIns = DefaultProfiles.allDefaultProfiles()
    private let zoom = "us.zoom.xos"

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("sidekey-layouts-\(UUID().uuidString)")
        store = UserLayoutStore(directory: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func zoomChange(_ action: KeyAction) -> LayoutCustomisation {
        LayoutCustomisation(layoutId: zoom, appBundleIdentifier: zoom, appName: "Zoom", slots: [
            3: .key(CustomKey(label: "Key", iconSystemName: nil, role: nil, requiresConfirm: false, action: action)),
        ])
    }

    private func write(_ text: String, to name: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: directory.appendingPathComponent(name))
    }

    func testAMissingFolderMeansNoCustomisations() {
        let result = store.loadAll(builtIns: builtIns)
        XCTAssertEqual(result.customisations, [])
        XCTAssertEqual(result.errors, [])
    }

    func testASavedLayoutLoadsBack() throws {
        let change = zoomChange(.hotkey(key: "y", modifiers: [.option]))
        try store.save(change)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("\(zoom).json").path))
        XCTAssertEqual(store.loadAll(builtIns: builtIns).customisations, [change])
    }

    func testDeleteRemovesTheFile() throws {
        try store.save(zoomChange(.hotkey(key: "y", modifiers: [.option])))
        try store.delete(layoutId: zoom)
        XCTAssertEqual(store.loadAll(builtIns: builtIns).customisations, [])
    }

    func testDeletingALayoutThatIsNotSavedIsAnError() {
        XCTAssertThrowsError(try store.delete(layoutId: zoom))
    }

    func testSaveRefusesALayoutTheValidatorRejects() {
        XCTAssertThrowsError(try store.save(zoomChange(.shellScript(command: "true"))))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("\(zoom).json").path))
    }

    func testATamperedFileIsReportedAndNotLoaded() throws {
        let tampered = try JSONEncoder().encode(zoomChange(.shellScript(command: "touch /tmp/x")))
        try write(String(decoding: tampered, as: UTF8.self), to: "\(zoom).json")
        let result = store.loadAll(builtIns: builtIns)
        XCTAssertEqual(result.customisations, [])
        XCTAssertEqual(result.errors, [LayoutFileError(fileName: "\(zoom).json",
                                                       reason: "Slot 3: this action type is not allowed in user layouts.")])
    }

    func testBrokenJSONIsReported() throws {
        try write("{ not json", to: "\(zoom).json")
        let result = store.loadAll(builtIns: builtIns)
        XCTAssertEqual(result.customisations, [])
        XCTAssertEqual(result.errors.map(\.fileName), ["\(zoom).json"])
        XCTAssertTrue(result.errors[0].reason.hasPrefix("Not a valid layout file"))
    }

    func testFilesThatAreNotJSONAreIgnored() throws {
        try write("notes", to: "README.txt")
        XCTAssertEqual(store.loadAll(builtIns: builtIns).errors, [])
    }

    func testFilesLoadInNameOrder() throws {
        let a = LayoutCustomisation(layoutId: "com.example.A", appBundleIdentifier: "com.example.A", appName: "A")
        let b = LayoutCustomisation(layoutId: "com.example.B", appBundleIdentifier: "com.example.B", appName: "B")
        try store.save(b)
        try store.save(a)
        XCTAssertEqual(store.loadAll(builtIns: builtIns).customisations.map(\.layoutId), ["com.example.A", "com.example.B"])
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `(cd iKeypadMac && swift test --filter UserLayoutStoreTests)`
Expected: build FAILS with `cannot find 'UserLayoutStore' in scope`.

- [ ] **Step 3: Implement**

`iKeypadMac/Sources/iKeypadMac/UserLayoutStore.swift`:

```swift
import Foundation
import iKeypadShared

/// A user layout file Sidekey refused to load, and why, for showing to the user.
struct LayoutFileError: Equatable {
    let fileName: String
    let reason: String
}

/// The user's layout files, one ``LayoutCustomisation`` per ``<layoutId>.json`` in ``directory``.
/// The app uses ``defaultDirectory``; tests pass a temporary folder so they never touch the
/// user's real layouts.
struct UserLayoutStore {
    let directory: URL

    /// ``~/Library/Application Support/Sidekey/Layouts``.
    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sidekey/Layouts", isDirectory: true)
    }

    /// Read and validate every ``.json`` file in the folder, in file name order. A file that fails
    /// to decode or validate is reported and skipped whole; it is never partly loaded.
    ///
    /// :param builtIns: Sidekey's built-in layouts, for ``LayoutValidator``.
    /// :returns: The files that are safe to install, and the ones that were refused.
    func loadAll(builtIns: [DeckProfile]) -> (customisations: [LayoutCustomisation], errors: [LayoutFileError]) {
        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        } catch CocoaError.fileReadNoSuchFile {
            return ([], [])
        } catch {
            return ([], [LayoutFileError(fileName: directory.lastPathComponent, reason: "Cannot read the folder: \(error.localizedDescription)")])
        }

        var customisations: [LayoutCustomisation] = []
        var errors: [LayoutFileError] = []
        for file in files.filter({ $0.pathExtension == "json" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let name = file.lastPathComponent
            let customisation: LayoutCustomisation
            do {
                customisation = try JSONDecoder().decode(LayoutCustomisation.self, from: Data(contentsOf: file))
            } catch {
                errors.append(LayoutFileError(fileName: name, reason: "Not a valid layout file: \(error.localizedDescription)"))
                continue
            }
            if let problem = LayoutValidator.problem(in: customisation, fileName: name, builtIns: builtIns) {
                errors.append(LayoutFileError(fileName: name, reason: problem))
            } else {
                customisations.append(customisation)
            }
        }
        return (customisations, errors)
    }

    /// Write ``customisation`` to ``<layoutId>.json``, replacing any earlier version atomically.
    ///
    /// :raises LayoutStoreError.invalid: when the validator rejects it, so the editor can never
    ///     write a file the next launch would refuse.
    func save(_ customisation: LayoutCustomisation) throws {
        let name = "\(customisation.layoutId).json"
        if let problem = LayoutValidator.problem(in: customisation, fileName: name, builtIns: DefaultProfiles.allDefaultProfiles()) {
            throw LayoutStoreError.invalid(problem)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(customisation).write(to: directory.appendingPathComponent(name), options: .atomic)
    }

    /// Remove ``<layoutId>.json``. Throws if there is no such file.
    func delete(layoutId: String) throws {
        try FileManager.default.removeItem(at: directory.appendingPathComponent("\(layoutId).json"))
    }
}

enum LayoutStoreError: LocalizedError, Equatable {
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .invalid(let reason): return reason
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `(cd iKeypadMac && swift test --filter UserLayoutStoreTests)`
Expected: 9 tests pass. If `testAMissingFolderMeansNoCustomisations` fails because the error is not `CocoaError.fileReadNoSuchFile`, print the caught error's domain and code, and match that exact error. Do not widen the catch to every error: an unreadable folder must still be reported.

- [ ] **Step 5: Build the app target and commit**

Run the Xcode build command. Expected: `** BUILD SUCCEEDED **`.

```bash
git add iKeypadMac/Sources/iKeypadMac/UserLayoutStore.swift iKeypadMac/Tests/iKeypadMacDaemonTests/UserLayoutStoreTests.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Read and write user layout files

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Install user layouts in place of built-in ones

`register(profile:)` keeps the first layout registered for an app, and built-ins register first, so a user layout cannot simply be registered. This task adds an explicit install, uninstall and reload.

**Files:**
- Modify: `iKeypadMac/Sources/iKeypadMac/AppContextMonitor.swift` (properties at lines 19-27, `init` at 31-41, `profile(withId:)` at 54-58)
- Create: `iKeypadMac/Tests/iKeypadMacDaemonTests/UserLayoutInstallTests.swift`

**Interfaces:**
- Consumes: `UserLayoutStore.loadAll(builtIns:)`, `LayoutResolver.resolve(_:base:)`, `LayoutFileError`.
- Produces (all on `AppContextMonitor`, `@MainActor`):
  - `let builtInProfiles: [DeckProfile]`: the layouts as shipped, the bases for customisations.
  - `@Published private(set) var layoutFileErrors: [LayoutFileError]`
  - `func install(_ profile: DeckProfile)`
  - `func uninstall(layoutId: String)`
  - `func reloadUserLayouts(from store: UserLayoutStore)`
  - `func builtInProfile(withId id: String) -> DeckProfile?`

- [ ] **Step 1: Write the failing tests**

`iKeypadMac/Tests/iKeypadMacDaemonTests/UserLayoutInstallTests.swift`:

```swift
import XCTest
import Combine
import AppKit
import iKeypadShared
@testable import iKeypadMacDaemon

/// These tests change the shared ``AppContextMonitor``; each one restores it (no user layouts,
/// the real frontmost app) so ``DeckServerCharacterizationTests`` see the built-in state.
@MainActor
final class UserLayoutInstallTests: XCTestCase {
    private let monitor = AppContextMonitor.shared
    private let zoom = "us.zoom.xos"
    private var directory: URL!
    private var store: UserLayoutStore!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("sidekey-install-\(UUID().uuidString)")
        store = UserLayoutStore(directory: directory)
    }

    override func tearDown() async throws {
        monitor.reloadUserLayouts(from: UserLayoutStore(directory: directory.appendingPathComponent("empty")))
        try? FileManager.default.removeItem(at: directory)
        let front = NSWorkspace.shared.frontmostApplication
        monitor.updateActiveApp(bundleId: front?.bundleIdentifier ?? "", appName: front?.localizedName ?? "")
    }

    private func raiseHand(at slot: Int, in layoutId: String, bundle: String? = nil) -> LayoutCustomisation {
        LayoutCustomisation(layoutId: layoutId, appBundleIdentifier: bundle ?? layoutId, appName: "App", slots: [
            slot: .key(CustomKey(label: "Raise Hand", iconSystemName: "hand.raised", role: .run,
                                 requiresConfirm: false, action: .hotkey(key: "y", modifiers: [.option]))),
        ])
    }

    func testAUserLayoutReplacesTheBuiltInOne() throws {
        try store.save(raiseHand(at: 4, in: zoom))
        monitor.reloadUserLayouts(from: store)

        monitor.updateActiveApp(bundleId: zoom, appName: "Zoom")
        XCTAssertEqual(monitor.activeProfile.keys.first { $0.position == 4 }?.label, "Raise Hand")
        XCTAssertEqual(monitor.profile(withId: zoom)?.keys.first { $0.position == 4 }?.label, "Raise Hand")
    }

    func testUninstallBringsTheBuiltInLayoutBack() throws {
        try store.save(raiseHand(at: 4, in: zoom))
        monitor.reloadUserLayouts(from: store)
        monitor.uninstall(layoutId: zoom)
        XCTAssertEqual(monitor.profile(withId: zoom), monitor.builtInProfile(withId: zoom))
    }

    func testANewAppGetsItsLayoutAndLosesItOnUninstall() throws {
        let app = "com.example.SidekeyTest"
        try store.save(raiseHand(at: 0, in: app))
        monitor.reloadUserLayouts(from: store)

        monitor.updateActiveApp(bundleId: app, appName: "Example")
        XCTAssertEqual(monitor.activeProfile.id, app)

        monitor.uninstall(layoutId: app)
        XCTAssertEqual(monitor.activeProfile.id, "default", "the app falls back to the System layout")
        XCTAssertNil(monitor.profile(withId: app))
    }

    func testTheSystemLayoutCanBeCustomised() throws {
        try store.save(raiseHand(at: 0, in: "default"))
        monitor.reloadUserLayouts(from: store)
        monitor.updateActiveApp(bundleId: "com.example.NoLayout", appName: "No Layout")
        XCTAssertEqual(monitor.activeProfile.keys.first { $0.position == 0 }?.label, "Raise Hand")
    }

    func testInstallingTheActiveLayoutSendsItToTheIPad() throws {
        monitor.updateActiveApp(bundleId: zoom, appName: "Zoom")
        var published: [DeckProfile] = []
        let subscription = monitor.$activeProfile.dropFirst().sink { published.append($0) }
        // Installed directly, not through a reload, so tearDown's reload would not undo it.
        defer { subscription.cancel(); monitor.uninstall(layoutId: zoom) }

        let custom = LayoutResolver.resolve(raiseHand(at: 4, in: zoom), base: monitor.builtInProfile(withId: zoom))
        monitor.install(custom)

        XCTAssertEqual(published, [custom])
    }

    /// Security: a planted file that puts a shell command on a key is refused at load, the
    /// built-in key stays, and the command never runs.
    func testATamperedFileLeavesTheBuiltInKeyAndRunsNothing() throws {
        let marker = directory.appendingPathComponent("pwned")
        var tampered = raiseHand(at: 3, in: zoom)
        tampered.slots[3] = .key(CustomKey(label: "Evil", iconSystemName: nil, role: nil, requiresConfirm: false,
                                           action: .shellScript(command: "touch '\(marker.path)'")))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(tampered).write(to: directory.appendingPathComponent("\(zoom).json"))

        monitor.reloadUserLayouts(from: store)

        XCTAssertEqual(monitor.layoutFileErrors.map(\.fileName), ["\(zoom).json"])
        XCTAssertEqual(monitor.profile(withId: zoom), monitor.builtInProfile(withId: zoom))
        XCTAssertFalse(FileManager.default.fileExists(atPath: marker.path))
    }

    /// Regression: with no user files every layout is exactly the built-in one.
    func testWithNoUserFilesEveryLayoutIsBuiltIn() {
        monitor.reloadUserLayouts(from: store)
        XCTAssertEqual(monitor.layoutFileErrors, [])
        for builtIn in monitor.builtInProfiles {
            XCTAssertEqual(monitor.profile(withId: builtIn.id), builtIn, builtIn.id)
        }
    }

    func testReloadDropsLayoutsWhoseFilesWereDeleted() throws {
        try store.save(raiseHand(at: 4, in: zoom))
        monitor.reloadUserLayouts(from: store)
        try store.delete(layoutId: zoom)
        monitor.reloadUserLayouts(from: store)
        XCTAssertEqual(monitor.profile(withId: zoom), monitor.builtInProfile(withId: zoom))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `(cd iKeypadMac && swift test --filter UserLayoutInstallTests)`
Expected: build FAILS with `value of type 'AppContextMonitor' has no member 'reloadUserLayouts'`.

- [ ] **Step 3: Implement**

In `AppContextMonitor.swift`:

1. Change `private let defaultProfile: DeckProfile` to `private var defaultProfile: DeckProfile`, and add below `modeByBundle`:

```swift
    /// The layouts as shipped, untouched by the user: the bases user layouts apply to, and what
    /// ``uninstall(layoutId:)`` restores.
    let builtInProfiles: [DeckProfile]
    /// Ids of the user layouts installed by the last ``reloadUserLayouts(from:)``.
    private var userLayoutIds: Set<String> = []
    /// User layout files the last reload refused, with the reason, for the menu and the editor.
    @Published private(set) var layoutFileErrors: [LayoutFileError] = []
```

2. In `init`, replace the registration loop:

```swift
        self.builtInProfiles = DefaultProfiles.allDefaultProfiles()
        for prof in builtInProfiles {
            register(profile: prof)
        }
```

(`builtInProfiles` must be assigned before `setupObserver()`; all stored properties must be initialised before the first method call, so put it directly after `self.activeProfile = defaultProfile`.)

3. Add after `profile(withId:)`:

```swift
    /// The built-in layout with ``id`` as shipped, ignoring any user layout.
    func builtInProfile(withId id: String) -> DeckProfile? {
        builtInProfiles.first { $0.id == id }
    }

    /// Show ``profile`` in place of the layout with the same id: a built-in layout (as the app's
    /// start layout too, when it is that) or a new app's layout. When it is on screen it is
    /// reassigned to ``activeProfile``, which the server already sends to every iPad.
    func install(_ profile: DeckProfile) {
        profilesById[profile.id] = profile
        if profile.id == defaultProfile.id { defaultProfile = profile }
        let bundle = profile.appBundleIdentifier
        if profileRegistry[bundle] == nil || profileRegistry[bundle]?.id == profile.id {
            profileRegistry[bundle] = profile
        }
        if activeProfile.id == profile.id { activeProfile = profile }
    }

    /// Undo ``install(_:)``: the built-in layout with ``layoutId`` comes back, or a new app's
    /// layout is removed and that app falls back to the System layout.
    func uninstall(layoutId: String) {
        if let builtIn = builtInProfile(withId: layoutId) {
            install(builtIn)
            return
        }
        guard let removed = profilesById.removeValue(forKey: layoutId) else { return }
        let bundle = removed.appBundleIdentifier
        if profileRegistry[bundle]?.id == layoutId { profileRegistry[bundle] = nil }
        if modeByBundle[bundle] == layoutId { modeByBundle[bundle] = nil }
        if activeProfile.id == layoutId { updateActiveApp(bundleId: activeBundleId, appName: activeAppName) }
    }

    /// Replace every installed user layout with the valid files in ``store``, and record the
    /// files that were refused in ``layoutFileErrors``.
    func reloadUserLayouts(from store: UserLayoutStore) {
        for id in userLayoutIds { uninstall(layoutId: id) }
        let loaded = store.loadAll(builtIns: builtInProfiles)
        for customisation in loaded.customisations {
            install(LayoutResolver.resolve(customisation, base: builtInProfile(withId: customisation.layoutId)))
        }
        userLayoutIds = Set(loaded.customisations.map(\.layoutId))
        layoutFileErrors = loaded.errors
    }
```

4. In `updateActiveApp`, no change is needed: it already reads `profileRegistry` and `defaultProfile`, which `install` keeps current.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `(cd iKeypadMac && swift test --filter UserLayoutInstallTests)`
Expected: 8 tests pass. Then the full Mac suite, since `DeckServerCharacterizationTests` share the monitor: `(cd iKeypadMac && swift test 2>&1 | grep -E "Executed .* tests|error:")`, expected 0 failures.

- [ ] **Step 5: Build the app target and commit**

Run the Xcode build command. Expected: `** BUILD SUCCEEDED **`.

```bash
git add iKeypadMac/Sources/iKeypadMac/AppContextMonitor.swift iKeypadMac/Tests/iKeypadMacDaemonTests/UserLayoutInstallTests.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Install user layouts in place of built-in ones

register(profile:) keeps the first layout for an app and built-ins come
first, so user layouts need their own install, uninstall and reload.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Load user layouts at launch and report bad files in the menu

After this task, hand-written layout files work.

**Files:**
- Modify: `iKeypadMac/Sources/iKeypadMac/iKeypadMacApp.swift`

**Interfaces:**
- Consumes: `AppContextMonitor.reloadUserLayouts(from:)`, `.layoutFileErrors`, `UserLayoutStore.defaultDirectory`.
- Produces: `UserLayoutStore.app` (the store the app uses; Part 2's editor writes through it).

- [ ] **Step 1: Add the app's store**

Append to `UserLayoutStore.swift`:

```swift
extension UserLayoutStore {
    /// The store the running app reads and the editor writes.
    static let app = UserLayoutStore(directory: defaultDirectory)
}
```

- [ ] **Step 2: Load at launch**

In `iKeypadMacApp.init()`, before `DeckServer.shared.start()`:

```swift
        // Before the server starts, so the first layout an iPad receives already has the user's keys.
        AppContextMonitor.shared.reloadUserLayouts(from: .app)
```

- [ ] **Step 3: Add the menu section**

In the menu `VStack`, between `PairingMenuSection(...)` and its following `Divider()`:

```swift
                Divider()

                LayoutsMenuSection(monitor: contextMonitor)
```

And add below `PairingMenuSection`:

```swift
/// Reload hand-edited layout files, and say when any were refused. The error count changes only
/// on reload, from a menu action, never while the menu is open (see ``PairingMenuSection``).
private struct LayoutsMenuSection: View {
    @ObservedObject var monitor: AppContextMonitor

    var body: some View {
        Button("Reload Layouts") { monitor.reloadUserLayouts(from: .app) }
        if !monitor.layoutFileErrors.isEmpty {
            let count = monitor.layoutFileErrors.count
            Button("\(count) layout file\(count == 1 ? " has" : "s have") errors...") {
                showErrors(monitor.layoutFileErrors)
            }
        }
    }

    private func showErrors(_ errors: [LayoutFileError]) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Sidekey didn't load these layout files"
        alert.informativeText = errors.map { "\($0.fileName): \($0.reason)" }.joined(separator: "\n\n")
            + "\n\nSidekey is using the built-in layouts for these apps. Files are in \(UserLayoutStore.defaultDirectory.path)."
        alert.runModal()
    }
}
```

- [ ] **Step 4: Verify by hand**

Build and run the app from Xcode (or the Xcode build command, then open the built `Sidekey.app` from DerivedData). Then:

```bash
mkdir -p ~/Library/Application\ Support/Sidekey/Layouts
cat > ~/Library/Application\ Support/Sidekey/Layouts/com.apple.finder.json <<'EOF'
{"version":1,"layoutId":"com.apple.finder","appBundleIdentifier":"com.apple.finder","appName":"Finder",
 "slots":{"0":{"key":{"label":"Test Key","iconSystemName":"star","role":"run","requiresConfirm":false,
 "action":{"hotkey":{"key":"n","modifiers":["cmd","shift"]}}}}}}
EOF
```

Choose **Reload Layouts**, bring Finder forward: the iPad's first key reads "Test Key" and creates a new folder. Then change `"hotkey"` to `"shellScript":{"command":"true"}` (replacing the hotkey object), choose Reload Layouts: the menu shows "1 layout file has errors...", the alert names the file and "this action type is not allowed", and Finder's first key is the built-in one again. (Finder's built-in layout id is `com.apple.finder`, `PopularAppProfiles.swift:127`.) Delete the test file afterwards and choose Reload Layouts.

- [ ] **Step 5: Run all tests, build, commit**

Run: `(cd iKeypadMac && swift test 2>&1 | grep -E "Executed .* tests|error:")` (0 failures), `(cd Packages/iKeypadShared && swift test 2>&1 | grep -E "Executed .* tests")` (0 failures), and the Xcode build command (`** BUILD SUCCEEDED **`).

```bash
git add iKeypadMac/Sources/iKeypadMac/iKeypadMacApp.swift iKeypadMac/Sources/iKeypadMac/UserLayoutStore.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Load user layouts at launch and report refused files

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

## Done for Part 1

- All tests green in both packages; `SidekeyMac` builds.
- A hand-written file changes a key on the iPad after Reload Layouts; a file with a shell action is refused and reported.
- Then continue with `plans/2026-10-09-custom-layouts-plan-2-editor.md`.
