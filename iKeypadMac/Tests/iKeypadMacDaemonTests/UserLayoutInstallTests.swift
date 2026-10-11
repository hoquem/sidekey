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

    func testReloadKeepsTheLayoutOfTheAppInFront() throws {
        let app = "com.example.SidekeyTest"
        monitor.updateActiveApp(bundleId: app, appName: "Example")
        XCTAssertEqual(monitor.activeProfile.id, "default")
        try store.save(raiseHand(at: 0, in: app))

        monitor.reloadUserLayouts(from: store)
        XCTAssertEqual(monitor.activeProfile.id, app, "a layout added for the app in front shows at once")

        monitor.reloadUserLayouts(from: store)
        XCTAssertEqual(monitor.activeProfile.id, app, "a second reload keeps it")
    }
}
