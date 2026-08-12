# Native Liquid Glass completion audit

Status: **in progress; completion is not yet proven**

This ledger applies the original objective's DONE criteria to current authoritative evidence. A row is `PROVEN` only when its required evidence matches the final pushed branch head. Earlier captures, tests run from a dirty tree, or a plausible implementation do not count as final proof.

## Product and design authority

| Criterion | Status | Authoritative evidence |
|---|---|---|
| Operator approved a design direction | PROVEN | [`DecisionLog.md`](DecisionLog.md), D-001: operator selected A1. |
| Operator confirmed the runnable native concept | PROVEN | [`DecisionLog.md`](DecisionLog.md), D-004 records `I confirm the runnable A1 native concept.` |
| Both native surfaces implement the confirmed design | PENDING | Implementation exists under `native/Sources/JackinDesktop/`; final pushed-head runtime proof is still required. |
| Visible regions are classified NATIVE, NATIVE-COMPOSED, or approved CUSTOM | PROVEN | [`NativeComponentMap.md`](NativeComponentMap.md); approved CUSTOM count is zero. |
| Visible regions are classified CONTENT or FUNCTIONAL | PROVEN | [`LayerMap.md`](LayerMap.md). |
| No HTML/CSS material recipe remains authoritative | PROVEN | [`README.md`](README.md), [`DRIFT_REPORT.md`](DRIFT_REPORT.md), and native architecture tests establish live macOS rendering as authority. |

## Architecture and material

| Criterion | Status | Authoritative evidence |
|---|---|---|
| Liquid Glass exists only where justified | PENDING | Source scans and `DesktopArchitectureLint` report zero explicit glass/material helpers; repeat against final pushed head and final captures. |
| Standard components own platform behavior | PENDING | Current implementation uses `NSPopover`, `NavigationSplitView`, `Table`, `List`, `Form`, `Picker`, `Button`, `ProgressView`, and native menus/toolbars; final design review must confirm no hard failure. |
| No content glass or glass-on-glass remains | PENDING | Source tests pass now; final pushed-head source scan and running captures remain required. |
| SwiftUI remains primary architecture | PROVEN | `native/Package.swift` and `native/Sources/JackinDesktop/` use SwiftUI for visible presentation. |
| Every AppKit boundary has a current SwiftUI capability gap | PROVEN | [`NativeComponentMap.md`](NativeComponentMap.md), [`LiquidGlassAudit.md`](LiquidGlassAudit.md), and the native README limit AppKit to dynamic status items, real popover anchoring/lifecycle, retained window lifecycle, main-menu integration, and toolbar hosting. |
| Rust retains domain ownership | PENDING | Presentation and parity tests pass; repeat exact gates at final pushed head. |

## Runtime, visual, and accessibility proof

| Criterion | Status | Authoritative evidence |
|---|---|---|
| All required fixtures and interaction states work | PENDING | F00-F14 fixtures and focused tests exist; complete fail-closed UI suite must pass on final pushed head without runtime warnings. |
| Real captures cover the required matrix | PENDING | Existing 36 core and 8 accessibility captures predate current source changes and must be regenerated from the final clean branch head. |
| Accessibility audit passes | PENDING | Earlier popover, Overview, and provider-detail audits passed; rerun complete suite from final pushed head. |
| A08 clear preference is operator-verified | PENDING | macOS exposes no public preference API; operator-owned manual capture and receipt required. |
| A09 tinted preference is operator-verified | PENDING | macOS exposes no public preference API; operator-owned manual capture and receipt required. |
| Final design review has no hard failures | PENDING | Review must use the final running application and regenerated captures. |

## Repository and delivery proof

| Criterion | Status | Authoritative evidence |
|---|---|---|
| Required project and repository gates pass at branch head | PENDING | Current runs pass formatting, lint, dead-code, 251 Rust/FFI tests, 66 Swift tests, build/verify, deterministic project generation, docs build/typecheck/18 tests, and fast/full CI. Repeat after the final evidence commits. |
| Working tree is clean | PENDING | Current implementation and evidence changes are intentionally uncommitted. |
| Every commit is conventional, signed off, co-authored, and pushed | PENDING | Operator-authorized DCO repair produced signed merge `276337ce`; source and paired CI fixes are signed, co-authored, and pushed. Re-audit after remaining commits. |
| Exactly one open unmerged PR contains complete evidence | PENDING | PR #843 is the sole open draft and remains unmerged, but its body and remote checks are stale. Remote inspection found a transient mold download failure, cross-workflow prepared-artifact races, and a lock-only version-check setup bug. The paired setup fix is pushed; final remote proof remains. |
| No required row remains TODO or IN PROGRESS | PENDING | Final captures, A08/A09 operator observations, final UI suite, design review, documentation reconciliation, and PR reconciliation remain open. |

## Current unblock sequence

1. Commit and push this documentation reconciliation; merge the latest `main` normally.
2. Build from the clean pushed branch head; run the complete UI suite without competing foreground input.
3. Regenerate all core and accessibility captures through the fail-closed matrix scripts.
4. Obtain operator A08/A09 manual captures and receipts.
5. Complete final design review, documentation and PR reconciliation, remote checks, and a clean-tree audit.
