# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Oracle:** `plans/previews/desktop-ui/`  
**Harness:** `DesktopVisualSnapshotHarness` + `PresentationStore.applyQIFixture`  
**Manifest:** `advisor-plans/qi-artifacts/native/MANIFEST.md`

## Capture honesty

| Scene | Shipped path used | Live menu bar / full app |
|-------|-------------------|--------------------------|
| popover-* | **PopoverRoot** (TabGrid+body+Footer) | Hosted view (not NSPopover window) |
| status-desktop | **StatusItemRendering** bitmap only | **BLOCKED** live NSStatusItem strip |
| usage-toolbar | **UsageWindowController** CGWindow top-band | Real NSWindow + unified toolbar |
| usage-detail | **ProviderCardView** | Content crop |
| usage-overview | **OverviewListView** | Content crop |
| usage-provider-nest | **UsageAccountNestView** | Nest unit (same meter as UsageWindowRoot) |

## Matrix

| Scene | HTML D/L | Native D/L | Verdict | Notes |
|-------|----------|------------|---------|-------|
| status-desktop | yes | yes | **BLOCKED** live bar; Pass API dual-stack only | See delta |
| popover-openai | yes | yes | **Pass** | Full PopoverRoot shell |
| popover-anthropic | yes | yes | **Pass** | Anthropic selection + 12% danger |
| usage-overview | yes | yes | **Pass** | Inventory content |
| usage-provider-nest | yes | yes | **Pass** | 0% empty mini meter |
| usage-detail-openai | yes | yes | **Pass** | Detail content + Limit Reset |
| usage-toolbar | yes | yes | **Pass** | Real unified toolbar window crop |

## High residual

- **G-S1 live status strip:** BLOCKED until live `NSStatusItem` capture (or Xcode GUI app launch).
- No High residual on hosted **popover shell** / Usage content / toolbar host paths claimed Pass above.

## Interactions (L2 + code)

| Flow | Result |
|------|--------|
| Left-click focus | Pass — StatusPopoverFocus + SoT harness |
| Right-click 3 rows | Pass — StatusItemMenuModel + SoT |
| Overview multi-account | Pass — OverviewInventory + harness |
| Open usage URLs | Pass — ProviderUsageLinks |
| Nest 0%/57%/100% meters | Pass — SoT meter fractions |
| Live popover/Usage open | **BLOCKED** interactive GUI walkthrough on CLT-only agent path |

## Automated gates

- `check_usage_liquid_glass.py` PASS  
- DesktopArchitectureLint ALL PASS  
- DesktopSoTParityHarness ×3 ALL PASS  
- DesktopParityMatrixHarness ALL PASS  
- StatusItemChipHarness ALL PASS  
- glass/limits grep clean  

## Artifacts

- `advisor-plans/qi-artifacts/html/*`  
- `advisor-plans/qi-artifacts/native/*` (+ MANIFEST.md)  
- `advisor-plans/qi-artifacts/deltas/2026-08-10-*.md` (scene-specific)  
