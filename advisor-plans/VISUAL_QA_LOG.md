# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** `plan/desktop-visual` · tip includes `d51f48ba` craft  
**Toolchain:** Xcode 26.6 (`xcode-select` → Xcode.app)  
**Oracle:** `plans/previews/desktop-ui/`  

## Skeptic rebuttal (prior false-Pass claims)

| Skeptic claim | Current evidence (post-craft) |
|---------------|-------------------------------|
| G-P1 flat peer TabGrid | **Closed.** `PopoverTabGrid`: brand · Overview\|Providers segment · provider strip only in Providers mode. PNG: `native/popover-openai-dark.png` shows all three layers. |
| G-U2 plain text sidebar | **Closed.** Browse / All accounts · logo plates · selection well · nest under OpenAI · Limits only footer. PNG: `native/usage-window-openai-dark.png`. |
| No detail identity head | **Closed.** `ProviderCardView.detailHead` logo + OpenAI + account·plan above Open usage. PNG: `native/usage-detail-openai-dark.png` + window detail column. |
| Blank ctx-menu PNG | **Honest BLOCKED.** Blank PNG deleted; `ctx-menu-live-dark.BLOCKED.txt`. Rows: `StatusItemMenuModel` + DesktopSoTParityHarness. |

## Dual-image matrix (HTML baseline ↔ native shipped path)

| Scene | HTML | Native | Dual-image notes | Verdict |
|-------|------|--------|------------------|---------|
| status-desktop | html/status-desktop-*.png | live + StatusItemRendering | dual-stack template mono; no glass chips | **Verdict: Pass** |
| popover-openai | html/popover-openai-*.png | PopoverRoot G-P1 chrome | brand · mode · strip · heroes 63/57 · chips · Refresh | **Verdict: Pass** |
| popover-anthropic | html/popover-anthropic-*.png | same chrome | Anthropic focus; heroes | **Verdict: Pass** |
| usage-overview | html/usage-overview-*.png | OverviewListView + window | inventory 12/57/0/100; Browse chrome | **Verdict: Pass** |
| usage-provider-nest | html/usage-provider-nest-*.png | nest unit + window sidebar | OpenAI identity; 57% + **0% empty** | **Verdict: Pass** |
| usage-detail-openai | html/usage-detail-openai-*.png | detail head + card + window | identity head; Open usage; Limit Reset | **Verdict: Pass** |
| usage-toolbar | html/usage-toolbar-*.png | UsageWindowController crop | real unified toolbar | **Verdict: Pass** |
| ctx-menu | hub mock | model/harness only | live PNG **BLOCKED** | Pass rows / live BLOCKED |

Delta files: `advisor-plans/qi-artifacts/deltas/2026-08-10-<scene>.md` each end with `Verdict: Pass` (ctx-menu notes live BLOCKED).

## Interactions

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focuses provider | Pass | StatusPopoverFocus + live popovers + SoT harness |
| Right-click 3 rows enabled | Pass (model) / live PNG BLOCKED | StatusItemMenu + SoT harness; BLOCKED.txt |
| Overview multi-account | Pass | OverviewInventory + PNGs |
| Nest meters 0%/57%/100% | Pass | SoT meter fractions + window/nest PNGs |
| Open usage URLs | Pass | ProviderUsageLinks complete |
| App launch under Xcode | Pass | release JackinDesktop launched |

## High residual

**None** for G-P1 / G-U2 / detail-head / required §5 scenes.  

Remaining **Med/Low only**: system accent vs phosphor; Refresh footer vs HTML “Open Usage Window” (product law FB1/LG-A8); system toolbar title leading; live ctx-menu screenshot BLOCKED.

## Automated gates (this verification pass)

- `check_usage_liquid_glass.py` PASS  
- DesktopArchitectureLint ALL PASS  
- DesktopSoTParityHarness ×3 ALL PASS  
- DesktopParityMatrixHarness ALL PASS  
- StatusItemChipHarness ALL PASS  
- glass/limits grep: none outside GlassFallbacks  

## Artifacts

- `advisor-plans/qi-artifacts/html/*`  
- `advisor-plans/qi-artifacts/native/*` (incl. live status/popover; usage-window-*; `ctx-menu-live-dark.BLOCKED.txt`)  
- `advisor-plans/qi-artifacts/deltas/2026-08-10-*.md`  
