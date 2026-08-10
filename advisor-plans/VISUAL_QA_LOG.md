# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6 (`xcode-select` → `/Applications/Xcode.app/Contents/Developer`)  
**Oracle:** `plans/previews/desktop-ui/`  
**Harness:** `DesktopVisualSnapshotHarness` + live `JackinDesktop` release binary  

## Capture paths

| Scene | Shipped path | Live |
|-------|--------------|------|
| status-desktop | StatusItemRendering bitmap | **Yes** — menu bar 2 extras screencapture + AX titles |
| popover-openai | PopoverRoot fixture | **Yes** — left-click OpenAI status |
| popover-anthropic | PopoverRoot fixture | **Yes** — left-click Anthropic status |
| usage-overview | OverviewListView + UsageWindowRoot | Hosted full shell |
| usage-provider-nest | UsageAccountNestView (+ window sidebar) | Hosted |
| usage-detail-openai | ProviderCardView (+ UsageWindowRoot) | Hosted |
| usage-toolbar | UsageWindowController CGWindow top-band | Real NSToolbar host |

## Matrix

| Scene | HTML D/L | Native | Verdict | Notes |
|-------|----------|--------|---------|-------|
| status-desktop | yes | live + API | **Pass** | Dual-stack AX + live extras; no glass chips |
| popover-openai | yes | hosted + live | **Pass** | Full shell; live focus OpenAI |
| popover-anthropic | yes | hosted + live | **Pass** | Full shell; live focus Anthropic |
| usage-overview | yes | hosted | **Pass** | Inventory + window shell |
| usage-provider-nest | yes | hosted | **Pass** | 0% empty mini meter |
| usage-detail-openai | yes | hosted | **Pass** | Limit Reset + Open usage |
| usage-toolbar | yes | real window | **Pass** | Unified NSToolbar |

## Interactions

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focuses provider | **Pass** | Live popover-openai / anthropic PNGs |
| Right-click menu 3 rows | **Pass** (code/harness) | DesktopSoTParityHarness; live CGEvent menu flaky without trusted accessibility |
| Overview multi-account | **Pass** | OverviewInventory + harness + PNGs |
| Nest meters 0%/mid/full | **Pass** | SoT harness + nest PNG |
| Open usage URLs | **Pass** | ProviderUsageLinks harness |
| App launch | **Pass** | app-launch-prod.log — JackinDesktop running |

## High residual

None claimed for required scenes on shipped-path + live status/popover evidence. Residual Med: footer Open Usage vs Refresh (product law), title centering (system toolbar), phosphor vs system accent.

## Automated gates

- check_usage_liquid_glass.py PASS  
- DesktopArchitectureLint ALL PASS  
- DesktopSoTParityHarness ×3 ALL PASS  
- DesktopParityMatrixHarness ALL PASS  
- StatusItemChipHarness ALL PASS  
- glass/limits grep clean  

## Artifacts

- `advisor-plans/qi-artifacts/html/*`  
- `advisor-plans/qi-artifacts/native/*` (includes live `*-live-*` + `usage-window-*`)  
- `advisor-plans/qi-artifacts/deltas/2026-08-10-*.md`  
