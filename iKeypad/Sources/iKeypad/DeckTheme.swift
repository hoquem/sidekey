import SwiftUI
import iKeypadShared

/// Colours of the dark hardware deck. Keys are graphite caps on a graphite plate; colour is
/// reserved for meaning: a key's role tints its icon, and amber "lit" marks a key that just
/// fired or a state that needs attention.
enum DeckTheme {
    static let plate = Color(red: 0.063, green: 0.071, blue: 0.090)          // #101218
    static let well = Color(red: 0.039, green: 0.047, blue: 0.059)           // #0A0C0F
    static let capTop = Color(red: 0.141, green: 0.153, blue: 0.180)         // #24272E
    static let capBottom = Color(red: 0.102, green: 0.114, blue: 0.137)      // #1A1D23
    static let capPressed = Color(red: 0.078, green: 0.086, blue: 0.106)     // #14161B
    static let raised = Color(red: 0.133, green: 0.149, blue: 0.176)         // #22262D
    static let hairline = Color.white.opacity(0.07)

    static let label = Color(red: 0.953, green: 0.961, blue: 0.973)          // #F3F5F8
    static let secondaryLabel = Color(red: 0.639, green: 0.678, blue: 0.729) // #A3ADBA

    /// Amber signal: a key that just fired, a live toggle, the app icon's lit key.
    static let lit = Color(red: 1.0, green: 0.690, blue: 0.125)              // #FFB020
    static let failure = Color(red: 1.0, green: 0.478, blue: 0.478)          // #FF7A7A

    static func tint(for role: KeyRole?) -> Color {
        switch role {
        case .navigate, .none: return Color(red: 0.796, green: 0.835, blue: 0.882) // #CBD5E1
        case .create: return Color(red: 0.478, green: 0.706, blue: 1.0)            // #7AB4FF
        case .run: return Color(red: 0.369, green: 0.890, blue: 0.557)             // #5EE38E
        case .danger: return failure
        case .modify: return Color(red: 0.788, green: 0.659, blue: 1.0)            // #C9A8FF
        }
    }

    static func tone(_ tone: ContextChip.Tone) -> Color {
        switch tone {
        case .good: return tint(for: .run)
        case .bad: return failure
        case .warn: return lit
        case .neutral: return secondaryLabel
        }
    }
}
