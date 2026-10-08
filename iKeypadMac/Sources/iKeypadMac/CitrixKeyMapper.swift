import CoreGraphics
import iKeypadShared

/// A key press with the modifier keys held around it, as a real keyboard would send it.
struct KeyChord: Equatable {
    /// Modifier keys pressed in this order and released in reverse.
    let modifierKeys: [CGKeyCode]
    /// The main key, or ``nil`` when the chord is a modifier on its own (the Win key).
    let keyCode: CGKeyCode?
    /// Flags for every posted event while the modifiers are held, including the device bits
    /// that tell left and right keys apart (Citrix reads right Command as the Win key).
    let flags: CGEventFlags
}

/// Translates a Windows shortcut into the Mac keys Citrix Viewer turns back into it.
///
/// Assumes these Citrix Viewer keyboard settings: Control via "Command (left) or Control", Alt via
/// "Command (left)-Option", the Windows key via Command (right), and F1 to F12 sent with Option.
/// Other settings send the wrong keys.
enum CitrixKeyMapper {
    struct UnknownKey: Error, Equatable { let key: String }

    private struct Modifier {
        let keyCode: CGKeyCode
        let flags: UInt64
    }

    private static let control = Modifier(keyCode: 0x3B, flags: CGEventFlags.maskControl.rawValue | 0x01)
    private static let shift = Modifier(keyCode: 0x38, flags: CGEventFlags.maskShift.rawValue | 0x02)
    private static let leftCommand = Modifier(keyCode: 0x37, flags: CGEventFlags.maskCommand.rawValue | 0x08)
    private static let option = Modifier(keyCode: 0x3A, flags: CGEventFlags.maskAlternate.rawValue | 0x20)
    private static let rightCommand = Modifier(keyCode: 0x36, flags: CGEventFlags.maskCommand.rawValue | 0x10)

    /// The chord for a Windows shortcut.
    ///
    /// :param key: A layout key name such as ``"s"``, ``"f4"`` or ``"win"`` (the Win key alone).
    /// :param modifiers: Windows modifiers, in any order.
    /// :returns: Modifiers in Windows order (Ctrl, Alt, Shift, Win), then Option for F-keys.
    /// :raises UnknownKey: when ``key`` has no Mac key code.
    static func chord(key: String, modifiers: [WindowsModifier]) throws -> KeyChord {
        var held: [Modifier] = []
        if modifiers.contains(.ctrl) { held.append(control) }
        if modifiers.contains(.alt) { held += [leftCommand, option] }
        if modifiers.contains(.shift) { held.append(shift) }
        if modifiers.contains(.win) || key == "win" { held.append(rightCommand) }

        var keyCode: CGKeyCode?
        if key != "win" {
            guard let code = ActionDispatcher.shared.keyCodeForString(key) else { throw UnknownKey(key: key) }
            keyCode = code
            let isFunctionKey = key.count >= 2 && key.lowercased().hasPrefix("f") && Int(key.dropFirst()) != nil
            if isFunctionKey && !held.contains(where: { $0.keyCode == option.keyCode }) { held.append(option) }
        }
        let flags = held.reduce(UInt64(0)) { $0 | $1.flags }
        return KeyChord(modifierKeys: held.map(\.keyCode), keyCode: keyCode, flags: CGEventFlags(rawValue: flags))
    }
}
