# QI delta: usage-toolbar · Dark + Light (G-U1)

**Date:** 2026-08-10 · **Tip:** readable Dark toolbar composite  
**Oracle HTML:** `html/usage-toolbar-{dark,light}.png`  
**Native:** `native/usage-toolbar-{dark,light}.png`

## Fail → Pass trail

| Cycle | High residual | Fix |
|-------|---------------|-----|
| Fail | Dark solid white SF Symbol disks | view-bitmap crop |
| Blocked | current Dark view-bitmap | unreadable white symbol disks; no coordinate capture fallback |
| Fail | Brand title was leading despite centered HTML oracle | hidden duplicate NSWindow title + SwiftUI `.principal` brand item |
| Pass | Brand centered with phosphor chevron | recaptured full window + toolbar Dark+Light |

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Brand | centered jackin❯ desktop | centered; phosphor chevron | Yes |
| Refresh | clockwise glyph | Light readable; Dark capture blocked | Partial |
| Sidebar toggle | system | present | Yes |
| Unified chrome | titlebar | NSToolbar crop | Yes |
| Limits only | n/a | no prices | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| High | Dark toolbar capture | Window-ID capture unavailable; view-bitmap symbols whiteout |

## Verdict
**Verdict: Light Pass; Dark Blocked**
