import Foundation

/// A user's changes to one layout, stored as ``<layoutId>.json`` in Sidekey's Layouts folder on
/// the Mac. Slots not listed keep the base layout's key: the built-in layout with the same id, or
/// nothing for an app Sidekey has no layout for. See ``LayoutResolver``.
public struct LayoutCustomisation: Codable, Equatable, Sendable {
    /// The only format this build reads; ``LayoutValidator`` on the Mac rejects a file with any other version rather than guessing at it.
    public static let currentVersion = 1

    public var version: Int
    /// The built-in layout's id, or the app's bundle id for an app with no built-in layout.
    public var layoutId: String
    public var appBundleIdentifier: String
    public var appName: String
    /// Changed slots by position, 0 to 14 in reading order of the 3 by 5 grid.
    public var slots: [Int: SlotChange]

    public init(layoutId: String, appBundleIdentifier: String, appName: String, slots: [Int: SlotChange] = [:]) {
        self.version = Self.currentVersion
        self.layoutId = layoutId
        self.appBundleIdentifier = appBundleIdentifier
        self.appName = appName
        self.slots = slots
    }
}

/// What the user did to one slot.
public enum SlotChange: Equatable, Sendable {
    /// Show this key instead of the base layout's.
    case key(CustomKey)
    /// Leave the slot empty even if the base layout has a key there.
    case removed
}

extension SlotChange: Codable {
    private enum CodingKeys: String, CodingKey { case key }
    private static let removedWord = "removed"

    /// Decodes the string ``removedWord`` or an object ``{"key": {...}}``; any other string is an error.
    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let word = try? single.decode(String.self) {
            guard word == Self.removedWord else {
                throw DecodingError.dataCorruptedError(in: single, debugDescription: "Expected \"removed\" or a key, found \"\(word)\"")
            }
            self = .removed
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = .key(try container.decode(CustomKey.self, forKey: .key))
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .removed:
            var single = encoder.singleValueContainer()
            try single.encode(Self.removedWord)
        case .key(let key):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(key, forKey: .key)
        }
    }
}

/// A key the user made. Unlike ``DeckKey`` it has no id (derived from layout and slot), badge or
/// live toggle: those belong to built-in keys that read app state.
public struct CustomKey: Codable, Equatable, Sendable {
    public var label: String
    public var iconSystemName: String?
    public var role: KeyRole?
    /// Fire only after a press and hold, for disruptive keys.
    public var requiresConfirm: Bool
    public var action: KeyAction

    public init(label: String, iconSystemName: String?, role: KeyRole?, requiresConfirm: Bool, action: KeyAction) {
        self.label = label
        self.iconSystemName = iconSystemName
        self.role = role
        self.requiresConfirm = requiresConfirm
        self.action = action
    }

    /// The user-editable part of ``key``, for starting an edit from a built-in key.
    public init(_ key: DeckKey) {
        self.init(label: key.label, iconSystemName: key.iconSystemName, role: key.role,
                  requiresConfirm: key.requiresConfirm, action: key.action)
    }
}
