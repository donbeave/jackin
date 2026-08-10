# VISUAL_QA_LOG — jackin❯ desktop HTML SoT parity

**Date:** 2026-08-10  
**Tip:** `1025b5b5`  
**Branch:** plan/desktop-visual  
**Authority:** UI_PARITY_MASTER §6 + QI_VERIFICATION L1–L4  

## Automated gates

```
check_usage_liquid_glass.py PASS
check_qi_evidence_ledger.py PASS
DesktopArchitectureLint ALL PASS
DesktopSoTParityHarness ALL PASS ×3
DesktopParityMatrixHarness ALL PASS
StatusItemChipHarness / ProviderMarks ALL PASS
usage_window_openai_dark/light: STRUCTURAL_INACTIVE
usage_toolbar_dark/light: readable inactive window-ID crops
```

Log: `qi-artifacts/native/desktop-gates.log`

## §6 matrix — Dark / Light

| Scene | Dark | Light | High residual | Verdict |
|-------|------|-------|---------------|---------|
| status-desktop | Pass | Pass | none | dual-stack mono |
| popover-openai | Pass | Pass | none | G-P3 meter-last |
| popover-anthropic | Pass | Pass | none | multi-limit + G-P3 |
| popover-overview | Pass | Pass | none | inventory |
| usage-overview | Pass | Pass | none | component |
| usage-provider-nest | Pass | Pass | none | 57%/0% |
| usage-detail-openai | Pass | Pass | none | G-P3 component |
| usage-toolbar | Pass | Pass | none | readable Refresh D+L |

**High residual craft product: none known. Active full-window evidence remains blocked.**

Re-audit closed false-pass primary-control deltas: Usage “Open usage page” now
uses oracle’s quiet tint + 0.5 pt hairline instead of solid phosphor; popover
footer CTA now matches centered phosphor glyph/label composition.

Re-audit also promoted Usage toolbar title placement from false-pass “leading”
to oracle parity: centered `jackin❯ desktop`, phosphor chevron, native principal
toolbar item. Dark/light full-window and toolbar captures refreshed.

Popover detail re-audit removed another false-pass: anonymous text-only header
and Usage-window chevron replaced by HTML’s official provider plate + local
refresh control. Official usage link now uses explicit external-link arrow.

Account-strip re-audit mapped HTML `--jk` / `--jk-ink` exactly by theme:
bright Dark selection uses dark ink; deep Light selection uses white ink. This
removes the prior white-on-bright-green mismatch.

Popover geometry re-audit replaced generic 12 pt cards / 28 pt rounded heroes
with HTML’s 14 pt content-card geometry and 32 pt monospaced metrics. Overview
groups and every provider block now share those named tokens.

Usage-detail re-audit corrected a structural false-pass: repeated Rust buckets
no longer create separate floating cards. One inset limit-list now owns all
quota rows and full-width dividers, including structured Limit Reset Credits,
matching the HTML oracle in deterministic dark/light component captures.

Full-window evidence re-audit corrected another false-pass: the harness had
accepted byte-identical Dark/Light window images. It now applies appearance to
the `NSWindow` explicitly and rejects identical theme pairs. New theme-distinct
component captures prove the floating sidebar roles, centered toolbar, and
single divided limit-list together.

Account-nest re-audit removed full-width repeated List rows. One shared,
labeled inset rail now owns both accounts, its hairline, and selected-account
fill in the live sidebar and QI component. This also removes duplicate SwiftUI
implementations that had allowed product and evidence to drift.

Popover Overview re-audit added its previously missing HTML Dark/Light oracle
captures and exposed several false passes. Native now follows canonical
OpenAI/Anthropic/Amp catalog order, shows Codex/Claude/Daily provider roles
instead of account subscription plans, removes fixture-only Anthropic Work,
uses horizontal divided group anatomy, 22 pt metrics, and one shared 28 pt
phosphor refresh control. Status burn-first order remains separate and intact.

Usage Overview re-audit corrected its prior structural false-pass. Native now
includes oracle page identity and groups all accounts inside one bordered,
divided inventory list. Rows use oracle 13/12/22 pt hierarchy, reset-before-meter
order, and one row-level hit target; architecture lint forbids floating row cards.

Full-window evidence re-audit found a more severe capture false-pass: coordinate
region capture had promoted an unrelated Telegram window. Harness now forbids
region capture and targets `NSWindow.windowNumber` only. Correct captures exposed
and fixed monochrome provider plates plus collapsed missing-reset row geometry.
Dark/Light full-shell captures are retained as structurally valid inactive
evidence, not active craft proof.

## Live
popover-live / ctx-menu **BLOCKED** — SoTParity proves focus/menu.

Agent sign-off: G-P3 Pass; multi-limit Pass; active full-window craft BLOCKED.
