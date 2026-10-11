import Foundation
import iKeypadShared

/// Everything the layout editor does, without the views. Each edit becomes a
/// ``LayoutCustomisation``, is saved through the store (which validates it, so the editor can
/// never write a file the next launch would refuse) and reloads the monitor, which sends the
/// active layout to every iPad.
@MainActor
final class LayoutEditorModel: ObservableObject {
    /// One row of the app list: a built-in layout (each Citrix mode is its own row) or a user's
    /// layout for another app.
    struct Entry: Identifiable, Equatable {
        let id: String
        let title: String
        let isBuiltIn: Bool
        let isCustomised: Bool
    }

    /// What a new key starts as; the user changes it straight away.
    static let newKey = CustomKey(label: "New Key", iconSystemName: "star", role: .navigate,
                                  requiresConfirm: false, action: .hotkey(key: "a", modifiers: [.command]))

    @Published private(set) var entries: [Entry] = []
    @Published var selectedLayoutId: String?
    /// The last edit that failed, for the view to show; cleared by the view.
    @Published var errorMessage: String?
    /// Layout files that could not be loaded; the window lists them.
    @Published private(set) var fileErrors: [LayoutFileError] = []

    private let monitor: AppContextMonitor
    private let store: UserLayoutStore
    private var customisations: [String: LayoutCustomisation] = [:]

    init(monitor: AppContextMonitor, store: UserLayoutStore) {
        self.monitor = monitor
        self.store = store
        reload()
    }

    /// Re-read the files, for when the window opens after a hand edit.
    func reload() {
        let loaded = store.loadAll(builtIns: monitor.builtInProfiles)
        customisations = Dictionary(uniqueKeysWithValues: loaded.customisations.map { ($0.layoutId, $0) })
        fileErrors = loaded.errors
        rebuildEntries()
    }

    /// The layout as the iPad shows it: built-in plus the user's changes.
    ///
    /// :param id: The layout id.
    /// :returns: The resolved layout, or ``nil`` when there is no such layout.
    func layout(_ id: String) -> DeckProfile? {
        let base = monitor.builtInProfile(withId: id)
        guard let customisation = customisations[id] else { return base }
        return LayoutResolver.resolve(customisation, base: base)
    }

    /// Slots the user changed or removed in a layout.
    ///
    /// :param id: The layout id.
    func changedSlots(in id: String) -> Set<Int> {
        Set(customisations[id]?.slots.keys.map { $0 } ?? [])
    }

    /// Whether a key can be edited or moved. Built-in keys that run a script cannot, because
    /// user layouts may not hold scripts; they can still be replaced or removed.
    ///
    /// :param key: The key to test.
    func isEditable(_ key: DeckKey) -> Bool {
        switch key.action {
        case .hotkey, .windowsHotkey, .runShortcut, .switchProfile: return true
        case .shellScript, .appleScript, .none: return false
        }
    }

    /// Whether a layout is one of Sidekey's built-in layouts.
    ///
    /// :param id: The layout id.
    func isBuiltIn(_ id: String) -> Bool {
        monitor.builtInProfile(withId: id) != nil
    }

    /// The layouts a Switch Layout key in a layout may go to: every built-in layout of the same app.
    ///
    /// :param id: The layout id.
    func modes(of id: String) -> [Entry] {
        guard let bundle = layout(id)?.appBundleIdentifier else { return [] }
        let ids = Set(monitor.builtInProfiles.filter { $0.appBundleIdentifier == bundle }.map(\.id))
        return entries.filter { ids.contains($0.id) }
    }

    /// Replace the key in a slot.
    ///
    /// :param key: The new key.
    /// :param slot: The slot position.
    /// :param id: The layout id.
    func setKey(_ key: CustomKey, at slot: Int, in id: String) {
        change(id) { $0.slots[slot] = .key(key) }
    }

    /// Empty a slot.
    ///
    /// :param slot: The slot position.
    /// :param id: The layout id.
    func removeKey(at slot: Int, in id: String) {
        change(id) { $0.slots[slot] = .removed }
    }

    /// Put back the built-in key (or nothing, for a new app) in a slot.
    ///
    /// :param slot: The slot position.
    /// :param id: The layout id.
    func resetKey(at slot: Int, in id: String) {
        change(id) { $0.slots[slot] = nil }
    }

