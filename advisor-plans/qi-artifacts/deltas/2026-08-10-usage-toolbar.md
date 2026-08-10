# QI delta: usage-toolbar · Dark + Light (G-U1)

**Date:** 2026-08-10 · **Tip:** readable Dark toolbar composite  
**Oracle HTML:** `html/usage-toolbar-{dark,light}.png`  
**Native:** `native/usage-toolbar-{dark,light}.png`

## Fail → Pass trail

| Cycle | High residual | Fix |
|-------|---------------|-----|
| Fail | Dark solid white SF Symbol disks | view-bitmap crop |
| Pass | screencapture composite | readable Refresh + sidebar toggle Dark+Light |
| Fail | Brand title was leading despite centered HTML oracle | hidden duplicate NSWindow title + SwiftUI `.principal` brand item |
| Pass | Brand centered with phosphor chevron | recaptured full window + toolbar Dark+Light |

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Brand | centered jackin❯ desktop | centered; phosphor chevron | Yes |
| Refresh | clockwise glyph | arrow.clockwise readable D+L | Yes |
| Sidebar toggle | system | present | Yes |
| Unified chrome | titlebar | NSToolbar crop | Yes |
| Limits only | n/a | no prices | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Traffic lights | System chrome N/A |

## Verdict
**Verdict: Pass** (Dark + Light)
