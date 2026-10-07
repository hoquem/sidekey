# iKeypad — Dynamic iPad Shortcut Deck & Adaptive Keypad

**iKeypad** transforms your iPad into an ultra-low-latency, context-aware macro deck (similar to an Elgato Stream Deck or Touch Bar) connected via **USB** or **Wi-Fi**.

Whenever you switch apps on your Mac (e.g. VS Code, Figma, Safari, Terminal, Zoom), the iPad screen instantly morphs to show shortcut keys, tools, and actions tailored specifically to that application.

---

## Architecture

- **`Packages/iKeypadShared`**: Swift package containing data models (`DeckProfile`, `DeckKey`, `KeyAction`, `DeckMessage`), JSON framed protocol, and default built-in profiles.
- **`iKeypadMac`**: Lightweight macOS menu bar app.
  - Monitors frontmost app activations via `NSWorkspace.didActivateApplicationNotification`.
  - Runs an `NWListener` TCP server over port 49200 advertising `_ikeypad._tcp` via Bonjour.
  - Executes actions using `CGEvent` (simulated keystrokes), `NSAppleScript`, and shell/Shortcuts commands.
- **`iKeypad`**: iPadOS SwiftUI client.
  - Auto-discovers the Mac over USB link-local or Wi-Fi using `NWBrowser`.
  - Renders a responsive, tactile grid with press animations and haptic feedback (`UIImpactFeedbackGenerator`).

---

## Getting Started

### 1. Build the Shared Package
```bash
cd Packages/iKeypadShared
swift build
```

### 2. Run / Test the macOS Companion
Open the macOS project in Xcode, or configure your macOS menu bar target.
Make sure macOS Accessibility permissions are granted if simulating keyboard events:
- **System Settings > Privacy & Security > Accessibility** -> Enable `iKeypadMac`.

### 3. Connect Your iPad
1. Connect your iPad to your Mac via USB-C or Lightning cable (or make sure both are on the same Wi-Fi).
2. Launch `iKeypad` on the iPad.
3. The iPad will automatically handshake with your Mac host.
4. Switch apps on macOS (e.g. VS Code, Safari) and watch the iPad keypad update in real time!
