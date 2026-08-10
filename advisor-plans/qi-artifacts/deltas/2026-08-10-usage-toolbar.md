# QI delta: usage-toolbar · Dark + Light (G-U1)

**Date:** 2026-08-10 · **Tip:** readable Dark toolbar composite  
**Oracle HTML:** `html/usage-toolbar-{dark,light}.png`  
**Native:** `native/usage-toolbar-{dark,light}.png`

## Fail → Pass trail

| Cycle | High residual | Fix |
|-------|---------------|-----|
| Fail | Dark solid white SF Symbol disks | view-bitmap crop |
| Pass | screencapture composite | readable Refresh + sidebar toggle Dark+Light |

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Brand | jackin❯ desktop | leading title | Yes |
| Refresh | clockwise glyph | arrow.clockwise readable D+L | Yes |
| Sidebar toggle | system | present | Yes |
| Unified chrome | titlebar | NSToolbar crop | Yes |
| Limits only | n/a | no prices | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Title placement | Native leading vs HTML center |
| Low | Traffic lights | System chrome N/A |

## Verdict
**Verdict: Pass** (Dark + Light)
