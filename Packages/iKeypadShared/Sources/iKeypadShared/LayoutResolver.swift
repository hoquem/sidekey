import Foundation

/// Applies a user's ``LayoutCustomisation`` to a base layout. Pure: no disk, no UI.
public enum LayoutResolver {
    /// The layout the Mac registers for ``customisation``.
    ///
    /// :param customisation: The user's changes.
    /// :param base: The built-in layout with the same id, or ``nil`` for an app with none. When
    ///     present it decides the app, name and grid size, so a file cannot move a built-in
    ///     layout to another app.
    /// :returns: The base's keys with the changed slots replaced or removed. Key ids are derived
    ///     by ``DeckProfile`` from the layout id and slot, so they match the built-in ones.
    public static func resolve(_ customisation: LayoutCustomisation, base: DeckProfile?) -> DeckProfile {
        var keys = Dictionary((base?.keys ?? []).map { ($0.position, $0) }, uniquingKeysWith: { first, _ in first })
        for (position, change) in customisation.slots {
            switch change {
            case .removed:
                keys[position] = nil
            case .key(let custom):
                keys[position] = DeckKey(position: position, label: custom.label, iconSystemName: custom.iconSystemName,
                                         action: custom.action, role: custom.role, requiresConfirm: custom.requiresConfirm)
            }
        }
        return DeckProfile(
            id: customisation.layoutId,
            appBundleIdentifier: base?.appBundleIdentifier ?? customisation.appBundleIdentifier,
            appName: base?.appName ?? customisation.appName,
            rows: base?.rows ?? 3,
            columns: base?.columns ?? 5,
            keys: keys.values.sorted { $0.position < $1.position }
        )
    }
}
