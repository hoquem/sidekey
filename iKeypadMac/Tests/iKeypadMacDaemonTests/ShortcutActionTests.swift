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
