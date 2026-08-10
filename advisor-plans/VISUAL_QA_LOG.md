# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6 (17F113) · Swift 6.3.3  
**Last full verification re-run:** 2026-08-10 (L1/L2 green · dual-image §5 Pass · live BLOCKED honest)
**Authority:** `qi-artifacts/EVIDENCE_LEDGER.toml` + dual-image §7.2/7.3  

## Craft closed (skeptic Highs)

| Gap | Resolution |
|-----|------------|
| Healthy severity / CTAs system blue | Phosphor `#5CF07A` / `#0B774E` via `JackinBrand` / `severityTint` default |
| Nest 57% greenwash | `UsageAccountMiniMeter(percent:severity:)` + a-pct → **warn orange** for mid 57% |
| Footer / brand / Open Usage | Phosphor chrome (FB1-43 / VS-13 / LG-A9) |

## Dual-image matrix — required §5 scenes (personal read)

| Scene | Dark | Light | High residual | Color / craft note | Verdict |
|-------|------|-------|---------------|--------------------|---------|
| status-desktop | yes | yes | none | template mono dual-stack (FB1-6) | **Pass** (harness) |
| popover-openai | yes | yes | none | G-P1 full shell; phosphor brand/CTA; ACCOUNT; Open Usage Window | **Pass** (harness) |
| popover-anthropic | yes | yes | none | same IA; 74% phosphor session | **Pass** (harness) |
| usage-overview | yes | yes | none | 12% red · 57% orange · 0% empty · 100% phosphor | **Pass** (harness) |
| usage-provider-nest | yes | yes | none | **57% mid orange** a-pct+meter; 0% empty | **Pass** (harness) |
| usage-detail-openai | yes | yes | none | Session green / Weekly orange severityTint | **Pass** (harness) |
| usage-toolbar | yes | yes | none | real NSToolbar titlebar crop | **Pass** (harness) |

**High residual craft scenes: none.**

## Live / interaction tiers (ledger)

| Scene | Verdict | Evidence |
|-------|---------|----------|
| popover-live-click | **BLOCKED** | `native/popover-live.BLOCKED.txt` · empty probe/keychain; craft = harness popovers |
| ctx-menu-live | **BLOCKED** | `native/ctx-menu-live-dark.BLOCKED.txt` · Accessibility; rows = SoT + StatusItemMenuModel |
| status-desktop-live-extras | optional live file | primary dual-stack = harness status-desktop |

Live re-attempt 2026-08-10: JackinDesktop accessory **RUNNING**, menubar capture has **no fixture multi-provider strip** (empty production probe) — not craft Pass.

## Interactions (wired + harness)

| Flow | Result |
|------|--------|
| Left-click focus | Pass — StatusPopoverFocus + DesktopSoTParityHarness |
| Right-click 3 rows | Pass — StatusItemMenuModel + SoT ×3 |
| Nest 0%/57% | Pass — SoT meters + dual-image orange mid |
| Open Usage Window dock | Pass — PopoverFooter FB1-43 |

## Automated gates (2026-08-10)

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS — 15 pass rows, 2 blocked
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ×3 ALL PASS
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS
glassEffect only GlassFallbacks; no spend/price UI strings
swift test 44/44 PASS (incl. nest severity bands)
```

## Artifacts

- HTML: `advisor-plans/qi-artifacts/html/*`
- Native harness: `advisor-plans/qi-artifacts/native/{status,popover,usage}-*.png`
- Deltas: `advisor-plans/qi-artifacts/deltas/2026-08-10-*.md` — all **Verdict: Pass**
- Live BLOCKED notes: `popover-live.BLOCKED.txt`, `ctx-menu-live-dark.BLOCKED.txt`
