# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6  
**Authority:** `EVIDENCE_LEDGER.toml` + dual-image §7.2/7.3  

## Craft closed this pass (skeptic High color)

| Gap | Resolution |
|-----|------------|
| Healthy severity / CTAs system blue | **Phosphor** `#5CF07A` dark / `#0B774E` light via `JackinBrand` / `Color.jackinPhosphor`; `severityTint` default no longer `Color.accentColor` |
| Nest 57% always phosphor (greenwash) | `UsageAccountMiniMeter` + a-pct use `account.meterSeverity` / `severityTint`; 57% → **warn orange** (HTML mid); 0% empty; unit `testRemainingPercentMeterSeverityMatchesHTMLNestBands` |
| Brand mark / chevron / selection / Open Usage | All map to phosphor (LG-A9 / VS-13 / FB1-43) |
| Footer CTA | **Open Usage Window** glass dock + phosphor hairline (FB1-43); ⌘R refresh invisible host (OV-9) |
| Brand plate chroma | Per-provider decorative plate fills (HTML plogo family) |
| ACCOUNT role | Account/Plan/Status/Updated/Credential card |
| SoT ×3 log | scratch `sot-x3.log` three consecutive ALL PASS |

## Dual-image matrix (personal read post-phosphor)

| Scene | Dark | Light | High residual | Color roles | Verdict |
|-------|------|-------|---------------|-------------|---------|
| status-desktop | yes | yes | none | template mono (FB1-6) | **Pass** |
| popover-openai | yes | yes | none | phosphor brand/CTA/meters; warn orange when fixture | **Pass** |
| popover-anthropic | yes | yes | none | same phosphor system | **Pass** |
| usage-overview | yes | yes | none | red/orange/green severity Tint map | **Pass** |
| usage-provider-nest | yes | yes | none | nest 0% empty / **57% mid orange** mini + a-pct | **Pass** |
| usage-detail-openai | yes | yes | none | healthy green · warn orange meters | **Pass** |
| usage-toolbar | yes | yes | none | system traffic + Refresh only | **Pass** |

## High residual

**None** for required §5 harness craft scenes after phosphor mapping.  

Live multi-provider status-item / live popover screencapture remain **BLOCKED** (documented in ledger) — not craft Pass claims.

## Low residual only

- SF Symbol glyphs inside brand fills vs HTML SVG marks  
- Fewer fixture account chips than HTML disabled peers  
- HTML footer often solid phosphor slab; native = glass capsule + phosphor stroke (FB1-43 intentional)

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
swift test ArchitectureTests phosphor+severity PASS
```

## Artifacts

Harness Dark+Light re-snapped under `advisor-plans/qi-artifacts/native/` after phosphor fix; deltas **Verdict: Pass** with Color dimension scored against HTML `--jk` / `--status-high`.
