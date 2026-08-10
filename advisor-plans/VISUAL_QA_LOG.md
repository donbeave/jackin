# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Authority:** UI_PARITY_MASTER §6 + QI_VERIFICATION L1–L4  
**Artifacts:** `advisor-plans/qi-artifacts/`

## Automated gates (L1–L2)

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ALL PASS
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS  (aligned SB-3/17/19)
ProviderMarksHarness ALL PASS (7/7 maxA)
```

## §6 matrix — Dark / Light

| Scene | Dark | Light | High residual | Verdict |
|-------|------|-------|---------------|---------|
| status-desktop | yes | yes | none | **Pass** |
| popover-openai | yes | yes | none | **Pass** |
| popover-anthropic | yes | yes | none | **Pass** |
| popover-overview | yes | yes | none | **Pass** |
| usage-overview | yes | yes | none | **Pass** |
| usage-provider-nest | yes | yes | none | **Pass** |
| usage-detail-openai | yes | yes | none | **Pass** |
| usage-toolbar | yes | yes | none | **Pass** |

**High residual craft: none.**

## Live / interaction

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focus | Pass | StatusPopoverFocus + SoT |
| Right-click 3 rows | Pass | StatusItemMenuModel + SoT |
| popover-live click | **BLOCKED** | popover-live.BLOCKED.txt |
| ctx-menu live | **BLOCKED** | ctx-menu-live-dark.BLOCKED.txt |

## Multimodal deltas

All required craft scenes: `deltas/2026-08-10-*.md` → **Verdict: Pass**

## Residual (not High craft fails)

- Usage full-window glass sidebar whiteout — structural nest/detail snaps
- SB-5 bar urgency color — partial (FB1-6 mono; SB-P4 OPEN)
- Live NSStatusItem Screen Recording — fixture StatusItemRendering

Agent sign-off: implementer QI loop complete for §6 Highs (harness + dual-image)
