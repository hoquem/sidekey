# Spec: Citrix Viewer layout

Status: built on branch citrix-layout-and-pairing, 2026-10-08; ships in Mac 1.3.0 and iPad build 5.

> **Superseded in part.** The Goal, the single 15-key table, its notes, and the Tests and Out of scope sections describe the first design. Live testing replaced it with modes: see **Modes** below, which wins wherever the two differ. The code is `makeCitrixViewerProfiles()`. Task View became Ctrl+Alt+Del, and Teams now has its own mode.

## Goal

When Citrix Viewer (`com.citrix.receiver.icaviewer.mac`) is in front on the Mac, the iPad shows
15 keys for working inside the remote Windows desktop: Windows navigation plus Office (mainly
Outlook) keys. Tapping a key sends the matching Windows shortcut into the session.

## Constraints found during design

- **No Mac shortcuts of its own.** Citrix Viewer has almost none (Enter Full Screen and the
  toolbar on ⇧⌘T); it forwards nearly every keystroke to Windows.
- **One layout per session.** Sidekey sees only "Citrix Viewer" in front, never the Windows app
  inside the session. The window title is the remote desktop's name. One
  layout therefore covers every app in the session.
- **The user's Citrix keyboard settings** (Citrix Viewer › Settings › Keyboard, screenshot
  2026-10-08) decide how Mac keys become Windows keys:
  - Send Control character using: "⌘ Command (left) or ^ Control"
  - Send Alt character using: "⌘⌥ Command (left)-Option"
  - Send Windows logo key using ⌘ Command (right): on
  - Send F1 - F12 keys with ⌥ Option: on
  - System shortcuts take effect on: Local device
- **Verified 2026-10-08 in the user's session:** a synthetic right ⌘ (key code 0x36, flags
  `maskCommand | 0x10`, posted at `.cghidEventTap`) opened the Start menu, and right ⌘ + D toggled
  the desktop. The throwaway script was `winkey-spike.swift`, in the session scratchpad.

## Design

### A Windows hotkey action (shared package)

- New `WindowsModifier: String, Codable` with cases `ctrl`, `alt`, `shift`, `win`.
- New `KeyAction.windowsHotkey(key: String, modifiers: [WindowsModifier])`. `key` uses the same
  key names as `hotkey` (letters, digits, `return`, `tab`, `escape`, `left`, `right`, `f1`..`f12`,
  and so on). The special key `"win"` means the Windows key pressed on its own.
- `shortcutHint` for `windowsHotkey` uses Windows notation, joined with "+":
  - Modifiers in the order Ctrl, Alt, Shift, Win, then the key.
  - Letters are upper case; `return` is "Enter", `escape` is "Esc", `tab` is "Tab", `left` and
    `right` are "←" and "→", F-keys are "F4".
  - Examples: `Ctrl+Shift+M`, `Win+E`, `Alt+F4`, and `Win` for the Win key alone.
- **Compatibility:** iPad builds 1.0.0 (3) and (4) cannot decode the new case. They drop the Citrix
  layout and keep showing the previous one, and taps on it are refused as "Layout changed". Only
  the developer's own iPad runs those builds, so this is accepted. iPad build 5 is required.

### The layout (first design; now `makeCitrixViewerProfiles()`)

The id and bundle are `com.citrix.receiver.icaviewer.mac`, the app name is "Citrix Viewer", and the
grid is 3 by 5. The sources are Microsoft's "Keyboard shortcuts in Windows" and "Keyboard
shortcuts for Outlook"; Ctrl+S and Ctrl+Z are the standard Office shortcuts.

| # | Label | Shortcut | Role | Hold |
|---|---|---|---|---|
| 0 | Start | Win | navigate | |
| 1 | Ctrl+Alt+Del | Ctrl+Alt+Del | navigate | |
| 2 | File Explorer | Win+E | navigate | |
| 3 | Show Desktop | Win+D | navigate | |
| 4 | Lock | Win+L | danger | yes |
| 5 | Switch App | Alt+Tab | navigate | |
| 6 | Snap Left | Win+← | modify | |
| 7 | Snap Right | Win+→ | modify | |
| 8 | Close App | Alt+F4 | danger | yes |
| 9 | Save | Ctrl+S | run | |
| 10 | New | Ctrl+N | create | |
| 11 | New Email | Ctrl+Shift+M | create | |
| 12 | Reply | Ctrl+R | create | |
| 13 | Send | Ctrl+Enter | run | |
| 14 | Undo | Ctrl+Z | modify | |

