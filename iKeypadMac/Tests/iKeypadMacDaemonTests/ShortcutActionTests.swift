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

    /// A command that fails without writing to stderr still says why.
    func testAFailureWithNoStderrNamesTheExitCode() {
        let result = ActionDispatcher.shared.execute(action: .shellScript(command: "exit 3"))
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.error, "Command failed with code 3")
    }

    /// The tool's stderr is the reason, without the trailing newline.
    func testAFailureReportsTrimmedStderr() {
        let result = ActionDispatcher.shared.execute(action: .shellScript(command: "echo nope >&2; exit 1"))
        XCTAssertEqual(result.error, "nope")
    }

    /// More stderr than a pipe holds (64 KB) must not hang the tool waiting for a reader.
    func testALargeStderrDoesNotHang() {
        let result = ActionDispatcher.shared.execute(action: .shellScript(command: "head -c 200000 /dev/zero | tr '\\0' x >&2; exit 1"))
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.error?.count, 200000)
    }
}
