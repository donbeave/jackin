# Native Liquid Glass completion audit

Status: **automated product proof complete; A08–A09 and final delivery proof pending**

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
| A08 clear preference is operator-verified | PENDING | macOS exposes no public preference API; operator-owned manual capture and receipt required. |
| A09 tinted preference is operator-verified | PENDING | macOS exposes no public preference API; operator-owned manual capture and receipt required. |
| Final design review has no hard failures | PROVEN | Principal branch-head Light, Dark, inactive, collapsed, minimum, expanded, popover, maximum-content, and Reduce Transparency views were inspected against A1/D-002/D-003/D-004 and both maps; hard failures: zero. |

## Repository and delivery proof

| Criterion | Status | Authoritative evidence |
|---|---|---|
| Required project and repository gates pass at branch head | PENDING | Current runs pass formatting, lint, dead-code, 251 Rust/FFI tests, 66 Swift tests, build/verify, deterministic project generation, docs build/typecheck/18 tests, and fast/full CI. Repeat after the final evidence commits. |
| Working tree is clean | PENDING | Current implementation and evidence changes are intentionally uncommitted. |
| Every commit is conventional, signed off, co-authored, and pushed | PENDING | Operator-authorized DCO repair produced signed merge `276337ce`; source and paired CI fixes are signed, co-authored, and pushed. Re-audit after remaining commits. |
| Exactly one open unmerged PR contains complete evidence | PENDING | PR #843 is the sole open draft and remains unmerged, but its body and remote checks are stale. Remote inspection found a transient mold download failure, cross-workflow prepared-artifact races, and a lock-only version-check setup bug. The paired setup fix is pushed; final remote proof remains. |
| No required row remains TODO or IN PROGRESS | PENDING | A08/A09 operator observations, post-evidence repository gates, documentation commit, and PR reconciliation remain open. |

## Current unblock sequence

1. Commit and push the branch-head evidence and documentation reconciliation.
2. Run the complete repository and documentation gates at the resulting branch head.
3. Reconcile PR #843 and its remote checks while keeping it draft and unmerged.
4. Obtain operator A08/A09 manual captures and receipts, then perform the final clean-tree audit.
