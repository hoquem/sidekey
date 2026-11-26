# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

A developer and power user working at a Mac, with an iPad or iPhone propped beside the keyboard as a touch control surface. They move between developer tools (Xcode, Terminal, VS Code, Safari), communication apps (WhatsApp, Telegram, Zoom) and writing tools (MacDown, Word) all day, and want the right shortcuts under their finger without remembering them. The device is glanced at mid-task, often from 50 to 70 cm away, and tapped without looking for long.

## Product Purpose

Sidekey turns an iPad or iPhone into a context-aware macro deck for a Mac. A Mac companion service watches the frontmost app and pushes that app's key layout to the device; tapping a key makes the Mac fire a hotkey, AppleScript, shell command or Shortcut. Success means the user trusts every tap: they can see which app the deck is driving, that the key fired, and why it didn't when it fails.

## Positioning

The deck follows the Mac's focus automatically, connects over Wi-Fi, or over USB first on an iPad (Wi-Fi fallback), and its built-in layouts are code in the open-source repository. From Mac 1.4.0 users can also change them, or add layouts for other apps, with an editor in the Mac app (files in `~/Library/Application Support/Sidekey/Layouts/`). Alternatives in the same space: Elgato Stream Deck Mobile (Smart Profiles), DevDeck, Deck Buddy, DeckPilot.

## Operating Context

- Two processes: the Sidekey Mac app (menu bar companion, target `SidekeyMac`, Bonjour `_sidekey._tcp` on TCP 49200) and the iPad and iPhone client. Messages are length-prefixed JSON (`Packages/iKeypadShared`).
- The Mac needs Accessibility permission to post keystrokes; window titles and app state also come from the Accessibility API.
- Profiles are 3 rows by 5 columns. Built-in profiles: System (fallback), VS Code, Cursor, Antigravity, OpenCode, Terminal, Xcode, Safari, Chrome, Arc, Finder, Mail, Messages, Notes, Calendar, Music, Photos, WhatsApp, Telegram, Zoom, Slack, Teams, Spotify, Notion, ChatGPT, MacDown, Word, Excel, PowerPoint, Outlook, Citrix Viewer (Windows shortcuts sent into a Citrix session through `CitrixKeyMapper`, which assumes specific Citrix keyboard settings; modes Windows, Outlook, Browser, VS Code and, under More, Word, Excel and Teams, switched from a fixed bottom row because the Windows app in front cannot be detected. The user rejected a scrolling mode row on 2026-10-08 in favour of fixed positions). Shortcuts are taken from each app's menu bar or published documentation; Zoom's in-meeting keys and state chips come from Zoom's documentation and are not yet tested in a live meeting. Teams has two modes, Chat (the start layout, id `com.microsoft.teams2`) and Meeting (`com.microsoft.teams2.meeting`, added 2026-11-26 for video calls and webinars), switched from slots 13 and 14; its Meeting keys come from Microsoft's published Mac shortcut list and are not yet tested in a live meeting (Captions shares Command+Shift+A with Accept Audio Call on that list).
- Brand name: Sidekey (chosen 2026-10-07). The iPad and iPhone universal app is live on the App Store (free); the Mac companion ships as a Developer ID signed, notarized DMG on GitHub Releases, because it posts keystrokes to other apps and runs AppleScript and shell actions, which the Mac App Store sandbox does not allow. Mac 1.0.0 was withdrawn on 2026-10-07 for running client-sent actions without pairing; 1.1.0 adds pairing and runs only built-in actions; 1.2.0 adds layouts for the most used Mac apps and AI coding tools; 1.3.0 (live since 2026-10-08) adds the Citrix Viewer layout and renames pairing to Pair Device; 1.4.0 adds the custom layout editor; 1.5.0 adds the Teams Meeting mode and the pairing window's "iPad or iPhone" wording. Source is public on GitHub under MIT.

## Capabilities and Constraints

- iOS/iPadOS 16 deployment target; SwiftUI; universal iPad and iPhone support.
- The Mac reports every action's success or failure (`actionExecuted`).
- Undecided: user-editable layouts on the iPad or iPhone, paging beyond 15 keys, dials (a dial component exists but is unused).

## Brand Commitments

- Name: Sidekey (internal module names still use the working name iKeypad).
- The user chose a dark "hardware deck" visual direction and the "Lit key" app icon concept (dark keycaps, one glowing key).

## Evidence on Hand

No screenshots, testimonials, users or metrics beyond the author's own use. Do not invent any.

## Product Principles

1. Every tap gets an honest answer: pending, done, or failed with the Mac's reason.
2. The deck always says which Mac app it is driving and over which link.
3. Keys stay where muscle memory expects them within an orientation; layouts never reflow under the finger. Portrait (3 columns by 5 rows) and landscape (5 columns by 3 rows) each have their own fixed positions, chosen by the user (2026-10-07) so portrait fills the screen.
4. Fail loudly: a missing permission or a lost connection is shown, never hidden behind live-looking keys.
5. The Mac does the work; the iPad or iPhone stays a thin, fast surface.
6. Nothing controls the Mac without pairing, an unpaired device learns only the Mac's name, and the Mac runs only its own actions.

## Accessibility & Inclusion

WCAG AA contrast for key labels, Dynamic Type, VoiceOver labels that say what a key does on the Mac, Reduce Motion respected.
