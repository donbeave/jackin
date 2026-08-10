# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6  
**Oracle:** `plans/previews/desktop-ui/`  
**Method:** Dual-image multimodal review (HTML baseline + native shipped-path PNG) per QI §7  

## Capture paths (shipped only)

| Scene | Native path | Live |
|-------|-------------|------|
| status-desktop | StatusItemRendering + live status-desktop-live-dark.png | Yes |
| popover-openai | PopoverRoot + popover-live-openai-dark.png | Yes |
| popover-anthropic | PopoverRoot + popover-live-anthropic-dark.png | Yes |
| usage-overview | OverviewListView + usage-window-overview CGWindow | Hosted window |
| usage-provider-nest | UsageAccountNestView + usage-window-openai sidebar | Hosted window |
| usage-detail-openai | ProviderCardView + usage-window-openai detail | Hosted window |
| usage-toolbar | UsageWindowController titlebar crop | Real NSWindow |

## Matrix (dual-image reviewed)

| Scene | HTML D/L | Native D/L | Dual-image | Verdict |
|-------|----------|------------|------------|---------|
| status-desktop | yes | yes | yes | **Pass** |
| popover-openai | yes | yes | yes | **Pass** |
| popover-anthropic | yes | yes | yes | **Pass** |
| usage-overview | yes | yes | yes | **Pass** |
| usage-provider-nest | yes | yes | yes | **Pass** |
| usage-detail-openai | yes | yes | yes | **Pass** |
| usage-toolbar | yes | yes | yes | **Pass** |

Every row has `advisor-plans/qi-artifacts/deltas/2026-08-10-<scene>.md` with **Verdict: Pass**.

## Interactions

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focuses provider | Pass | Live popover PNGs OpenAI/Anthropic |
| Right-click 3 menu rows | Pass | DesktopSoTParityHarness (live CGEvent menu flaky) |
| Overview multi-account | Pass | OverviewInventory + PNGs |
| Nest 0%/57%/100% meters | Pass | SoT harness + nest/window PNGs |
| Open usage URLs | Pass | ProviderUsageLinks harness |
| App launch | Pass | JackinDesktop under Xcode |

## High residual

**None.** Remaining deltas are Med/Low only (Refresh vs Open Usage Window footer product law; system accent vs phosphor; system toolbar title alignment).

## Automated gates

- check_usage_liquid_glass.py PASS  
- DesktopArchitectureLint ALL PASS  
- DesktopSoTParityHarness ×3 ALL PASS  
- DesktopParityMatrixHarness ALL PASS  
- StatusItemChipHarness ALL PASS  
- glass/limits grep clean  

## Artifacts

- `advisor-plans/qi-artifacts/html/*`  
- `advisor-plans/qi-artifacts/native/*`  
- `advisor-plans/qi-artifacts/deltas/2026-08-10-*.md`  
