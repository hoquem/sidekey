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

Sidekey has two parts: a menu bar app for your Mac and an app for your iPad. The Mac app is available now; the iPad app is not yet publicly available (see step 2). Once both are installed, pair them once.

If you installed Mac version 1.0.0, replace it with the latest version: 1.0.0 had a security problem and was withdrawn (see the [1.0.0 release notes](https://github.com/hoquem/sidekey/releases/tag/v1.0.0)).

### 1. Mac app (DMG download)

Requires macOS 13 or later.

1. Download **Sidekey.dmg** from the [latest release](https://github.com/hoquem/sidekey/releases/latest).
2. Open the downloaded `Sidekey.dmg`. In the window that appears, drag **Sidekey** onto the **Applications** folder.
3. Eject the Sidekey disk in Finder, and delete `Sidekey.dmg` if you like.
4. Open **Sidekey** from your Applications folder. The first time, macOS says it was downloaded from the internet; click **Open**. The app is signed with Developer ID and notarized by Apple. Sidekey has no Dock icon: it appears in the menu bar as a keyboard icon with three dots. On a crowded menu bar it may be hidden behind other icons.
5. When macOS asks, open System Settings › Privacy & Security › **Accessibility** and switch **Sidekey** on. Sidekey needs this to send shortcuts and read window titles. If Sidekey is not in the list, click **+**, choose Sidekey from Applications and switch it on.
6. On macOS 15 or later, allow Sidekey to find devices on your local network if asked. Keys that run AppleScript, such as Play/Pause, may also ask for Automation access the first time.

**Updating:** Sidekey does not update itself; watch the [releases page](https://github.com/hoquem/sidekey/releases) for new versions. Quit Sidekey from its menu bar icon, download the new `Sidekey.dmg` and drag Sidekey to Applications again, replacing the old copy. If keys stop working after an update, switch Sidekey off and on again in the Accessibility list; if that does not help, remove it with the minus button, add it back with the plus button and switch it on.

**Uninstalling:** first choose **Forget Paired iPads** in the Sidekey menu, so a later reinstall does not still trust your old iPads. Then quit Sidekey, delete it from Applications, and remove it from System Settings › Privacy & Security › Accessibility (and Automation and Local Network, if listed).

### 2. iPad app (coming to the App Store)

Requires iPadOS 16 or later.

Sidekey for iPad is not on the App Store yet; this section will link to it when it is available. Once it is, open the **App Store** on your iPad, search for **Sidekey**, and tap **Get**.

Until then, the iPad app is in a private TestFlight beta, or you can build it yourself from source (see [Build from source](#build-from-source)). Building needs Xcode and your own Apple developer team and bundle IDs; with a free personal team, Apple lets the build run for 7 days before you must reinstall it.

However you install it, open **Sidekey** on the iPad and tap **Allow** when it asks to find devices on your local network.

### 3. Connect and pair

1. Plug the iPad into the Mac with a USB cable, or put both on the same Wi-Fi network.
2. Open Sidekey on the iPad. When it finds the Mac, it asks for a pairing code.
3. On the Mac, click the Sidekey menu bar icon and choose **Pair iPad...**. A window shows a 6-digit code for two minutes.
4. On the iPad, type the code and tap **Pair**. After five wrong codes, or two minutes, choose Pair iPad again for a new code.

From then on the iPad connects to that Mac by itself whenever Sidekey is running on both. Switch apps on the Mac and the keys on the iPad change to match.

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
| Safari | New Tab, Reopen, Reader, Tab Overview, Reading List, Private |
| Chrome | New Tab, Reopen Tab, Dev Tools, Search Tabs, Downloads, Incognito |
| Arc | New Tab, Close Tab, Reopen Tab, Dev Tools, Reload |
| Cursor | New Agent, Accept All, Reject All, Model, Mode, Add to Chat |
| Antigravity | Agent Panel, Command Palette, Go to File, Find in Files, Terminal |
| OpenCode | New Session, Stop, Previous and Next Session, Terminal |
| Finder | New Folder, Get Info, Quick Look, Move to Trash, Downloads, AirDrop |
| Mail | New Message, Reply, Reply All, Archive, Mark Read, Get Mail |
| Messages | New Message, Reply, Tapback, Edit Last, Previous and Next Chat |
| Notes | New Note, Checklist, Heading, Bullets, Table, Attach |
| Calendar | New Event, Today, Day, Week, Month, Year |
| Music | Play/Pause, Previous, Next, Volume Up and Down, Lyrics, MiniPlayer |
| Photos | Import, Rotate Left and Right, Enhance, Favorite, Hide, Delete |
| WhatsApp | New Chat, Search, Archive, Mute Chat, End Call |
| Telegram | Search, Saved Msgs, Pinned 1 to 4, Prev and Next Folder |
| Zoom | Mute, Video, Share Screen, Raise Hand, Record |
| MacDown | Bold, Italic, Code, Link, Numbered, Bullets, Copy HTML |
| Word | Bold, Italic, Underline, Comment, Track Changes, Focus |
| Excel | AutoSum, Fill Down, Format Cells, Filter, Create Table, Show Formulas |
| PowerPoint | New Slide, Play Start, Presenter, Slide Sorter, Comment, Group |
| Outlook | New Message, Reply, Archive, Mark Read, Flag, Mail, Calendar |
| Teams | New Chat, Search, Mute, Video, Raise Hand, End Call |
| Slack | Jump To, All Unreads, Threads, Activity, Next Unread, Huddle |
| Spotify | Play/Pause, Like, Shuffle, Repeat, Search, Queue |
| Notion | New Page, Search, Back, Forward, Copy Link, Comment |
| ChatGPT | Chat Bar, Find, Stop, Share Desktop, Share Window, Browser |

Shortcuts are taken from each app's own menus or published documentation. The Outlook, Slack, Spotify, Notion and ChatGPT layouts, most of the Excel and Teams keys, and Cursor's AI keys come from each vendor's published shortcuts. Not every key has been tried in its app yet. Notion and ChatGPT publish only a few shortcuts, so their decks are partly empty. Layouts are code in `Packages/iKeypadShared/Sources/iKeypadShared/` (`DefaultProfiles.swift` and `PopularAppProfiles.swift`); add an app by adding a profile there.

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
