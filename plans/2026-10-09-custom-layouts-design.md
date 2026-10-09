# Spec: custom layouts

Status: design agreed 2026-10-09; not built. Targets Mac 1.4.0. The iPad app does not change.

## Goal

Anyone, not only developers, can change the keys Sidekey shows for an app, and create a layout
for an app Sidekey has no built-in layout for, using a visual editor on the Mac.

**Done means:**
- A user changes a key in a built-in layout (for example, swaps a Zoom key) and the iPad shows it
  straight away, with no restart.
- A user adds a layout for an app with no built-in layout, and the iPad shows it when that app is in front.
- A user can reset one key, or a whole layout, to the built-in version.
- Keys the user never changed still pick up fixes from later Sidekey releases.
- Nothing a user layout contains can make Sidekey run a shell command or an AppleScript.

## Decisions (2026-10-09)

| Question | Decision |
|---|---|
| Who edits layouts | Everyone, through a visual editor on the Mac. Not on the iPad: an iPad editor would send actions from the iPad to the Mac, which breaks product principle 6 (the Mac runs only its own actions). |
| What a user key can do | Keyboard shortcut, Windows shortcut (Citrix), Apple Shortcut, switch layout. No shell, no AppleScript. |
| What can be customised | Both: any key in a built-in layout, and new layouts for other apps. |
| How changes are stored | Per-slot overrides on top of the built-in layout (or an empty one), not a full copy. |
| Paging beyond 15 keys | Out of scope. |
| "Open app" action | Out of scope for 1.4.0: it is a new `KeyAction` case, and iPad builds 5 and 6 cannot decode a case they do not know (the same break `windowsHotkey` caused for builds 3 and 4). |

## Why no shell or AppleScript

Sidekey holds the Accessibility and Apple Events permissions. If a layout file could carry a
shell or AppleScript action, any process able to write the layouts folder could run commands
with those permissions by planting one. Restricting user layouts to shortcut-type actions closes
that, and the check happens when files are loaded, not only in the editor, because files can be
edited by hand or tampered with.

## Components

| Unit | Lives in | Responsibility |
|---|---|---|
| `LayoutCustomisation` | `Packages/iKeypadShared` | The file format (below). `Codable`. |
| `LayoutResolver` | `Packages/iKeypadShared` | Pure function: base layout (built-in, or empty) + customisation gives the `DeckProfile` the Mac registers. No disk, no UI. |
| `UserLayoutStore` | `iKeypadMac` | Reads, validates and writes the files in `~/Library/Application Support/Sidekey/Layouts/`. Reports every rejected file with its reason. |
| `AppContextMonitor` (changed) | `iKeypadMac` | Registers resolved layouts at launch. On every save, replaces the registered layout and, if it is the active one, publishes it to the iPad. |
| Layout editor window | `iKeypadMac` | The visual editor (below), opened from a new "Edit Layouts..." menu item. |

The tap path does not change: the iPad sends only key and layout ids, and `ActionDispatcher`
finds the action in the Mac's own registered layouts.

## File format

One file per layout: `~/Library/Application Support/Sidekey/Layouts/<layout id>.json`.

```json
{
  "version": 1,
  "layoutId": "us.zoom.xos",
  "appBundleIdentifier": "us.zoom.xos",
  "appName": "Zoom",
  "slots": {
    "4": { "key": { "label": "Raise Hand", "iconSystemName": "hand.raised",
                    "role": "run", "requiresConfirm": false,
                    "action": { "hotkey": { "key": "y", "modifiers": ["opt"] } } } },
    "9": "removed"
  }
}
```

- `layoutId` is the built-in layout's `id` when customising one (Citrix modes each have their
  own id, so each mode is customised separately), or the app's bundle id for a new app.
- A slot is either a replacement key or `"removed"`. Slots not listed come from the base layout.
- `action` uses the existing `KeyAction` JSON encoding, so the iPad needs no change.
- Key ids are not stored. `DeckProfile.init` derives them as `<layout id>#<slot>`, so a tap from a
  layout pinned on the iPad still finds its key.

## Validation (on every load)

A file is rejected as a whole, never partly applied, when any of these hold:
- It is not valid JSON, or does not decode as `LayoutCustomisation`.
- `version` is not one this build knows.
- A slot is outside 0 to 14.
- A key's label is empty or longer than 16 characters (the longest built-in label, "Command
  Palette", is 15).
