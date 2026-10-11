import CryptoKit
import Foundation

/// Applies a user's ``LayoutCustomisation`` to a base layout. Pure: no disk, no UI.
public enum LayoutResolver {
    /// The layout the Mac registers for ``customisation``.
    ///
    /// :param customisation: The user's changes.
    /// :param base: The built-in layout with the same id, or ``nil`` for an app with none. When
    ///     present it decides the app, name and grid size, so a file cannot move a built-in
    ///     layout to another app.
    /// :returns: The base's keys with the changed slots replaced or removed. Untouched keys keep
    ///     the id ``DeckProfile`` derives, ``<layoutId>#<slot>``; a user's key gets
    ///     ``<layoutId>#<slot>#<digest>`` (see ``digest(of:)``). The Mac finds a tapped key by id,
    ///     so a layout pinned on the iPad before a key changed can never run the new key.
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
        var profile = DeckProfile(
            id: customisation.layoutId,
            appBundleIdentifier: base?.appBundleIdentifier ?? customisation.appBundleIdentifier,
            appName: base?.appName ?? customisation.appName,
            rows: base?.rows ?? 3,
            columns: base?.columns ?? 5,
            keys: keys.values.sorted { $0.position < $1.position }
        )
        // After the init, which sets every id to <layoutId>#<slot>.
        for index in profile.keys.indices {
            guard case .key(let custom) = customisation.slots[profile.keys[index].position] else { continue }
            profile.keys[index].id += "#\(digest(of: custom))"
        }
        return profile
    }

    /// A short fingerprint of everything a user's key does and shows, the same on every launch.
    ///
    /// :param key: The user's key.
    /// :returns: The first 8 hex characters of SHA-256 over the key's JSON with sorted keys.
    static func digest(of key: CustomKey) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        // Encoding plain strings, bools and enums cannot fail.
        let json = try! encoder.encode(key)
        return String(SHA256.hash(data: json).map { String(format: "%02x", $0) }.joined().prefix(8))
    }
}
