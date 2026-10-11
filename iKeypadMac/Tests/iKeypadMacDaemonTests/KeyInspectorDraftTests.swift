import XCTest
import iKeypadShared
@testable import iKeypadMacDaemon

/// The inspector saves its draft only into the slot the draft was loaded from. A drag that swaps
/// keys also moves the selection, and a draft loaded for the old slot must never be written into
/// the newly selected one (that wrote one key into two slots).
final class KeyInspectorDraftTests: XCTestCase {
    private let goToFile = CustomKey(label: "Go to File", iconSystemName: nil, role: nil, requiresConfirm: false,
                                     action: .hotkey(key: "p", modifiers: [.command]))
    private let terminal = CustomKey(label: "Terminal", iconSystemName: nil, role: nil, requiresConfirm: false,
                                     action: .hotkey(key: "`", modifiers: [.control]))

    private func owner(_ slot: Int) -> KeyInspectorDraft.Owner {
        KeyInspectorDraft.Owner(layoutId: "app", slot: slot)
    }

    func testADraftFromAnotherSlotIsNeverSaved() {
        let draft = KeyInspectorDraft(owner: owner(3), key: goToFile)
        XCTAssertFalse(draft.shouldSave(into: owner(1), savedKey: terminal))
    }

    func testAnEditedDraftIsSavedIntoItsOwnSlot() {
        let draft = KeyInspectorDraft(owner: owner(1), key: goToFile)
        XCTAssertTrue(draft.shouldSave(into: owner(1), savedKey: terminal))
    }

    func testAnUnchangedDraftIsNotSaved() {
        let draft = KeyInspectorDraft(owner: owner(1), key: goToFile)
        XCTAssertFalse(draft.shouldSave(into: owner(1), savedKey: goToFile))
    }

    func testADraftWithNoOwnerIsNotSaved() {
        let draft = KeyInspectorDraft(owner: nil, key: goToFile)
        XCTAssertFalse(draft.shouldSave(into: owner(1), savedKey: terminal))
    }

    func testADraftForAnEmptySlotIsNotSaved() {
        let draft = KeyInspectorDraft(owner: owner(1), key: goToFile)
        XCTAssertFalse(draft.shouldSave(into: owner(1), savedKey: nil))
    }
}
