import XCTest
import AppKit
import iKeypadShared
@testable import iKeypadMacDaemon

final class EditorDataTests: XCTestCase {
    func testEveryOfferedMacKeyCanBeSent() {
        for name in KeyNames.mac {
            XCTAssertNotNil(ActionDispatcher.shared.keyCodeForString(name), name)
        }
    }

    func testEveryOfferedWindowsKeyCanBeSent() {
        for name in KeyNames.windows {
            XCTAssertNoThrow(try CitrixKeyMapper.chord(key: name, modifiers: []), name)
        }
    }

    func testKeyCodesMapBackToTheirNames() {
        for name in KeyNames.mac {
            let code = ActionDispatcher.shared.keyCodeForString(name)!
            XCTAssertEqual(KeyNames.name(forKeyCode: code), name)
        }
        XCTAssertNil(KeyNames.name(forKeyCode: 0x3F), "fn is not a key a layout can send")
    }

    func testTheCatalogHasEveryBuiltInIcon() {
        let builtIn = Set(DefaultProfiles.allDefaultProfiles().flatMap(\.keys).compactMap(\.iconSystemName))
        XCTAssertTrue(builtIn.isSubset(of: Set(SymbolCatalog.all)))
    }

    func testEveryCatalogSymbolExists() {
        for name in SymbolCatalog.all {
            XCTAssertNotNil(NSImage(systemSymbolName: name, accessibilityDescription: nil), name)
        }
    }

    func testSearchMatchesPartsOfNames() {
        XCTAssertTrue(SymbolCatalog.matching("hand").contains("hand.raised"))
        XCTAssertEqual(SymbolCatalog.matching(""), SymbolCatalog.all)
    }
}
