---
target: iKeypad iPad app UI
total_score: 18
max_score: 40
na_heuristics: 
p0_count: 2
p1_count: 2
timestamp: 2026-10-07T16-28-05Z
slug: ikeypad-sources-ikeypad-ikeypadapp-swift
---
## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 1 | actionExecuted(success,error) dropped; haptic fires even when disconnected; profile switch is a text change in a grey pill |
| 2 | Match System / Real World | 2 | Raw Bonjour text in status ("iKeypad\032Host._ikeypad._tcp.local."); keys don't show the real shortcut |
| 3 | User Control and Freedom | 2 | Can't pin/lock a profile or stop it following focus |
| 4 | Consistency and Standards | 2 | Colour carries no meaning (red = Mute Mic and Close Tab); same arrow.clockwise glyph for Reload key and reconnect button |
| 5 | Error Prevention | 2 | Lock Mac / Close Tab / Interrupt sit beside harmless keys with no hold-to-fire |
| 6 | Recognition Rather Than Recall | 3 | Icon + label works; shortcut never shown so it never transfers to the keyboard |
| 7 | Flexibility and Efficiency | 2 | rows/position ignored; dial component built but unused; no paging or pinning |
| 8 | Aesthetic and Minimalist Design | 2 | Keys use ~17% of the screen; 75% empty; shadows + saturated fills on light grey |
| 9 | Error Recovery | 1 | localizedDescription in a truncated pill, no next step; action failures invisible |
| 10 | Help and Documentation | 1 | No first-run guidance (install Mac host, permissions, USB vs Wi-Fi) |
| **Total** | | **18/40** | **Poor** |

## Design Specificity Verdict

LLM: Generic. Grey grouped background, capsule pill, Tailwind-palette rounded rectangles. The hero idea (deck follows the Mac's frontmost app) is a 14pt grey word.
Deterministic: impeccable detector does not scan .swift (exit 0, 0 files scanned) so it is not a clean pass. Mechanical checks: 9 of 17 key colours (52 of 111 keys) fail WCAG 4.5:1 with white 14pt labels; #25D366 (1.98) and #D69E2E (2.39) fail even 3:1. Zero accessibility labels; fixed font sizes; raw NWError/endpoint strings at DeckClient.swift:43,66,107; deprecated cornerRadius/foregroundColor/onChange.

## Priority Issues

- [P0] No action feedback: actionExecuted ignored, send() silently no-ops while disconnected but the haptic still fires. Fix: per-key pending/ok/failed state, success glow + haptic, failure shake + toast with the Mac's error; inert keys when disconnected.
- [P0] Connection status raw and unrecoverable. Fix: three human states (Looking for your Mac / Connected to <Mac name> via USB|Wi-Fi / Disconnected, retrying) with transport icon; dim the grid when not connected; troubleshooting hint after ~8s.
- [P1] Hero feature invisible, 75% of screen wasted. Fix: "Now controlling" band (app icon, name, window/document title, context chips); size keys from available space; always render rows x columns by position with empty wells; animate profile changes.
- [P1] Accessibility: contrast failures on 52 keys, no Dynamic Type, VoiceOver reads SF Symbol names, unlabeled reconnect button. Fix: darken failing fills or compute text colour; scaled fonts; accessibilityLabel/Hint; announce profile changes.
- [P2] Colour has no semantics; off-the-shelf look. Fix: semantic roles (navigate/create/run/destructive/toggle), dark "hardware" deck surface, per-app accent.

## Persona Red Flags

- Power user: grid swaps under the finger on app switch with no transition; no Build-started confirmation; no ⌘B hint; can't pin a profile.
- First-timer: first screen is a Bonjour string; System keys look live but do nothing while connecting; no setup guidance.
- Accessibility user: failing contrast on green/gold/teal/orange; no Dynamic Type; no announcement when the grid changes meaning.

## Minor Observations

Color(hex:) silently returns black; Color.blue fallback; reconnect button hit area < 44pt; ScrollView unnecessary; haptic generator not prepared; landscape/Split View tiles distort; no idle-timer handling; DeckRotaryDialView dead code.

## Questions to Consider

- Should the deck wear the controlled app's identity (icon, accent, window title) so the user knows where a tap lands?
- Is a 3x5 hardware grid the right primitive on an 11-13" touchscreen, or should toggles with live state and dials join it?
- If focus changes between seeing and tapping, which app should receive the key? (Send profileId with executeAction.)
