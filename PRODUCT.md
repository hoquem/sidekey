# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

A developer and power user working at a Mac, with an iPad propped beside the keyboard as a touch control surface. They move between developer tools (Xcode, Terminal, VS Code, Safari), communication apps (WhatsApp, Telegram, Zoom) and writing tools (MacDown) all day, and want the right shortcuts under their finger without remembering them. The iPad is glanced at mid-task, often from 50 to 70 cm away, and tapped without looking for long.

## Product Purpose

iKeypad turns an iPad into a context-aware macro deck for a Mac. A Mac companion service watches the frontmost app and pushes that app's key layout to the iPad; tapping a key makes the Mac fire a hotkey, AppleScript, shell command or Shortcut. Success means the user trusts every tap: they can see which app the deck is driving, that the key fired, and why it didn't when it fails.

## Positioning

The deck follows the Mac's focus automatically, connects over USB first for low latency (Wi-Fi fallback), and its layouts live as code in the user's own repository rather than in a vendor configuration app. Alternatives in the same space: Elgato Stream Deck Mobile (Smart Profiles), DevDeck, Deck Buddy, DeckPilot.

## Operating Context

- Two processes: `iKeypadMacDaemon` (macOS menu bar companion, Bonjour `_ikeypad._tcp` on TCP 49200) and the iPadOS client. Messages are length-prefixed JSON (`Packages/iKeypadShared`).
- The Mac needs Accessibility permission to post keystrokes; window titles and app state also come from the Accessibility API.
- Profiles are a 3 x 5 grid. Built-in profiles: System (fallback), VS Code, Terminal, Xcode, Safari, Chrome, Arc, WhatsApp, Telegram, Zoom, MacDown. Shortcuts are verified against each app's menu bar or published documentation.
- The user runs and installs the app themselves on their own iPad Air (5th generation) and MacBook Pro; it is not on the App Store.

## Capabilities and Constraints

- iPadOS 16 deployment target; SwiftUI; iPad only.
- The Mac reports every action's success or failure (`actionExecuted`).
- Undecided: user-editable layouts on the iPad, paging beyond 15 keys, dials (a dial component exists but is unused).

## Brand Commitments

- Name: iKeypad.
- The user chose a dark "hardware deck" visual direction and the "Lit key" app icon concept (dark keycaps, one glowing key).

## Evidence on Hand

No screenshots, testimonials, users or metrics beyond the author's own use. Do not invent any.

## Product Principles

1. Every tap gets an honest answer: pending, done, or failed with the Mac's reason.
2. The deck always says which Mac app it is driving and over which link.
3. Keys stay where muscle memory expects them within an orientation; layouts never reflow under the finger. Portrait (3 x 5) and landscape (5 x 3) each have their own fixed positions, chosen by the user (2026-10-07) so portrait fills the screen.
4. Fail loudly: a missing permission or a lost connection is shown, never hidden behind live-looking keys.
5. The Mac does the work; the iPad stays a thin, fast surface.

## Accessibility & Inclusion

WCAG AA contrast for key labels, Dynamic Type, VoiceOver labels that say what a key does on the Mac, Reduce Motion respected.
