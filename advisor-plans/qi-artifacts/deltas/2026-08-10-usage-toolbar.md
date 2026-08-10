# QI delta: usage-toolbar · Dark + Light (G-U1)

**Date:** 2026-08-10 · **Tip:** goal toolbar honesty fix  
**Oracle HTML:** `html/usage-toolbar-{dark,light}.png` — brand title + icon-only Refresh (clockwise)  
**Native:** Light harness titlebar crop; Dark **BLOCKED** (white-blob SF Symbol crop)

## Dual-image — Light (Pass)

| Check | HTML | Native light | Match |
|-------|------|--------------|-------|
| Brand title | `jackin❯ desktop` centered/leading | Leading title present | Yes |
| Refresh | Clockwise glyph, icon-only | `arrow.clockwise` readable mid-toolbar | Yes |
| Unified chrome | Titlebar strip | Real NSToolbar / unified host crop | Yes |
| Limits-only | n/a on chrome | No prices/trends | Yes |

## Dual-image — Dark (not Pass)

| Severity | Element | Notes |
|----------|---------|-------|
| **High (capture)** | Toolbar SF Symbols | Dark crop shows **solid white disks** instead of sidebar + Refresh glyphs — unusable as G-U1 evidence |
| Med | Capture path | CGWindow + screencapture -l/-R fail on CLT; falls back to `cacheDisplay` which blows out Dark template icons |
| Low | Traffic lights | System chrome N/A |

**Honest disposition:** `usage-toolbar-dark.BLOCKED.txt` — do **not** Verdict Pass Dark.  
**Product law still holds:** `UsageWindowRoot.toolbar` ships icon-only Refresh; ArchitectureLint requires NSToolbar hosting; **Light** crop proves readable icons.

## Different vs HTML (not craft High when Light holds)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Title placement | Native unified often leading; HTML mock centers |
| Low | Extra sidebar toggle | System NavigationSplitView control beside Refresh |

## Verdict
- **Light: Pass**
- **Dark: BLOCKED** (capture) — not invent green Pass  
- **§6 High residual craft product: none** (G-U1 observed Light + code; Dark evidence blocked)
