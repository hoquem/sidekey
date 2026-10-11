import iKeypadShared

/// The SF Symbols the icon picker offers. macOS has no public API listing every symbol, so this is
/// every icon the built-in layouts use plus common extras. Tests check each one exists.
enum SymbolCatalog {
    private static let extras = [
        "star", "star.fill", "heart", "bolt", "flag", "bell", "bookmark", "tag", "paperclip", "link",
        "folder", "doc", "doc.on.doc", "tray", "archivebox", "trash", "pencil", "scissors",
        "magnifyingglass", "gearshape", "slider.horizontal.3", "terminal", "keyboard", "command",
        "play", "pause", "stop", "forward", "backward", "speaker.wave.2", "speaker.slash",
        "mic", "mic.slash", "video", "video.slash", "phone", "message", "envelope", "paperplane",
        "hand.raised", "hand.thumbsup", "person", "person.2", "calendar", "clock", "timer",
        "lock", "lock.open", "eye", "eye.slash", "lightbulb", "moon", "sun.max", "cloud",
        "arrow.clockwise", "arrow.uturn.backward", "arrow.uturn.forward", "arrow.up", "arrow.down",
        "arrow.left", "arrow.right", "plus", "minus", "xmark", "checkmark", "questionmark",
        "1.circle", "2.circle", "3.circle", "4.circle", "5.circle",
    ]

    static let all: [String] = Set(
        DefaultProfiles.allDefaultProfiles().flatMap(\.keys).compactMap(\.iconSystemName) + extras
    ).sorted()

    /// Symbols whose name contains the query (case-insensitive); everything for an empty query.
    ///
    /// :param query: Text typed into the icon picker's search field.
    /// :returns: The matching symbol names, sorted as in ``all``.
    static func matching(_ query: String) -> [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty ? all : all.filter { $0.contains(q) }
    }
}
