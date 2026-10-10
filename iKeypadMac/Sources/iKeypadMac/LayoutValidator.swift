import Foundation
import iKeypadShared

/// Decides whether a user layout file is safe to install. Runs on every load, not only in the
/// editor, because layout files can be edited by hand or tampered with. Sidekey holds the
/// Accessibility and Apple Events permissions, so a user layout may only send keys or run the
/// user's own Apple Shortcuts: never a shell command or an AppleScript.
enum LayoutValidator {
    static let maxLabelLength = 16
    static let slots = 0..<15

    /// The first problem with ``customisation``, or ``nil`` when it is safe to install.
    ///
    /// :param customisation: The decoded file.
    /// :param fileName: The file's name, which must be ``<layoutId>.json``.
    /// :param builtIns: Sidekey's built-in layouts, to find the app a layout belongs to and its modes.
    /// :returns: A sentence for the user, naming the slot when the problem is in one.
    static func problem(in customisation: LayoutCustomisation, fileName: String, builtIns: [DeckProfile]) -> String? {
        let c = customisation
        guard c.version == LayoutCustomisation.currentVersion else {
            return "Unsupported version \(c.version); this Sidekey reads version \(LayoutCustomisation.currentVersion)."
        }
        guard isSafeLayoutId(c.layoutId) else {
            return "Invalid layoutId \"\(c.layoutId)\"."
        }
        guard fileName == "\(c.layoutId).json" else { return "File name must be \(c.layoutId).json." }

        let base = builtIns.first { $0.id == c.layoutId }
        if base == nil {
            guard !c.appBundleIdentifier.isEmpty else { return "appBundleIdentifier is empty." }
            if let app = builtIns.first(where: { $0.appBundleIdentifier == c.appBundleIdentifier }) {
                return "\(app.appName) already has a built-in layout; customise layout \(app.id) instead."
            }
        }
        let bundle = base?.appBundleIdentifier ?? c.appBundleIdentifier
        let modeIds = Set(builtIns.filter { $0.appBundleIdentifier == bundle }.map(\.id))

        for position in c.slots.keys.sorted() {
            guard slots.contains(position) else { return "Slot \(position) is outside 0 to 14." }
            guard case .key(let key) = c.slots[position] else { continue }
            if let problem = problem(in: key, modeIds: modeIds) { return "Slot \(position): \(problem)" }
        }
        return nil
    }

    /// Whether ``id`` can name a file in the layouts folder: non-empty, no path separator, and not
    /// hidden. Stops a layout id from reaching outside the folder.
    ///
    /// :param id: A layout id, from a file or from the editor.
    /// :returns: ``true`` when ``id`` is safe to use as a file name stem.
    static func isSafeLayoutId(_ id: String) -> Bool {
        !id.isEmpty && !id.contains("/") && !id.hasPrefix(".")
    }

    private static func problem(in key: CustomKey, modeIds: Set<String>) -> String? {
        if key.label.trimmingCharacters(in: .whitespaces).isEmpty { return "label is empty." }
        if key.label.count > maxLabelLength { return "label is longer than \(maxLabelLength) characters." }
        switch key.action {
        case .hotkey(let name, _):
            return ActionDispatcher.shared.keyCodeForString(name) == nil ? "unknown key \"\(name)\"." : nil
        case .windowsHotkey(let name, let modifiers):
            return (try? CitrixKeyMapper.chord(key: name, modifiers: modifiers)) == nil ? "unknown Windows key \"\(name)\"." : nil
        case .runShortcut(let name):
            return name.trimmingCharacters(in: .whitespaces).isEmpty ? "shortcut name is empty." : nil
        case .switchProfile(let id):
            return modeIds.contains(id) ? nil : "\"\(id)\" is not another mode of this app."
        case .shellScript, .appleScript, .none:
            return "this action type is not allowed in user layouts."
        }
    }
}
