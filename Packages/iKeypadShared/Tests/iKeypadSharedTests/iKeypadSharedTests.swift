import XCTest
@testable import iKeypadShared

final class iKeypadSharedTests: XCTestCase {
    func testFramedProtocolEncodingDecoding() throws {
        let testProfile = DefaultProfiles.makeDefaultFallbackProfile()
        let originalMessage = DeckMessage.profileUpdated(profile: testProfile)

        let encodedData = try FramedMessageProtocol.encode(originalMessage)
        XCTAssertGreaterThan(encodedData.count, 4)

        var buffer = encodedData
        let decodedMessage = FramedMessageProtocol.decode(from: &buffer)

        XCTAssertNotNil(decodedMessage)
        XCTAssertEqual(originalMessage, decodedMessage)
        XCTAssertEqual(buffer.count, 0)
    }

    func testPartialFrameDecoding() throws {
        let testProfile = DefaultProfiles.makeDefaultFallbackProfile()
        let originalMessage = DeckMessage.profileUpdated(profile: testProfile)
        let encodedData = try FramedMessageProtocol.encode(originalMessage)

        var partialBuffer = encodedData.prefix(encodedData.count - 10)
        let decodedNil = FramedMessageProtocol.decode(from: &partialBuffer)
        XCTAssertNil(decodedNil)
        XCTAssertEqual(partialBuffer.count, encodedData.count - 10)

        // Append rest of data
        partialBuffer.append(encodedData.suffix(10))
        let decoded = FramedMessageProtocol.decode(from: &partialBuffer)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(partialBuffer.count, 0)
    }

    func testTerminalProfileIsRegisteredWithFullGrid() throws {
        let terminal = try XCTUnwrap(
            DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "com.apple.Terminal" }
        )

        XCTAssertEqual(terminal.appName, "Terminal")
        XCTAssertEqual(terminal.keys.count, terminal.rows * terminal.columns)
        XCTAssertEqual(terminal.keys.map(\.position), Array(0..<15))
        XCTAssertEqual(
            terminal.keys.first { $0.label == "Interrupt" }?.action,
            .hotkey(key: "c", modifiers: [.control])
        )
    }

    func testXcodeProfileIsRegisteredWithFullGrid() throws {
        let xcode = try XCTUnwrap(
            DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "com.apple.dt.Xcode" }
        )

        XCTAssertEqual(xcode.appName, "Xcode")
        XCTAssertEqual(xcode.keys.count, xcode.rows * xcode.columns)
        XCTAssertEqual(xcode.keys.map(\.position), Array(0..<15))
        XCTAssertEqual(
            xcode.keys.first { $0.label == "Run" }?.action,
            .hotkey(key: "r", modifiers: [.command])
        )
    }

    func testWhatsAppProfileIsRegisteredWithFullGrid() throws {
        let whatsApp = try XCTUnwrap(
            DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "net.whatsapp.WhatsApp" }
        )

        XCTAssertEqual(whatsApp.appName, "WhatsApp")
        XCTAssertEqual(whatsApp.keys.map(\.position), Array(0..<15))
        XCTAssertEqual(
            whatsApp.keys.first { $0.label == "New Chat" }?.action,
            .hotkey(key: "n", modifiers: [.command])
        )
    }

    func testTelegramProfileIsRegisteredWithFullGrid() throws {
        let telegram = try XCTUnwrap(
            DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "com.tdesktop.Telegram" }
        )

        XCTAssertEqual(telegram.appName, "Telegram")
        XCTAssertEqual(telegram.keys.map(\.position), Array(0..<15))
        XCTAssertEqual(
            telegram.keys.first { $0.label == "Saved Msgs" }?.action,
            .hotkey(key: "0", modifiers: [.command])
        )
    }

    func testZoomProfileIsRegisteredWithFullGrid() throws {
        let zoom = try XCTUnwrap(
            DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "us.zoom.xos" }
        )

        XCTAssertEqual(zoom.appName, "Zoom")
        XCTAssertEqual(zoom.keys.map(\.position), Array(0..<15))
        XCTAssertEqual(
            zoom.keys.first { $0.label == "Mute" }?.action,
            .hotkey(key: "a", modifiers: [.command, .shift])
        )
    }

    func testMacDownProfileIsRegisteredWithFullGrid() throws {
        let macDown = try XCTUnwrap(
            DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "com.uranusjr.macdown" }
        )

        XCTAssertEqual(macDown.appName, "MacDown")
        XCTAssertEqual(macDown.keys.map(\.position), Array(0..<15))
        XCTAssertEqual(
            macDown.keys.first { $0.label == "Bold" }?.action,
            .hotkey(key: "b", modifiers: [.command])
        )
    }

    func testWordProfileIsRegisteredWithFullGrid() throws {
        let word = try XCTUnwrap(
            DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "com.microsoft.Word" }
        )

        XCTAssertEqual(word.appName, "Word")
        XCTAssertEqual(word.keys.map(\.position), Array(0..<15))
        XCTAssertEqual(
            word.keys.first { $0.label == "Track Changes" }?.action,
            .hotkey(key: "e", modifiers: [.command, .shift])
        )
    }
}
