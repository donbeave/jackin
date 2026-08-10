# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** `7b760a7e`  
**Branch:** plan/desktop-visual  
**Authority:** UI_PARITY_MASTER §6 + QI_VERIFICATION L1–L4  
**Artifacts:** `advisor-plans/qi-artifacts/`

## Automated gates (L1–L2)

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS — 16 pass / 3 blocked
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ALL PASS (18/18)
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS
ProviderMarksHarness ALL PASS (7/7 maxA)
DesktopVisualSnapshotHarness: usage_toolbar_dark BLOCKED; light OK
```

Log: `qi-artifacts/native/desktop-gates.log`

## §6 matrix — Dark / Light

| Scene | Dark | Light | High residual craft | Evidence | Verdict |
|-------|------|-------|---------------------|----------|---------|
| status-desktop | yes | yes | none | native/status-desktop-*.png · deltas/…-status-desktop.md | **Pass** |
| popover-openai | yes | yes | none | native/popover-openai-*.png | **Pass** |
| popover-anthropic | yes | yes | none | native/popover-anthropic-*.png | **Pass** |
| popover-overview | yes | yes | none | native/popover-overview-*.png | **Pass** |
| usage-overview | yes | yes | none | native/usage-overview-*.png | **Pass** |
| usage-provider-nest | yes | yes | none | native/usage-provider-nest-*.png · 57%/0% | **Pass** |
| usage-detail-openai | yes | yes | none | native/usage-detail-openai-*.png | **Pass** |
| usage-toolbar | **BLOCKED** | yes | capture only | Light PNG · Dark `usage-toolbar-dark.BLOCKED.txt` | **Light Pass / Dark BLOCKED** |

**High residual craft product: none.**  
Dark usage-toolbar = capture BLOCKED (white-blob SF Symbols) — not claimed Pass. G-U1 via Light + `UsageWindowRoot.toolbar` + ArchitectureLint.

## Live / interaction

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focus | Pass | StatusPopoverFocus + DesktopSoTParityHarness |
| Right-click 3 rows | Pass | StatusItemMenuModel + SoT |
| popover-live | **BLOCKED** | native/popover-live.BLOCKED.txt |
| ctx-menu live | **BLOCKED** | native/ctx-menu-live-dark.BLOCKED.txt |

## Multimodal deltas

Scene-specific under `deltas/2026-08-10-*.md` — Usage + popover rewritten (no wrong-surface boilerplate).

## Residual (honest non-Pass)

| Item | Status |
|------|--------|
| usage-toolbar Dark white blobs | **BLOCKED** |
| Usage full-window sidebar whiteout | BLOCKED · component snaps Pass |
| Live NSStatusItem | fixture StatusItemRendering |
| System  / clock | N/A |

## Definition of done

- [x] §6 no High product craft fails
- [x] L1+L2 green
- [x] GlassFallbacks-only; limits-only; brand jackin❯ desktop
- [x] Evidence + scene deltas + harness logs
- [ ] Operator L5 (optional)

Agent sign-off: QI L1–L4 craft closed; Dark toolbar BLOCKED honest (§12).