- A key's action is `shellScript`, `appleScript`, or anything other than `hotkey`,
  `windowsHotkey`, `runShortcut` or `switchProfile`.
- A `switchProfile` action names a layout that is not another mode of the same app.

A rejected file leaves the built-in layout in place. The menu shows "1 layout file has
errors..." and the editor lists each file with its reason. Nothing is silently skipped.

## Edge cases

- **Built-in layout removed in a later release:** its customisation is kept, resolved on an
  empty base, and flagged as orphaned in the editor.
- **Two files for the same layout id:** impossible by naming; the file name is the layout id.
  A file whose name does not match its `layoutId` is rejected.
- **Fallback (System) layout:** customisable like any other, by its id.

## Editor window

```
+ Sidekey Layouts ----------------------------------------------+
| Apps           |  Zoom  (customised . Reset Layout)           |
| -------------  |  +----+----+----+----+----+  + Key 7 ------+ |
| * Zoom      o  |  |Mute|Vid |Shr |Chat| x  |  | Label  [   ]| |
|   Xcode        |  +----+----+----+----+----+  | Icon   [   ]| |
|   VS Code      |  |    | o  |    |    |    |  | Colour ooooo| |
|   ...          |  +----+----+----+----+----+  | Action [v  ]| |
| [+ Add App...] |  |    |    |    |    |    |  | [Record   ] | |
|                |  +----+----+----+----+----+  | [ ] Hold    | |
|                |   o = changed from built-in  | [Reset Key] | |
+---------------------------------------------------------------+
```

- **App list:** built-in layouts plus user layouts; a dot marks customised ones; Citrix modes
  nest under Citrix Viewer. **Add App...** picks an installed app and creates an empty layout.
- **Grid:** the resolved layout in landscape order (3 rows by 5 columns) with role colours, and a
  small portrait preview (the iPad keeps reading order in portrait, `iKeypadApp.swift`
  `keyGrid`). Click to select; drag to move or swap.
- **Key inspector:** label; icon from a searchable list of about 150 curated SF Symbols (macOS
  has no public API listing them); colour as one of the five roles; action type; hold-to-fire.
  - Keyboard shortcut: **Record** captures the next key press. macOS keeps some combinations
    (Command-Tab, Command-Space), so a key menu plus modifier checkboxes is the fallback, with a
    warning when the shortcut matches a system one.
  - Windows shortcut: the same manual entry with Ctrl, Alt, Shift, Win.
  - Apple Shortcut: a menu filled from `shortcuts list`.
  - Switch layout: offered only for apps with several modes.
- **Saving:** every change writes the file at once and the iPad updates live. Reset Key and
  Reset Layout confirm first; Reset Layout deletes the file.
- **Window:** Sidekey has no Dock icon, so the window activates the app when it opens, as
  `PairingCodeWindow` does. The menu gains only a static "Edit Layouts..." item: no state that
  changes while the menu is open, which is what crashed 1.1.0.

## Tests

- `LayoutResolver`: replaced slot, removed slot, new app on an empty base, key ids stable.
- `UserLayoutStore`: one test per validation rule above, and a rejected file leaves the
  built-in layout untouched.
- Security: with a tampered file putting a `shellScript` on slot 3, a tap on slot 3 runs the
  built-in action and no shell runs.
- Regression: with no user files, all built-in layouts are unchanged (alongside
  `DeckServerCharacterizationTests`).
- Compatibility: a resolved user layout encodes and decodes with the current shared models, which
  are the ones iPad builds 5 and 6 use.
- By hand: edit a key and watch the iPad update; record a shortcut; Add App; Reset Key and
  Reset Layout; portrait and landscape.

## Delivery

Small green commits, each batch under 400 lines:
1. `LayoutCustomisation` and `LayoutResolver`, with tests.
2. `UserLayoutStore`, validation and live reload in `AppContextMonitor`. Hand-written files work from here.
3. Editor window: app list, grid, key inspector.
4. Shortcut recorder, Apple Shortcuts menu, Add App, Reset.
5. README, site and 1.4.0 release notes, each through the fresh-subagent review in CLAUDE.md.

## Out of scope

Paging beyond 15 keys; an editor on the iPad; shell and AppleScript actions in user layouts;
the "open app" action; importing or sharing layouts; syncing layouts between Macs.
