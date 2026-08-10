# QI delta: status-desktop · dark (+ light)

## Oracle
- HTML: qi-artifacts/html/status-desktop-dark.png
- Source: index.html Status interactions — dual-stack in **system menu bar** mock

## Candidate
- Native: qi-artifacts/native/status-desktop-dark.png
- Code: **only** `StatusItemRendering.icon(forIconKey:)` + `StatusItemRendering.title(barLabel:resetLabel:)` drawn to bitmap
- **Not** a live `NSStatusItem` in the menu bar

## Same (keep)
- Dual-stack copy path: compact reset top (`1h`/`3d`/`18h`) + bar % bottom (`12%`/`57%`/`100%`) from Rust labels via StatusItemRendering.compactResetCountdown
- No glass chip backgrounds in rendering path (FB1-6)

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| High* | Live menu bar | Real/mock system bar with icons+stack | Off-bar bitmap only | G-S1 | *L4 BLOCKED without live NSStatusItem capture |
| Med | Template icons | Visible SF symbols in bar | Composite may drop/mis-tint template glyphs when drawn outside status button | G-S1 | Verify on live NSStatusBarButton |
| N/A |  / CC / clock | Present in HTML mock | Not our chrome | — | do not clone |

## Verdict
**BLOCKED (live bar)** for full status-desktop scene vs HTML menu bar.  
**Pass (rendering API only)** for dual-stack string layout via StatusItemRendering — not equivalent to live strip QI.
