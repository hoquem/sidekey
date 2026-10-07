# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

A developer and power user working at a Mac, with an iPad propped beside the keyboard as a touch control surface. They move between developer tools (Xcode, Terminal, VS Code, Safari), communication apps (WhatsApp, Telegram, Zoom) and writing tools (MacDown) all day, and want the right shortcuts under their finger without remembering them. The iPad is glanced at mid-task, often from 50 to 70 cm away, and tapped without looking for long.

## Product Purpose

Sidekey turns an iPad into a context-aware macro deck for a Mac. A Mac companion service watches the frontmost app and pushes that app's key layout to the iPad; tapping a key makes the Mac fire a hotkey, AppleScript, shell command or Shortcut. Success means the user trusts every tap: they can see which app the deck is driving, that the key fired, and why it didn't when it fails.

## Positioning

The deck follows the Mac's focus automatically, connects over USB first for low latency (Wi-Fi fallback), and its layouts live as code in the user's own repository rather than in a vendor configuration app. Alternatives in the same space: Elgato Stream Deck Mobile (Smart Profiles), DevDeck, Deck Buddy, DeckPilot.

## Operating Context

- Two processes: the Sidekey Mac app (menu bar companion, target `SidekeyMac`, Bonjour `_sidekey._tcp` on TCP 49200) and the iPadOS client. Messages are length-prefixed JSON (`Packages/iKeypadShared`).
- The Mac needs Accessibility permission to post keystrokes; window titles and app state also come from the Accessibility API.
- Profiles are 3 rows by 5 columns. Built-in profiles: System (fallback), VS Code, Terminal, Xcode, Safari, Chrome, Arc, WhatsApp, Telegram, Zoom, MacDown. Shortcuts are taken from each app's menu bar or published documentation; Zoom's in-meeting keys and state chips come from Zoom's documentation and are not yet tested in a live meeting.
- Brand name: Sidekey (chosen 2026-10-07). The iPad app will ship through TestFlight, then the App Store (free); the Mac companion will ship as a Developer ID signed, notarized DMG on GitHub Releases, because a sandboxed Mac App Store app cannot post keystrokes to other apps. Source is public on GitHub under MIT.

## Capabilities and Constraints

- iPadOS 16 deployment target; SwiftUI; iPad only.
- The Mac reports every action's success or failure (`actionExecuted`).
- Undecided: user-editable layouts on the iPad, paging beyond 15 keys, dials (a dial component exists but is unused).

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
5. The Mac does the work; the iPad stays a thin, fast surface.

## Accessibility & Inclusion

WCAG AA contrast for key labels, Dynamic Type, VoiceOver labels that say what a key does on the Mac, Reduce Motion respected.
