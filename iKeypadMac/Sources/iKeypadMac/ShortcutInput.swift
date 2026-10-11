import AppKit
import iKeypadShared

/// Shortcuts macOS acts on before the app in front sees them (default settings), so a key using
/// one would not reach the app. The editor warns but does not refuse: the user may have changed
/// the system setting.
enum SystemShortcuts {
    private static let reserved: [(key: String, modifiers: Set<KeyModifier>, use: String)] = [
        ("tab", [.command], "the app switcher"),
        ("space", [.command], "Spotlight"),
        ("space", [.command, .option], "Finder search"),
        ("3", [.command, .shift], "screenshots"),
        ("4", [.command, .shift], "screenshots"),
        ("5", [.command, .shift], "screenshots"),
        ("q", [.command, .control], "Lock Screen"),
        ("escape", [.command, .option], "Force Quit"),
        ("up", [.control], "Mission Control"),
        ("down", [.control], "App Exposé"),
        ("left", [.control], "moving between Spaces"),
        ("right", [.control], "moving between Spaces"),
    ]

    /// A sentence naming what macOS uses ``key`` with ``modifiers`` for, or ``nil``.
    static func conflict(key: String, modifiers: [KeyModifier]) -> String? {
        let mods = Set(modifiers)
        return reserved.first { $0.key == key && $0.modifiers == mods }.map { "macOS uses this for \($0.use)." }
    }
}

/// The user's Apple Shortcuts, for the Apple Shortcut menu.
enum AppleShortcuts {
    /// Names from ``shortcuts list`` output, one per line, sorted.
    static func parse(_ listOutput: String) -> [String] {
        listOutput.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.sorted()
    }

    /// Run ``/usr/bin/shortcuts list``.
    ///
    /// :raises: when the tool cannot run or exits with an error, with its message.
    static func names() throws -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["list"]
        let out = Pipe(), err = Pipe()
        task.standardOutput = out
        task.standardError = err
        try task.run()
        let output = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else {
            let message = String(decoding: err.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            throw ShortcutsListError(errorDescription: "Couldn't list your shortcuts: \(message)")
        }
        return parse(String(decoding: output, as: UTF8.self))
    }
}

struct ShortcutsListError: LocalizedError {
    let errorDescription: String?
}

/// Captures the next key press in the editor window as a layout shortcut.
@MainActor
final class ShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    private var monitor: Any?

    /// Listen for the next key press a layout can send; other keys are swallowed and ignored.
    func start(onRecord: @escaping (String, [KeyModifier]) -> Void) {
        stop()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if let recorded = Self.shortcut(keyCode: CGKeyCode(event.keyCode), flags: event.modifierFlags) {
                onRecord(recorded.key, recorded.modifiers)
                self?.stop()
            }
            return nil
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    /// The layout shortcut for a key press, modifiers in menu order (⌃⌥⇧⌘).
    ///
    /// :returns: ``nil`` for a key a layout cannot send.
    static func shortcut(keyCode: CGKeyCode, flags: NSEvent.ModifierFlags) -> (key: String, modifiers: [KeyModifier])? {
        guard let name = KeyNames.name(forKeyCode: keyCode) else { return nil }
        let order: [(NSEvent.ModifierFlags, KeyModifier)] = [(.control, .control), (.option, .option), (.shift, .shift), (.command, .command)]
        return (name, order.filter { flags.contains($0.0) }.map(\.1))
    }
}
