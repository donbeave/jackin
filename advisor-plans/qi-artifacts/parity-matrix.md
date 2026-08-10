# Parity matrix summary — plan/desktop-visual (2026-08-10)

## Criteria 1 — status / popover / menu
| Item | Status | Evidence |
|------|--------|----------|
| Template mono dual-stack status | Pass | StatusItemRendering harness PNG + StatusItemChipHarness |
| Full G-P1 popover (not mini) | Pass | popover-openai/anthropic harness dual-image |
| Left-click focus wiring | Pass | StatusPopoverFocus + SoT |
| Right-click Open Usage / Refresh / Quit | Pass | SoT ×3; live PNG BLOCKED |
| Live multi-provider strip / live popover PNG | BLOCKED | popover-live.BLOCKED.txt · empty probe |

## Criteria 2 — Usage window
| Item | Status | Evidence |
|------|--------|----------|
| Real NSToolbar host | Pass | usage-toolbar + usage-window CGWindow |
| Provider ≠ account nest | Pass | nest dual-image; 57% mid orange |
| Meter 1:1 / 0% empty | Pass | SoT + PNGs |
| Open usage page + Limit Reset | Pass | usage-detail dual-image |

## Criteria 3 — product / glass law
| Item | Status | Evidence |
|------|--------|----------|
| glassEffect only GlassFallbacks | Pass | ArchLint + glass-and-limits-grep |
| Limits only | Pass | parity matrix no sparkline; grep clean |
| Phosphor healthy / severity mid orange | Pass | BrandColors + nest severity dual-image |

## High residual
None on required §5 harness craft scenes. Live popover/ctx remain honest BLOCKED.
