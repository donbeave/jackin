# Plan 007: Ship the native desktop usage experience

## Status
TODO

## Why this matters
The blessed prototype must become production-native behavior over shared Rust truth, not parallel Swift logic.

## Preconditions — run before anything else
Plans 001–004 DONE; read desktop spec, production mapping, prototype SIGNOFF, native rules and current FFI/store/window/popover code.

## Spec contract
Desktop sanitized bridge, status popover, Usage window, accessibility/state truth.

## Screen contract
S7–S8 and blessed dark matrix; minimum/default/wide, collapse, hover/focus, stale/unavailable, accessibility, multi-display.

## Must NOT
N1-N4, N8-N10, N14.

## Inputs to provide
Canonical V1 projection/client, boltffi generator, production native seams/assets, blessed prototype behavior/assets only.

## Starting state
Production desktop exists; prototype proves target visuals/interactions but its store/scenarios are nonproduction.

## Commands you will need
`rtk cargo test -p jackin-usage-ffi canonical_projection -- --test-threads=1`; `rtk mise run desktop-bindings-check`; `rtk mise run desktop-ci`; `rtk mise run desktop-merge`; prototype/signoff evidence commands.

## Suggested executor toolkit
boltffi, AppKit system status item/toolbar/split/popover, SwiftUI typed views, XCTest/UI tests.

## Scope
FFI DTO/bridge, Swift presentation store, status modes/popover anchoring, Usage window/sidebar/detail/rain/assets/settings handoff, accessibility and docs.

## Git workflow
Current branch/PR only. Regenerate bindings in same signed commit as Rust DTO; push immediately.

## Steps
### Step 1: Adapt canonical projection through FFI
Generate sanitized typed DTOs; remove Swift sorting/semantics/freshness ownership; keep nonblocking callbacks.
### Step 2: Implement status modes and popover
Rust ranks worst/pinned/strip; native popover uses centered logo, truthful states, Refresh/Open Usage, active secondary-display anchoring.
### Step 3: Port blessed Usage behavior
Production architecture implements dark-only grouped Overview/detail, compact account-only sidebar with per-row meters, centered logo, shared min/default/wide constants, native refresh, rain and no duplicate titles/rail.
### Step 4: Complete state/accessibility behavior
Selection normalization/removal notice, hover/focus/keyboard, collapse/live resize, inactive, reduced transparency, increased contrast, VoiceOver/localization.
### Step 5: Prove production—not prototype—matrix
Real-host screenshots/tests from one executable SHA and explicit metadata; multi-display popover integration.

## Test plan
FFI golden/parity and nonblocking tests; binding drift; Swift unit/UI/accessibility; desktop-ci/merge; all F00–F29 operator matrix rows.

## Done criteria
Production matches blessed contract; Swift is display-only; all required states and secondary-display popover pass; OpenCode absent.

## STOP conditions
Custom imitation replaces working native chrome; prototype harness enters production; FFI exposes secrets/raw provider errors; minimum constant diverges.

## Maintenance notes
System-owned visuals follow current OS; authored tokens/assets retain signoff and accessibility evidence.
