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

    func testDeleteCannotReachOutsideTheFolder() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let sibling = directory.deletingLastPathComponent().appendingPathComponent("sibling-\(UUID().uuidString).json")
        try Data("keep me".utf8).write(to: sibling)
        defer { try? FileManager.default.removeItem(at: sibling) }
        let escape = "../" + sibling.deletingPathExtension().lastPathComponent

        XCTAssertThrowsError(try store.delete(layoutId: escape))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sibling.path))
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
