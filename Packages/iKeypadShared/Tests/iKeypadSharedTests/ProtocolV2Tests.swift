import XCTest
@testable import iKeypadShared

final class ProtocolV2Tests: XCTestCase {
    func testShortcutHintFormatsHotkeysInMacModifierOrder() {
        XCTAssertEqual(KeyAction.hotkey(key: "t", modifiers: [.command]).shortcutHint, "⌘T")
        XCTAssertEqual(KeyAction.hotkey(key: "tab", modifiers: [.shift, .control]).shortcutHint, "⌃⇧⇥\u{FE0E}")
        XCTAssertEqual(KeyAction.hotkey(key: "up", modifiers: [.command, .option]).shortcutHint, "⌥⌘↑")
        XCTAssertEqual(KeyAction.hotkey(key: "return", modifiers: [.option, .command]).shortcutHint, "⌥⌘↩\u{FE0E}")
        XCTAssertNil(KeyAction.shellScript(command: "ls").shortcutHint)
    }

    func testKeyWithoutNewFieldsStillDecodes() throws {
        let legacy = """
        {"id":"k1","position":0,"label":"Run","action":{"none":{}}}
        """.data(using: .utf8)!
        let key = try JSONDecoder().decode(DeckKey.self, from: legacy)
        XCTAssertNil(key.role)
        XCTAssertFalse(key.requiresConfirm)
        XCTAssertNil(key.toggleChipId)
    }

    func testAppContextRoundTripsThroughFraming() throws {
        let context = AppContext(
            bundleIdentifier: "us.zoom.xos",
            appName: "Zoom",
            windowTitle: "Zoom Meeting",
            iconPNG: Data([0x89, 0x50]),
            accessibilityTrusted: true,
            chips: [ContextChip(id: "zoom.audio", label: "Mic muted", systemImage: "mic.slash.fill", tone: .bad, isOn: false)]
        )
        var buffer = try FramedMessageProtocol.encode(.appContextUpdated(context: context))
        XCTAssertEqual(FramedMessageProtocol.decode(from: &buffer), .appContextUpdated(context: context))
    }

    func testExecuteActionCarriesProfileAndPin() throws {
        let message = DeckMessage.executeAction(keyId: "k", profileId: "p1", pinned: true)
        var buffer = try FramedMessageProtocol.encode(message)
        XCTAssertEqual(FramedMessageProtocol.decode(from: &buffer), message)
    }

    /// A tap names a key; the action it runs is the Mac's own. An action field sent by an older or
    /// hostile client must not survive decoding.
    func testExecuteActionDropsAnyClientSuppliedAction() throws {
        let frame = #"{"executeAction":{"keyId":"k","action":{"shellScript":{"command":"touch /tmp/x"}},"profileId":"p","pinned":false}}"#
        let decoded = try JSONDecoder().decode(DeckMessage.self, from: Data(frame.utf8))
        XCTAssertEqual(decoded, .executeAction(keyId: "k", profileId: "p", pinned: false))
    }

    func testDefaultProfileKeyIdsAreStableAcrossLaunches() {
        let first = DefaultProfiles.makeTerminalProfile().keys.map(\.id)
        XCTAssertEqual(first, DefaultProfiles.makeTerminalProfile().keys.map(\.id))
        XCTAssertEqual(first.first, "com.apple.Terminal#0")
    }

    func testEveryDefaultKeyHasARole() {
        for profile in DefaultProfiles.allDefaultProfiles() {
            for key in profile.keys {
                XCTAssertNotNil(key.role, "\(profile.appName) › \(key.label) has no role")
            }
        }
    }

    func testDisruptiveKeysRequireHoldToConfirm() {
        let disruptive: Set<String> = ["Lock Mac", "Interrupt", "End Call", "Lock", "Clean"]
        for profile in DefaultProfiles.allDefaultProfiles() {
            for key in profile.keys where disruptive.contains(key.label) {
                XCTAssertTrue(key.requiresConfirm, "\(profile.appName) › \(key.label) should require hold-to-confirm")
            }
        }
    }

    func testZoomToggleKeysAreLinkedToLiveChips() throws {
        let zoom = try XCTUnwrap(DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "us.zoom.xos" })
        XCTAssertEqual(zoom.keys.first { $0.label == "Mute" }?.toggleChipId, "zoom.audio")
        XCTAssertEqual(zoom.keys.first { $0.label == "Video" }?.toggleChipId, "zoom.video")
    }

    func testDefaultProfileIdsAreStableAcrossLaunches() {
        // A pinned layout is referenced by id after the Mac companion restarts.
        XCTAssertEqual(DefaultProfiles.makeTerminalProfile().id, DefaultProfiles.makeTerminalProfile().id)
        XCTAssertEqual(DefaultProfiles.makeDefaultFallbackProfile().id, "default")
        let ids = DefaultProfiles.allDefaultProfiles().map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "profile ids must be unique")
    }
}
