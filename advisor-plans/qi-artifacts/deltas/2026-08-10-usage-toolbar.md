# QI delta: usage-toolbar · Dark + Light (G-U1)

**Date:** 2026-08-10 · **Tip:** `bd3f3dc9`  
**Oracle HTML:** `html/usage-toolbar-{dark,light}.png`  
**Native Light:** `native/usage-toolbar-light.png`  
**Native Dark:** **BLOCKED** — `native/usage-toolbar-dark.BLOCKED.txt`

## Dual-image — Light (Pass)

| Check | HTML | Native light | Match |
|-------|------|--------------|-------|
| Brand title | jackin❯ desktop | leading title | Yes |
| Refresh | clockwise glyph | arrow.clockwise readable | Yes |
| Unified chrome | titlebar strip | NSToolbar crop | Yes |
| Limits only | n/a | no prices | Yes |

## Dual-image — Dark (not Pass)

| Severity | Element | Notes |
|----------|---------|-------|
| **High (capture)** | SF Symbol icons | Solid white disks on view-bitmap crop — unusable G-U1 evidence |
| Med | Capture path | CGWindow/screencapture fail on CLT → cacheDisplay |
| Low | Traffic lights | System chrome N/A |

**Honest disposition:** do **not** Verdict Pass Dark. Product: `UsageWindowRoot.toolbar` icon-only Refresh + ArchitectureLint NSToolbar host; Light crop proves readable icons.

## Verdict
- **Light: Pass**
- **Dark: BLOCKED** (capture) — §12 no invent Pass  
- **§6 High residual craft product: none**
