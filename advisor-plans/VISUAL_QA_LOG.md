# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** `144ec22e`  
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
| status-desktop | yes | yes | none | dual-stack 12/57/100 | **Pass** |
| popover-openai | yes | yes | none | 63/57/88/100 + LRC | **Pass** |
| popover-anthropic | yes | yes | none | full multi-limit 74/12/28/35/28/100 + Extra | **Pass** |
| popover-overview | yes | yes | none | inventory OV-5 | **Pass** |
| usage-overview | yes | yes | none | per-account cards | **Pass** |
| usage-provider-nest | yes | yes | none | 57%/0% | **Pass** |
| usage-detail-openai | yes | yes | none | Session/Weekly/Spark/LRC | **Pass** |
| usage-toolbar | **BLOCKED** | yes | capture only | Light Refresh · Dark BLOCKED.txt | **Light Pass / Dark BLOCKED** |

**High residual craft product: none.**

## Live

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focus | Pass | StatusPopoverFocus + SoTParity |
| Right-click 3 rows | Pass | StatusItemMenuModel + SoT |
| popover-live | **BLOCKED** | popover-live.BLOCKED.txt |
| ctx-menu live | **BLOCKED** | ctx-menu-live-dark.BLOCKED.txt |

## Multimodal

Scene deltas: `deltas/2026-08-10-*.md`. Anthropic multi-limit: `deltas/2026-08-10-popover-anthropic.md` Verdict Pass.

Agent sign-off: QI L1–L4 craft closed; Dark toolbar BLOCKED (§12); Anthropic multi-limit density Pass.
