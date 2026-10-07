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

    /// Shell actions run with the Mac app's working directory (/), so a key like `git add -A`
    /// can never work; built-in layouts must not ship one.
    func testNoDefaultKeyRunsAShellCommandThatDependsOnTheWorkingDirectory() {
        for profile in DefaultProfiles.allDefaultProfiles() {
            for key in profile.keys {
                if case .shellScript(let command) = key.action {
                    XCTAssertFalse(command.hasPrefix("git "), "\(profile.appName) › \(key.label) runs \(command) from /")
                }
            }
        }
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

    func testDeleteKeyHasItsGlyph() {
        XCTAssertEqual(KeyAction.hotkey(key: "delete", modifiers: [.command, .shift]).shortcutHint, "⇧⌘⌫")
    }

    func testVibeCodingLayoutsAreRegistered() throws {
        let profiles = DefaultProfiles.allDefaultProfiles()
        func profile(_ bundle: String) throws -> DeckProfile {
            try XCTUnwrap(profiles.first { $0.appBundleIdentifier == bundle }, bundle)
        }
        let cursor = try profile("com.todesktop.230313mzl4w4u92")
        XCTAssertEqual(cursor.appName, "Cursor")
        XCTAssertEqual(cursor.keys.first { $0.label == "Accept All" }?.action, .hotkey(key: "return", modifiers: [.command]))
        XCTAssertEqual(cursor.keys.first { $0.label == "Reject All" }?.action, .hotkey(key: "delete", modifiers: [.command, .shift]))

        let antigravity = try profile("com.google.antigravity-ide")
        XCTAssertEqual(antigravity.appName, "Antigravity")
        XCTAssertEqual(antigravity.keys.first { $0.label == "Agent Panel" }?.action, .hotkey(key: "l", modifiers: [.command]))

        let opencode = try profile("ai.opencode.desktop")
        XCTAssertEqual(opencode.appName, "OpenCode")
        XCTAssertEqual(opencode.keys.first { $0.label == "New Session" }?.action, .hotkey(key: "s", modifiers: [.command, .shift]))
        XCTAssertEqual(opencode.keys.first { $0.label == "Stop" }?.action, .hotkey(key: "escape", modifiers: []))

        for layout in [cursor, antigravity, opencode] {
            XCTAssertEqual(Set(layout.keys.map(\.position)).count, layout.keys.count, "\(layout.appName) has duplicate slots")
            XCTAssertLessThanOrEqual(layout.keys.count, 15)
        }
    }

    func testChromeHasItsOwnFullLayout() throws {
        let chrome = try XCTUnwrap(DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "com.google.Chrome" })
        XCTAssertEqual(chrome.appName, "Google Chrome")
        XCTAssertEqual(chrome.keys.count, 15)
        XCTAssertEqual(chrome.keys.first { $0.label == "Search Tabs" }?.action, .hotkey(key: "a", modifiers: [.command, .shift]))
    }

    func testPopularMacAppsHaveLayouts() {
        let bundles = Set(DefaultProfiles.allDefaultProfiles().map(\.appBundleIdentifier))
        let popular = ["com.apple.Safari", "com.google.Chrome", "com.apple.finder", "com.apple.mail", "com.apple.MobileSMS",
                       "com.microsoft.Word", "com.microsoft.Excel", "com.microsoft.Powerpoint", "com.microsoft.Outlook",
                       "com.microsoft.teams2", "com.tinyspeck.slackmacgap", "us.zoom.xos", "net.whatsapp.WhatsApp",
                       "com.spotify.client", "com.apple.Notes", "com.apple.iCal", "com.apple.Music", "notion.id",
                       "com.openai.chat", "com.apple.Photos"]
        for bundle in popular {
            XCTAssertTrue(bundles.contains(bundle), "no layout for \(bundle)")
        }
        let safari = DefaultProfiles.allDefaultProfiles().first { $0.appBundleIdentifier == "com.apple.Safari" }
        XCTAssertEqual(safari?.keys.count, 15)
    }
}

