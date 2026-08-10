# Parity matrix — plan/desktop-visual (2026-08-10 verification re-run)

## Criteria 1 — status / popover / menu
| Item | Status | Evidence |
|------|--------|----------|
| Template mono dual-stack | Pass | status-desktop harness PNG + StatusItemChipHarness |
| Full G-P1 popover | Pass | popover-openai/anthropic dual-image (brand·mode·strip·ACCOUNT·SESSION·Open Usage Window) |
| Left-click focus | Pass | StatusPopoverFocus + DesktopSoTParityHarness |
| Right-click 3 rows | Pass | SoT ×3; live PNG BLOCKED |
| Live multi-provider / live popover PNG | BLOCKED | popover-live.BLOCKED.txt |

## Criteria 2 — Usage window
| Item | Status | Evidence |
|------|--------|----------|
| Real NSToolbar | Pass | usage-toolbar + usage-window CGWindow |
| Provider ≠ account nest | Pass | nest dual-image; 57% mid orange |
| Meter 1:1 / 0% empty | Pass | SoT + PNGs |
| Open usage + Limit Reset | Pass | usage-detail dual-image |

## Criteria 3 — product / glass / color
| Item | Status | Evidence |
|------|--------|----------|
| glassEffect only GlassFallbacks | Pass | ArchLint + glass-and-limits-grep |
| Limits only | Pass | no spend/sparkline strings |
| Phosphor healthy / mid orange 57% | Pass | BrandColors + nest severity dual-image |

## High residual
None on required §5 harness craft. Live popover/ctx honest BLOCKED.
