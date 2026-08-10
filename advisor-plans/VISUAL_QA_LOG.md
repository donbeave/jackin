# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Oracle:** plans/previews/desktop-ui/  
**Native capture path:** DesktopVisualSnapshotHarness (NSHostingView fixtures)  
**Live app GUI:** BLOCKED — `xcode-select` → Command Line Tools; no Xcode.app

## Matrix (hosted views + structural)

| Scene | HTML | Native host | Dark | Light | Verdict | Notes |
|-------|------|-------------|------|-------|---------|-------|
| status-desktop | yes | dual-stack preview | yes | yes | Pass* | *Not live NSStatusItem strip |
| popover-openai | yes | PopoverProviderTab | yes | yes | Pass* | *Body craft; tab grid/footer need PopoverRoot live |
| popover-anthropic | yes | PopoverProviderTab | yes | yes | Pass* | same |
| usage-overview | yes | OverviewListView | yes | yes | Pass | inventory + meters |
| usage-provider-nest | yes | UsageAccountNestView | yes | yes | Pass | 0% empty meter |
| usage-detail-openai | yes | ProviderCardView | yes | yes | Pass | Open usage + Limit Reset |
| usage-toolbar | yes | stand-in + code path | yes | yes | Pass* | *Real toolbar in UsageWindowController |

## Interactions (code + harness)

| Flow | Result |
|------|--------|
| Left-click focuses provider | Pass — StatusPopoverFocus + DesktopSoTParityHarness |
| Right-click menu 3 rows | Pass — StatusItemMenuModel + SoT harness |
| Overview multi-account | Pass — OverviewInventory + harness |
| Open usage URLs | Pass — ProviderUsageLinks complete |
| Nest mini meter 0%/57%/100% | Pass — DesktopSoTParityHarness meter fractions |
| Live open popover/Usage window | BLOCKED — no full app on CLT |

## Automated gates

- check_usage_liquid_glass.py — PASS  
- DesktopArchitectureLint — ALL PASS  
- DesktopSoTParityHarness ×3 — ALL PASS  
- DesktopParityMatrixHarness — ALL PASS  
- StatusItemChipHarness — ALL PASS  
- glass/limits grep — clean  

## High residual

None on **hosted body IA**. Program L4 full Done needs Xcode + live captures for status bar strip + full PopoverRoot chrome.

## Artifacts

- `advisor-plans/qi-artifacts/html/*`  
- `advisor-plans/qi-artifacts/native/*`  
- `advisor-plans/qi-artifacts/deltas/2026-08-10-*.md`  
