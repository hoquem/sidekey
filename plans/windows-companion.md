# Plan: Sidekey for Windows

Status: approved 2026-10-07; VM software chosen (UTM). Nothing here is built yet.

## Goal

A Windows companion app that does what the Mac app does today: it follows the app in front,
sends that app's layout to the paired iPad, and runs the shortcut when a key is tapped. The
same iPad app drives a Mac or a Windows PC.

**Done for a first release (v0.1) means:**
- A Windows 11 PC and an iPad on the same Wi-Fi find each other, pair with a 6-digit code and
  reconnect by themselves afterwards.
- The iPad shows the app in front on the PC (name, icon, window title) and its layout.
- Six apps have their own Windows layouts, with a system layout for everything else: Chrome,
  Edge, File Explorer, Word, Excel and VS Code.
- Taps send the right shortcut to the right app, with the same success and failure feedback as on the Mac.
- It ships as a signed installer from GitHub Releases.

**Not in v0.1:** USB, the Microsoft Store, matching all 30 Mac layouts, and app state chips
(like Zoom's mic chip).

## What exists today (the contract the Windows app must speak)

The iPad does not care what it talks to, as long as the messages are identical:

- **Discovery:** Bonjour service `_sidekey._tcp`, TXT record `hostId=<stable id>`; the Mac listens on TCP port 49200.
- **Framing:** a 4-byte big-endian length, then a JSON body (`FramedMessageProtocol.swift`).
- **Messages:** `DeckMessage` in `Models.swift`. The JSON shape is whatever Swift's synthesized
  `Codable` produces for an enum with associated values, for example `{"handshake":{"clientName":"..."}}`,
  and `Data` fields are base64. The C# side has to reproduce that shape exactly.
- **Pairing:** a 6-digit code, open for 2 minutes and closed after 5 wrong tries. The
  host returns a random 32-byte token. On every later connection the host sends a nonce and the
  iPad answers with HMAC-SHA256(token, nonce) (`PairingCrypto.swift`, `DeckServer.swift`, `Pairing.swift`).
- **Taps:** a tap carries only key and layout ids. The host runs the action from its own layout,
  never one sent over the network. This security property from 1.1.0 must hold on Windows too.
- **Layouts:** `DeckProfile` with 3x5 `DeckKey`s. Icons are SF Symbol names, which the iPad draws,
  so Windows layouts can use the same names.

## Domain terms (new and changed)

| Term | Meaning |
|---|---|
| Host | The computer the iPad controls: a Mac or a Windows PC. Today's code says "Mac" or "server". |
| Host platform | `mac` or `windows`; decides how the iPad writes shortcuts and names the host. |
| App identifier | Mac: bundle id (`com.google.Chrome`). Windows: lower-case executable name (`chrome.exe`). Goes in the existing `appBundleIdentifier` field, unchanged on the wire. |
| Windows layout | A `DeckProfile` whose shortcuts are Windows shortcuts (Ctrl, Alt, Shift, Win). |

## Changes to the shared protocol and the iPad app

1. **Host platform on the wire.** Add an optional `platform` field to `challenge` and
   `handshakeAck` (missing means `mac`). A new iPad build talking to an old Mac sees no field
   and assumes Mac. An old iPad build talking to a Windows host connects and works, but shows Mac
   symbols. Accept that and require the new iPad build for Windows.
   - *Verify first:* that Swift's synthesized decoding of an enum case ignores the extra key in
     old iPad builds. Add a test that decodes the new JSON with the old model.
2. **Modifier key on the wire.** Add `windows = "win"` to `KeyModifier`. Windows layouts use
   `.control` where Mac layouts use `.command`, so nothing gets remapped silently.
   - *Risk:* an old iPad build cannot decode a layout containing `"win"`. Keep Win-key shortcuts out
     of v0.1 layouts, or gate them on the iPad's version.
3. **Shortcut text.** `KeyAction.shortcutHint` takes the host platform. On Windows it renders
   `Ctrl+Shift+T` (and `Win+D`), not `⌃⇧T`.
4. **Wording.** iPad text that says "Mac" ("Looking for your Mac…", "Sends ⌘T to Safari on your
   Mac.", "Forget This Mac", the pairing instructions) uses the host's name or "PC" when the
   platform is `windows`.
5. **Golden protocol fixtures.** A Swift test writes one JSON file per `DeckMessage` case into
   `protocol-fixtures/`. The C# tests decode and re-encode each file and compare the bytes, so
   the two implementations cannot drift apart unnoticed.

## The Windows app

**Stack:** C# on .NET 8, as a tray app (WinForms `NotifyIcon`; no main window except the pairing
code dialog). Build for `win-x64` and `win-arm64`, since the test VM is ARM.

**Where it lives:** `windows/` in this repo. Its solution has two projects: `Sidekey.Windows` (the
app) and `Sidekey.Windows.Tests` (xUnit).

| Module | Job | Mac counterpart |
|---|---|---|
| `Protocol` | Framing, the `DeckMessage` JSON shape, golden-fixture tests | `FramedMessageProtocol`, `Models` |
| `Pairing` | Code window (2 min, 5 tries), token store, HMAC challenge | `Pairing.swift`, `PairingCrypto` |
| `HostServer` | TCP listener on 49200, per-connection authentication, tap handling, layout-changed check | `DeckServer` |
| `Discovery` | Advertises `_sidekey._tcp` with `hostId` in the TXT record | `NWListener.service` |
| `ForegroundMonitor` | Foreground window, executable name, title, icon, change events | `AppContextMonitor` |
| `KeySender` | Turns a hotkey into `SendInput` key-down/key-up events | `ActionDispatcher` |
| `Layouts` | Windows layouts, looked up by executable name | `DefaultProfiles` |

**Platform details to settle in a spike** (each one goes into the code with its source):
- **Discovery:** Windows 10+ has `DnsServiceRegister` (windns.h) for advertising DNS-SD services.
  Check the minimum Windows build and that the iPad's Bonjour browser sees it. If it doesn't,
  fall back to a small mDNS responder library.
- **Foreground app:** use `SetWinEventHook(EVENT_SYSTEM_FOREGROUND)` →
  `GetWindowThreadProcessId` → `QueryFullProcessImageName`. Edge cases: UWP apps all show up as
  `ApplicationFrameHost.exe`, and elevated (admin) windows.
- **Sending keys:** `SendInput` cannot send keystrokes into admin windows from a non-admin process
  (Windows' integrity levels). Report that as a clear failure ("Can't control an administrator
  window") instead of failing silently.
- **Icon:** the executable's icon converted to PNG (`Icon.ExtractAssociatedIcon`).
- **Token storage:** Windows Credential Manager, or DPAPI-protected files under
  `%LOCALAPPDATA%\Sidekey`.
- **Firewall:** the first time it listens, Windows asks to allow the app on private networks. The
  installer can add the firewall rule instead.

**Actions:** v0.1 supports only `hotkey`. Layouts are code, so a Windows layout can't contain the
Mac-only `appleScript`, `runShortcut` or `shellScript` actions. The system layout uses
media keys (play/pause, volume), Win+Shift+S for screenshots, Win+L to lock and Win+D for the
desktop.

## Windows layouts

The method is the same as for the Mac: take each app's menus and Microsoft's or the vendor's
published Windows shortcuts, write the source above each layout, and check every key by pressing
it in the VM. A test checks that every key name maps to a virtual-key code, and that every icon
appears in the Mac's list of known-good SF Symbols.

## Shipping

- **Signed installer:** without a code-signing certificate, Windows SmartScreen warns on download.
  The options are Azure Trusted Signing (a low monthly cost; individual eligibility to be checked)
  or an OV certificate (yearly).
  - *Decision needed:* which one, and whether to accept unsigned builds for early testers.
- **Packaging:** an MSIX or Inno Setup installer that adds the firewall rule and an optional
  "start at login".
- **Docs:** README, the site and the App Store listing get Windows mentions only once it ships.
  Each one gets the usual independent review.

## Test machine: a Windows VM on this Mac

This Mac is an M2 Pro with 16 GB RAM, so it needs **Windows 11 on ARM** (x64 apps run under
Windows' built-in emulation).

| Option | Cost | Notes |
|---|---|---|
| UTM | Free, open source | Works, but setup is more manual. Graphics are slower. |
| VMware Fusion | Free for personal use | Supports Windows 11 ARM. |
| Parallels Desktop | About £100 a year | Smoothest. Microsoft authorises it for Windows 11 on Apple Silicon. |

- **Windows licence:** Windows 11 runs unactivated for testing (with a watermark and locked
  personalisation). Activating it needs a Windows 11 Pro or Home licence.
- **Networking:** the VM must use **bridged** networking on the Mac's Wi-Fi so the iPad can reach
  it and see its Bonjour advert. NAT, the default, hides it.
- **Blocker: disk space.** The Mac has **21 GB free**. A Windows 11 VM needs about 40 to 64 GB, plus
  room for Visual Studio Build Tools or the .NET SDK. Free up space or use an external SSD first.
- **VM size:** give it 4 cores and 6 to 8 GB RAM.

## Order of work (each step a small, green commit)

1. **VM:** free disk space, install UTM and Windows 11 ARM with bridged networking and the .NET 8 SDK.
2. **Spike, throwaway:** a C# console app on the VM that advertises `_sidekey._tcp`, sends the
   pairing `challenge`, and logs the foreground app. Check the iPad sees it. This answers the
   discovery question before anything else is built.
3. **Shared protocol** (Swift, test first): the `platform` field, the `win` modifier, the golden
   fixtures, and the old-iPad compatibility test.
4. **Windows `Protocol` + `Pairing`** (C#, test first, against the fixtures).
5. **`HostServer` + `Discovery`:** pair a real iPad and reconnect after a restart.
6. **`ForegroundMonitor` + `KeySender` + the system layout:** the first working tap.
7. **iPad wording and shortcut text by platform:** a new TestFlight build.
8. **The six app layouts,** each key pressed and checked in the VM.
9. **Signed installer and firewall rule:** v0.1 on GitHub Releases, after the docs review.

## Decisions for you

1. ~~VM software~~ UTM (decided 2026-10-07).
2. ~~Disk space~~ The user is freeing space (2026-10-07).
3. **Windows licence:** run unactivated for testing, or buy one.
4. **Code signing:** Azure Trusted Signing, an OV certificate, or unsigned for now.
5. **The six v0.1 apps:** keep Chrome, Edge, File Explorer, Word, Excel and VS Code, or change them.
