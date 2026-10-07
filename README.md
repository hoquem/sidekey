# Sidekey

Sidekey turns an iPad into a shortcut deck for your Mac. Prop the iPad beside your keyboard: whenever you switch apps on the Mac, the iPad shows keys for that app, and tapping a key runs the shortcut on the Mac.

- **Follows your Mac.** The keys change with the frontmost app: Xcode shows Run, Build and Test; Zoom shows Mute, Video and Share; Terminal shows tabs, Clear and Interrupt.
- **Shows what it is driving.** The top of the screen shows the Mac app's icon, name and window title, live state such as Zoom's mic, and whether the link is USB or Wi-Fi.
- **Every tap gets an answer.** A key glows amber while the Mac works, lights up when the shortcut fired, and shakes with the Mac's reason when it could not (for example, a missing permission).
- **USB first.** Connects over the iPad's USB cable for low latency and falls back to Wi-Fi.
- **Safe by design.** Disruptive keys (Lock Mac, Interrupt, End Call) fire only after a press and hold.

## Requirements

- iPad with iPadOS 16 or later
- Mac with macOS 13 or later
- A USB cable between them, or both on the same Wi-Fi network

## Install

1. **Mac:** download `Sidekey.dmg` from [Releases](https://github.com/hoquem/sidekey/releases), open it and drag Sidekey to Applications. Open it; it lives in the menu bar.
2. **Allow Accessibility:** macOS asks the first time. Switch Sidekey on in System Settings › Privacy & Security › Accessibility. Sidekey needs this to send shortcuts and read window titles.
3. **iPad:** install Sidekey on the iPad (TestFlight while in beta), open it and allow it to find devices on your local network.
4. Connect the iPad to the Mac with a USB cable, or join the same Wi-Fi network. Sidekey finds the Mac by itself.

## Built-in layouts

| App | Example keys |
|---|---|
| System (any other app) | Play/Pause, Screenshot, Spotlight, Lock Mac |
| Xcode | Run, Build, Test, Stop, Clean, Open Quickly |
| VS Code | Command Palette, Quick Open, Toggle Terminal, Run Tests |
| Terminal | New Tab, Close Tab, Clear, Interrupt, Split Pane |
| Safari, Chrome, Arc | New Tab, Close Tab, Reopen Tab, Dev Tools, Reload |
| WhatsApp | New Chat, Search, Archive, Mute Chat, End Call |
| Telegram | Search, Saved Messages, Pinned Chats, Folders |
| Zoom | Mute, Video, Share Screen, Raise Hand, Record |
| MacDown | Bold, Italic, Code, Link, Lists, Copy HTML |

Shortcuts come from each app's own menus or published documentation. Layouts are code in `Packages/iKeypadShared/Sources/iKeypadShared/DefaultProfiles.swift`; add an app by adding a profile there.

## Build from source

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open iKeypadApp.xcodeproj
```

Set `DEVELOPMENT_TEAM` in `project.yml` to your own Apple team ID before building. Schemes:

- `iKeypad`: the iPad app (product name Sidekey)
- `SidekeyMac`: the Mac menu bar app

Internal module and folder names still use the project's working name, iKeypad.

## Tests

```bash
(cd Packages/iKeypadShared && swift test)   # protocol and layouts
(cd iKeypadMac && swift test)               # Mac companion, over a real TCP connection
xcodebuild test -project iKeypadApp.xcodeproj -scheme iKeypad \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)'   # iPad client
```

## How it works

- `iKeypadMac`: the Mac app. Watches the frontmost app, advertises `_sidekey._tcp` over Bonjour on port 49200, sends the matching layout and app state to the iPad, and runs tapped actions (keyboard shortcuts via `CGEvent`, AppleScript, shell commands, Shortcuts).
- `iKeypad`: the iPad app. Finds the Mac with Bonjour, prefers the USB link, and renders the deck.
- `Packages/iKeypadShared`: the length-prefixed JSON protocol, models and built-in layouts.

## License

MIT. See [LICENSE](LICENSE).
