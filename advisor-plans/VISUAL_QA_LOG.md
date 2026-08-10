# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6  

## Skeptic light-popover + live IA fix (this round)

| Issue | Resolution |
|-------|------------|
| Light popover black void / missing G-P1 | Fixed: opaque `windowBackgroundColor` base under glass; light stage + taller frame; mode segment controlBackground. Recaptured light OpenAI/Anthropic. |
| Live popover PNG pre-G-P1 / contaminated | Live re-capture post-rebuild empty + keychain noise — **removed from artifacts**; `popover-live.BLOCKED.txt`. G-P1 craft evidence = **harness Dark+Light only**. |
| Dishonest dual-image Pass | Re-opened dual-image for light; Pass only after full chrome readable on light. |

## Dual-image matrix

| Scene | Dark | Light | Dual-image | Verdict |
|-------|------|-------|------------|---------|
| status-desktop | harness + live extras prior | harness | yes | **Verdict: Pass** |
| popover-openai | harness G-P1 | harness G-P1 full chrome | yes | **Verdict: Pass** |
| popover-anthropic | harness G-P1 | harness G-P1 full chrome | yes | **Verdict: Pass** |
| usage-overview | yes | yes | yes | **Verdict: Pass** |
| usage-provider-nest | yes | yes | yes | **Verdict: Pass** |
| usage-detail-openai | yes | yes | yes | **Verdict: Pass** |
| usage-toolbar | yes | yes | yes | **Verdict: Pass** |
| popover live click | — | — | BLOCKED | interaction harness only |
| ctx-menu live | — | — | BLOCKED | model/harness rows |

## High residual

**None** for required §5 harness scenes Dark+Light.  

Live left-click craft PNG **BLOCKED** (empty probe/keychain) — not claimed Pass. Focus wiring still Pass via SoT harness.

## Automated gates

- check_usage_liquid_glass.py PASS  
- ArchitectureLint ALL PASS  
- SoTParity ×3 ALL PASS  
- ParityMatrix ALL PASS  
- StatusItemChip ALL PASS  

## Artifacts

- `advisor-plans/qi-artifacts/native/popover-*-{dark,light}.png` (light fixed)  
- `advisor-plans/qi-artifacts/native/popover-live.BLOCKED.txt`  
- `advisor-plans/qi-artifacts/native/ctx-menu-live-dark.BLOCKED.txt`  
