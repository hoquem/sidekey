# Sidekey

Sidekey turns an iPad into a shortcut deck for your Mac. Prop the iPad beside your keyboard: whenever you switch apps on the Mac, the iPad shows keys for that app, and tapping a key runs the shortcut on the Mac.

- **Follows your Mac.** The keys change with the frontmost app: Xcode shows Run, Build and Test; Zoom shows Mute, Video and Share Screen; Terminal shows tabs, Clear and Interrupt.
- **Shows what it is driving.** The top of the screen shows the Mac app's icon, name and window title, and whether the link is USB or Wi-Fi. For Zoom it also shows meeting state such as the mic (built from Zoom's documented menus and not yet tested in a live meeting).
- **Every tap gets an answer.** A key glows amber while the Mac works, lights up when the Mac reports the shortcut was sent, and shakes with the Mac's reason when it could not (for example, a missing permission).
- **USB first.** Connects over the iPad's USB cable when it is plugged in and falls back to Wi-Fi.
- **Paired, not open.** Only an iPad you pair with your Mac, using a code shown on the Mac, can see or control it. A tap carries which key on which layout (and whether that layout is pinned); the Mac runs the action from its own copy of the layout, either a built-in one or one you made on the Mac.
- **Hold for disruptive keys.** Lock Mac, Interrupt, End Call, Telegram Lock, Xcode Clean, and Citrix Viewer's Lock, Close App and Teams Leave fire only after a press and hold.

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
7. To start Sidekey when you log in, tick **Launch at Login** in the Sidekey menu (Mac 1.4.0 or later). It is off until you turn it on. If macOS needs your approval, System Settings opens at Login Items; if macOS refuses, Sidekey shows why.

