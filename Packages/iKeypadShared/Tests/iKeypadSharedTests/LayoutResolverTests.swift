import XCTest
@testable import iKeypadShared

final class LayoutResolverTests: XCTestCase {
    private let base = DeckProfile(id: "us.zoom.xos", appBundleIdentifier: "us.zoom.xos", appName: "Zoom", keys: [
        DeckKey(position: 0, label: "Mute", iconSystemName: "mic", action: .hotkey(key: "a", modifiers: [.command, .shift]), role: .modify),
        DeckKey(position: 1, label: "Video", action: .hotkey(key: "v", modifiers: [.command, .shift]), role: .modify),
        DeckKey(position: 9, label: "End", action: .hotkey(key: "w", modifiers: [.command]), role: .danger, requiresConfirm: true),
    ])
    private let raiseHand = CustomKey(label: "Raise Hand", iconSystemName: "hand.raised", role: .run,
                                      requiresConfirm: false, action: .hotkey(key: "y", modifiers: [.option]))

    private func customisation(_ slots: [Int: SlotChange]) -> LayoutCustomisation {
        LayoutCustomisation(layoutId: "us.zoom.xos", appBundleIdentifier: "us.zoom.xos", appName: "Zoom", slots: slots)
    }

    func testUntouchedSlotsComeFromTheBase() {
        let layout = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        XCTAssertEqual(layout.keys.first { $0.position == 0 }, base.keys[0])
        XCTAssertEqual(layout.keys.first { $0.position == 9 }, base.keys[2])
    }

    func testAChangedSlotTakesTheUsersKey() {
        let layout = LayoutResolver.resolve(customisation([1: .key(raiseHand)]), base: base)
        let key = try! XCTUnwrap(layout.keys.first { $0.position == 1 })
        XCTAssertEqual(key.label, "Raise Hand")
        XCTAssertEqual(key.action, .hotkey(key: "y", modifiers: [.option]))
        XCTAssertEqual(key.role, .run)
    }

    func testARemovedSlotIsEmpty() {
        let layout = LayoutResolver.resolve(customisation([9: .removed]), base: base)
        XCTAssertNil(layout.keys.first { $0.position == 9 })
        XCTAssertEqual(layout.keys.count, 2)
    }

    func testKeyIdsStayStableSoPinnedTapsStillLand() {
        let layout = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        XCTAssertEqual(Set(layout.keys.map(\.id)), ["us.zoom.xos#0", "us.zoom.xos#1", "us.zoom.xos#4", "us.zoom.xos#9"])
    }

    func testANewAppStartsFromAnEmptyThreeByFiveLayout() {
        let new = LayoutCustomisation(layoutId: "com.example.App", appBundleIdentifier: "com.example.App", appName: "Example",
                                      slots: [0: .key(raiseHand)])
        let layout = LayoutResolver.resolve(new, base: nil)
        XCTAssertEqual(layout.id, "com.example.App")
        XCTAssertEqual(layout.appBundleIdentifier, "com.example.App")
        XCTAssertEqual(layout.appName, "Example")
        XCTAssertEqual([layout.rows, layout.columns], [3, 5])
        XCTAssertEqual(layout.keys.map(\.label), ["Raise Hand"])
    }

    /// A file cannot move a built-in layout to another app by naming a different bundle.
    func testTheBaseDecidesWhichAppALayoutBelongsTo() {
        var c = customisation([:])
        c.appBundleIdentifier = "com.example.Other"
        c.appName = "Other"
        let layout = LayoutResolver.resolve(c, base: base)
        XCTAssertEqual(layout.appBundleIdentifier, "us.zoom.xos")
        XCTAssertEqual(layout.appName, "Zoom")
    }

    /// The file format in the spec decodes, and encoding keeps "removed" as a plain string.
    func testTheSpecExampleDecodesAndRoundTrips() throws {
        let json = #"""
        {
          "version": 1,
          "layoutId": "us.zoom.xos",
          "appBundleIdentifier": "us.zoom.xos",
          "appName": "Zoom",
          "slots": {
            "4": { "key": { "label": "Raise Hand", "iconSystemName": "hand.raised",
                            "role": "run", "requiresConfirm": false,
                            "action": { "hotkey": { "key": "y", "modifiers": ["opt"] } } } },
            "9": "removed"
          }
        }
        """#
        let decoded = try JSONDecoder().decode(LayoutCustomisation.self, from: Data(json.utf8))
        XCTAssertEqual(decoded, customisation([4: .key(raiseHand), 9: .removed]))

        let encoded = try JSONEncoder().encode(decoded)
        XCTAssertTrue(String(decoding: encoded, as: UTF8.self).contains(#""9":"removed""#))
        XCTAssertEqual(try JSONDecoder().decode(LayoutCustomisation.self, from: encoded), decoded)
    }

    func testAnUnknownSlotWordIsAnError() {
        let json = #"{"version":1,"layoutId":"a","appBundleIdentifier":"a","appName":"A","slots":{"0":"gone"}}"#
        XCTAssertThrowsError(try JSONDecoder().decode(LayoutCustomisation.self, from: Data(json.utf8)))
    }

    func testCustomKeyCopiesADeckKey() {
        XCTAssertEqual(CustomKey(base.keys[2]), CustomKey(label: "End", iconSystemName: nil, role: .danger,
                                                         requiresConfirm: true, action: .hotkey(key: "w", modifiers: [.command])))
    }
}