    /// Swap the keys in two slots; a key moved to an empty slot leaves its old slot empty.
    ///
    /// :param from: The slot being dragged.
    /// :param to: The slot it is dropped on.
    /// :param id: The layout id.
    func moveKey(from: Int, to: Int, in id: String) {
        guard from != to, let layout = layout(id) else { return }
        let moving = layout.keys.first { $0.position == from }
        let displaced = layout.keys.first { $0.position == to }
        if [moving, displaced].compactMap({ $0 }).contains(where: { !isEditable($0) }) {
            errorMessage = "Built-in keys that run a script can't be moved. You can replace or remove them."
            return
        }
        change(id) { c in
            c.slots[to] = moving.map { .key(CustomKey($0)) } ?? .removed
            c.slots[from] = displaced.map { .key(CustomKey($0)) } ?? .removed
        }
    }

    /// Remove every change to a layout: a built-in layout returns to as shipped, a new app's layout
    /// is deleted.
    ///
    /// :param id: The layout id.
    func resetLayout(_ id: String) {
        guard customisations[id] != nil || fileError(for: id) != nil else { return }
        do {
            try store.delete(layoutId: id)
        } catch {
            errorMessage = "Couldn't delete \(id).json: \(error.localizedDescription)"
            return
        }
        if monitor.builtInProfile(withId: id) == nil, selectedLayoutId == id { selectedLayoutId = nil }
        applyFiles()
    }

    /// Add a layout for an app, or select its layout if it has one.
    ///
    /// :param bundleIdentifier: The app's bundle identifier.
    /// :param name: The app's display name.
    func addApp(bundleIdentifier: String, name: String) {
        if refuseToOverwriteBrokenFile(for: bundleIdentifier) { return }
        if let existing = monitor.builtInProfiles.first(where: { $0.appBundleIdentifier == bundleIdentifier })?.id
            ?? customisations[bundleIdentifier]?.layoutId {
            selectedLayoutId = existing
            return
        }
        if save(LayoutCustomisation(layoutId: bundleIdentifier, appBundleIdentifier: bundleIdentifier, appName: name)) {
            selectedLayoutId = bundleIdentifier
        }
    }

    private func fileError(for id: String) -> LayoutFileError? {
        fileErrors.first { $0.fileName == "\(id).json" }
    }

    /// Saving over a file that failed to load would lose the user's hand edits.
    ///
    /// :returns: ``true`` (with ``errorMessage`` set) when the layout's file is broken.
    private func refuseToOverwriteBrokenFile(for id: String) -> Bool {
        guard let error = fileError(for: id) else { return false }
        errorMessage = "Fix or delete \(error.fileName) first: \(error.reason)"
        return true
    }

    private func change(_ id: String, _ edit: (inout LayoutCustomisation) -> Void) {
        guard let current = layout(id) else { return }
        if refuseToOverwriteBrokenFile(for: id) { return }
        var customisation = customisations[id]
            ?? LayoutCustomisation(layoutId: id, appBundleIdentifier: current.appBundleIdentifier, appName: current.appName)
        edit(&customisation)
        // A built-in layout with no changes left needs no file.
        if customisation.slots.isEmpty, monitor.builtInProfile(withId: id) != nil {
            resetLayout(id)
        } else {
            save(customisation)
        }
    }

    /// :returns: ``false`` when the store refused it; ``errorMessage`` says why.
    @discardableResult
    private func save(_ customisation: LayoutCustomisation) -> Bool {
        do {
            try store.save(customisation)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
        applyFiles()
        return true
    }

    /// Reload the monitor from the files, so the editor and the iPad always show what is on disk.
    private func applyFiles() {
        monitor.reloadUserLayouts(from: store)
        reload()
    }

    private func rebuildEntries() {
        let builtIn = monitor.builtInProfiles.map {
            Entry(id: $0.id, title: title(for: $0), isBuiltIn: true, isCustomised: customisations[$0.id] != nil)
        }
        let added = customisations.values.filter { monitor.builtInProfile(withId: $0.layoutId) == nil }.map {
            Entry(id: $0.layoutId, title: $0.appName, isBuiltIn: false, isCustomised: true)
        }
        entries = (builtIn + added).sorted { ($0.title.localizedLowercase, $0.id) < ($1.title.localizedLowercase, $1.id) }
    }

    /// "Citrix Viewer: Outlook" for an extra mode, named by the key that switches to it; the app's
    /// name for its start layout.
    private func title(for profile: DeckProfile) -> String {
        guard profile.id != profile.appBundleIdentifier else { return profile.appName }
        let modeName = monitor.builtInProfiles.lazy.flatMap(\.keys)
            .first { $0.action == .switchProfile(profileId: profile.id) }?.label
        return modeName.map { "\(profile.appName): \($0)" } ?? profile.appName
    }
}
