# Facade retirement (console phase)

## Purpose

Execute the console slice of the settled facade end-state: the console surface speaks upstream TermRock contracts directly, its facade duplicates retire with no compatibility shim, and the facade keeps only what later surfaces (capsule, launch, oppicker) still consume until their own phases. End-state across all phases: facade = brand `tokens.rs` + `operator_info` only; the arch gate's run-loop ownership rule is untouched.

Anchors: F6, N2 · Evidence: research/termrock-head-adoption/07-facade-trait-retirement-inventory.md, roadmap item §Decisions (facade end-state ruling, 2026-08-19), `crates/jackin-xtask/src/arch.rs:253-275`

## Requirements

### Requirement: Console speaks upstream event contracts

The console SHALL consume `termrock::interaction::EventResult` (`Redraw`/`Propagation`/`FocusRequest`/`OverlayRequest`) and `termrock::interaction::Redraw` directly for its update-path results; the facade's `UpdateResult`/`Dirty`/`NoEffect` types MUST lose every console consumer. Where console update results are today discarded at every call site (research ch07: all `drop`/`let _unused`, the effect channel dead), the replacement MAY be the Rust unit type; no facade re-export or alias may remain.

Covers: F6, N2 · Evidence: research/termrock-head-adoption/07-facade-trait-retirement-inventory.md (UpdateResult/Dirty rows)

#### Scenario: No console import of facade update types

- **WHEN** the migration lands
- **THEN** `rg 'UpdateResult|Dirty|NoEffect' crates/jackin-console crates/jackin/src/console` finds no facade imports (test-only references to the new contracts excepted per the plan)
- **AND** the workspace compiles with no console-side alias

### Requirement: Console focus on FocusGraph directly

The console SHALL replace `SurfaceFocus`/`SurfaceFocusTarget` with `FocusGraph` + `FocusNode` used directly, with a console-owned identity enum; the two load-bearing semantics MUST be preserved: `focused()` falls back to the tab bar when the graph is empty, and zero-area registration keeps the graph keyboard-only.

Covers: F6 · Evidence: research/termrock-head-adoption/07-facade-trait-retirement-inventory.md (SurfaceFocus row + focus semantics note)

#### Scenario: Focus behavior preserved

- **GIVEN** the console migrated off `SurfaceFocus`
- **WHEN** the console focus tests run (tab-bar fallback, content focus, cursor visibility)
- **THEN** every pre-migration focus behavior test passes unmodified in expectation
- **AND** mouse hit registration does not alter keyboard focus order (zero-area pattern preserved)

### Requirement: Console modal bookkeeping on OverlayStack

The console SHALL replace `ModalFlow` with `OverlayStack` used directly for geometry/stacking plus product-owned `current/parents` bookkeeping; the 19-variant `ConsoleModal` flow enum stays product-owned. The facade's `ModalFlow` (console-exclusive per research ch07) MUST be deleted in this phase. The fake-depth `OverlayStack` coupling inside the old `ModalFlow` (id `modal-{depth}`, zero rect) MUST NOT be carried into the new code; the plan records whether real overlay geometry is adopted or the depth bookkeeping stands alone.

Covers: F6 · Evidence: research/termrock-head-adoption/07-facade-trait-retirement-inventory.md (ModalFlow row + fake-depth note)

#### Scenario: Modal flows unchanged, facade type gone

- **WHEN** the migration lands
- **THEN** open/open_sub/pop/clear/take_current behaviors match the pre-migration flows (Esc cascade and focus restore parity tests still pass)
- **AND** `crates/jackin-tui/src/runtime/modal_flow.rs` and its re-exports are deleted

### Requirement: Subscription split — ready-once upstream, blocking product-owned

The console SHALL adopt `termrock::runtime::ReadySubscription` for its ready-once subscription arms; its blocking tri-state subscription (`Ready/Pending/Closed`) MUST be re-homed as product-owned code inside `crates/jackin-console` because upstream has no `Pending` carrier (research ch07, MED). The facade's `Subscription`/`SubscriptionPoll` MUST lose every console consumer; the types themselves remain in the facade only while oppicker consumes them (oppicker modernizes in this same phase per the op-picker requirement in spec/console-modernization.md).

