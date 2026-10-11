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

    /// A sentence naming what macOS uses a shortcut for, if it reserves that shortcut.
    ///
    /// :param key: The layout key name, such as ``tab`` or ``4``.
    /// :param modifiers: The modifiers held with the key, in any order.
    /// :returns: A sentence naming the macOS feature, or ``nil`` when macOS does not reserve the shortcut.
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

    /// Run ``/usr/bin/shortcuts list`` directly, with no shell. Blocks the calling thread briefly
    /// until the tool exits, so call it off the main thread for anything interactive.
    ///
    /// :returns: The shortcut names, sorted.
    /// :raises: ``ShortcutsListError`` when the tool exits with a non-zero status, carrying its
    ///     stderr or the exit code. Other errors come from ``Process`` when the tool cannot start.
    static func names() throws -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["list"]
        let out = Pipe(), err = Pipe()
        task.standardOutput = out
        task.standardError = err
        try task.run()
        // Drain stderr on another thread while stdout is read, so a full stderr pipe cannot block the tool.
        let errorBox = DataBox()
        let stderrDrained = DispatchGroup()
        stderrDrained.enter()
        DispatchQueue.global().async {
            errorBox.data = err.fileHandleForReading.readDataToEndOfFile()
            stderrDrained.leave()
        }
        let output = out.fileHandleForReading.readDataToEndOfFile()
        stderrDrained.wait()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else {
            let text = String(decoding: errorBox.data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            let reason = text.isEmpty ? "exit code \(task.terminationStatus)" : text
            throw ShortcutsListError(errorDescription: "Couldn't list your shortcuts: \(reason)")
        }
        return parse(String(decoding: output, as: UTF8.self))
    }
}

/// Holds bytes read on a background thread; written once before the thread's group is left.
private final class DataBox: @unchecked Sendable {
    var data = Data()
}

/// Raised when ``AppleShortcuts/names()`` cannot list the user's shortcuts.
///
/// ``errorDescription`` says why, using the tool's stderr when it wrote any.
struct ShortcutsListError: LocalizedError {
    let errorDescription: String?
}

/// Captures the next key press in the editor window as a layout shortcut.
///
/// While recording, a local key monitor swallows every key press in the app. Keys a layout cannot
/// send beep and keep recording. The monitor is removed by ``stop()``, when a key is recorded, or
/// when the recorder is deallocated.
@MainActor
final class ShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    private var monitor: Any?

    /// Whether a key monitor is installed. Internal so tests can check that stopping removes it.
    var isMonitoring: Bool { monitor != nil }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }

    /// Start recording. The first key press a layout can send is passed to ``onRecord`` and
    /// recording stops; other key presses beep and are ignored.
    ///
    /// :param onRecord: Called once with the layout key name and its modifiers in menu order.
    func start(onRecord: @escaping (String, [KeyModifier]) -> Void) {
        stop()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let recorded = Self.shortcut(keyCode: CGKeyCode(event.keyCode), flags: event.modifierFlags) else {
                NSSound.beep()
                return nil
            }
            onRecord(recorded.key, recorded.modifiers)
            self?.stop()
            return nil
        }
    }

    /// Stop recording and remove the key monitor. Safe to call when not recording.
    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    /// The layout shortcut for a key press, modifiers in menu order (⌃⌥⇧⌘).
    ///
    /// :param keyCode: The virtual key code reported by the key event.
    /// :param flags: The modifier flags held with the key.
    /// :returns: The layout key name and its modifiers, or ``nil`` for a key a layout cannot send.
    static func shortcut(keyCode: CGKeyCode, flags: NSEvent.ModifierFlags) -> (key: String, modifiers: [KeyModifier])? {
        guard let name = KeyNames.name(forKeyCode: keyCode) else { return nil }
        let order: [(NSEvent.ModifierFlags, KeyModifier)] = [(.control, .control), (.option, .option), (.shift, .shift), (.command, .command)]
        return (name, order.filter { flags.contains($0.0) }.map(\.1))
    }
}
