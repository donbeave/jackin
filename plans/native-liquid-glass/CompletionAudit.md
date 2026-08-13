# Native Liquid Glass completion audit

Status: **complete**

This ledger applies the original objective's DONE criteria to current authoritative evidence. A row is `PROVEN` only when its required evidence matches the final pushed branch head. Earlier captures, tests run from a dirty tree, or a plausible implementation do not count as final proof.

## Product and design authority

| Criterion | Status | Authoritative evidence |
|---|---|---|
| Operator approved a design direction | PROVEN | [`DecisionLog.md`](DecisionLog.md), D-001: operator selected A1. |
| Operator confirmed the runnable native concept | PROVEN | [`DecisionLog.md`](DecisionLog.md), D-004 records `I confirm the runnable A1 native concept.` |
| Both native surfaces implement the confirmed design | PROVEN | Clean pushed source `c69a237b0b80c62164df34a39edd6578d78d81c9`, 36 core captures, eight accessibility captures, and 15/15 real-host tests cover the Usage window and provider popover. |
| Visible regions are classified NATIVE, NATIVE-COMPOSED, or approved CUSTOM | PROVEN | [`NativeComponentMap.md`](NativeComponentMap.md); approved CUSTOM count is zero. |
| Visible regions are classified CONTENT or FUNCTIONAL | PROVEN | [`LayerMap.md`](LayerMap.md). |
| No HTML/CSS material recipe remains authoritative | PROVEN | [`README.md`](README.md), [`DRIFT_REPORT.md`](DRIFT_REPORT.md), and native architecture tests establish live macOS rendering as authority. |

## Architecture and material

| Criterion | Status | Authoritative evidence |
|---|---|---|
| Liquid Glass exists only where justified | PROVEN | Branch-head architecture scans report zero explicit glass/material helpers; real layer-0 Usage and layer-25 popover captures show system-owned functional material only. |
| Standard components own platform behavior | PROVEN | `NSPopover`, `NavigationSplitView`, `Table`, `List`, `Form`, `Picker`, `Button`, `ProgressView`, and native menus/toolbars own behavior in source and real-host evidence. |
| No content glass or glass-on-glass remains | PROVEN | Exact-source architecture tests and running captures show no app-owned material, nested material, or content glass. |
| SwiftUI remains primary architecture | PROVEN | `native/Package.swift` and `native/Sources/JackinDesktop/` use SwiftUI for visible presentation. |
| Every AppKit boundary has a current SwiftUI capability gap | PROVEN | [`NativeComponentMap.md`](NativeComponentMap.md), [`LiquidGlassAudit.md`](LiquidGlassAudit.md), and the native README limit AppKit to dynamic status items, real popover anchoring/lifecycle, retained window lifecycle, main-menu integration, and toolbar hosting. |
| Rust retains domain ownership | PROVEN | Exact-source architecture/parity tests and the canonical Rust-backed Release application preserve provider, account, quota, refresh, and string ownership. |

## Runtime, visual, and accessibility proof

| Criterion | Status | Authoritative evidence |
|---|---|---|
| All required fixtures and interaction states work | PROVEN | F00–F14 have both real surfaces captured; 68 Swift package tests plus two generated-baseline tests and 15/15 real-host tests pass at source `c69a237b` with zero runtime warnings. |
| Real captures cover the required matrix | PROVEN | [`evidence/final/`](evidence/final/) contains 36 core and eight accessibility captures with exact source/application/image hashes and `failures=0` provenance validation. |
| Accessibility audit passes | PROVEN | Branch-head real-host tests pass audits for popover, Overview, and provider detail; four real setting pairs have byte-identical restoration receipts. |
| A08 clear preference is operator-verified | PROVEN | Operator attested `Clear ready`; [`evidence/final/appearance/`](evidence/final/appearance/) contains the Clear-selected System Settings receipt plus real layer-0 Usage and layer-25 popover captures with exact source/application/image provenance. |
| A09 tinted preference is operator-verified | PROVEN | Operator attested `Tinted ready`; [`evidence/final/appearance/`](evidence/final/appearance/) contains the Tinted-selected System Settings receipt plus real layer-0 Usage and layer-25 popover captures with exact source/application/image provenance. |
| Final design review has no hard failures | PROVEN | Principal branch-head Light, Dark, inactive, collapsed, minimum, expanded, popover, maximum-content, and Reduce Transparency views were inspected against A1/D-002/D-003/D-004 and both maps; hard failures: zero. |

## Repository and delivery proof

| Criterion | Status | Authoritative evidence |
|---|---|---|
| Required project and repository gates pass at branch head | PROVEN | Final-head runs pass tool installation, deterministic generation, formatting, lint, dead-code, 251 Rust/FFI tests, 68 Swift package tests plus two generated-baseline tests, 15/15 real-host tests, build/verify, fast/full CI, and docs build/typecheck/18 tests. |
| Working tree is clean | PROVEN | Final audit finds no tracked or untracked product/evidence changes, and local HEAD matches the remote PR branch. |
| Every commit is conventional, signed off, co-authored, and pushed | PROVEN | Final history audit verifies the complete branch range; the operator-authorized DCO repair, source work, paired CI fix, and final evidence commit all carry DCO signoff plus `Co-authored-by: Codex <codex@openai.com>` and are pushed. |
| Exactly one open unmerged PR contains complete evidence | PROVEN | PR #843 is the sole open PR for the branch, remains draft and unmerged, contains the complete objective/design/architecture/evidence/test record, and has green required remote checks at final HEAD. |
| No required row remains TODO or IN PROGRESS | PROVEN | P1–P4, every required-state row, appearance restoration, branch-head verification, evidence reconciliation, and draft-PR audit are complete. |

## Final state

The confirmed A1 native design is implemented and proven on both surfaces. The original Clear preference and System Settings application state are restored. No product, design, repository, or delivery criterion remains open; external signing, notarization, release activation, and merge remain explicit non-goals without separate operator authority.
