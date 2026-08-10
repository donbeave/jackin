# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6  
**Oracle:** `plans/previews/desktop-ui/`  

## Craft fixes this round (skeptic Highs)

| ID | Fix |
|----|-----|
| G-P1 | `PopoverTabGrid`: brand · **Overview\|Providers** segment · provider strip only in Providers mode |
| G-U2 | Usage sidebar: Browse/All accounts · logo plates · selection well · nest well · Limits only footer |
| Detail head | `ProviderCardView`: logo + name + account·plan above Open usage |
| ctx-menu live PNG | Honest **BLOCKED** (blank discarded); rows via StatusItemMenuModel + SoT harness |

## Dual-image matrix

| Scene | HTML | Native (post-craft) | Verdict |
|-------|------|---------------------|---------|
| status-desktop | yes | live + StatusItemRendering | **Verdict: Pass** |
| popover-openai | yes | PopoverRoot G-P1 chrome | **Verdict: Pass** |
| popover-anthropic | yes | same chrome, Anthropic focus | **Verdict: Pass** |
| usage-overview | yes | list + CGWindow shell | **Verdict: Pass** |
| usage-provider-nest | yes | unit + window sidebar nest | **Verdict: Pass** |
| usage-detail-openai | yes | detail head + card + window | **Verdict: Pass** |
| usage-toolbar | yes | real NSToolbar crop | **Verdict: Pass** |
| ctx-menu | mock | model/harness; live PNG BLOCKED | **Pass (rows) / live BLOCKED** |

## High residual

**None remaining** for G-P1 / G-U2 / detail-head after craft.  
Live ctx-menu screenshot remains **BLOCKED** (not claimed as PNG Pass). Med only: system accent vs phosphor; Refresh footer vs HTML Open Usage Window (product law FB1/LG-A8).

## Interactions

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focus | Pass | Live popovers (prior) + selection wiring |
| Right-click 3 rows | Pass (model) / live PNG BLOCKED | SoT harness + StatusItemMenu |
| Nest 0%/57% | Pass | usage-window-openai + nest PNG |
| App launch | Pass | Xcode release binary |

## Automated gates

- check_usage_liquid_glass.py PASS  
- ArchitectureLint ALL PASS  
- SoTParity ×3 ALL PASS  
- ParityMatrix ALL PASS  
- StatusItemChip ALL PASS  

## Artifacts

- `advisor-plans/qi-artifacts/{html,native,deltas}/`  
- `ctx-menu-live-dark.BLOCKED.txt`  
