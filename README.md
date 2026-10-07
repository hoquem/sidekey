# Sidekey

Sidekey turns an iPad into a shortcut deck for your Mac. Prop the iPad beside your keyboard: whenever you switch apps on the Mac, the iPad shows keys for that app, and tapping a key runs the shortcut on the Mac.

- **Follows your Mac.** The keys change with the frontmost app: Xcode shows Run, Build and Test; Zoom shows Mute, Video and Share Screen; Terminal shows tabs, Clear and Interrupt.
- **Shows what it is driving.** The top of the screen shows the Mac app's icon, name and window title, and whether the link is USB or Wi-Fi. For Zoom it also shows meeting state such as the mic (built from Zoom's documented menus and not yet tested in a live meeting).
- **Every tap gets an answer.** A key glows amber while the Mac works, lights up when the Mac reports the shortcut was sent, and shakes with the Mac's reason when it could not (for example, a missing permission).
- **USB first.** Connects over the iPad's USB cable when it is plugged in and falls back to Wi-Fi.
- **Paired, not open.** Only an iPad you pair with your Mac, using a code shown on the Mac, can see or control it. The Mac only ever runs actions from its own built-in layouts.
- **Hold for disruptive keys.** Lock Mac, Interrupt, End Call, Telegram Lock and Xcode Clean fire only after a press and hold.

## Requirements

- iPad with iPadOS 16 or later
- Mac with macOS 13 or later
- A USB cable between them, or both on the same Wi-Fi network

## Install

The Mac app is a signed, notarized download. The iPad app is in a private TestFlight beta and will come to the App Store later; until then, build it from source (below).

If you installed Mac version 1.0.0, replace it: it had a security problem and was withdrawn (see the [1.0.0 release notes](https://github.com/hoquem/sidekey/releases/tag/v1.0.0)).

1. **Mac:** download `Sidekey.dmg` from the [latest release](https://github.com/hoquem/sidekey/releases/latest), open it and drag Sidekey to Applications. Open it from Applications; it then lives in the menu bar.
2. **Allow Accessibility:** macOS asks the first time. Switch Sidekey on in System Settings › Privacy & Security › Accessibility. Sidekey needs this to send shortcuts and read window titles.
3. **iPad:** open Sidekey and allow it to find devices on your local network.
4. **Connect:** plug the iPad into the Mac with a USB cable, or put both on the same Wi-Fi network.
5. **Pair once:** on the Mac, choose **Pair iPad...** in the Sidekey menu. Type the 6-digit code it shows into the iPad and tap Pair. From then on the iPad connects to that Mac by itself.

## Security

- **Pairing:** a Mac accepts an iPad only after it has been paired with a short-lived code shown on the Mac. Until then the iPad receives only the Mac's name and identifier and a pairing request, and its taps are refused. Each side stores a pairing token in its Keychain; later connections prove the token without sending it.
- **Only built-in actions:** a tap names a key; the Mac runs that key's action from its own built-in layout, never an action sent over the network.
- **Not encrypted yet:** Traffic between the iPad and the Mac is not encrypted yet. Someone who can watch or tamper with your network could read what Sidekey sends (app names, window titles, the keys you tap and both device names). If they capture the one-time pairing exchange or interfere with a live connection, they could also press your Mac's built-in keys, for example to open Terminal or lock the Mac, until you choose Forget Paired iPads on the Mac. Use Sidekey over USB or on a network you trust. Encryption is planned.
- **The iPad does not verify the Mac yet:** a paired iPad looks for its Mac by an identifier the Mac advertises on the network, which another device could copy.
- **Forgetting:** Forget Paired iPads in the Mac's Sidekey menu revokes every paired iPad. Forget This Mac on the iPad (press and hold the connection label while connected) only removes the iPad's copy; to revoke access, use the Mac.

## Built-in layouts

| App | Example keys |
|---|---|
| System (any other app) | Play/Pause, Screenshot, Spotlight, Lock Mac |
| Xcode | Run, Build, Test, Stop, Clean, Open Quickly |
| VS Code | Cmd Palette, Quick Open, Toggle Term, Source Control, Run Tests |
| Terminal | New Tab, Close Tab, Clear, Interrupt, Split Pane |
| Safari, Chrome, Arc | New Tab, Close Tab, Reopen Tab, Dev Tools, Reload |
| WhatsApp | New Chat, Search, Archive, Mute Chat, End Call |
| Telegram | Search, Saved Msgs, Pinned 1 to 4, Prev and Next Folder |
| Zoom | Mute, Video, Share Screen, Raise Hand, Record |
| MacDown | Bold, Italic, Code, Link, Numbered, Bullets, Copy HTML |
| Word | Bold, Italic, Underline, Comment, Track Changes, Focus |

Shortcuts are taken from each app's own menus or published documentation. Layouts are code in `Packages/iKeypadShared/Sources/iKeypadShared/DefaultProfiles.swift`; add an app by adding a profile there.

## Build from source

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open iKeypadApp.xcodeproj
```

To build only the iPad app, use the `iKeypad` scheme. Before building, change these in `project.yml` to your own values, then run `xcodegen generate` again:

- `DEVELOPMENT_TEAM` (three places): your Apple team ID.
- The bundle IDs `com.hoque.sidekey`, `com.hoque.sidekey.tests` and `com.hoque.sidekey.mac`: they are registered to the author's team, so automatic signing fails for anyone else.

Schemes:

- `iKeypad`: the iPad app (shown as Sidekey on the Home Screen)
- `SidekeyMac`: the Mac menu bar app (builds `Sidekey.app`)

Internal module and folder names still use the project's working name, iKeypad.

## Tests

```bash
(cd Packages/iKeypadShared && swift test)   # protocol and layouts
(cd iKeypadMac && swift test)               # Mac companion, over a real TCP connection
xcodebuild test -project iKeypadApp.xcodeproj -scheme iKeypad \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)'   # iPad client
```

Use the name of any iPad simulator installed with your Xcode (`xcrun simctl list devices`).

## How it works

- `iKeypadMac`: the Mac app. Watches the frontmost app, advertises `_sidekey._tcp` over Bonjour on port 49200, and serves only paired iPads: it sends them the matching layout and app state, and runs the built-in action of each key they tap (keyboard shortcuts via `CGEvent`, AppleScript, shell commands, Shortcuts).
- `iKeypad`: the iPad app. Finds its paired Mac with Bonjour (any Sidekey Mac until it has paired), prefers the USB link, and renders the deck.
- `Packages/iKeypadShared`: the length-prefixed JSON protocol, models and built-in layouts.

## License

MIT. See [LICENSE](LICENSE).
