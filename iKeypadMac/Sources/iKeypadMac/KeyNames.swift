import CoreGraphics

/// The key names a user layout can use, in the order the editor lists them. Tests check that each
/// one maps through ``ActionDispatcher/keyCodeForString(_:)`` (Mac) or ``CitrixKeyMapper`` (Windows),
/// so the editor never offers a key the Mac cannot send.
enum KeyNames {
    static let mac: [String] = "abcdefghijklmnopqrstuvwxyz0123456789".map(String.init)
        + ["-", "=", "[", "]", "\\", ";", "'", ",", ".", "/", "`",
           "space", "return", "tab", "escape", "delete", "forwarddelete", "left", "right", "up", "down"]
        + (1...12).map { "f\($0)" }

    /// Windows keys: the same keys, plus the Windows key pressed on its own.
    static let windows: [String] = mac + ["win"]

    /// The layout name of the key with ``code``, for the shortcut recorder.
    ///
    /// :param code: The virtual key code reported by the event.
    /// :returns: ``nil`` for keys a layout cannot send, such as fn.
    static func name(forKeyCode code: CGKeyCode) -> String? {
        mac.first { ActionDispatcher.shared.keyCodeForString($0) == code }
    }
}
