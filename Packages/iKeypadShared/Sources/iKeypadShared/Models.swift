import Foundation

public struct DeckProfile: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let appBundleIdentifier: String
    public let appName: String
    public let rows: Int
    public let columns: Int
    public var keys: [DeckKey]

    public init(
        id: String = UUID().uuidString,
        appBundleIdentifier: String,
        appName: String,
        rows: Int = 3,
        columns: Int = 5,
        keys: [DeckKey] = []
    ) {
        self.id = id
        self.appBundleIdentifier = appBundleIdentifier
        self.appName = appName
        self.rows = rows
        self.columns = columns
        // Key ids derive from the layout id and slot, so the same key has the same id on every
        // launch; the Mac finds a tapped key by id, including for a layout pinned on the iPad.
        self.keys = keys.map { key in
            var key = key
            key.id = "\(id)#\(key.position)"
            return key
        }
    }
}

/// What a key does, which drives its colour on the deck so colour carries meaning.
public enum KeyRole: String, Codable, Equatable, Sendable {
    /// Move around: tabs, chats, panels, search.
    case navigate
    /// Make or open something: new tab, new chat, open file.
    case create
    /// Start something: run, build, play, share.
    case run
    /// Stop, close or destroy something.
    case danger
    /// Change formatting, state or settings.
    case modify
}

public struct DeckKey: Codable, Identifiable, Equatable, Sendable {
    public internal(set) var id: String
    public let position: Int
    public var label: String
    public var iconSystemName: String?
    public var badgeText: String?
    public var action: KeyAction
    public var role: KeyRole?
    /// Disruptive keys (lock, end call, interrupt) fire only after a press-and-hold.
    public var requiresConfirm: Bool
    /// Id of an ``ContextChip`` whose ``ContextChip/isOn`` is this key's live toggle state.
    public var toggleChipId: String?

    public init(
        id: String = UUID().uuidString,
        position: Int,
        label: String,
        iconSystemName: String? = nil,
        badgeText: String? = nil,
        action: KeyAction,
        role: KeyRole? = nil,
        requiresConfirm: Bool = false,
        toggleChipId: String? = nil
    ) {
        self.id = id
        self.position = position
        self.label = label
        self.iconSystemName = iconSystemName
        self.badgeText = badgeText
        self.action = action
        self.role = role
        self.requiresConfirm = requiresConfirm
        self.toggleChipId = toggleChipId
    }

    private enum CodingKeys: String, CodingKey {
        case id, position, label, iconSystemName, badgeText, action
        case role, requiresConfirm, toggleChipId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        position = try c.decode(Int.self, forKey: .position)
        label = try c.decode(String.self, forKey: .label)
        iconSystemName = try c.decodeIfPresent(String.self, forKey: .iconSystemName)
        badgeText = try c.decodeIfPresent(String.self, forKey: .badgeText)
        action = try c.decode(KeyAction.self, forKey: .action)
        role = try c.decodeIfPresent(KeyRole.self, forKey: .role)
        requiresConfirm = try c.decodeIfPresent(Bool.self, forKey: .requiresConfirm) ?? false
        toggleChipId = try c.decodeIfPresent(String.self, forKey: .toggleChipId)
    }
}

public enum KeyModifier: String, Codable, Equatable, Sendable {
    case command = "cmd"
    case shift = "shift"
    case option = "opt"
    case control = "ctrl"
}

public enum KeyAction: Codable, Equatable, Sendable {
    case hotkey(key: String, modifiers: [KeyModifier])
    case shellScript(command: String)
    case appleScript(script: String)
    case runShortcut(name: String)
    case switchProfile(profileId: String)
    case none

