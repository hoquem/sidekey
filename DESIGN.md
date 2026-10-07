---
name: iKeypad
description: A dark hardware macro deck for the Mac, worn by the iPad beside the keyboard.
colors:
  lit: "#FFB020"
  failure: "#FF7A7A"
  role-navigate: "#CBD5E1"
  role-create: "#7AB4FF"
  role-run: "#5EE38E"
  role-modify: "#C9A8FF"
  plate: "#101218"
  well: "#0A0C0F"
  cap-top: "#24272E"
  cap-bottom: "#1A1D23"
  cap-pressed: "#14161B"
  raised: "#22262D"
  hairline: "rgba(255,255,255,0.07)"
  well-hairline: "rgba(255,255,255,0.035)"
  label: "#F3F5F8"
  secondary-label: "#A3ADBA"
typography:
  band-name-column:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "28pt"
    fontWeight: 700
  band-name-row:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "22pt"
    fontWeight: 700
  status-headline:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "20pt"
    fontWeight: 700
  key-label:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "15pt"
    fontWeight: 600
  body-secondary:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "15pt"
    fontWeight: 400
  toast:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "15pt"
    fontWeight: 500
  chip-label:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "13pt"
    fontWeight: 600
  host-caption:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "12pt"
    fontWeight: 400
  key-hint:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "11pt"
    fontWeight: 500
rounded:
  toast: "14pt"
  chip: "999pt"
  pin: "22pt"
spacing:
  chip-gap: "8pt"
  link-pin-gap: "12pt"
  band-column-stack: "16pt"
  band-row: "18pt"
  margin: "24pt"
  portrait-band-to-grid: "24pt"
  landscape-column-gap: "28pt"
components:
  keycap:
    backgroundColor: "{colors.cap-top}"
    textColor: "{colors.label}"
  keycap-pressed:
    backgroundColor: "{colors.cap-pressed}"
    textColor: "{colors.label}"
  key-well:
    backgroundColor: "{colors.well}"
  chip-good:
    textColor: "{colors.role-run}"
    rounded: "{rounded.chip}"
    padding: "5pt 10pt"
  chip-warn:
    textColor: "{colors.lit}"
    rounded: "{rounded.chip}"
    padding: "5pt 10pt"
  chip-bad:
    textColor: "{colors.failure}"
    rounded: "{rounded.chip}"
    padding: "5pt 10pt"
  chip-neutral:
    textColor: "{colors.secondary-label}"
    rounded: "{rounded.chip}"
    padding: "5pt 10pt"
  pin-button:
    backgroundColor: "{colors.raised}"
    textColor: "{colors.secondary-label}"
    rounded: "{rounded.pin}"
    size: "44pt"
  pin-button-on:
    textColor: "{colors.lit}"
    rounded: "{rounded.pin}"
    size: "44pt"
  toast:
    backgroundColor: "{colors.raised}"
    textColor: "{colors.label}"
    rounded: "{rounded.toast}"
    padding: "12pt 18pt"
---

# Design System: iKeypad

## Overview

**Creative North Star: "The Lit Key"**

iKeypad is a dark hardware deck: a graphite plate carrying a fixed grid of raised graphite keycaps, read from 50 to 70 cm away and tapped without looking. The surface is deliberately quiet so that the two things that matter can be seen at a glance: which Mac app the deck is driving (the real app icon, name and window title in the band) and what the Mac said about the last tap. Colour is never decoration. Each key's role tints its SF Symbol; a single warm amber, the lit signal, marks a key that is firing or has fired, a live state that needs attention, and the app icon's glowing centre key.

The deck is forced dark whatever the system appearance (`preferredColorScheme(.dark)`). There is no light theme. Depth is physical: caps carry a soft drop shadow and a top-to-bottom gradient, sink and darken when pressed, and empty slots are recessed wells darker than the plate. Type is the platform's own: SF Pro through Dynamic Type text styles, SF Symbols for every glyph.

The signature move is the lit-key glow travelling from tap to confirmation: a faint amber edge and glow while the Mac works, a full amber bloom when it reports success, a red edge, badge and shake with the Mac's reason when it fails.

**Key Characteristics:**
- Graphite plate, graphite caps, high-contrast white labels.
- Role colour lives on the key's symbol; the cap edge is reserved for the Mac's answer.
- One amber signal colour, used only for "lit" meaning.
- A fixed 3 x 5 grid with recessed wells, so keys never move within an orientation.
- Native materials: SF Pro, Dynamic Type, SF Symbols, continuous-corner rounded rectangles.

## Colors

A near-monochrome graphite world with a handful of pale, desaturated role tints and one warm amber signal.

### Primary
- **Lit Amber** (lit): the brand signal. Pending and succeeded key edges and glow, a key lit by a live attention state (muted, sharing, recording), the warn chip tone, the pinned pin, and the hold-hint toast icon. Nothing else may be amber.

### Status
- **Signal Red** (failure): a failed key's edge and corner badge, the bad chip tone, error toast icons. The danger role reuses it, so a destructive key's symbol and a failure read as the same family.

