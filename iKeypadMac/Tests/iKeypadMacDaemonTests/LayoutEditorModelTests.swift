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

    private func writeBrokenFile(_ id: String) throws -> Data {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bytes = Data("{ not json".utf8)
        try bytes.write(to: directory.appendingPathComponent("\(id).json"))
        model.reload()
        return bytes
    }

    func testABrokenFileIsListedInFileErrors() throws {
        _ = try writeBrokenFile(zoom)
        XCTAssertEqual(model.fileErrors.map(\.fileName), ["\(zoom).json"])
    }

    func testEditingALayoutWithABrokenFileRefusesAndKeepsTheFile() throws {
        let bytes = try writeBrokenFile(zoom)
        model.setKey(raiseHand, at: 4, in: zoom)
        XCTAssertTrue(model.errorMessage?.hasPrefix("Fix or delete \(zoom).json first: ") == true, model.errorMessage ?? "nil")
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("\(zoom).json")), bytes)
    }

    func testAddingAnAppWhoseFileIsBrokenRefuses() throws {
        let bytes = try writeBrokenFile("com.example.SidekeyTest")
        model.addApp(bundleIdentifier: "com.example.SidekeyTest", name: "Example")
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("com.example.SidekeyTest.json")), bytes)
    }

    func testResettingALayoutDeletesItsBrokenFile() throws {
        _ = try writeBrokenFile(zoom)
        model.resetLayout(zoom)
        XCTAssertFalse(fileExists(zoom))
        XCTAssertTrue(model.fileErrors.isEmpty)
    }

    func testEditingRefusesWhenTheFileWasBrokenByHandAfterTheEditorLoaded() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bytes = Data("{ not json".utf8)
        try bytes.write(to: directory.appendingPathComponent("\(zoom).json"))
        // No model.reload(): the editor has not seen the hand edit.
        model.setKey(raiseHand, at: 4, in: zoom)
        XCTAssertTrue(model.errorMessage?.hasPrefix("Fix or delete \(zoom).json first: ") == true, model.errorMessage ?? "nil")
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("\(zoom).json")), bytes)
    }

    /// A drag after a valid hand edit moves the hand-edited key, not the one the editor loaded.
    func testMovingAKeyUsesTheFileAsItIsNow() throws {
        var handEdited = raiseHand
        handEdited.label = "Hand Edited"
        try store.save(LayoutCustomisation(layoutId: zoom, appBundleIdentifier: zoom, appName: "Zoom", slots: [4: .key(handEdited)]))
        model.moveKey(from: 4, to: 0, in: zoom)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.layout(zoom)?.keys.first { $0.position == 0 }?.label, "Hand Edited")
    }
}
