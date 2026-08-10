# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Verification (aaac081e0708):** L1/L2 green · ALL_PIXEL_OK · dual-image critical scenes Pass · app RUNNING · live BLOCKED  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6 (17F113) · Swift 6.3.3  
**Authority:** `qi-artifacts/EVIDENCE_LEDGER.toml` + dual-image §7.2/7.3  

## Craft closed (skeptic Highs)

| Gap | Resolution |
|-----|------------|
| Healthy chrome system blue | Phosphor `#5CF07A`/`#0B774E` via `JackinBrand` / `severityTint` |
| Nest 57% greenwash | mid → warn orange (`account.meterSeverity`) |
| status-desktop Light blank | Menu-bar stage + template icon tint; measured cellW |
| usage-toolbar/window pure black | Reject blank CGImage; restore non-blank CGWindow craft |

## Dual-image matrix — required §5 (personal read HTML + native)

| Scene | Dark | Light | High residual | Craft note | Verdict |
|-------|------|-------|---------------|------------|---------|
| status-desktop | yes | yes | none | Icons + dual-stack 1h/12% · 3d/57% · 18h/100%; Light readable | **Pass** |
| popover-openai | yes | yes | none | G-P1 full shell; ACCOUNT; 63% session; Open Usage Window; phosphor | **Pass** |
| popover-anthropic | yes | yes | none | G-P1; 74% session phosphor; Open Usage Window | **Pass** |
| usage-overview | yes | yes | none | 12% red · 57% orange · 0% empty · 100% green | **Pass** |
| usage-provider-nest | yes | yes | none | 57% **mid orange** a-pct+meter; 0% empty track | **Pass** |
| usage-detail-openai | yes | yes | none | Open usage CTA; Session green; Weekly orange; Limit Reset | **Pass** |
| usage-toolbar | yes | yes | none | Real NSToolbar title + Refresh (**not black**) | **Pass** |

**High residual craft scenes: none.**

Shell extras: `usage-window-openai` / `usage-window-overview` show nest + detail + toolbar with 57% orange nest.

## Live / interaction (ledger)

| Scene | Verdict | Evidence |
|-------|---------|----------|
| popover-live-click | **BLOCKED** | `popover-live.BLOCKED.txt` empty probe |
| ctx-menu-live | **BLOCKED** | `ctx-menu-live-dark.BLOCKED.txt` A11y |
| Left-click focus wiring | **Pass** | StatusPopoverFocus + SoT |
| Right-click 3 rows | **Pass** | StatusItemMenuModel + SoT |
| Nest 0%/57% | **Pass** | SoT + dual-image |

## Automated gates

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS — 15 pass / 2 blocked
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ×3 ALL PASS
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS
severity/phosphor unit tests PASS
Pixel proof ALL_PIXEL_OK (no solid-black required PNGs)
App launch RUNNING then clean kill
```

## Artifacts

- HTML: `advisor-plans/qi-artifacts/html/*`
- Native: `advisor-plans/qi-artifacts/native/{status,popover,usage}-*.png`
- Deltas: `advisor-plans/qi-artifacts/deltas/2026-08-10-*.md` — **Verdict: Pass** for craft scenes