### Role Tints
Role tints colour a key's SF Symbol only (hierarchical rendering), never the cap fill.
- **Slate** (role-navigate): move around; also the default when a key has no role.
- **Sky** (role-create): make or open something.
- **Signal Green** (role-run): start something; also the good chip tone.
- **Lavender** (role-modify): change formatting, state or settings.

### Neutral
- **Deck Plate** (plate): the full-bleed background behind everything.
- **Recessed Well** (well): empty grid slots, darker than the plate so they read as holes.
- **Cap Top / Cap Bottom** (cap-top, cap-bottom): the resting keycap's vertical gradient, lighter at the top.
- **Cap Pressed** (cap-pressed): the flat fill of a cap held down.
- **Raised Graphite** (raised): small raised surfaces off the grid: the toast, the pin button at rest, the app icon placeholder.
- **Cap Hairline** (hairline): the 1pt resting edge of every cap.
- **Well Hairline** (well-hairline): the fainter 1pt edge of an empty well.
- **Label White** (label): key labels, app name, connection label, toast text.
- **Secondary Grey** (secondary-label): shortcut hints, window title, host name, the neutral chip, inactive pin.

Measured contrast: label is 13.7:1 on cap-top; secondary-label 6.6:1; every role tint, lit and failure are at least 5.9:1 on cap-top and higher on darker surfaces, so all pass WCAG AA for the 11pt key hint.

The app icon uses its own warmer amber ramp (face gradient from a light gold to deep orange, with an orange bloom) and a slightly lighter graphite cap; those values belong to `tools/render_app_icon.swift` only and are not deck tokens.

### Named Rules
**The One Signal Rule.** Amber means lit: firing, fired, live attention state, pinned. If a use of amber cannot be described as "lit", it is the wrong colour.

**The Symbol Carries the Role Rule.** Role colour tints the key's symbol only. Cap fills stay graphite on every key, so the grid never becomes a wall of coloured tiles.

## Typography

**Display Font:** SF Pro (system), via Dynamic Type text styles
**Body Font:** SF Pro (system)
**Label/Mono Font:** none; shortcut glyphs (⌃⌥⇧⌘, ⇥ ↩ ⎋ with text presentation forced) are set in the same face.

**Character:** The platform face at bold weights for identity and semibold for keys; nothing custom, because the deck must feel like part of the device and scale with Dynamic Type.

### Hierarchy
Sizes in the frontmatter are the default Large Dynamic Type sizes; the build uses the text styles, so they scale.
- **Band name, column** (title, bold): the controlled app's name in the landscape column; also the not-connected headline in landscape (title2, bold).
- **Band name, row** (title2, bold): the app's name in the portrait band.
- **Status headline** (title3, bold): "Looking for your Mac…" and siblings in portrait.
- **Key label** (subheadline, semibold, up to 2 lines, scales down to 70%): what the key does.
- **Secondary body** (subheadline, regular): window title (middle truncation), setup help text.
- **Toast** (subheadline, medium).
- **Chip label / connection label** (footnote, semibold).
- **Host caption** (caption, regular): the Mac's name under USB / Wi-Fi.
- **Key hint** (caption2, medium, 1 line, scales to 70%): the shortcut sent, "Hold · ⌃⌘Q" on confirm keys, or a bound chip's live state.

Key symbols are not a text style: they are sized at 24% of the key's shorter side, semibold.

### Named Rules
**The Shortcut Teaches Rule.** Every hotkey key shows the exact shortcut it sends, in Mac modifier glyph order ⌃⌥⇧⌘, so the deck teaches the keyboard.

## Layout

One screen, full-bleed plate, 24pt margin on all sides.

- **Orientation switch:** landscape when width exceeds 1.15 x height; otherwise portrait. This holds for Split View widths too.
- **Portrait:** the Now Controlling band sits in a row on top, 24pt above the grid. Profiles are authored as 5 columns x 3 rows; portrait renders 3 columns x 5 rows, refilling slots in reading order (slot index = row x columns + column with the dimensions swapped).
- **Landscape:** the band becomes a left column, width min(300pt, 28% of screen width), 28pt from a 5 x 3 grid.
- **Grid sizing:** the gap is 2.8% of the grid area's shorter side. Keys divide the remaining space; portrait keys are clamped to near square (height at most 1.1 x width, width at most 1.4 x height), landscape keys at most 1.25 x width, with the leftover height spread into the row gaps (up to 2.5 x the base gap). Portrait grids are top-aligned; landscape grids are vertically centred.
- **Fixed slots:** every slot renders: a key or an empty well. Within an orientation, a key never moves.
- **Band row (portrait):** 64pt app icon, 18pt gap, name and window title stacked 3pt apart, chips 8pt below, flexible space, then connection and pin.
- **Band column (landscape):** 72pt app icon, identity, chips stacked vertically, 16pt stack spacing, connection and pin pinned to the bottom.
- **Toast:** bottom-centred, 28pt from the bottom, 24pt side inset.

