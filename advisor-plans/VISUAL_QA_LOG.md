# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6  
**Authority:** `EVIDENCE_LEDGER.toml` + dual-image §7.2/7.3  

## Craft closed this pass (evaluator Med gaps)

| Gap | Resolution |
|-----|------------|
| Footer CTA | **Open Usage Window** glass dock (FB1-43); ⌘R refresh invisible host (OV-9) |
| Brand plate chroma | Per-provider decorative plate fills (HTML plogo family) |
| ACCOUNT role | Account/Plan/Status/Updated/Credential card (prior) |
| SoT ×3 log | `native-unit.log` three consecutive ALL PASS |

## Dual-image matrix (personal read)

| Scene | Dark | Light | High residual | Verdict |
|-------|------|-------|---------------|---------|
| status-desktop | yes | yes | none | **Pass** |
| popover-openai | yes | yes | none | **Pass** |
| popover-anthropic | yes | yes | none | **Pass** |
| usage-overview | yes | yes | none | **Pass** |
| usage-provider-nest | yes | yes | none | **Pass** |
| usage-detail-openai | yes | yes | none | **Pass** |
| usage-toolbar | yes | yes | none | **Pass** |

## High residual

**None** for required §5 harness craft scenes.  

Live popover/ctx screenshots remain **BLOCKED** (wiring via SoT harness only) — not craft Pass claims.

## Low residual only

- SF Symbol glyphs inside brand fills vs HTML SVG marks  
- Fewer fixture account chips than HTML disabled peers  

## Interactions

| Flow | Result |
|------|--------|
| Left-click focus wiring | Pass — SoT + StatusPopoverFocus |
| Right-click 3 rows | Pass — StatusItemMenuModel + SoT ×3 |
| Nest 0%/57% | Pass — SoT meters + PNGs |
| Open Usage Window dock | Pass — PopoverFooter FB1-43 |

## Automated gates

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ×3 ALL PASS
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS
```

## Artifacts

Harness Dark+Light under `advisor-plans/qi-artifacts/native/`; deltas with **Verdict: Pass**.  