**Updating:** Sidekey does not update itself; watch the [releases page](https://github.com/hoquem/sidekey/releases) for new versions. Quit Sidekey from its menu bar icon, download the new `Sidekey.dmg` and drag Sidekey to Applications again, replacing the old copy. If keys stop working after an update, switch Sidekey off and on again in the Accessibility list; if that does not help, remove it with the minus button, add it back with the plus button and switch it on.

**Uninstalling:** first choose **Forget Paired Devices** in the Sidekey menu, so a later reinstall does not still trust your old iPads. Then quit Sidekey, delete it from Applications, and remove it from System Settings › Privacy & Security › Accessibility (and Automation and Local Network, if listed).

### 2. iPad app (coming to the App Store)

Requires iPadOS 16 or later.

Sidekey for iPad is not on the App Store yet; this section will link to it when it is available. Once it is, open the **App Store** on your iPad, search for **Sidekey**, and tap **Get**.

Until then, the iPad app is in a private TestFlight beta, or you can build it yourself from source (see [Build from source](#build-from-source)). Building needs Xcode and your own Apple developer team and bundle IDs; with a free personal team, Apple lets the build run for 7 days before you must reinstall it.

However you install it, open **Sidekey** on the iPad and tap **Allow** when it asks to find devices on your local network.

### 3. Connect and pair

1. Plug the iPad into the Mac with a USB cable, or put both on the same Wi-Fi network.
2. Open Sidekey on the iPad. When it finds the Mac, it asks for a pairing code.
3. On the Mac, click the Sidekey menu bar icon and choose **Pair Device...**. A window shows a 6-digit code for two minutes.
4. On the iPad, type the code and tap **Pair**. After five wrong codes, or two minutes, choose Pair Device again for a new code.

From then on the iPad connects to that Mac by itself whenever Sidekey is running on both. Switch apps on the Mac and the keys on the iPad change to match.

## Security

- **Pairing:** a Mac accepts an iPad only after it has been paired with a short-lived code shown on the Mac. Until then the iPad receives only the Mac's name and identifier and a pairing request, and its taps are refused. Each side stores a pairing token in its Keychain; later connections prove the token without sending it.
- **The Mac runs only its own actions:** a tap carries which key on which layout (and whether it is pinned); the Mac runs that key's action from its own copy of the layout, never an action sent over the network. Layouts you make on the Mac can only send keyboard or Windows shortcuts, run your Apple Shortcuts or switch Citrix modes. They cannot run shell commands or AppleScript themselves (an Apple Shortcut you choose runs its own steps), and every layout file is checked each time it is loaded.
- **Not encrypted yet:** Traffic between the iPad and the Mac is not encrypted yet. Someone who can watch or tamper with your network could read what Sidekey sends (app names, window titles, the keys you tap and both device names). If they capture the one-time pairing exchange or interfere with a live connection, they could also press keys in your Mac's layouts, including ones you made, for example to open Terminal or lock the Mac, until you choose Forget Paired Devices on the Mac. Use Sidekey over USB or on a network you trust. Encryption is planned.
- **The iPad does not verify the Mac yet:** a paired iPad looks for its Mac by an identifier the Mac advertises on the network, which another device could copy.
- **Forgetting:** Forget Paired Devices in the Mac's Sidekey menu revokes every paired iPad. Forget This Mac on the iPad (press and hold the connection label while connected) only removes the iPad's copy; to revoke access, use the Mac.

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
| OpenCode | New Session, Stop, Prev and Next Session, Terminal |
| Finder | New Folder, Get Info, Quick Look, Move to Trash, Downloads, AirDrop |
| Mail | New Message, Reply, Reply All, Archive, Mark Read, Get Mail |
| Messages | New Message, Reply, Tapback, Edit Last, Prev and Next Chat |
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
| Citrix Viewer | Modes for Windows, Outlook, Browser, VS Code and, under More, Word, Excel and Teams; the bottom row switches mode (Windows shortcuts from Microsoft's published lists, sent into the session; needs iPad build 5 or later and the Citrix keyboard settings in [Support](https://hoquem.github.io/sidekey/support.html)) |

Shortcuts are taken from each app's own menus or published documentation. The Outlook, Slack, Spotify, Notion and ChatGPT layouts, most of the Excel and Teams keys, Cursor's Accept All, Reject All, Model, Mode, Mode Menu and Add to Chat keys, Antigravity's Agent Panel key and OpenCode's Stop key come from each vendor's published shortcuts. Not every key has been tried in its app yet. Notion and ChatGPT publish only a few shortcuts, so their decks are partly empty. The built-in layouts are code in `Packages/iKeypadShared/Sources/iKeypadShared/` (`DefaultProfiles.swift` and `PopularAppProfiles.swift`). To add an app without writing code, use **Edit Layouts...** (see [Custom layouts](#custom-layouts)); contributors can also add a profile in those files.

## Custom layouts

Needs Sidekey for Mac 1.4.0 or later and iPad or iPhone app build 5 or later. Choose **Edit Layouts...** in the Sidekey menu to change what the keys do. You can change, move, remove and reset keys (built-in keys that run scripts are the exception, see below) and add a layout for any app. Changes take effect at once and show on the iPad or iPhone when that app is in front. On a pinned layout, a key you changed, moved, removed or reset is refused until you unpin, bring the app to the front and pin again; keys you have not changed since pinning keep working. If you reset or remove a layout you added for an app, unpin it.

- **The editor.** The list on the left holds every built-in layout (each Citrix mode is its own row, such as "Citrix Viewer: Outlook") and any app you add with the **+** button under the list (choosing an app that already has a layout selects it instead). The **−** (minus) button removes an app you added after you confirm, and the iPad then shows the System layout for that app; it is greyed out for built-in apps, where **Reset Layout...** undoes your changes. A dot marks a layout you have changed. Select an app to see its 15 key slots as a 5 columns by 3 rows grid plus a preview of how they sit on the iPad or iPhone in portrait. Drag a key onto another to swap them, or onto an empty slot to move it.
- **Editing a key.** Select a key to set its label (1 to 16 characters), icon, colour and action, and whether it needs a press and hold. The action is a keyboard shortcut (record it, or pick the keys by hand; the editor warns when the shortcut is one macOS uses itself, such as Command-Space), a Windows shortcut, one of your Apple Shortcuts chosen from a list, or, for apps with several modes such as Citrix Viewer, a switch to another mode. **Reset Key...** appears on keys you changed and **Reset Layout...** on layouts you changed; both go back to the built-in version after you confirm. For an app you added, Reset Key empties the slot and Reset Layout removes the layout.
- **What custom keys cannot do.** They cannot run shell commands or AppleScript themselves; an Apple Shortcut you choose runs whatever steps it contains. A few built-in keys do run scripts (for example Play/Pause); those can be replaced or removed but not edited or moved. A key that lights with the app's state, such as Zoom's mute key or a Citrix mode key, stops lighting once you edit or move it.
- **Files.** Each customised layout is saved as `~/Library/Application Support/Sidekey/Layouts/<layoutId>.json`. You can edit these by hand; choose **Reload Layouts** in the menu to pick up the changes. Sidekey checks every file each time it loads. A file with a problem is refused whole and reported: the menu shows "1 layout file has errors..." or "N layout files have errors..." and the editor lists the file with a **Delete File...** button. Until you fix or delete it, that app uses its built-in layout, or the System layout if you added the app.

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

- `iKeypadMac`: the Mac app. Watches the frontmost app, advertises `_sidekey._tcp` over Bonjour on port 49200, and serves only paired iPads: it sends them the matching layout and app state, and runs the action of each key they tap from its own copy of the layout (keyboard shortcuts via `CGEvent`, AppleScript, shell commands, Shortcuts).
- `iKeypad`: the iPad app. Finds its paired Mac with Bonjour (any Sidekey Mac until it has paired), prefers the USB link, and renders the deck.
- `Packages/iKeypadShared`: the length-prefixed JSON protocol, models and built-in layouts.

## License

MIT. See [LICENSE](LICENSE).
