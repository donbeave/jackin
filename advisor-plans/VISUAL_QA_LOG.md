# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** `d0fcf5ef`  
**Verification:** re-run L1/L2 green · CAPSULE_OK Session meters · ALL_PIXEL_OK · live 2 BLOCKED · app RUNNING  

**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6 (17F113) · Swift 6.3.3  
**Authority:** `qi-artifacts/EVIDENCE_LEDGER.toml` + dual-image §7.2/7.3  

## Craft closed (skeptic Highs)

| Gap | Resolution |
|-----|------------|
| Healthy chrome system blue | Phosphor via `JackinBrand` / `severityTint` |
| Nest 57% greenwash | mid → warn orange |
| status-desktop Light blank | Menu-bar stage + template tint |
| usage-toolbar/window pure black | Reject blank CGImage |
| Popover Session meter missing | track+overlay capsule; taller snap — **CAPSULE_OK y=1110** |

## Dual-image matrix — required §5

| Scene | Dark | Light | High residual | Craft note | Verdict |
|-------|------|-------|---------------|------------|---------|
| status-desktop | yes | yes | none | Icons + dual-stack readable | **Pass** |
| popover-openai | yes | yes | none | G-P1; 63% + **fill+track meter**; pace/reset | **Pass** |
| popover-anthropic | yes | yes | none | 74% + capsule meter; pace/reset | **Pass** |
| usage-overview | yes | yes | none | 12% red · 57% orange · 0% empty · 100% green | **Pass** |
| usage-provider-nest | yes | yes | none | 57% mid orange; 0% empty | **Pass** |
| usage-detail-openai | yes | yes | none | Session green · Weekly orange · Limit Reset | **Pass** |
| usage-toolbar | yes | yes | none | Real NSToolbar (**not black**) | **Pass** |

**High residual craft: none.**

## Live / interaction (ledger — 2 blocked)

| Scene | Verdict | Evidence |
|-------|---------|----------|
| popover-live-click | **BLOCKED** | `popover-live.BLOCKED.txt` · empty probe; craft=harness |
| ctx-menu-live | **BLOCKED** | `ctx-menu-live-dark.BLOCKED.txt` · A11y; rows=SoT |
| Left-click focus | **Pass** | StatusPopoverFocus + SoT |
| Right-click 3 rows | **Pass** | StatusItemMenuModel + SoT |
| Nest 0%/57% | **Pass** | dual-image |

## Automated gates

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS — 15 pass / 2 blocked
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ×3 ALL PASS
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS
SESSION_CAPSULE_METER_PROOF_OK
```

## Artifacts

- HTML / native / deltas under `advisor-plans/qi-artifacts/`
- Deltas craft scenes: **Verdict: Pass**
- Live: honest BLOCKED only (not craft Pass)
