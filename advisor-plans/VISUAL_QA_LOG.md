# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6  
**Authority:** `advisor-plans/qi-artifacts/EVIDENCE_LEDGER.toml`  
**Lint:** `python3 plans/previews/desktop-ui/qi/check_qi_evidence_ledger.py`

## Capture policy

| Tier | Meaning |
|------|---------|
| **harness** | `DesktopVisualSnapshotHarness` / StatusItemRendering / UsageWindowController — craft dual-image Pass |
| **live** | On-disk live screencapture accepted only if ledger row + file exist |
| **blocked** | No craft Pass; `*.BLOCKED.txt` + interaction/harness wiring only |

## Matrix (from ledger)

| Scene | Dark | Light | Tier | Verdict |
|-------|------|-------|------|---------|
| status-desktop | status-desktop-dark.png | status-desktop-light.png | harness | **Pass** |
| popover-openai | popover-openai-dark.png | popover-openai-light.png | harness | **Pass** |
| popover-anthropic | popover-anthropic-dark.png | popover-anthropic-light.png | harness | **Pass** |
| usage-overview | usage-overview-*.png | same | harness | **Pass** |
| usage-provider-nest | usage-provider-nest-*.png | same | harness | **Pass** |
| usage-detail-openai | usage-detail-openai-*.png | same | harness | **Pass** |
| usage-toolbar | usage-toolbar-*.png | same | harness | **Pass** |
| popover-live-click | — | — | blocked | **BLOCKED** |
| ctx-menu-live | — | — | blocked | **BLOCKED** |

Left-click **craft** evidence = harness PopoverRoot Dark+Light only.  
Left-click **wiring** = StatusPopoverFocus + DesktopSoTParityHarness (not a live PNG).

## Interactions

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focuses provider | Pass (wiring) | SoT harness; craft = harness popover PNGs |
| Right-click 3 rows | Pass (model) | StatusItemMenuModel + SoT; live PNG BLOCKED |
| Nest 0%/57%/100% | Pass | SoT meter fractions + nest/window harness PNGs |
| Open usage URLs | Pass | ProviderUsageLinks harness |

## High residual

None for ledger `pass` scenes. Live popover/ctx screenshots remain **blocked**.

## Automated gates

```sh
python3 plans/previews/desktop-ui/check_usage_liquid_glass.py
python3 plans/previews/desktop-ui/qi/check_qi_evidence_ledger.py
cd native && swift run -c release DesktopArchitectureLint
swift run -c release DesktopSoTParityHarness   # ×3
swift run -c release DesktopParityMatrixHarness
swift run -c release StatusItemChipHarness
```

## Artifacts

- Ledger: `qi-artifacts/EVIDENCE_LEDGER.toml`  
- Deltas: `qi-artifacts/deltas/2026-08-10-*.md`  
- BLOCKED notes: `popover-live.BLOCKED.txt`, `ctx-menu-live-dark.BLOCKED.txt`  
