# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** `bc09f784`  
**Branch:** plan/desktop-visual  
**Authority:** UI_PARITY_MASTER §6 + QI_VERIFICATION L1–L4  

## Automated gates

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ALL PASS ×3
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS
usage_window_openai_dark BLOCKED (sidebar whiteout)
usage_toolbar_dark BLOCKED (white blobs)
```

## §6 matrix

| Scene | Dark | Light | High residual | Verdict |
|-------|------|-------|---------------|---------|
| status-desktop | Pass | Pass | none | dual-stack mono |
| popover-openai | Pass | Pass | none | G-P3 meter-last |
| popover-anthropic | Pass | Pass | none | multi-limit + G-P3 |
| popover-overview | Pass | Pass | none | inventory |
| usage-overview | Pass | Pass | none | component |
| usage-provider-nest | Pass | Pass | none | 57%/0% |
| usage-detail-openai | Pass | Pass | none | component |
| usage-toolbar | BLOCKED | Pass | capture | Dark blobs |
| usage-window full shell | BLOCKED | partial | whiteout | not Pass |

**High residual craft product: none** (G-P3 fixed; whiteout honest BLOCKED).

## Live
popover-live / ctx-menu **BLOCKED** — SoTParity proves focus/menu.

Agent sign-off: G-P3 anatomy Pass; full-window whiteout not claimed Pass.