- **New Email:** Microsoft lists Ctrl+Shift+M for classic Outlook and Ctrl+N for new Outlook.
  Ctrl+Shift+M worked in the user's session (classic Outlook). The modes design has no Ctrl+N
  key, so new Outlook would need one.
- **Teams Mute** (also Ctrl+Shift+M) is deliberately left out because it clashes with New Email.
- **Task View** (Win+Tab) was in the first design. In the live test on 2026-10-08, macOS took right ⌘+Tab as its own app switcher, so Ctrl+Alt+Del (sent as ⌃ + left ⌘ + ⌥ + Forward Delete, verified live) replaced it.
- **Icons:** SF Symbols checked by the existing Mac icon test.

#### Modes (added 2026-10-08, after the live test)

The single 15-key layout grew into modes, because the Windows app in front cannot be detected from the Mac:

- **Mode row:** every mode's bottom row is the same: Windows, Outlook, Browser, VS Code and More (the user's most used apps).
- **More:** a picker whose keys open the Word, Excel and Teams modes.
- **Keys per mode:** each mode has ten keys above the row. They are listed in `makeCitrixViewerProfiles()` (`PopularAppProfiles.swift`), which also cites each source.
- **Mac behaviour:**
  - The Mac implements the switch-layout action (`AppContextMonitor.switchMode(to:)`) and remembers each app's mode.
  - It sends a "<Mode> mode" chip that lights the mode key. A mode picked under More lights the More key.
- **Rejected:** a scrolling mode row, because it breaks fixed key positions.
- **Replaced:** the original table above is the first design. Task View there was replaced by Ctrl+Alt+Del.

## Mapping to Citrix (Mac)

`CitrixKeyMapper` is a pure function from `(key, [WindowsModifier])` to the Mac key code plus the
modifier set to post:

| Windows | Mac |
|---|---|
| Ctrl | ⌃ Control (left) |
| Alt | ⌘ Command (left) + ⌥ Option |
| Shift | ⇧ Shift |
| Win | ⌘ Command (right): key code 0x36, flag bit 0x10 |
| F1 to F12 | the F-key with ⌥ Option added |
| Win alone | right ⌘ down, then up |

It throws for an unknown key name, so the existing unknown-key path reports the failure on the
iPad. `ActionDispatcher` posts the result:
- **Win combinations:** right ⌘ down, the key down and up with the combined flags, then right ⌘ up.
- **Other combinations:** posted the way `hotkey` posts its modifiers today.

### Error handling

This needs nothing new:
- Leaving Citrix between seeing and tapping a key is refused by the existing "Layout changed"
  check.
- Lock and Close App need the existing press and hold.
- A failure to send shows on the key and in a toast, as it does today.

## Tests (written first)

- **Shared:**
  - `windowsHotkey` round-trips through `FramedMessageProtocol`.
  - The hint for every row of the table above matches the Shortcut column.
  - The Citrix profile is registered, has 15 keys, and holds exactly Lock and Close App.
- **Mac:**
  - Mapper table cases: Ctrl+S, Ctrl+Shift+M, Ctrl+Enter, Alt+Tab, Alt+F4 (⌘⌥ plus F4 with ⌥),
    Win alone, Win+L and Win+←.
  - An unknown key throws.
  - The existing "every built-in hotkey maps to a key code" test is extended to `windowsHotkey`.
- **Live:** with the user's permission and while they watch, each of the 15 keys is pressed in the
  Citrix session. Lock, Close App and Send are only tried somewhere safe the user picks.

## Shipping

- **iPad 1.0.0 (5):** includes the reconnect fix (`904f7e9`) and this action. It goes to TestFlight
  and replaces build 4 for the App Store submission.
- **Mac 1.3.0:** includes the Citrix layout and the pairing message fix (`901ec54`). It is
  notarized DMG on GitHub Releases.
- **Docs:**
  - The README layouts table.
  - A support page note on the Citrix keyboard settings the layout needs.
  - The App Store app list and the release notes.
  - Each gets the fresh-subagent review. The user confirms before anything is uploaded or published.

## Out of scope

- Detecting the Windows app inside the session.
- Supporting other Citrix keyboard settings.
- Teams-specific keys.