    /// The keyboard shortcut this action sends, in Mac menu notation (``⌃⌥⇧⌘`` then the key).
    public var shortcutHint: String? {
        guard case .hotkey(let key, let modifiers) = self else { return nil }
        let order: [(KeyModifier, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        let prefix = order.filter { modifiers.contains($0.0) }.map(\.1).joined()
        return prefix + Self.keyGlyph(key)
    }

    private static func keyGlyph(_ key: String) -> String {
        switch key.lowercased() {
        // U+FE0E forces text presentation; without it ↩ renders as an emoji keycap.
        case "tab": return "⇥\u{FE0E}"
        case "return", "enter": return "↩\u{FE0E}"
        case "escape", "esc": return "⎋\u{FE0E}"
        case "space": return "Space"
        case "delete", "backspace": return "⌫"
        case "up": return "↑"
        case "down": return "↓"
        case "left": return "←"
        case "right": return "→"
        default: return key.uppercased()
        }
    }
}

/// Live state of the Mac app the deck is driving, shown in the Now Controlling band.
public struct AppContext: Codable, Equatable, Sendable {
    public let bundleIdentifier: String
    public let appName: String
    /// Focused window title (needs Accessibility permission on the Mac).
    public let windowTitle: String?
    /// App icon PNG, sent when the frontmost app changes and omitted on title-only updates.
    public let iconPNG: Data?
    /// Whether the Mac companion is trusted for Accessibility; without it keys cannot fire.
    public let accessibilityTrusted: Bool
    public let chips: [ContextChip]

    public init(
        bundleIdentifier: String,
        appName: String,
        windowTitle: String?,
        iconPNG: Data?,
        accessibilityTrusted: Bool,
        chips: [ContextChip]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.windowTitle = windowTitle
        self.iconPNG = iconPNG
        self.accessibilityTrusted = accessibilityTrusted
        self.chips = chips
    }
}

/// One piece of app state, such as Zoom's microphone.
public struct ContextChip: Codable, Equatable, Sendable, Identifiable {
    public enum Tone: String, Codable, Sendable {
        case neutral, good, warn, bad
    }

    public let id: String
    public let label: String
    public let systemImage: String
    public let tone: Tone
    /// On/off state for toggle-like chips; drives keys whose ``DeckKey/toggleChipId`` matches.
    public let isOn: Bool?

    public init(id: String, label: String, systemImage: String, tone: Tone, isOn: Bool?) {
        self.id = id
        self.label = label
        self.systemImage = systemImage
        self.tone = tone
        self.isOn = isOn
    }
}

public enum DeckMessage: Codable, Equatable, Sendable {
    case handshake(clientName: String)
    case handshakeAck(serverVersion: String, hostName: String?)
    case profileUpdated(profile: DeckProfile)
    case appContextUpdated(context: AppContext)
    /// A tap on key ``keyId`` of layout ``profileId``. The Mac runs the action from its own copy
    /// of that layout; a tap never carries an action, so a client cannot make the Mac run anything
    /// outside its built-in layouts. The Mac rejects taps on a layout that is no longer active
    /// unless ``pinned`` is set, in which case it brings that layout's app forward.
    case executeAction(keyId: String, profileId: String?, pinned: Bool?)
    case actionExecuted(keyId: String, success: Bool, errorMessage: String?)

    // Pairing and authentication (see ``PairingCrypto``). Until a connection authenticates, the
    // Mac sends it nothing but ``challenge`` and pairing or authentication results.

    /// Mac to iPad on connect: a fresh nonce to prove a stored token against, and who the Mac is.
    case challenge(nonce: Data, hostId: String, hostName: String?)
    /// iPad to Mac: the 6-digit code shown in the Mac's menu while pairing is open.
    case pair(code: String, clientId: String, clientName: String)
    /// Mac to iPad: the token to keep for this Mac. Sent once, at pairing.
    case paired(token: Data)
    case pairingFailed(reason: String)
    /// iPad to Mac: ``PairingCrypto/proof(token:nonce:)`` for the current challenge.
    case authenticate(clientId: String, proof: Data)
    case authenticationFailed(reason: String)
    case ping
    case pong
}