Covers: F6 · Evidence: research/termrock-head-adoption/07-facade-trait-retirement-inventory.md (Subscription row + subscription gap note)

#### Scenario: Subscription behavior preserved

- **WHEN** the migration lands
- **THEN** every console subscription arm polls with the same ready/pending/closed semantics as before (existing subscription tests pass)
- **AND** no console file imports `jackin_tui::runtime::Subscription` or `SubscriptionPoll`

### Requirement: View and drive_frame inlined

The console SHALL replace the `View<ConsoleState>` impl and `drive_frame` call with a plain render function plus direct `Terminal::draw` (what `drive_frame` wraps); TermRock's `runner::run` MUST NOT be adopted — it owns the whole loop and the arch gate keeps run loops surface-owned. The facade's `View` trait and `drive_frame` remain in the facade for capsule and launch until their phases.

Covers: F6 · Evidence: research/termrock-head-adoption/07-facade-trait-retirement-inventory.md (View/drive_frame rows + runner rejection)

#### Scenario: Frame path direct

- **WHEN** the migration lands
- **THEN** the console frame path calls `Terminal::draw` directly with the overlay closure inlined
- **AND** `rg 'drive_frame|View<' crates/jackin-console crates/jackin/src/console` finds no console consumer
- **AND** the arch gate passes (run loop still surface-owned)

### Requirement: ModalOutcome re-homed and facade copy deleted

The `ModalOutcome<T>` enum (`Continue`/`Cancel`/`Commit(T)`) — no upstream analog per research ch07 — SHALL be re-homed as a single product-owned enum and the facade's `ModalOutcome` MUST be deleted in this phase. The canonical location MUST NOT introduce a dependency cycle: `crates/jackin-console` already consumes `jackin-oppicker` (research ch07: `op_picker/load.rs` uses `jackin_oppicker::BlockingSubscription`), so the cycle-free canonical is the `jackin-oppicker` crate (which already owns an identical crate-local enum, adapters.rs:6) — the console and oppicker then share one enum and the "duplicate removed" ruling (D25) is satisfied. Deletion is sequenced: the facade-internal `operator_info` module (part of the settled end-state facade) consumes `crate::ModalOutcome` in its public API (operator_info.rs:15,203,241 per vetting) and jackin-tui cannot depend on the enum's new home — so `operator_info` MUST first migrate to its own outcome contract, and only then is the facade enum deleted.

Covers: F6 · Evidence: research/termrock-head-adoption/07-facade-trait-retirement-inventory.md (ModalOutcome row + deletable-this-phase note), roadmap item §Decisions (D25)

#### Scenario: Single product-owned outcome enum

- **WHEN** the migration lands
- **THEN** all console components and jackin-oppicker import the same `ModalOutcome` from its canonical location
- **AND** `operator_info` compiles against its own outcome contract with behavior unchanged (its existing tests pass)
- **AND** `crates/jackin-tui/src/modal_outcome.rs` and the `lib.rs` re-export are deleted
- **AND** no crate dependency cycle exists (`cargo check` passes)

### Requirement: No shim, atomic cutovers, facade remnant frozen

Each trait's console migration SHALL land atomically with all its call sites in one commit — no compatibility re-export, alias, or shim at any point (N2, latest-only law). The facade items still consumed by capsule/launch/oppicker (`Component`, `View`, `Subscription`, `SubscriptionPoll`, `Dirty`, `UpdateResult`, `NoEffect`, `SurfaceFocus`, `drive_frame`, `drive_render`) MUST NOT be deleted in this phase, and no NEW consumer of any facade runtime trait may be introduced anywhere in the workspace.

Covers: F6, N2 · Evidence: research/termrock-head-adoption/07-facade-trait-retirement-inventory.md (stays-until-later-phase set + atomicity note)

#### Scenario: Remnant intact, no new adoption

- **WHEN** the console phase completes
- **THEN** the stays-until-later-phase items still compile and serve their capsule/launch consumers unchanged
- **AND** `rg 'jackin_tui::runtime|jackin_tui::ModalOutcome' --type rust` shows consumers only in `crates/jackin-capsule`, `crates/jackin-launch`, `crates/jackin-oppicker`, and `crates/jackin-tui` itself
