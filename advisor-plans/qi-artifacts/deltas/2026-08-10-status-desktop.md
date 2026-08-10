# QI delta: status-desktop · dark + light

**Date:** 2026-08-10 · **Tip:** `7df4d841` · harness recapture stable

## Oracle
- HTML: `qi-artifacts/html/status-desktop-*.png` (menu-bar strip in full desktop scene)

## Candidate
- Native: `qi-artifacts/native/status-desktop-*.png` (StatusItemRendering bitmap)

## Dual-image (re-verify)
- Dual stack: compact countdown top (1h / 3d / 18h) + % bottom (12% / 57% / 100%)
- Template mono provider glyphs; no brand color plates; no glass chip fill (FB1-6)
- Light theme: dark text on light stage; same IA
- Brand N/A on bar extras (system menu bar)
- Limits only: no prices/trends

## Different (not High)
| Severity | Element | Notes |
|----------|---------|-------|
| Low | System chrome |  / Control Center / clock N/A (system) |
| Low | Capture framing | Native = isolated status extras; HTML = full desktop mock |
| Med | Live NSStatusItem | BLOCKED without Screen Recording — harness craft Pass |

## Verdict
Verdict: Pass
