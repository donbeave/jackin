# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Branch:** plan/desktop-visual  
**Toolchain:** Xcode 26.6  
**Authority:** `advisor-plans/qi-artifacts/EVIDENCE_LEDGER.toml`  
**Lint:** `python3 plans/previews/desktop-ui/qi/check_qi_evidence_ledger.py`

## Skeptic fix (this round)

| Flag | Resolution |
|------|------------|
| SoT harness log only 1 run | `{SCRATCH}/native-unit.log` now has **3** consecutive ALL PASS blocks |
| Popover missing ACCOUNT role | `PopoverProviderTab.accountMetaBlock` — Account/Plan/Status/Updated/Credential |
| Bare SF strip | `PopoverTabGrid.brandPlate` rounded identity plates |
| Rubber-stamp deltas | Popover deltas re-scored with §7.3 table + Med residuals |
| High residual: None (false) | Residual table lists **Med** craft deltas (footer CTA, plate chroma) — not High IA |

## Dual-image matrix (harness craft)

| Scene | Dark+Light | Dual-image | Verdict |
|-------|------------|------------|---------|
| status-desktop | harness | dual-stack API | **Pass** |
| popover-openai | harness | ACCOUNT+G-P1 present | **Pass** |
| popover-anthropic | harness | same chrome | **Pass** |
| usage-overview | harness | inventory | **Pass** |
| usage-provider-nest | harness | 0% empty | **Pass** |
| usage-detail-openai | harness | detail head | **Pass** |
| usage-toolbar | harness | real NSToolbar | **Pass** |
| popover-live-click | blocked | — | **BLOCKED** |
| ctx-menu-live | blocked | — | **BLOCKED** |

## Residual (not High IA)

| Severity | Item | Notes |
|----------|------|-------|
| Med | Footer Open Usage Window vs Refresh | Product law FB1/LG-A8 — Refresh kept |
| Med | Multi-brand plogo colors vs SF plates | Native system SF + accent plates |
| Low | Chip % + fewer disabled peers | Accept |
| Blocked | Live popover/ctx PNGs | `*.BLOCKED.txt`; wiring via harnesses |

## Interactions

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focus wiring | Pass | StatusPopoverFocus + SoT |
| Right-click 3 rows | Pass (model) | StatusItemMenuModel + SoT ×3 |
| Nest 0%/57% | Pass | SoT meters + nest PNG |
| App launch | Pass | app-launch.log under Xcode |

## Automated gates

- check_usage_liquid_glass.py PASS  
- check_qi_evidence_ledger.py PASS  
- ArchitectureLint ALL PASS  
- DesktopSoTParityHarness ×3 ALL PASS (`native-unit.log`)  
- ParityMatrix ALL PASS  
- StatusItemChip ALL PASS  

## Artifacts

- Ledger + deltas under `advisor-plans/qi-artifacts/`  
- ACCOUNT craft visible in `native/popover-openai-dark.png`  
