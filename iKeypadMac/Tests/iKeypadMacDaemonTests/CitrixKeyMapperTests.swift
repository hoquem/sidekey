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

    func testCtrlAltDelIsControlCommandOptionForwardDelete() throws {
        // Verified live 2026-10-08: brings up the Windows security screen in the user's session.
        XCTAssertEqual(try CitrixKeyMapper.chord(key: "forwarddelete", modifiers: [.ctrl, .alt]),
                       KeyChord(modifierKeys: [leftControl, leftCommand, leftOption], keyCode: 0x75, flags: ctrlFlags.union(altFlags)))
    }

    func testUnknownKeyThrows() {
        XCTAssertThrowsError(try CitrixKeyMapper.chord(key: "pageup", modifiers: [.ctrl])) { error in
            XCTAssertEqual(error as? CitrixKeyMapper.UnknownKey, CitrixKeyMapper.UnknownKey(key: "pageup"))
        }
    }
}
