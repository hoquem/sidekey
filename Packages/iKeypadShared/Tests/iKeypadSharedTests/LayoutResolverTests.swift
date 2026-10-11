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

    /// Untouched keys keep ``<layoutId>#<slot>``, so a tap from a layout pinned on the iPad still lands.
    func testUntouchedKeysKeepThePlainId() {
        let layout = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        XCTAssertEqual(Set(layout.keys.filter { $0.position != 4 }.map(\.id)), ["us.zoom.xos#0", "us.zoom.xos#1", "us.zoom.xos#9"])
    }

    /// A user's key carries a digest of its content, so a pinned copy of an older key is never
    /// matched to the new one. The literal value proves the id is the same on every launch.
    func testACustomKeyIdCarriesADigestOfTheKey() {
        let layout = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        XCTAssertEqual(layout.keys.first { $0.position == 4 }?.id, "us.zoom.xos#4#\(Self.raiseHandDigest)")
    }

    /// First 8 hex characters of SHA-256 over ``raiseHand`` encoded with sorted keys, checked with
    /// `shasum -a 256` on that JSON.
    private static let raiseHandDigest = "3843a83c"

    func testCustomKeyIdsAreTheSameOnEveryResolve() {
        let first = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        let second = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        XCTAssertEqual(first.keys.map(\.id), second.keys.map(\.id))
    }

    /// Turning on hold-to-fire is an edit like any other: the key gets a new id.
    func testEditingAKeyChangesItsId() {
        var held = raiseHand
        held.requiresConfirm = true
        let before = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        let after = LayoutResolver.resolve(customisation([4: .key(held)]), base: base)
        XCTAssertNotEqual(before.keys.first { $0.position == 4 }?.id, after.keys.first { $0.position == 4 }?.id)
    }

    /// The digest ids reach the iPad unchanged; decoding must not derive them again.
    func testCustomKeyIdsSurviveTheWire() throws {
        let layout = LayoutResolver.resolve(customisation([4: .key(raiseHand)]), base: base)
        let decoded = try JSONDecoder().decode(DeckProfile.self, from: JSONEncoder().encode(layout))
        XCTAssertEqual(decoded.keys.map(\.id), layout.keys.map(\.id))
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
