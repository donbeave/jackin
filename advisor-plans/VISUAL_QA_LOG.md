# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** `e227f37f`  
**Branch:** plan/desktop-visual  
**Authority:** UI_PARITY_MASTER §6 + QI_VERIFICATION L1–L4  
**Artifacts:** `advisor-plans/qi-artifacts/`

## Automated gates (L1–L2)

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS — 16 pass / 3 blocked
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ALL PASS ×3 (18/18)
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS
ProviderMarksHarness ALL PASS (7/7 maxA)
DesktopVisualSnapshotHarness: usage_toolbar_dark BLOCKED; light OK
```

Log: `qi-artifacts/native/desktop-gates.log`

## §6 matrix — Dark / Light

| Scene | Dark | Light | High residual craft | Evidence | Verdict |
|-------|------|-------|---------------------|----------|---------|
| status-desktop | yes | yes | none | html+native/status-desktop-*.png | **Pass** |
| popover-openai | yes | yes | none | html+native/popover-openai-*.png | **Pass** |
| popover-anthropic | yes | yes | none | html+native/popover-anthropic-*.png | **Pass** |
| popover-overview | yes | yes | none | native/popover-overview-*.png | **Pass** |
| usage-overview | yes | yes | none | html+native/usage-overview-*.png | **Pass** |
| usage-provider-nest | yes | yes | none | nest 57%/0% | **Pass** |
| usage-detail-openai | yes | yes | none | detail 63/57/88 | **Pass** |
| usage-toolbar | **BLOCKED** | yes | capture only | Light PNG · Dark BLOCKED.txt | **Light Pass / Dark BLOCKED** |

**High residual craft product: none.**

## Live / interaction

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focus | Pass | StatusPopoverFocus + SoTParity |
| Right-click 3 rows | Pass | StatusItemMenuModel + SoT |
| popover-live | **BLOCKED** | popover-live.BLOCKED.txt |
| ctx-menu live | **BLOCKED** | ctx-menu-live-dark.BLOCKED.txt |

## Multimodal

Scene-specific deltas `deltas/2026-08-10-*.md`. Dual-image notes in scratch `deltas/multimodal-verify.md`.

Agent sign-off: QI L1–L4 craft closed; Dark toolbar BLOCKED (§12).
