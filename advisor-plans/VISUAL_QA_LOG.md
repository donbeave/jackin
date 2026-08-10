# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** `ac389c68`+ (re-verify this session)  
**Branch:** plan/desktop-visual  
**Authority:** UI_PARITY_MASTER §6 + QI_VERIFICATION L1–L4  
**Artifacts:** `advisor-plans/qi-artifacts/`

## Automated gates (L1–L2) — re-run green

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS — 15 pass / 2 blocked
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ALL PASS (18/18)
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness ALL PASS
ProviderMarksHarness ALL PASS (7/7 maxA)
```

Log: `qi-artifacts/native/desktop-gates.log`

## §6 matrix — Dark / Light (no High fails)

| Scene | Dark | Light | High residual | Evidence | Verdict |
|-------|------|-------|---------------|----------|---------|
| status-desktop | yes | yes | none | native/status-desktop-*.png · deltas/…-status-desktop.md | **Pass** |
| popover-openai | yes | yes | none | native/popover-openai-*.png · dual-image Session/Weekly meters | **Pass** |
| popover-anthropic | yes | yes | none | native/popover-anthropic-*.png | **Pass** |
| popover-overview | yes | yes | none | native/popover-overview-*.png · inventory + OV-5 calendar | **Pass** |
| usage-overview | yes | yes | none | native/usage-overview-*.png | **Pass** |
| usage-provider-nest | yes | yes | none | native/usage-provider-nest-*.png · 57% mid / 0% empty | **Pass** |
| usage-detail-openai | yes | yes | none | native/usage-detail-openai-*.png · Session/Weekly/Spark/LRC | **Pass** |
| usage-toolbar | yes | yes | none | native/usage-toolbar-*.png | **Pass** |

**High residual craft: none.**

## Live / interaction

| Flow | Result | Evidence |
|------|--------|----------|
| Left-click focus | Pass | StatusPopoverFocus + DesktopSoTParityHarness |
| Right-click 3 rows | Pass | StatusItemMenuModel + SoT |
| popover-live click | **BLOCKED** | native/popover-live.BLOCKED.txt · craft=harness |
| ctx-menu live | **BLOCKED** | native/ctx-menu-live-dark.BLOCKED.txt |

## Multimodal deltas

All craft scenes under `deltas/2026-08-10-*.md` → **Verdict: Pass**

## Residual (not High craft fails)

| Item | Status |
|------|--------|
| Usage full-window glass sidebar whiteout | BLOCKED · structural nest/detail/overview/toolbar |
| SB-5 bar urgency color | partial · FB1-6 mono; SB-P4 OPEN |
| Live NSStatusItem Screen Recording | fixture StatusItemRendering |
| System  / clock | N/A system chrome |

## Definition of done (§13)

- [x] §6 matrix Dark+Light no High fails (craft scenes)
- [x] §7 automated gates green
- [x] No glass outside GlassFallbacks; limits-only
- [x] DATA_CONTRACT fixture consistency (harness QI fixtures)
- [x] VISUAL_QA_LOG + deltas + snaps in qi-artifacts
- [ ] Operator human sign-off (optional L5)

Agent sign-off: QI L1–L4 complete for HTML SoT craft parity (harness captures + dual-image). Live menu-bar/popover click remains BLOCKED on CLT — not claimed Pass.
