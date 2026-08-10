# QI delta: status-desktop · Dark + Light (G-S1)

**Date:** 2026-08-10 · **Tip:** `bd3f3dc9`  
**Oracle HTML:** `html/status-desktop-{dark,light}.png` (menu-bar strip in desktop mock)  
**Native:** `native/status-desktop-{dark,light}.png` (StatusItemRendering bitmap)

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Dual stack | countdown top + % bottom | 1h/12% · 3d/57% · 18h/100% | Yes |
| Template mono | transparent glyphs | no brand color plates | Yes |
| No glass chips | FB1-6 | no capsule fill | Yes |
| Fixture % | Anthropic 12 · OpenAI 57 · Amp 100 | same | Yes |
| Light theme | dark text on light bar | same IA | Yes |
| Limits only | remaining % only | no prices/trends | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Framing | Native = isolated extras; HTML = full desktop + system /clock |
| Low | System chrome |  / Control Center / clock **N/A** (system) |
| Med | Live NSStatusItem | harness craft Pass; live BLOCKED without Screen Recording |

## Verdict
**Verdict: Pass** (Dark + Light)
