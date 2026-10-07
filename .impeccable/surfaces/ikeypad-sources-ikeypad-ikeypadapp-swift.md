---
version: 1
slug: "ikeypad-sources-ikeypad-ikeypadapp-swift"
primary_target: "iKeypad/Sources/iKeypad/iKeypadApp.swift"
related_targets: ["iKeypad/Sources/iKeypad/DeckKeyView.swift"]
---

# Deck screen (iPad)

Scope: the single main screen of the iPad app (connection states, Now Controlling band, key grid) plus the app icon. Mode: Operate.

Audience and job: a Mac power user glancing at an iPad beside the keyboard; needs to know which app the deck drives, fire a shortcut, and see whether it worked.

Constraints: iPadOS 16, SwiftUI, native controls, Dynamic Type, VoiceOver, portrait and landscape, Split View widths. No image generation: code-led build.

Unresolved: Zoom state chips are built against Zoom's documented in-meeting menu titles and are untested until the user is in a real meeting.

## Direction contract

THESIS: The deck wears the identity of the Mac app it is driving. Refuses the category default of a floating grid of coloured tiles under a tiny status label.

OWN-WORLD: Dark deck plate (graphite, slightly blue), keys as raised graphite caps with an SF Symbol and label in high-contrast white; colour lives in a role edge (run green, stop red, create blue, navigate neutral, toggle amber) and in the app's accent. One warm amber "lit" glow is the brand signal: success flash, live toggle, and the icon.

STORY: The user glances, reads the app icon, name and window title, sees the USB/Wi-Fi link, taps a key, watches it light up (or shake with the Mac's reason), and trusts the deck.

FIRST VIEWPORT: Top band (about 120 pt) with 56 pt app icon, app name in title weight, window title secondary, context chips, connection glyph and pin on the right. Below, a fixed 3 x 5 grid filling the rest, empty slots as recessed wells. Landscape moves the band to a left column.

FORM: Pinned direction "Dark hardware deck" (user choice; concept-seed skipped because a user-pinned direction beats the roll). Signature move: the lit-key glow travelling from tap to confirmation. Seed key: pinned-user-dark-hardware-deck.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