### Named Rules
**The Muscle Memory Rule.** The grid is always full: a layout with fewer keys than slots shows wells, never a reflowed, shorter grid. Positions are fixed per orientation: portrait re-flows the same reading order into 3 columns x 5 rows, a deliberate trade the user chose so portrait fills the screen.

## Elevation & Depth

Physical, low-key depth: shadows on things you press or that float, tonal recession for things that are absent. Caps sit on the plate with a soft black drop shadow; pressing a cap shrinks it to 96.5%, flattens its fill and pulls the shadow in tight. Empty wells drop below the plate tone instead of rising above it. The only coloured shadow in the system is the amber lit glow, which has no offset: it is light, not depth. The toast floats with the heaviest shadow. Exact shadow values live in `.impeccable/design.json`.

### Named Rules
**The Light Not Lift Rule.** The amber glow is centred and unoffset; it never doubles as an elevation shadow, and black shadows never carry colour.

## Shapes

Continuous-corner (squircle) rounded rectangles throughout, matching iPadOS.
- **Keycaps and wells:** corner radius 16% of the key's shorter side, so corners scale with the key.
- **App icon placeholder:** radius 22% of its size, echoing an app icon.
- **Toast:** 14pt continuous corners.
- **Chips:** full capsules. **Pin button:** a 44pt circle.

## Components

### Keycap (signature)
Raised, quiet, and honest about what the Mac said.
- **Anatomy:** SF Symbol (tinted by role, hierarchical), label in white, hint line in secondary grey; content padded 9% of the shorter side, 5% between lines, vertically centred.
- **Rest:** cap-top to cap-bottom gradient, 1pt hairline edge, soft drop shadow.
- **Pressed:** cap-pressed fill, scale 0.965, tight shadow, medium impact haptic.
- **Pending:** 2pt amber edge at 45%, faint amber glow.
- **Succeeded:** 2pt full amber edge, wide amber bloom.
- **Failed:** 2pt red edge, red exclamation badge in the top-trailing corner, horizontal shake (skipped under Reduce Motion). The Mac's reason appears in the toast.
- **Lit by live state:** when a bound chip is warn or bad (muted, sharing, recording), the symbol and hint turn amber and the edge goes 1.5pt amber at 80%; the hint shows the live state.
- **Disabled (not connected):** whole cap at 38% opacity and inert.
- **Hold to confirm:** disruptive keys fire only after a 0.6 s press-and-hold; a role-tinted fill at 28% rises from the bottom of the cap; the hint reads "Hold · shortcut"; releasing early shows a "Hold to …" toast. VoiceOver double-tap fires without the hold.

### Empty Well
A recessed slot: well fill, 1pt well hairline, same corner formula as a key, hidden from VoiceOver.

### Chips
- **Style:** footnote semibold label with SF Symbol, coloured by tone, on a capsule of the same colour at 14% opacity; 10pt by 5pt padding.
- **Tones:** good (green), warn (amber), bad (red), neutral (secondary grey). A missing Accessibility permission on the Mac is always the first chip, in bad tone. "System keys" (neutral) marks the fallback profile.

### Now Controlling Band
- **Connected:** real app icon PNG from the Mac (placeholder: raised squircle with a macwindow symbol), app name, window title, chips, then the link (USB with a cable glyph or Wi-Fi, plus host name) and the pin.
- **Pinned:** the pin turns amber on an amber 16% circle and the window title line reads "Pinned. Keys bring <App> forward."
- **Not connected:** spinner and bold headline ("Looking for your Mac…", "Connecting…", "Reconnecting to <Mac>…"); after 8 s of searching, setup help appears; while reconnecting, "Keys are paused until the Mac is back."

### Toast
Raised graphite, 14pt corners, heavy shadow; red warning triangle for errors, amber tap glyph for hints; subheadline medium text that wraps. Slides up from the bottom (fades only under Reduce Motion).

## Do's and Don'ts

### Do:
- **Do** keep every cap fill graphite (cap-top to cap-bottom) and put role colour on the symbol only.
- **Do** answer every tap on the cap edge: amber 45% pending, full amber succeeded, red failed with badge and shake.
- **Do** render all 15 slots, using recessed wells for empty ones.
- **Do** show the exact shortcut in ⌃⌥⇧⌘ order under every hotkey key.
- **Do** use Dynamic Type text styles and SF Symbols; scale key symbols and corners from the key's shorter side (24% and 16%).
- **Do** gate disruptive keys behind the 0.6 s hold with a rising role-tinted fill.
- **Do** dim keys to 38% and make them inert while the Mac is not connected.
- **Do** honour Reduce Motion: no shake, and opacity-only transitions.

### Don't:
- **Don't** use amber for anything that is not lit, pinned or an attention state.
- **Don't** fill caps with saturated colour or give each role a coloured cap.
- **Don't** reflow or shorten the grid when a layout has fewer keys.
- **Don't** add a light appearance; the deck is dark whatever the system setting.
- **Don't** give the amber glow an offset or use coloured shadows for elevation.
