# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** post-toolbar-honesty (see git log)  
**Branch:** plan/desktop-visual  
**Authority:** UI_PARITY_MASTER §6 + QI_VERIFICATION L1–L4  
**Artifacts:** `advisor-plans/qi-artifacts/`

## Automated gates (L1–L2)

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ALL PASS (18/18)
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS
ProviderMarksHarness ALL PASS (7/7 maxA)
DesktopVisualSnapshotHarness: usage_toolbar_dark BLOCKED (white-blob gate); light OK
```

Log: `qi-artifacts/native/desktop-gates.log`

## §6 matrix — Dark / Light

| Scene | Dark | Light | High residual craft | Evidence | Verdict |
|-------|------|-------|---------------------|----------|---------|
| status-desktop | yes | yes | none | native/status-desktop-*.png · deltas/…-status-desktop.md | **Pass** |
| popover-openai | yes | yes | none | native/popover-openai-*.png | **Pass** |
| popover-anthropic | yes | yes | none | native/popover-anthropic-*.png | **Pass** |
| popover-overview | yes | yes | none | native/popover-overview-*.png | **Pass** |
| usage-overview | yes | yes | none | native/usage-overview-*.png · scene delta | **Pass** |
| usage-provider-nest | yes | yes | none | native/usage-provider-nest-*.png · 57%/0% | **Pass** |
| usage-detail-openai | yes | yes | none | native/usage-detail-openai-*.png | **Pass** |
| usage-toolbar | **BLOCKED** | yes | capture only (not product High) | Light: native/usage-toolbar-light.png · Dark: usage-toolbar-dark.BLOCKED.txt | **Light Pass / Dark BLOCKED** |

**High residual craft product: none.**  
Dark usage-toolbar is **BLOCKED** (view-bitmap SF Symbol white disks) — not claimed Pass. G-U1 icon Refresh proven by Light crop + `UsageWindowRoot.toolbar` + ArchitectureLint.

## Live / interaction

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focus | Pass | StatusPopoverFocus + DesktopSoTParityHarness |
| Right-click 3 rows | Pass | StatusItemMenuModel + SoT |
| popover-live click | **BLOCKED** | native/popover-live.BLOCKED.txt |
| ctx-menu live | **BLOCKED** | native/ctx-menu-live-dark.BLOCKED.txt |

## Multimodal deltas

Scene-specific deltas under `deltas/2026-08-10-*.md` (Usage scenes rewritten — no status/popover boilerplate).

## Residual (not invent Pass)

| Item | Status |
|------|--------|
| usage-toolbar Dark white blobs | **BLOCKED** harness gate |
| Usage full-window sidebar whiteout | BLOCKED · component nest/detail/overview Pass |
| Live NSStatusItem | fixture StatusItemRendering |
| System  / clock | N/A system chrome |

## Definition of done

- [x] §6 craft matrix no High product fails (Dark toolbar capture BLOCKED honest)
- [x] §7 automated gates green
- [x] GlassFallbacks-only; limits-only; brand jackin❯ desktop
- [x] Evidence + deltas + harness logs
- [ ] Operator L5 (optional)

Agent sign-off: QI L1–L4 craft closed with honest Dark toolbar BLOCKED.
