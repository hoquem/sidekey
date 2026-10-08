import Foundation
import Cocoa
import CoreGraphics
import iKeypadShared

public final class ActionDispatcher {
    public static let shared = ActionDispatcher()

    private init() {}

    public func execute(action: KeyAction) -> (success: Bool, error: String?) {
        switch action {
        case .hotkey(let key, let modifiers):
            return triggerHotkey(key: key, modifiers: modifiers)

        case .windowsHotkey(let key, let modifiers):
            do {
                return triggerChord(try CitrixKeyMapper.chord(key: key, modifiers: modifiers))
            } catch {
                return (false, "Unrecognized key character: \(key)")
            }

        case .appleScript(let script):
            return executeAppleScript(script)

        case .shellScript(let command):
            return executeShellScript(command)

        case .runShortcut(let name):
            return executeShellScript("/usr/bin/shortcuts run \"\(name)\"")

        case .switchProfile, .none:
            return (true, nil)
        }
    }

    private func triggerHotkey(key: String, modifiers: [KeyModifier]) -> (Bool, String?) {
        guard let keyCode = keyCodeForString(key) else {
            return (false, "Unrecognized key character: \(key)")
        }
        // Without Accessibility trust macOS drops posted events without reporting an error,
        // so check up front rather than report a success that never happened.
        guard AXIsProcessTrusted() else {
            return (false, "Allow Sidekey in System Settings › Privacy & Security › Accessibility on your Mac.")
        }

        var flags: CGEventFlags = []
        for mod in modifiers {
            switch mod {
            case .command: flags.insert(.maskCommand)
            case .shift: flags.insert(.maskShift)
            case .option: flags.insert(.maskAlternate)
            case .control: flags.insert(.maskControl)
            }
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return (false, "Failed to create CGEvent keyboard events")
        }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.post(tap: .cghidEventTap)
        // Brief pause between key down and key up
        usleep(20_000)
        keyUp.post(tap: .cghidEventTap)

        return (true, nil)
    }

    /// Post a chord as a keyboard would: each modifier key down, the key, then modifiers up.
    ///
    /// Remote-desktop apps such as Citrix Viewer read the modifier keys themselves (including
    /// which side was pressed), so flags on the main key alone are not enough.
    private func triggerChord(_ chord: KeyChord) -> (Bool, String?) {
        guard AXIsProcessTrusted() else {
            return (false, "Allow Sidekey in System Settings › Privacy & Security › Accessibility on your Mac.")
        }
        let source = CGEventSource(stateID: .hidSystemState)
        func post(_ code: CGKeyCode, down: Bool, flags: CGEventFlags) -> Bool {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down) else { return false }
            event.flags = flags
            event.post(tap: .cghidEventTap)
            usleep(20_000)
            return true
        }
        var ok = chord.modifierKeys.allSatisfy { post($0, down: true, flags: chord.flags) }
        if let key = chord.keyCode {
            ok = ok && post(key, down: true, flags: chord.flags) && post(key, down: false, flags: chord.flags)
        }
        // Release in reverse even after a failure, so no modifier is left held down.
        for code in chord.modifierKeys.reversed() { ok = post(code, down: false, flags: []) && ok }
        return ok ? (true, nil) : (false, "Failed to create CGEvent keyboard events")
    }

    private func executeAppleScript(_ scriptText: String) -> (Bool, String?) {
        var errorDict: NSDictionary?
        let script = NSAppleScript(source: scriptText)
        _ = script?.executeAndReturnError(&errorDict)
        if let error = errorDict {
            let msg = error[NSAppleScript.errorMessage] as? String ?? "AppleScript error"
            return (false, msg)
        }
        return (true, nil)
    }

    private func executeShellScript(_ command: String) -> (Bool, String?) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus != 0 {
                let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errMsg = String(data: errData, encoding: .utf8) ?? "Command failed with code \(task.terminationStatus)"
                return (false, errMsg)
            }
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    /// The virtual key code for a layout's key name; internal so tests can check every layout key maps.
    func keyCodeForString(_ key: String) -> CGKeyCode? {
        let lower = key.lowercased()
        switch lower {
        case "a": return 0x00
        case "s": return 0x01
        case "d": return 0x02
        case "f": return 0x03
        case "h": return 0x04
        case "g": return 0x05
        case "z": return 0x06
        case "x": return 0x07
        case "c": return 0x08
        case "v": return 0x09
        case "b": return 0x0B
        case "q": return 0x0C
        case "w": return 0x0D
        case "e": return 0x0E
        case "r": return 0x0F
        case "y": return 0x10
        case "t": return 0x11
        case "1": return 0x12
        case "2": return 0x13
        case "3": return 0x14
        case "4": return 0x15
        case "6": return 0x16
        case "5": return 0x17
        case "=": return 0x18
        case "9": return 0x19
        case "7": return 0x1A
        case "-": return 0x1B
        case "8": return 0x1C
        case "0": return 0x1D
        case "]": return 0x1E
        case "o": return 0x1F
        case "u": return 0x20
        case "[": return 0x21
        case "i": return 0x22
        case "p": return 0x23
        case "l": return 0x25
        case "j": return 0x26
        case "'": return 0x27
        case "k": return 0x28
        case ";": return 0x29
        case "\\": return 0x2A
        case ",": return 0x2B
        case "/": return 0x2C
        case "n": return 0x2D
        case "m": return 0x2E
        case ".": return 0x2F
        case "`": return 0x32
        case "space": return 0x31
        case "return", "enter": return 0x24
        case "tab": return 0x30
        case "escape", "esc": return 0x35
        case "delete", "backspace": return 0x33
        case "left": return 0x7B
        case "right": return 0x7C
        case "down": return 0x7D
        case "up": return 0x7E
        case "f1": return 0x7A
        case "f2": return 0x78
        case "f3": return 0x63
        case "f4": return 0x76
        case "f5": return 0x60
        case "f6": return 0x61
        case "f7": return 0x62
        case "f8": return 0x64
        case "f9": return 0x65
        case "f10": return 0x6D
        case "f11": return 0x67
        case "f12": return 0x6F
        default: return nil
        }
    }
}
