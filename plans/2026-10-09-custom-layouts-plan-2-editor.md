# Custom Layouts, Part 2 (Editor) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A visual editor on the Mac where anyone can change keys in any layout, add a layout for another app, and reset changes, with the iPad updating live.

**Architecture:** All editing logic lives in `LayoutEditorModel` (tested): it turns edits into `LayoutCustomisation`s, saves them through `UserLayoutStore.app` and reloads the monitor, which sends the active layout to the iPad. SwiftUI views are thin and checked by hand. Small data helpers (`KeyNames`, `SymbolCatalog`, `SystemShortcuts`, `AppleShortcuts`, `ShortcutRecorder`'s key mapping) are tested.

**Tech Stack:** Swift 5.9, SwiftUI on macOS 13 (`NavigationSplitView`, `Grid`, `draggable`/`dropDestination`), AppKit (`NSWindow`, `NSOpenPanel`, `NSEvent` monitors), XCTest.

**Prerequisite:** Part 1 (`plans/2026-10-09-custom-layouts-plan-1-engine.md`) complete: `LayoutCustomisation`, `SlotChange`, `CustomKey`, `LayoutResolver`, `LayoutValidator`, `UserLayoutStore` (with `.app`), `LayoutFileError`, and `AppContextMonitor.builtInProfiles` / `builtInProfile(withId:)` / `reloadUserLayouts(from:)` / `layoutFileErrors` exist.

**Spec:** `plans/2026-10-09-custom-layouts-design.md`.

## Global Constraints

- macOS 13.0 deployment target. No new dependencies. No new `KeyAction` cases. The iPad app does not change.
- User layouts may contain only `hotkey`, `windowsHotkey`, `runShortcut` and `switchProfile` actions.
- Label length: 1 to 16 characters. Slots: 0 to 14.
- Every edit saves at once (no Save button); Reset Key and Reset Layout ask first.
- The menu bar menu may only gain static items. Nothing in it may change on a timer or while it is open (the 1.1.0 crash).
- Doc comments: `///` prose with `:param name:` / `:returns:` fields.
- Commit messages: imperative one-line summary, why in the body when not obvious, ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Every task that adds a Mac source file ends with `xcodegen generate`, a `SidekeyMac` build, and the regenerated `iKeypadApp.xcodeproj/project.pbxproj` in the commit.
- Worktree: `/Users/mahmud/projects/ikeypad-custom-layouts`, branch `custom-layouts`.

## Commands used throughout

```bash
(cd iKeypadMac && swift test --filter <TestClass>)
(cd iKeypadMac && swift test 2>&1 | grep -E "Executed .* tests|error:")
xcodegen generate && xcodebuild -project iKeypadApp.xcodeproj -scheme SidekeyMac -configuration Debug -destination 'platform=macOS' build 2>&1 | grep -E "error:|\*\* BUILD"
```

## File map

| File | Status | Responsibility |
|---|---|---|
| `iKeypadMac/Sources/iKeypadMac/KeyNames.swift` | Create | Key names the editor offers; key code to name for the recorder. |
| `iKeypadMac/Sources/iKeypadMac/SymbolCatalog.swift` | Create | SF Symbols the icon picker offers. |
| `iKeypadMac/Sources/iKeypadMac/LayoutEditorModel.swift` | Create | All editing logic. |
| `iKeypadMac/Sources/iKeypadMac/LayoutEditorWindow.swift` | Create | Window, app list, grid, portrait preview. |
| `iKeypadMac/Sources/iKeypadMac/KeyInspectorView.swift` | Create | Editing one key. |
| `iKeypadMac/Sources/iKeypadMac/ShortcutInput.swift` | Create | `SystemShortcuts`, `AppleShortcuts`, `ShortcutRecorder`. |
| `iKeypadMac/Sources/iKeypadMac/iKeypadMacApp.swift` | Modify | "Edit Layouts..." menu item. |
| `iKeypadMac/Tests/iKeypadMacDaemonTests/EditorDataTests.swift` | Create | `KeyNames`, `SymbolCatalog`. |
| `iKeypadMac/Tests/iKeypadMacDaemonTests/LayoutEditorModelTests.swift` | Create | Model behaviour. |
| `iKeypadMac/Tests/iKeypadMacDaemonTests/ShortcutInputTests.swift` | Create | Recorder mapping, system shortcut warnings, shortcut list parsing. |
| `README.md`, `docs/index.html`, `docs/support.html` | Modify | Describe custom layouts. |

---

### Task 7: Key names and the icon catalogue

**Files:**
- Create: `iKeypadMac/Sources/iKeypadMac/KeyNames.swift`
- Create: `iKeypadMac/Sources/iKeypadMac/SymbolCatalog.swift`
- Create: `iKeypadMac/Tests/iKeypadMacDaemonTests/EditorDataTests.swift`

**Interfaces:**
- Consumes: `ActionDispatcher.shared.keyCodeForString(_:)`, `CitrixKeyMapper.chord(key:modifiers:)`, `DefaultProfiles.allDefaultProfiles()`.
- Produces:
  - `enum KeyNames { static let mac: [String]; static let windows: [String]; static func name(forKeyCode: CGKeyCode) -> String? }`
  - `enum SymbolCatalog { static let all: [String]; static func matching(_ query: String) -> [String] }`

- [ ] **Step 1: Write the failing tests**

`iKeypadMac/Tests/iKeypadMacDaemonTests/EditorDataTests.swift`:

```swift
import XCTest
import AppKit
import iKeypadShared
@testable import iKeypadMacDaemon

final class EditorDataTests: XCTestCase {
    func testEveryOfferedMacKeyCanBeSent() {
        for name in KeyNames.mac {
            XCTAssertNotNil(ActionDispatcher.shared.keyCodeForString(name), name)
        }
    }

    func testEveryOfferedWindowsKeyCanBeSent() {
        for name in KeyNames.windows {
            XCTAssertNoThrow(try CitrixKeyMapper.chord(key: name, modifiers: []), name)
        }
    }

    func testKeyCodesMapBackToTheirNames() {
        for name in KeyNames.mac {
            let code = ActionDispatcher.shared.keyCodeForString(name)!
            XCTAssertEqual(KeyNames.name(forKeyCode: code), name)
        }
        XCTAssertNil(KeyNames.name(forKeyCode: 0x3F), "fn is not a key a layout can send")
    }

    func testTheCatalogHasEveryBuiltInIcon() {
        let builtIn = Set(DefaultProfiles.allDefaultProfiles().flatMap(\.keys).compactMap(\.iconSystemName))
        XCTAssertTrue(builtIn.isSubset(of: Set(SymbolCatalog.all)))
    }

    func testEveryCatalogSymbolExists() {
        for name in SymbolCatalog.all {
            XCTAssertNotNil(NSImage(systemSymbolName: name, accessibilityDescription: nil), name)
        }
    }

    func testSearchMatchesPartsOfNames() {
        XCTAssertTrue(SymbolCatalog.matching("hand").contains("hand.raised"))
        XCTAssertEqual(SymbolCatalog.matching(""), SymbolCatalog.all)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `(cd iKeypadMac && swift test --filter EditorDataTests)`
Expected: build FAILS with `cannot find 'KeyNames' in scope`.

- [ ] **Step 3: Implement**

`iKeypadMac/Sources/iKeypadMac/KeyNames.swift`:

```swift
import CoreGraphics

/// The key names a user layout can use, in the order the editor lists them. Tests check that each
/// one maps through ``ActionDispatcher/keyCodeForString(_:)`` (Mac) or ``CitrixKeyMapper`` (Windows),
/// so the editor never offers a key the Mac cannot send.
enum KeyNames {
    static let mac: [String] = "abcdefghijklmnopqrstuvwxyz0123456789".map(String.init)
        + ["-", "=", "[", "]", "\\", ";", "'", ",", ".", "/", "`",
           "space", "return", "tab", "escape", "delete", "forwarddelete", "left", "right", "up", "down"]
        + (1...12).map { "f\($0)" }

    /// Windows keys: the same keys, plus the Windows key pressed on its own.
    static let windows: [String] = mac + ["win"]

    /// The layout name of the key with ``code``, for the shortcut recorder.
    ///
    /// :returns: ``nil`` for keys a layout cannot send, such as fn.
    static func name(forKeyCode code: CGKeyCode) -> String? {
        mac.first { ActionDispatcher.shared.keyCodeForString($0) == code }
    }
}
```

`iKeypadMac/Sources/iKeypadMac/SymbolCatalog.swift`:

```swift
import iKeypadShared

/// The SF Symbols the icon picker offers. macOS has no public API listing every symbol, so this is
/// every icon the built-in layouts use plus common extras. Tests check each one exists.
enum SymbolCatalog {
    private static let extras = [
        "star", "star.fill", "heart", "bolt", "flag", "bell", "bookmark", "tag", "paperclip", "link",
        "folder", "doc", "doc.on.doc", "tray", "archivebox", "trash", "pencil", "scissors",
        "magnifyingglass", "gearshape", "slider.horizontal.3", "terminal", "keyboard", "command",
        "play", "pause", "stop", "forward", "backward", "speaker.wave.2", "speaker.slash",
        "mic", "mic.slash", "video", "video.slash", "phone", "message", "envelope", "paperplane",
        "hand.raised", "hand.thumbsup", "person", "person.2", "calendar", "clock", "timer",
        "lock", "lock.open", "eye", "eye.slash", "lightbulb", "moon", "sun.max", "cloud",
        "arrow.clockwise", "arrow.uturn.backward", "arrow.uturn.forward", "arrow.up", "arrow.down",
        "arrow.left", "arrow.right", "plus", "minus", "xmark", "checkmark", "questionmark",
        "1.circle", "2.circle", "3.circle", "4.circle", "5.circle",
    ]

    static let all: [String] = Set(
        DefaultProfiles.allDefaultProfiles().flatMap(\.keys).compactMap(\.iconSystemName) + extras
    ).sorted()

    /// Symbols whose name contains ``query`` (case-insensitive); everything for an empty query.
    static func matching(_ query: String) -> [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty ? all : all.filter { $0.contains(q) }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `(cd iKeypadMac && swift test --filter EditorDataTests)`
Expected: 6 tests pass. If `testEveryCatalogSymbolExists` names an extra that does not exist on macOS 13, delete that extra from the list (do not weaken the test).

- [ ] **Step 5: Build and commit**

Run the Xcode build command. Expected: `** BUILD SUCCEEDED **`.

```bash
git add iKeypadMac/Sources/iKeypadMac/KeyNames.swift iKeypadMac/Sources/iKeypadMac/SymbolCatalog.swift iKeypadMac/Tests/iKeypadMacDaemonTests/EditorDataTests.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Add the key names and icons the layout editor offers

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Layout editor model

**Files:**
- Create: `iKeypadMac/Sources/iKeypadMac/LayoutEditorModel.swift`
- Create: `iKeypadMac/Tests/iKeypadMacDaemonTests/LayoutEditorModelTests.swift`

**Interfaces:**
- Consumes: Part 1 (see Prerequisite).
- Produces (`@MainActor final class LayoutEditorModel: ObservableObject`):
  - `struct Entry: Identifiable, Equatable { let id: String; let title: String; let isBuiltIn: Bool; let isCustomised: Bool }`
  - `@Published private(set) var entries: [Entry]`
  - `@Published var selectedLayoutId: String?`
  - `@Published var errorMessage: String?`
  - `init(monitor: AppContextMonitor, store: UserLayoutStore)`
  - `func reload()`
  - `func layout(_ id: String) -> DeckProfile?`
  - `func changedSlots(in id: String) -> Set<Int>`
  - `func isEditable(_ key: DeckKey) -> Bool`
  - `func isBuiltIn(_ id: String) -> Bool`
  - `func modes(of id: String) -> [Entry]`
  - `func setKey(_ key: CustomKey, at slot: Int, in id: String)`
  - `func removeKey(at slot: Int, in id: String)`
  - `func resetKey(at slot: Int, in id: String)`
  - `func moveKey(from: Int, to: Int, in id: String)`
  - `func resetLayout(_ id: String)`
  - `func addApp(bundleIdentifier: String, name: String)`
  - `static let newKey: CustomKey`

- [ ] **Step 1: Write the failing tests**

`iKeypadMac/Tests/iKeypadMacDaemonTests/LayoutEditorModelTests.swift`:

```swift
import XCTest
import AppKit
import iKeypadShared
@testable import iKeypadMacDaemon

/// Uses the shared monitor with a temporary store; tearDown restores the built-in state.
@MainActor
final class LayoutEditorModelTests: XCTestCase {
    private let monitor = AppContextMonitor.shared
    private let zoom = "us.zoom.xos"
    private let citrix = "com.citrix.receiver.icaviewer.mac"
    private var directory: URL!
    private var store: UserLayoutStore!
    private var model: LayoutEditorModel!

    private let raiseHand = CustomKey(label: "Raise Hand", iconSystemName: "hand.raised", role: .run,
                                      requiresConfirm: false, action: .hotkey(key: "y", modifiers: [.option]))

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("sidekey-editor-\(UUID().uuidString)")
        store = UserLayoutStore(directory: directory)
        model = LayoutEditorModel(monitor: monitor, store: store)
    }

    override func tearDown() async throws {
        monitor.reloadUserLayouts(from: UserLayoutStore(directory: directory.appendingPathComponent("empty")))
        try? FileManager.default.removeItem(at: directory)
    }

    private func fileExists(_ id: String) -> Bool {
        FileManager.default.fileExists(atPath: directory.appendingPathComponent("\(id).json").path)
    }

    func testEveryBuiltInLayoutIsListedWithModesNamedByTheirKey() {
        XCTAssertEqual(model.entries.count, monitor.builtInProfiles.count)
        XCTAssertEqual(model.entries.first { $0.id == zoom }?.title, "Zoom")
        XCTAssertEqual(model.entries.first { $0.id == "\(citrix).outlook" }?.title, "Citrix Viewer: Outlook")
        XCTAssertEqual(model.entries.first { $0.id == "default" }?.title, "System")
    }

    func testSettingAKeySavesTheFileAndUpdatesTheLiveLayout() {
        model.setKey(raiseHand, at: 4, in: zoom)
        XCTAssertNil(model.errorMessage)
        XCTAssertTrue(fileExists(zoom))
        XCTAssertEqual(monitor.profile(withId: zoom)?.keys.first { $0.position == 4 }?.label, "Raise Hand")
        XCTAssertEqual(model.changedSlots(in: zoom), [4])
        XCTAssertEqual(model.entries.first { $0.id == zoom }?.isCustomised, true)
    }

    func testRemovingAKeyEmptiesTheSlot() {
        let slot = monitor.builtInProfile(withId: zoom)!.keys[0].position
        model.removeKey(at: slot, in: zoom)
        XCTAssertNil(model.layout(zoom)?.keys.first { $0.position == slot })
    }

    func testResettingTheLastChangeDeletesTheFile() {
        model.setKey(raiseHand, at: 4, in: zoom)
        model.resetKey(at: 4, in: zoom)
        XCTAssertFalse(fileExists(zoom))
        XCTAssertEqual(monitor.profile(withId: zoom), monitor.builtInProfile(withId: zoom))
        XCTAssertEqual(model.entries.first { $0.id == zoom }?.isCustomised, false)
    }

    func testMovingAKeySwapsTwoSlots() {
        let builtIn = monitor.builtInProfile(withId: zoom)!
        let first = builtIn.keys.first { $0.position == 0 }!, second = builtIn.keys.first { $0.position == 1 }!
        model.moveKey(from: 0, to: 1, in: zoom)
        XCTAssertEqual(model.layout(zoom)?.keys.first { $0.position == 1 }?.label, first.label)
        XCTAssertEqual(model.layout(zoom)?.keys.first { $0.position == 0 }?.label, second.label)
    }

    func testMovingAKeyToAnEmptySlotLeavesItsOldSlotEmpty() {
        model.removeKey(at: 14, in: zoom)
        let moved = model.layout(zoom)!.keys.first { $0.position == 0 }!
        model.moveKey(from: 0, to: 14, in: zoom)
        XCTAssertEqual(model.layout(zoom)?.keys.first { $0.position == 14 }?.label, moved.label)
        XCTAssertNil(model.layout(zoom)?.keys.first { $0.position == 0 })
    }

    func testBuiltInScriptKeysCannotBeMoved() throws {
        let system = try XCTUnwrap(monitor.builtInProfile(withId: "default"))
        let script = try XCTUnwrap(system.keys.first { !model.isEditable($0) }, "the System layout has script keys")
        let target = script.position == 0 ? 1 : 0
        model.moveKey(from: script.position, to: target, in: "default")
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(fileExists("default"))
    }

    func testAnInvalidKeyIsNotSavedAndSaysWhy() {
        var bad = raiseHand
        bad.label = ""
        model.setKey(bad, at: 4, in: zoom)
        XCTAssertEqual(model.errorMessage, "Slot 4: label is empty.")
        XCTAssertFalse(fileExists(zoom))
    }

    func testAddingANewAppCreatesItsLayout() {
        model.addApp(bundleIdentifier: "com.example.SidekeyTest", name: "Example")
        XCTAssertTrue(fileExists("com.example.SidekeyTest"))
        XCTAssertEqual(model.selectedLayoutId, "com.example.SidekeyTest")
        XCTAssertEqual(model.entries.first { $0.id == "com.example.SidekeyTest" }?.isBuiltIn, false)
    }

    func testAddingAnAppWithABuiltInLayoutSelectsItInstead() {
        model.addApp(bundleIdentifier: zoom, name: "zoom.us")
        XCTAssertEqual(model.selectedLayoutId, zoom)
        XCTAssertFalse(fileExists(zoom))
    }

    func testResettingANewAppRemovesIt() {
        model.addApp(bundleIdentifier: "com.example.SidekeyTest", name: "Example")
        model.resetLayout("com.example.SidekeyTest")
        XCTAssertNil(model.entries.first { $0.id == "com.example.SidekeyTest" })
        XCTAssertNil(model.selectedLayoutId)
        XCTAssertNil(monitor.profile(withId: "com.example.SidekeyTest"))
    }

    func testModesAreTheSameAppsLayouts() {
        XCTAssertEqual(Set(model.modes(of: "\(citrix).outlook").map(\.id)),
                       Set(monitor.builtInProfiles.filter { $0.appBundleIdentifier == citrix }.map(\.id)))
        XCTAssertEqual(model.modes(of: zoom).map(\.id), [zoom])
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `(cd iKeypadMac && swift test --filter LayoutEditorModelTests)`
Expected: build FAILS with `cannot find 'LayoutEditorModel' in scope`.

- [ ] **Step 3: Implement**

`iKeypadMac/Sources/iKeypadMac/LayoutEditorModel.swift`:

```swift
import Foundation
import iKeypadShared

/// Everything the layout editor does, without the views. Each edit becomes a
/// ``LayoutCustomisation``, is saved through the store (which validates it, so the editor can
/// never write a file the next launch would refuse) and reloads the monitor, which sends the
/// active layout to every iPad.
@MainActor
final class LayoutEditorModel: ObservableObject {
    /// One row of the app list: a built-in layout (each Citrix mode is its own row) or a user's
    /// layout for another app.
    struct Entry: Identifiable, Equatable {
        let id: String
        let title: String
        let isBuiltIn: Bool
        let isCustomised: Bool
    }

    /// What a new key starts as; the user changes it straight away.
    static let newKey = CustomKey(label: "New Key", iconSystemName: "star", role: .navigate,
                                  requiresConfirm: false, action: .hotkey(key: "a", modifiers: [.command]))

    @Published private(set) var entries: [Entry] = []
    @Published var selectedLayoutId: String?
    /// The last edit that failed, for the view to show; cleared by the view.
    @Published var errorMessage: String?

    private let monitor: AppContextMonitor
    private let store: UserLayoutStore
    private var customisations: [String: LayoutCustomisation] = [:]

    init(monitor: AppContextMonitor, store: UserLayoutStore) {
        self.monitor = monitor
        self.store = store
        reload()
    }

    /// Re-read the files, for when the window opens after a hand edit.
    func reload() {
        let loaded = store.loadAll(builtIns: monitor.builtInProfiles)
        customisations = Dictionary(uniqueKeysWithValues: loaded.customisations.map { ($0.layoutId, $0) })
        rebuildEntries()
    }

    /// The layout as the iPad shows it: built-in plus the user's changes.
    func layout(_ id: String) -> DeckProfile? {
        let base = monitor.builtInProfile(withId: id)
        guard let customisation = customisations[id] else { return base }
        return LayoutResolver.resolve(customisation, base: base)
    }

    /// Slots the user changed or removed in layout ``id``.
    func changedSlots(in id: String) -> Set<Int> {
        Set(customisations[id]?.slots.keys.map { $0 } ?? [])
    }

    /// Whether ``key`` can be edited or moved. Built-in keys that run a script cannot, because
    /// user layouts may not hold scripts; they can still be replaced or removed.
    func isEditable(_ key: DeckKey) -> Bool {
        switch key.action {
        case .hotkey, .windowsHotkey, .runShortcut, .switchProfile: return true
        case .shellScript, .appleScript, .none: return false
        }
    }

    /// Whether ``id`` is one of Sidekey's built-in layouts.
    func isBuiltIn(_ id: String) -> Bool {
        monitor.builtInProfile(withId: id) != nil
    }

    /// The layouts a Switch Layout key in ``id`` may go to: every built-in layout of the same app.
    func modes(of id: String) -> [Entry] {
        guard let bundle = layout(id)?.appBundleIdentifier else { return [] }
        let ids = Set(monitor.builtInProfiles.filter { $0.appBundleIdentifier == bundle }.map(\.id))
        return entries.filter { ids.contains($0.id) }
    }

    func setKey(_ key: CustomKey, at slot: Int, in id: String) {
        change(id) { $0.slots[slot] = .key(key) }
    }

    func removeKey(at slot: Int, in id: String) {
        change(id) { $0.slots[slot] = .removed }
    }

    /// Put back the built-in key (or nothing, for a new app) in ``slot``.
    func resetKey(at slot: Int, in id: String) {
        change(id) { $0.slots[slot] = nil }
    }

    /// Swap the keys in two slots; a key moved to an empty slot leaves its old slot empty.
    func moveKey(from: Int, to: Int, in id: String) {
        guard from != to, let layout = layout(id) else { return }
        let moving = layout.keys.first { $0.position == from }
        let displaced = layout.keys.first { $0.position == to }
        if [moving, displaced].compactMap({ $0 }).contains(where: { !isEditable($0) }) {
            errorMessage = "Built-in keys that run a script can't be moved. You can replace or remove them."
            return
        }
        change(id) { c in
            c.slots[to] = moving.map { .key(CustomKey($0)) } ?? .removed
            c.slots[from] = displaced.map { .key(CustomKey($0)) } ?? .removed
        }
    }

    /// Remove every change to ``id``: a built-in layout returns to as shipped, a new app's layout
    /// is deleted.
    func resetLayout(_ id: String) {
        guard customisations[id] != nil else { return }
        do {
            try store.delete(layoutId: id)
        } catch {
            errorMessage = "Couldn't delete \(id).json: \(error.localizedDescription)"
            return
        }
        if monitor.builtInProfile(withId: id) == nil, selectedLayoutId == id { selectedLayoutId = nil }
        applyFiles()
    }

    /// Add a layout for the app with ``bundleIdentifier``, or select its layout if it has one.
    func addApp(bundleIdentifier: String, name: String) {
        if let existing = monitor.builtInProfiles.first(where: { $0.appBundleIdentifier == bundleIdentifier })?.id
            ?? customisations[bundleIdentifier]?.layoutId {
            selectedLayoutId = existing
            return
        }
        if save(LayoutCustomisation(layoutId: bundleIdentifier, appBundleIdentifier: bundleIdentifier, appName: name)) {
            selectedLayoutId = bundleIdentifier
        }
    }

    private func change(_ id: String, _ edit: (inout LayoutCustomisation) -> Void) {
        guard let current = layout(id) else { return }
        var customisation = customisations[id]
            ?? LayoutCustomisation(layoutId: id, appBundleIdentifier: current.appBundleIdentifier, appName: current.appName)
        edit(&customisation)
        // A built-in layout with no changes left needs no file.
        if customisation.slots.isEmpty, monitor.builtInProfile(withId: id) != nil {
            resetLayout(id)
        } else {
            save(customisation)
        }
    }

    /// :returns: ``false`` when the store refused it; ``errorMessage`` says why.
    @discardableResult
    private func save(_ customisation: LayoutCustomisation) -> Bool {
        do {
            try store.save(customisation)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
        applyFiles()
        return true
    }

    /// Reload the monitor from the files, so the editor and the iPad always show what is on disk.
    private func applyFiles() {
        monitor.reloadUserLayouts(from: store)
        reload()
    }

    private func rebuildEntries() {
        let builtIn = monitor.builtInProfiles.map {
            Entry(id: $0.id, title: title(for: $0), isBuiltIn: true, isCustomised: customisations[$0.id] != nil)
        }
        let added = customisations.values.filter { monitor.builtInProfile(withId: $0.layoutId) == nil }.map {
            Entry(id: $0.layoutId, title: $0.appName, isBuiltIn: false, isCustomised: true)
        }
        entries = (builtIn + added).sorted { ($0.title.localizedLowercase, $0.id) < ($1.title.localizedLowercase, $1.id) }
    }

    /// "Citrix Viewer: Outlook" for an extra mode, named by the key that switches to it; the app's
    /// name for its start layout.
    private func title(for profile: DeckProfile) -> String {
        guard profile.id != profile.appBundleIdentifier else { return profile.appName }
        let modeName = monitor.builtInProfiles.lazy.flatMap(\.keys)
            .first { $0.action == .switchProfile(profileId: profile.id) }?.label
        return modeName.map { "\(profile.appName): \($0)" } ?? profile.appName
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `(cd iKeypadMac && swift test --filter LayoutEditorModelTests)`
Expected: 12 tests pass. Note `testEveryBuiltInLayoutIsListedWithModesNamedByTheirKey` relies on the System layout's id `default` equalling its bundle id `default`, and Citrix's start layout id equalling its bundle id; both hold in `DefaultProfiles.swift` and `PopularAppProfiles.swift:1922`.

- [ ] **Step 5: Run the full suite, build, commit**

Run the full Mac suite (0 failures) and the Xcode build command (`** BUILD SUCCEEDED **`).

```bash
git add iKeypadMac/Sources/iKeypadMac/LayoutEditorModel.swift iKeypadMac/Tests/iKeypadMacDaemonTests/LayoutEditorModelTests.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Add the layout editor model

Every edit is saved through the validating store and reloads the
monitor, so the editor, the files and the iPad cannot disagree.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: Editor window with app list, grid and portrait preview

**Files:**
- Create: `iKeypadMac/Sources/iKeypadMac/LayoutEditorWindow.swift`
- Modify: `iKeypadMac/Sources/iKeypadMac/iKeypadMacApp.swift` (`LayoutsMenuSection` from Part 1, Task 6)

**Interfaces:**
- Consumes: `LayoutEditorModel` (Task 8).
- Produces: `LayoutEditorWindow.shared.show()`; `struct KeyGridView`; `enum EditorTheme { static func tint(for: KeyRole?) -> Color }`; `LayoutEditorView` with `@State selectedSlot: Int?` that Task 10 passes to the inspector.

- [ ] **Step 1: Implement the window and views**

`iKeypadMac/Sources/iKeypadMac/LayoutEditorWindow.swift`:

```swift
import AppKit
import SwiftUI
import iKeypadShared

/// The "Sidekey Layouts" window. Sidekey has no Dock icon, so showing it activates the app, as
/// ``PairingCodeWindow`` does.
@MainActor
final class LayoutEditorWindow {
    static let shared = LayoutEditorWindow()

    private var window: NSWindow?
    private lazy var model = LayoutEditorModel(monitor: .shared, store: .app)

    func show() {
        model.reload()
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: LayoutEditorView(model: model)))
            window.title = "Sidekey Layouts"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 1000, height: 600))
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

/// Role colours, matching the iPad's ``DeckTheme.tint(for:)`` in `iKeypad/Sources/iKeypad/DeckTheme.swift`.
/// Keep the two in step.
enum EditorTheme {
    static let cap = Color(red: 0.141, green: 0.153, blue: 0.180)   // #24272E
    static let plate = Color(red: 0.063, green: 0.071, blue: 0.090) // #101218

    static func tint(for role: KeyRole?) -> Color {
        switch role {
        case .navigate, .none: return Color(red: 0.796, green: 0.835, blue: 0.882) // #CBD5E1
        case .create: return Color(red: 0.478, green: 0.706, blue: 1.0)            // #7AB4FF
        case .run: return Color(red: 0.369, green: 0.890, blue: 0.557)             // #5EE38E
        case .danger: return Color(red: 1.0, green: 0.478, blue: 0.478)            // #FF7A7A
        case .modify: return Color(red: 0.788, green: 0.659, blue: 1.0)            // #C9A8FF
        }
    }
}

struct LayoutEditorView: View {
    @ObservedObject var model: LayoutEditorModel
    @State private var selectedSlot: Int?
    @State private var confirmingResetLayout = false

    var body: some View {
        NavigationSplitView {
            List(model.entries, selection: $model.selectedLayoutId) { entry in
                HStack {
                    Text(entry.title)
                    Spacer()
                    if entry.isCustomised {
                        Circle().fill(Color.accentColor).frame(width: 7, height: 7)
                            .accessibilityLabel("Customised")
                    }
                }
            }
            .frame(minWidth: 230)
        } detail: {
            if let id = model.selectedLayoutId, let layout = model.layout(id) {
                detail(id: id, layout: layout)
            } else {
                Text("Choose an app on the left.").foregroundStyle(.secondary)
            }
        }
        .onChange(of: model.selectedLayoutId) { _ in selectedSlot = nil }
        .alert("Sidekey couldn't make that change", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private func detail(id: String, layout: DeckProfile) -> some View {
        let changed = model.changedSlots(in: id)
        return HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(layout.appName).font(.title2.weight(.semibold))
                    Spacer()
                    if !changed.isEmpty || !model.isBuiltIn(id) {
                        Button("Reset Layout...") { confirmingResetLayout = true }
                    }
                }
                KeyGridView(model: model, layoutId: id, layout: layout, changed: changed, selection: $selectedSlot, columns: 5)
                Text("Dot: changed from the built-in layout. Drag a key to move it.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Portrait on the iPad").font(.caption.weight(.semibold)).padding(.top, 8)
                KeyGridView(model: model, layoutId: id, layout: layout, changed: changed, selection: $selectedSlot, columns: 3, compact: true)
            }
            // Task 11 adds the key inspector here.
        }
        .padding(24)
        .confirmationDialog("Reset \(layout.appName)?", isPresented: $confirmingResetLayout) {
            Button("Reset Layout", role: .destructive) { model.resetLayout(id) }
        } message: {
            Text(model.isBuiltIn(id)
                 ? "Every key goes back to Sidekey's built-in layout."
                 : "This removes the layout for this app.")
        }
    }
}

/// A layout's 15 slots. ``columns`` is 5 for landscape, or 3 for the portrait preview, which keeps
/// reading order the way the iPad does (`iKeypadApp.swift` `keyGrid`).
struct KeyGridView: View {
    @ObservedObject var model: LayoutEditorModel
    let layoutId: String
    let layout: DeckProfile
    let changed: Set<Int>
    @Binding var selection: Int?
    let columns: Int
    var compact = false

    var body: some View {
        let keys = Dictionary(layout.keys.map { ($0.position, $0) }, uniquingKeysWith: { first, _ in first })
        let rows = layout.rows * layout.columns / columns
        Grid(horizontalSpacing: compact ? 4 : 8, verticalSpacing: compact ? 4 : 8) {
            ForEach(0..<rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<columns, id: \.self) { column in
                        let slot = row * columns + column
                        SlotView(key: keys[slot], isChanged: changed.contains(slot), isSelected: selection == slot, compact: compact)
                            .onTapGesture { selection = slot }
                            .draggable(String(slot))
                            .dropDestination(for: String.self) { items, _ in
                                guard let from = items.first.flatMap(Int.init) else { return false }
                                model.moveKey(from: from, to: slot, in: layoutId)
                                selection = slot
                                return true
                            }
                    }
                }
            }
        }
        .padding(compact ? 6 : 12)
        .background(EditorTheme.plate, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SlotView: View {
    let key: DeckKey?
    let isChanged: Bool
    let isSelected: Bool
    let compact: Bool

    var body: some View {
        let size = compact ? CGSize(width: 46, height: 40) : CGSize(width: 104, height: 84)
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                if let key {
                    if let icon = key.iconSystemName {
                        Image(systemName: icon).font(compact ? .caption : .title2).foregroundStyle(EditorTheme.tint(for: key.role))
                    }
                    if !compact {
                        Text(key.label).font(.caption).lineLimit(1).foregroundStyle(.white)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .background(key == nil ? EditorTheme.plate : EditorTheme.cap, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isSelected ? Color.accentColor : .white.opacity(0.08),
                                                                     lineWidth: isSelected ? 2 : 1))
            if isChanged {
                Circle().fill(Color.accentColor).frame(width: 7, height: 7).padding(5)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(key.map { "\($0.label)\(isChanged ? ", changed" : "")" } ?? "Empty slot")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

- [ ] **Step 2: Add the menu item**

In `LayoutsMenuSection` (`iKeypadMacApp.swift`), make the first item:

```swift
        Button("Edit Layouts...") { LayoutEditorWindow.shared.show() }
```

- [ ] **Step 3: Build**

Run the Xcode build command. Expected: `** BUILD SUCCEEDED **`. Fix compile errors in the views only; do not change the model's tested behaviour.

- [ ] **Step 4: Verify by hand**

Run the app, choose **Edit Layouts...**:
- The window comes to the front. The list shows every built-in layout, Citrix modes as "Citrix Viewer: Outlook" and so on, sorted by name.
- Selecting Zoom shows its 15 slots in 3 rows of 5 with role colours, and a 5-row by 3-column portrait preview in the same reading order as the iPad in portrait.
- Drag Zoom's first key onto its second: they swap, dots appear on both, and the iPad (with Zoom in front) shows the swap within a second.
- **Reset Layout...** asks first, then the dots go and the iPad shows the built-in layout.
- Drag a System layout key that runs a script: the alert says it can't be moved.
- Open the menu while the window is open: the menu works and does not change while open.

- [ ] **Step 5: Run the suites and commit**

Run the full Mac suite (0 failures).

```bash
git add iKeypadMac/Sources/iKeypadMac/LayoutEditorWindow.swift iKeypadMac/Sources/iKeypadMac/iKeypadMacApp.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Add the layout editor window

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: Shortcut input helpers

**Files:**
- Create: `iKeypadMac/Sources/iKeypadMac/ShortcutInput.swift`
- Create: `iKeypadMac/Tests/iKeypadMacDaemonTests/ShortcutInputTests.swift`

**Interfaces:**
- Consumes: `KeyNames.name(forKeyCode:)` (Task 7).
- Produces:
  - `enum SystemShortcuts { static func conflict(key: String, modifiers: [KeyModifier]) -> String? }`
  - `enum AppleShortcuts { static func parse(_ listOutput: String) -> [String]; static func names() throws -> [String] }`
  - `@MainActor final class ShortcutRecorder: ObservableObject { @Published private(set) var isRecording: Bool; func start(onRecord: @escaping (String, [KeyModifier]) -> Void); func stop(); static func shortcut(keyCode: CGKeyCode, flags: NSEvent.ModifierFlags) -> (key: String, modifiers: [KeyModifier])? }`

- [ ] **Step 1: Write the failing tests**

`iKeypadMac/Tests/iKeypadMacDaemonTests/ShortcutInputTests.swift`:

```swift
import XCTest
import AppKit
import iKeypadShared
@testable import iKeypadMacDaemon

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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `(cd iKeypadMac && swift test --filter ShortcutInputTests)`
Expected: build FAILS with `cannot find 'ShortcutRecorder' in scope`.

- [ ] **Step 3: Implement**

`iKeypadMac/Sources/iKeypadMac/ShortcutInput.swift`:

```swift
import AppKit
import iKeypadShared

/// Shortcuts macOS acts on before the app in front sees them (default settings), so a key using
/// one would not reach the app. The editor warns but does not refuse: the user may have changed
/// the system setting.
enum SystemShortcuts {
    private static let reserved: [(key: String, modifiers: Set<KeyModifier>, use: String)] = [
        ("tab", [.command], "the app switcher"),
        ("space", [.command], "Spotlight"),
        ("space", [.command, .option], "Finder search"),
        ("3", [.command, .shift], "screenshots"),
        ("4", [.command, .shift], "screenshots"),
        ("5", [.command, .shift], "screenshots"),
        ("q", [.command, .control], "Lock Screen"),
        ("escape", [.command, .option], "Force Quit"),
        ("up", [.control], "Mission Control"),
        ("down", [.control], "App Exposé"),
        ("left", [.control], "moving between Spaces"),
        ("right", [.control], "moving between Spaces"),
    ]

    /// A sentence naming what macOS uses ``key`` with ``modifiers`` for, or ``nil``.
    static func conflict(key: String, modifiers: [KeyModifier]) -> String? {
        let mods = Set(modifiers)
        return reserved.first { $0.key == key && $0.modifiers == mods }.map { "macOS uses this for \($0.use)." }
    }
}

/// The user's Apple Shortcuts, for the Apple Shortcut menu.
enum AppleShortcuts {
    /// Names from ``shortcuts list`` output, one per line, sorted.
    static func parse(_ listOutput: String) -> [String] {
        listOutput.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.sorted()
    }

    /// Run ``/usr/bin/shortcuts list``.
    ///
    /// :raises: when the tool cannot run or exits with an error, with its message.
    static func names() throws -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["list"]
        let out = Pipe(), err = Pipe()
        task.standardOutput = out
        task.standardError = err
        try task.run()
        let output = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else {
            let message = String(decoding: err.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            throw ShortcutsListError(errorDescription: "Couldn't list your shortcuts: \(message)")
        }
        return parse(String(decoding: output, as: UTF8.self))
    }
}

struct ShortcutsListError: LocalizedError {
    let errorDescription: String?
}

/// Captures the next key press in the editor window as a layout shortcut.
@MainActor
final class ShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    private var monitor: Any?

    /// Listen for the next key press a layout can send; other keys are swallowed and ignored.
    func start(onRecord: @escaping (String, [KeyModifier]) -> Void) {
        stop()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if let recorded = Self.shortcut(keyCode: CGKeyCode(event.keyCode), flags: event.modifierFlags) {
                onRecord(recorded.key, recorded.modifiers)
                self?.stop()
            }
            return nil
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    /// The layout shortcut for a key press, modifiers in menu order (⌃⌥⇧⌘).
    ///
    /// :returns: ``nil`` for a key a layout cannot send.
    static func shortcut(keyCode: CGKeyCode, flags: NSEvent.ModifierFlags) -> (key: String, modifiers: [KeyModifier])? {
        guard let name = KeyNames.name(forKeyCode: keyCode) else { return nil }
        let order: [(NSEvent.ModifierFlags, KeyModifier)] = [(.control, .control), (.option, .option), (.shift, .shift), (.command, .command)]
        return (name, order.filter { flags.contains($0.0) }.map(\.1))
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `(cd iKeypadMac && swift test --filter ShortcutInputTests)`
Expected: 5 tests pass.

- [ ] **Step 5: Build and commit**

Run the Xcode build command (`** BUILD SUCCEEDED **`).

```bash
git add iKeypadMac/Sources/iKeypadMac/ShortcutInput.swift iKeypadMac/Tests/iKeypadMacDaemonTests/ShortcutInputTests.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Add shortcut recording, system shortcut warnings and the shortcuts list

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Key inspector

**Files:**
- Create: `iKeypadMac/Sources/iKeypadMac/KeyInspectorView.swift`
- Modify: `iKeypadMac/Sources/iKeypadMac/LayoutEditorWindow.swift` (the "Task 11 adds the key inspector here." comment in `detail`)

**Interfaces:**
- Consumes: `LayoutEditorModel` (`layout`, `changedSlots`, `isEditable`, `isBuiltIn`, `modes`, `setKey`, `removeKey`, `resetKey`, `newKey`, `errorMessage`), `KeyNames`, `SymbolCatalog`, `SystemShortcuts`, `AppleShortcuts`, `ShortcutRecorder`, `EditorTheme`, `LayoutValidator.maxLabelLength`.
- Produces: `struct KeyInspectorView: View { init(model: LayoutEditorModel, layoutId: String, slot: Int) }`.

- [ ] **Step 1: Implement**

`iKeypadMac/Sources/iKeypadMac/KeyInspectorView.swift`:

```swift
import SwiftUI
import iKeypadShared

/// Edits the key in one slot. Every valid change saves at once; a label outside 1 to 16
/// characters is shown as a problem and not saved until fixed.
struct KeyInspectorView: View {
    @ObservedObject var model: LayoutEditorModel
    let layoutId: String
    let slot: Int

    @State private var draft = LayoutEditorModel.newKey
    @State private var confirmingReset = false
    @State private var choosingIcon = false
    @State private var shortcutNames: [String] = []
    @StateObject private var recorder = ShortcutRecorder()

    private enum Kind: String, CaseIterable, Identifiable {
        case keyboard = "Keyboard Shortcut", windows = "Windows Shortcut", shortcut = "Apple Shortcut", mode = "Switch Layout"
        var id: Self { self }
    }

    private var key: DeckKey? { model.layout(layoutId)?.keys.first { $0.position == slot } }
    private var isChanged: Bool { model.changedSlots(in: layoutId).contains(slot) }
    private var labelProblem: String? {
        let label = draft.label.trimmingCharacters(in: .whitespaces)
        if label.isEmpty { return "Enter a label." }
        if draft.label.count > LayoutValidator.maxLabelLength { return "At most \(LayoutValidator.maxLabelLength) characters." }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key \(slot + 1)").font(.headline)
            if let key, !model.isEditable(key) {
                Text("\"\(key.label)\" is a built-in key that runs a script. Custom keys can't run scripts, so it can only be replaced or removed.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("Replace with a New Key") { model.setKey(LayoutEditorModel.newKey, at: slot, in: layoutId) }
                Button("Remove Key", role: .destructive) { model.removeKey(at: slot, in: layoutId) }
            } else if key == nil {
                Text("Empty slot").foregroundStyle(.secondary)
                Button("Add Key") { model.setKey(LayoutEditorModel.newKey, at: slot, in: layoutId) }
                if isChanged { resetButton }
            } else {
                form
            }
        }
        .frame(width: 300, alignment: .topLeading)
        .onAppear(perform: loadDraft)
        .onChange(of: slot) { _ in loadDraft() }
        .onChange(of: layoutId) { _ in loadDraft() }
        .onChange(of: draft) { new in
            guard labelProblem == nil, let key, new != CustomKey(key) else { return }
            model.setKey(new, at: slot, in: layoutId)
        }
        .onDisappear { recorder.stop() }
        .confirmationDialog("Reset this key?", isPresented: $confirmingReset) {
            Button("Reset Key", role: .destructive) { model.resetKey(at: slot, in: layoutId) }
        } message: {
            Text(model.isBuiltIn(layoutId) ? "It goes back to the built-in key." : "The slot becomes empty.")
        }
    }

    private var form: some View {
        Form {
            TextField("Label", text: $draft.label)
            if let labelProblem { Text(labelProblem).font(.caption).foregroundStyle(.red) }

            HStack {
                Text("Icon")
                Spacer()
                Button {
                    choosingIcon = true
                } label: {
                    Image(systemName: draft.iconSystemName ?? "square.dashed")
                }
                .popover(isPresented: $choosingIcon) { IconPicker(selection: $draft.iconSystemName) }
            }

            Picker("Colour", selection: $draft.role) {
                Text("Navigate").tag(KeyRole?.some(.navigate))
                Text("Create").tag(KeyRole?.some(.create))
                Text("Run").tag(KeyRole?.some(.run))
                Text("Modify").tag(KeyRole?.some(.modify))
                Text("Danger").tag(KeyRole?.some(.danger))
            }

            Picker("Action", selection: kind) {
                ForEach(availableKinds) { Text($0.rawValue).tag($0) }
            }
            actionEditor

            Toggle("Hold to fire", isOn: $draft.requiresConfirm)
            if key?.toggleChipId != nil && !isChanged {
                Text("Editing this key stops it lighting with the app's state.").font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                Button("Remove Key", role: .destructive) { model.removeKey(at: slot, in: layoutId) }
                if isChanged { resetButton }
            }
        }
    }

    private var resetButton: some View {
        Button("Reset Key...") { confirmingReset = true }
    }

    private var availableKinds: [Kind] {
        model.modes(of: layoutId).count > 1 ? Kind.allCases : [.keyboard, .windows, .shortcut]
    }

    private var kind: Binding<Kind> {
        Binding(
            get: {
                switch draft.action {
                case .windowsHotkey: return .windows
                case .runShortcut: return .shortcut
                case .switchProfile: return .mode
                default: return .keyboard
                }
            },
            set: { new in
                switch new {
                case .keyboard: draft.action = .hotkey(key: "a", modifiers: [.command])
                case .windows: draft.action = .windowsHotkey(key: "a", modifiers: [.ctrl])
                case .shortcut:
                    loadShortcutNames()
                    if let first = shortcutNames.first {
                        draft.action = .runShortcut(name: first)
                    } else if model.errorMessage == nil {
                        model.errorMessage = "You have no Apple Shortcuts yet. Make one in the Shortcuts app first."
                    }
                case .mode:
                    if let first = model.modes(of: layoutId).first { draft.action = .switchProfile(profileId: first.id) }
                }
            }
        )
    }

    @ViewBuilder private var actionEditor: some View {
        switch draft.action {
        case .hotkey(let name, let modifiers):
            HStack {
                ForEach([(KeyModifier.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")], id: \.1) { mod, symbol in
                    Toggle(symbol, isOn: Binding(
                        get: { modifiers.contains(mod) },
                        set: { on in draft.action = .hotkey(key: name, modifiers: on ? modifiers + [mod] : modifiers.filter { $0 != mod }) }
                    ))
                    .toggleStyle(.button)
                }
                Picker("Key", selection: Binding(get: { name }, set: { draft.action = .hotkey(key: $0, modifiers: modifiers) })) {
                    ForEach(KeyNames.mac, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
            }
            Button(recorder.isRecording ? "Press a shortcut... (click to cancel)" : "Record Shortcut") {
                if recorder.isRecording { recorder.stop() } else {
                    recorder.start { key, mods in draft.action = .hotkey(key: key, modifiers: mods) }
                }
            }
            if let warning = SystemShortcuts.conflict(key: name, modifiers: modifiers) {
                Text(warning).font(.caption).foregroundStyle(.orange)
            }
        case .windowsHotkey(let name, let modifiers):
            HStack {
                ForEach([WindowsModifier.ctrl, .alt, .shift, .win], id: \.self) { mod in
                    Toggle(mod.rawValue.capitalized, isOn: Binding(
                        get: { modifiers.contains(mod) },
                        set: { on in draft.action = .windowsHotkey(key: name, modifiers: on ? modifiers + [mod] : modifiers.filter { $0 != mod }) }
                    ))
                    .toggleStyle(.button)
                }
                Picker("Key", selection: Binding(get: { name }, set: { draft.action = .windowsHotkey(key: $0, modifiers: modifiers) })) {
                    ForEach(KeyNames.windows, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
            }
        case .runShortcut(let name):
            Picker("Shortcut", selection: Binding(get: { name }, set: { draft.action = .runShortcut(name: $0) })) {
                ForEach(shortcutNames.contains(name) ? shortcutNames : [name] + shortcutNames, id: \.self) { Text($0).tag($0) }
            }
            .onAppear(perform: loadShortcutNames)
        case .switchProfile(let id):
            Picker("Layout", selection: Binding(get: { id }, set: { draft.action = .switchProfile(profileId: $0) })) {
                ForEach(model.modes(of: layoutId)) { Text($0.title).tag($0.id) }
            }
        case .shellScript, .appleScript, .none:
            EmptyView()
        }
    }

    private func loadDraft() {
        recorder.stop()
        if let key, model.isEditable(key) { draft = CustomKey(key) }
    }

    private func loadShortcutNames() {
        guard shortcutNames.isEmpty else { return }
        do {
            shortcutNames = try AppleShortcuts.names()
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
}

/// A searchable grid of ``SymbolCatalog`` symbols.
private struct IconPicker: View {
    @Binding var selection: String?
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            TextField("Search icons", text: $query).textFieldStyle(.roundedBorder)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 8), spacing: 8) {
                    ForEach(SymbolCatalog.matching(query), id: \.self) { name in
                        Button {
                            selection = name
                            dismiss()
                        } label: {
                            Image(systemName: name).frame(width: 32, height: 32)
                        }
                        .buttonStyle(.borderless)
                        .help(name)
                        .accessibilityLabel(name)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 340, height: 360)
    }
}
```

In `LayoutEditorView.detail`, replace the comment `// Task 11 adds the key inspector here.` with:

```swift
            if let slot = selectedSlot {
                KeyInspectorView(model: model, layoutId: id, slot: slot)
            }
```

Note: `WindowsModifier` needs `Hashable` for `ForEach(..., id: \.self)`. It is a `String` raw-value enum, so it already is; `KeyModifier` likewise.

- [ ] **Step 2: Build**

Run the Xcode build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Verify by hand**

With the iPad connected and Zoom (or any app with a built-in layout) in front:
- Select a key: the inspector shows its label, icon, colour, action and hold setting.
- Change the label: the iPad updates as you type; clear the label: "Enter a label." shows and nothing is saved; 17 characters: "At most 16 characters."
- Pick an icon from the popover (search "hand"): the iPad shows it.
- **Record Shortcut**, press ⌥Y: the key becomes ⌥Y; tapping it on the iPad sends ⌥Y. Press ⌘Tab while recording: macOS takes it and nothing is recorded; choose Tab and ⌘ by hand instead and the "app switcher" warning shows.
- Switch Action to Apple Shortcut: your shortcuts are listed; pick one and tap the key: it runs.
- Citrix Viewer: Switch Layout is offered and lists its modes; elsewhere it is not.
- A System layout key that runs a script shows the replace-or-remove message.
- **Reset Key...** asks, then the built-in key returns and its dot goes.
- Empty slot: **Add Key** creates "New Key".

- [ ] **Step 4: Run the suites and commit**

Run the full Mac suite (0 failures).

```bash
git add iKeypadMac/Sources/iKeypadMac/KeyInspectorView.swift iKeypadMac/Sources/iKeypadMac/LayoutEditorWindow.swift iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Add the key inspector to the layout editor

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: Add App

**Files:**
- Modify: `iKeypadMac/Sources/iKeypadMac/LayoutEditorWindow.swift` (`LayoutEditorView`)

**Interfaces:**
- Consumes: `LayoutEditorModel.addApp(bundleIdentifier:name:)`, `.errorMessage`.
- Produces: nothing for later tasks.

- [ ] **Step 1: Implement**

In `LayoutEditorView`, add to the `List` (after `.frame(minWidth: 230)`):

```swift
            .safeAreaInset(edge: .bottom) {
                Button("Add App...", action: chooseApp)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
```

and the method:

```swift
    /// Pick an app in Applications and give it a layout (or select the one it has).
    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.prompt = "Add"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let bundleId = Bundle(url: url)?.bundleIdentifier else {
            model.errorMessage = "\(url.lastPathComponent) has no bundle identifier, so Sidekey can't tell when it is in front."
            return
        }
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        model.addApp(bundleIdentifier: bundleId, name: name)
    }
```

Add `import UniformTypeIdentifiers` at the top of the file for `.application`.

- [ ] **Step 2: Build**

Run the Xcode build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Verify by hand**

- **Add App...**, choose an app with no built-in layout (for example TextEdit): it appears in the list, selected, with an empty grid. Add a key, bring TextEdit forward: the iPad shows that key.
- **Add App...** with Zoom: Zoom is selected; no new entry.
- **Reset Layout...** on TextEdit: it leaves the list and the iPad shows the System layout for TextEdit.

- [ ] **Step 4: Commit**

```bash
git add iKeypadMac/Sources/iKeypadMac/LayoutEditorWindow.swift
git commit -m "Let the layout editor add a layout for any app

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 13: Documentation and the 1.4.0 release notes

**Files:**
- Modify: `README.md`, `docs/index.html`, `docs/support.html`
- Create: release notes text for Mac 1.4.0 (in the PR description; the GitHub release is published only after the user confirms)

- [ ] **Step 1: Write the documentation**

- `README.md`: a "Custom layouts" section: open **Edit Layouts...** from the menu bar; change, move, remove or reset any key; add a layout for any app; changes reach the iPad straight away; custom keys can send keyboard or Windows shortcuts, run your Apple Shortcuts, or switch Citrix modes, and cannot run scripts; files live in `~/Library/Application Support/Sidekey/Layouts/` and can be edited by hand (then choose **Reload Layouts**).
- `docs/support.html`: the same, plus what "N layout files have errors" means and how to fix or delete a file.
- `docs/index.html`: replace any claim that layouts are fixed or code-only with one sentence on the editor.
- Release notes for Mac 1.4.0: the editor; the shortcut-name fix from Task 1, described plainly ("Apple Shortcut keys now run the shortcuts tool directly instead of through a shell"); iPad app unchanged and not required to update.

Check every claim against the code as built. Do not mention features from the spec's Out of scope list.

- [ ] **Step 2: Fresh-subagent review (CLAUDE.md "Outgoing documents")**

Dispatch a fresh subagent (not the one that wrote the text) to review `README.md`, `docs/index.html`, `docs/support.html` and the release notes for: factual claims against the source (quote the line or say NOT FOUND), contradictions with other files (`appstore/metadata.md`, `PRODUCT.md`), stale references, dates against `date`, and every em dash with its line number. Report the findings list first (even if empty), then apply the fixes.

- [ ] **Step 3: Version and final checks**

In `project.yml`, set the `SidekeyMac` target's `MARKETING_VERSION: "1.4.0"` and `CURRENT_PROJECT_VERSION: "6"`. Run `xcodegen generate`, both test suites (0 failures) and the Xcode build (`** BUILD SUCCEEDED **`).

- [ ] **Step 4: Commit**

```bash
git add README.md docs/index.html docs/support.html project.yml iKeypadApp.xcodeproj/project.pbxproj
git commit -m "Document custom layouts and set the Mac version to 1.4.0

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

Do not tag, publish a release or push without the user's go-ahead.

---

## Done for Part 2

- All tests green; `SidekeyMac` builds; every hand check in Tasks 9, 11 and 12 done with a real iPad.
- Docs reviewed by a fresh subagent and fixed.
- Ready for a PR into `main` and, on the user's confirmation, the 1.4.0 release.
