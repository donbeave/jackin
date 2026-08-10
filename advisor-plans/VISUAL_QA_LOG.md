# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** `55861dee`  
**Branch:** plan/desktop-visual  
**Authority:** UI_PARITY_MASTER §6 + QI_VERIFICATION L1–L4  
**Artifacts:** `advisor-plans/qi-artifacts/`

## Automated gates (L1–L2)

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS — 16 pass / 3 blocked
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ALL PASS
DesktopParityMatrixHarness ALL PASS
```

Log: `qi-artifacts/native/desktop-gates.log`

## §6 matrix — Dark / Light (dual-image read)

| Scene | Dark | Light | High residual | Evidence | Verdict |
|-------|------|-------|---------------|----------|---------|
| status-desktop | yes | yes | none | html+native · deltas/…-status-desktop.md | **Pass** |
| popover-openai | yes | yes | none | html+native · deltas/…-popover-openai.md | **Pass** |
| popover-anthropic | yes | yes | none | full multi-limit · deltas/…-popover-anthropic.md | **Pass** |
| popover-overview | yes | yes | none | native · deltas/…-popover-overview.md | **Pass** |
| usage-overview | yes | yes | none | html+native · deltas/…-usage-overview.md | **Pass** |
| usage-provider-nest | yes | yes | none | 57%/0% · deltas/…-usage-provider-nest.md | **Pass** |
| usage-detail-openai | yes | yes | none | html+native · deltas/…-usage-detail-openai.md | **Pass** |
| usage-toolbar | **BLOCKED** | yes | capture only | Light PNG · Dark BLOCKED.txt · deltas/…-usage-toolbar.md | **Light Pass / Dark BLOCKED** |

**High residual craft product: none.**

## Live

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focus | Pass | StatusPopoverFocus + SoTParity |
| Right-click 3 rows | Pass | StatusItemMenuModel + SoT |
| popover-live | **BLOCKED** | popover-live.BLOCKED.txt |
| ctx-menu live | **BLOCKED** | ctx-menu-live-dark.BLOCKED.txt |

## Multimodal

Every craft scene dual-read HTML+native; scene-specific QI §7.2 deltas with Severity table + Verdict.

Agent sign-off: QI L1–L4 craft closed; Dark toolbar BLOCKED (§12); Anthropic multi-limit Pass.
