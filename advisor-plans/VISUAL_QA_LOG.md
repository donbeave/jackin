# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** `1025b5b5`  
**Branch:** plan/desktop-visual  
**Authority:** UI_PARITY_MASTER §6 + QI_VERIFICATION L1–L4  

## Automated gates

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ALL PASS ×3
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness / ProviderMarks ALL PASS
usage_window_openai_dark: OK (sidebar visible)
usage_toolbar_dark: OK (readable Refresh)
```

Log: `qi-artifacts/native/desktop-gates.log`

## §6 matrix — Dark / Light

| Scene | Dark | Light | High residual | Verdict |
|-------|------|-------|---------------|---------|
| status-desktop | Pass | Pass | none | dual-stack mono |
| popover-openai | Pass | Pass | none | G-P3 meter-last |
| popover-anthropic | Pass | Pass | none | multi-limit + G-P3 |
| popover-overview | Pass | Pass | none | inventory |
| usage-overview | Pass | Pass | none | component |
| usage-provider-nest | Pass | Pass | none | 57%/0% |
| usage-detail-openai | Pass | Pass | none | G-P3 component |
| usage-toolbar | Pass | Pass | none | readable Refresh D+L |

**High residual craft product: none.**

Re-audit closed false-pass primary-control deltas: Usage “Open usage page” now
uses oracle’s quiet tint + 0.5 pt hairline instead of solid phosphor; popover
footer CTA now matches centered phosphor glyph/label composition.

Re-audit also promoted Usage toolbar title placement from false-pass “leading”
to oracle parity: centered `jackin❯ desktop`, phosphor chevron, native principal
toolbar item. Dark/light full-window and toolbar captures refreshed.

## Live
popover-live / ctx-menu **BLOCKED** — SoTParity proves focus/menu.

Agent sign-off: G-P3 Pass; multi-limit Pass; Dark toolbar Pass this capture; full-window dark shell OK this capture.
