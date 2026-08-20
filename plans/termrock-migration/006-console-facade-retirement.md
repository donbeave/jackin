# Plan 006: Retire the console facade — migrate the console onto upstream TermRock contracts and re-home the rest

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED (behavior-preserving refactor across two crates plus two facade deletions; the only upstream gap is the subscription `Pending` carrier, which research ch07 routes to product-owned code — no upstream blocker)
- **Depends on**: plans/005-*.md (its PNG baselines are this refactor's pixel-parity gate)
- **Covers**: F6 (console speaks upstream contracts; facade duplicates retired for console), N2 (no shim, atomic cutover), D22 (facade end-state ruling); also satisfies the plan-006 half of D25 (shared `ModalOutcome` canonical home — oppicker's own modernization is plan 013)
- **Guardrails**: N2 inlined below
- **Research basis**: `research/termrock-head-adoption/07-facade-trait-retirement-inventory.md` (the retirement inventory — consumer tables and sequencing are this plan's step skeleton), `research/termrock-head-adoption/04-component-adoption-candidates.md` (jackin-tui facade row; two-end-states dead end resolved by D22); commands from `research/jackin-verification-tooling/01-gates-and-commands.md`
- **Planned at**: commit `f320b51f`, 2026-08-19

## Why this matters

The jackin❯ facade (`crates/jackin-tui`) duplicates upstream TermRock contracts that now exist at the pinned rev (`EventResult`/`Redraw`, `FocusGraph`, `OverlayStack`, `ReadySubscription`). D22 settled the end state: facade = brand `tokens.rs` + `operator_info` only, retiring per surface, no shim. This plan executes the console slice: the console speaks upstream contracts directly, the two console-exclusive facade items (`ModalFlow`, `ModalOutcome`) are deleted, blocking-subscription and outcome machinery become product-owned code, and every item capsule/launch/oppicker still consumes stays frozen until those surfaces' phases. After this lands, plans 008–013 build on post-retirement foundations instead of migrating call sites twice.

## Preconditions — run before anything else

Run each; any failure is a STOP.

1. **Plan 005 landed (PNG baselines pass).** `grep -E '^\| 005 \|' plans/termrock-migration/README.md | grep -q 'DONE'` → exit 0. Then open `plans/termrock-migration/005-*.md` (match by the `005-` prefix), find the cheapest done criterion it names, and run it → passes. If no `005-*.md` file exists or it names no runnable criterion, STOP.
2. **Pin**: `grep -n 'rev = "29a16b5bff84ea8609854711b774e87acbc456cc"' Cargo.toml` → prints the pin line (planning time: line 118).
3. **TermRock checkout**: `git -C <TERMROCK_CHECKOUT> rev-parse HEAD` → `29a16b5bff84ea8609854711b774e87acbc456cc`.
4. **Toolchain**: `rustc --version` → `rustc 1.97.1`; `cargo nextest --version` → `cargo-nextest 0.9.140` (both verified in research jackin-verification-tooling ch01 §Toolchain).
5. **Drift check** (this plan edits pre-existing code): `git diff --stat f320b51f..HEAD -- crates/jackin-tui crates/jackin-console crates/jackin/src/console crates/jackin-oppicker` and `git log --oneline f320b51f..HEAD -- crates/jackin-tui crates/jackin-console crates/jackin/src/console crates/jackin-oppicker`. Changes from the landed commits of plan 005 are expected, not drift. For every in-scope file this plan edits, compare the "Starting state" anchors below against live code before editing: **symbol names are the authority; every line number in this plan is a planning-time snapshot**. A mismatch that changes the migration shape — a renamed/deleted facade symbol, a new console consumer of a facade trait, a moved call site — is a STOP.
6. **Parity gates start green**: `cargo nextest run -p jackin-capsule -p jackin-console --locked` → all pass (repo-proven snapshot lane; ch01 §Snapshot workflow), and the plan-005 PNG baseline check → zero diff. Both must be green before the first edit; the same pair is re-run after every step.
7. **Clean tree**: `git status --porcelain` → empty.

## Spec contract

The requirements this plan implements, inlined **verbatim** from `plans/termrock-migration/spec/facade-retirement.md` — the executor does not read `spec/`:

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

Done means these scenarios hold; the test plan below exercises them.

## Must NOT

Guardrail inlined verbatim from the must-not registry, with reason. This overrides anything a step seems to imply:

- **N2**: No compatibility facades or shims over renamed TermRock APIs — repo latest-only law; upstream directive 0061/0331. For this plan that means: each trait's console migration lands atomically with all its call sites in one commit; no re-export, alias, `type X = ...`, or transitional wrapper over a facade item at any point — not even mid-sequence within a commit.

Plan-specific guardrails:

- **Run loop stays surface-owned.** The arch gate (`crates/jackin-xtask/src/arch.rs:272-280`) forbids `run.rs`/`terminal.rs`/`theme.rs` in jackin-tui, and jackin-tui's charter binds: `crates/jackin-tui/src/lib.rs:3-4` — "**Architecture Invariant:** T1. Product composition may depend on T0 facts and `TermRock`, but never owns neutral widgets or surface event loops." TermRock's `runner::run` owns the whole loop and MUST NOT be adopted; the console keeps its own run loop.
- **Fake-depth OverlayStack coupling dies with ModalFlow.** The old `ModalFlow` holds an `OverlayStack` with id `modal-{depth}` and zero rect/spec (modal_flow.rs:111-118) — that pattern MUST NOT be carried into the new code. Either adopt real `OverlayStack` geometry or let the product-owned `current/parents` bookkeeping stand alone; record which in the commit body.
- **Remnant frozen.** Do not delete, rename, or re-signature any facade item in the stays-until-later-phase set (`Component`, `View`, `Subscription`, `SubscriptionPoll`, `Dirty`, `UpdateResult`, `NoEffect`, `SurfaceFocus`, `drive_frame`, `drive_render`) — capsule/launch/oppicker consume them unchanged until their own phases.

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — the local TermRock git checkout used to read upstream API shapes (`EventResult`, `FocusGraph`, `OverlayStack`, `ReadySubscription`, `FocusNode` semantics) at the pinned rev. On the planning machine: `/Users/donbeave/Projects/tailrocks/termrock`. Needed by every step that names an upstream symbol.
  - If absent: proceed from the compiled crate sources under the cargo git checkout (`~/.cargo/git/checkouts/termrock-*`) at the same rev; swap later by cloning `https://github.com/tailrocks/termrock.git` and `git checkout 29a16b5bff84ea8609854711b774e87acbc456cc`. Do NOT edit the checkout (hub TermRock-misfit rule); do NOT block waiting.

## Starting state

The facts, inlined (all line numbers are planning-time snapshots at `f320b51f` — symbol names are the authority; re-derive counts with the grep shown and treat the fresh number as the authority):

**Facade public surface** (all in `crates/jackin-tui/src/`; crate root re-exports only `ModalOutcome` at lib.rs:20; `runtime` module declared lib.rs:17):

- `SubscriptionPoll<Event>` — runtime.rs:20-27; enum `Ready(E)/Pending/Closed`.
- `Subscription` — runtime.rs:30-36; trait, `type Output; fn poll_next(&mut self) -> SubscriptionPoll<Output>`.
- `Dirty` — runtime.rs:40-63; enum `Clean/Redraw`, `is_dirty()`, `merge()`.
- `NoEffect` — runtime.rs:67; uninhabited enum.
- `UpdateResult<Effect=NoEffect>` — runtime.rs:72-125.
- `Component<Event,Message>` — runtime.rs:128-131 (no console consumers — nothing to migrate).
- `View<Model>` — runtime.rs:134-137.
- `drive_frame` — runtime.rs:140-156; thin `Terminal::draw` wrap over `View` + overlay closure.
- `drive_render` — runtime.rs:159-168.
- `SurfaceFocusTarget<Content>` / `SurfaceFocus<Content>` — runtime/focus.rs:11-16 / :20-106; wrapper over `FocusGraph<SurfaceFocusTarget<C>>`. Load-bearing semantics: `focused()` falls back to `TabBar` when the graph is empty (focus.rs:61-66); zero-area registration keeps the graph keyboard-only (focus.rs:48-57).
- `ModalFlow<Modal>` — runtime/modal_flow.rs:11-119; `current/parents` + depth-only `OverlayStack` (id `modal-{depth}`, zero rect — fake-depth, :111-118).
- `ModalOutcome<T>` — modal_outcome.rs:9-16; enum `Continue/Cancel/Commit(T)`.

**Console consumers** (console = `crates/jackin-console` + `crates/jackin/src/console` adapter), per research ch07:

- `View<ConsoleState>`: impl at `crates/jackin-console/src/tui/runtime.rs:25-35`; consumed via `drive_frame` at `crates/jackin/src/console/adapter/run.rs:371`.
- `Subscription`/`SubscriptionPoll`: impl `runtime.rs:43-53` (`BlockingSubscription`); poll sites `state/manager.rs:648-678+`, `components/file_browser/git_prompt.rs:69-76`, `screens/editor/model/state_impl/pending.rs:98,148,193,236` (fn-local imports :95,145,190,233), `screens/settings/model/auth_impls.rs:266-269`; rx fields `tui/subscriptions.rs:158,178,212,245`. Ready-once producer: `ready_blocking_subscription` at `crates/jackin-console/src/tui/runtime.rs:55-59`.
- `UpdateResult`: alias `tui/update.rs:13-15` (`ConsoleUpdate<E>`), `state/update.rs:83` (`ManagerUpdate`); ctor `ManagerUpdate::redraw()` `state/update.rs:307`; **all results discarded** (`drop`/`let _unused`) across `input/dispatch.rs:202-447` and `adapter/run.rs:556-889`; the `ManagerEffect` channel is dead (no `with_effect` anywhere). `update_manager` return-type change (state/update.rs:93) ripples to ~15 discard sites.
- `Dirty`: no direct consumers (only via `UpdateResult`).
- `SurfaceFocus`/`SurfaceFocusTarget`: `state.rs:23`, `state/manager.rs:159`, `screens/settings/model.rs:45,157-206,435`, `screens/editor/model.rs:14`, editor `navigation.rs:5,87,120-126,231,271-310`; tests `state/update/tests.rs:12`, editor `model/tests.rs:1846,1871`.
- `ModalFlow`: `screens/settings/model.rs:1105,1131,1350` (fields/ctor), `:1164-1214` (`clear/open_sub/pop/is_open`); `auth_impls.rs:41`, `env_impls.rs:28,60`; reads in `view.rs:565-704`, `file_browser.rs:417-827`, `input/global_mounts.rs:202-606` (`take_current` :566).
- `ModalOutcome`: components `agent_choice.rs:9`, `confirm_save.rs:20`, `dialogs.rs:8`, `github_picker.rs:14`, `mount_dst_choice.rs:21`, `role_picker.rs:7`, `scope_picker.rs:8`, `source_picker.rs:8`, `workdir_pick.rs:10`; planners `model/create_prelude.rs:175-256`, `update.rs:602-816`, `run.rs:233-239`; `input/editor.rs:1054`; `screens/settings/update.rs:21`, `screens/workspaces/update.rs:13` (+14 console test files — planning-time count; re-derive: `rg -l 'ModalOutcome' crates/jackin-console/src` | count).

**Sequencing constraint for the ModalOutcome deletion**: facade-internal `operator_info.rs` consumes `crate::ModalOutcome` in its public API — `use crate::ModalOutcome;` (operator_info.rs:15), `handle_key` returns `ModalOutcome<()>` (:203, :241). jackin-tui cannot depend on the enum's new home (layering). So step 1 migrates `operator_info` to its own outcome contract first; only then can the facade enum be deleted (step 6).

**Canonical ModalOutcome home**: `crates/jackin-oppicker` (cycle-free — jackin-console already depends on jackin-oppicker: `op_picker/load.rs:6,28` uses `jackin_oppicker::BlockingSubscription`). jackin-oppicker already owns an identical crate-local enum at `crates/jackin-oppicker/src/adapters.rs:6`; this plan promotes it to the canonical shared enum (oppicker's remaining modernization is plan 013 — out of scope here).

**Upstream replacements at the pinned rev** (verify each against `<TERMROCK_CHECKOUT>` before use): `EventResult` interaction/event_result.rs:142, `Redraw` :16, `Propagation` :44, `FocusRequest` :72, `OverlayRequest` :99 (re-exported interaction/mod.rs:22-25); `FocusGraph` focus_graph.rs:203, `FocusNode` :68 (re-exported mod.rs:26-28); `OverlayStack` overlay_stack.rs:755, `OverlaySpec` :364, `OverlaySize` :137 (re-exported mod.rs:53-57); `ReadySubscription`/`ReadySubscriptionPoll`/`ready_subscription` runtime/subscription.rs:22/9/49 (re-exported runtime/mod.rs:30). `ReadySubscription` covers only the immediately-ready case — no upstream `Pending` carrier (subscription.rs:9-14), so the blocking tri-state becomes product-owned code.

**Stays-until-later-phase set** (frozen this plan; blocking surface in parentheses): `Component` (capsule runtime.rs:34), `View` (capsule runtime.rs:17, launch model.rs:115), `drive_frame` (capsule daemon/compositor.rs:394, launch run.rs:451), `drive_render` (launch run.rs:520+), `UpdateResult`+`Dirty` (launch update.rs:7,14,193), `NoEffect` (launch effect.rs:10), `Subscription`/`SubscriptionPoll` (oppicker adapters.rs:2, load.rs:7), `SurfaceFocus` (capsule view.rs:12, daemon/compositor.rs:151-155 +5 test sites).

**Dead end resolved by D22** (research ch04): jackin-tui's charter vs upstream runtime — "Both 'keep product traits' and 'adopt upstream contracts' satisfy the letter of the gate; they cannot both be the end state." D22 ruled: upstream contracts win; product traits retire per surface phase.

## Commands you will need

All proven by `research/jackin-verification-tooling/01-gates-and-commands.md` (ch01):

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Workspace check | `cargo check --workspace --all-targets --locked` | exit 0 (ch01, tests partition step, ci.rs:185-189) |
| Full test suite | `cargo nextest run --workspace --all-features --locked` | all pass (ch01, ci.rs:190-200) |
| Text-snapshot parity lane | `cargo nextest run -p jackin-capsule -p jackin-console --locked` | all pass, zero `.snap` diffs, no `*.pending-snap` (ch01 §Snapshot workflow) |
| One crate | `cargo nextest run -p <crate> --locked` | all pass (ch01 §Test runner) |
| Lint | `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` | exit 0 (ch01, ci.rs:167-180) |
| Format | `cargo fmt --check` | exit 0 (ch01, ci.rs:166) |
| Arch gate (run-loop ownership) | `cargo xtask lint --strict` | exit 0 (ch01, ci.rs:181; arch rule source `crates/jackin-xtask/src/arch.rs:272-280`) |
| Merge-readiness (final) | `cargo xtask ci --fast` | exit 0 (ch01 §Merge-readiness gates) |
| PNG pixel parity | the PNG baseline check command named in `plans/termrock-migration/005-*.md` | zero diff against the plan-005 blessed baselines |

## Scope

**In scope** (the only files to create or modify):

- `crates/jackin-console/src/**` — migrate off facade runtime traits; new product-owned modules: blocking subscription (tri-state poll enum + `BlockingSubscription`), focus identity enum + `FocusGraph` wiring, modal `current/parents` bookkeeping over `OverlayStack`, plain render function replacing the `View` impl.
- `crates/jackin/src/console/**` — adapter half: `drive_frame` call site (adapter/run.rs) → direct `Terminal::draw`; the ~15 `UpdateResult` discard sites in dispatch/run.
- `crates/jackin-tui/src/operator_info.rs` — migrate its public API off `crate::ModalOutcome` onto its own outcome contract (behavior unchanged; its existing tests pass unmodified).
- `crates/jackin-tui/src/runtime/modal_flow.rs` — **delete** (plus its declarations/re-exports in `runtime.rs`).
- `crates/jackin-tui/src/modal_outcome.rs` — **delete** (plus the `lib.rs` re-export).
- `crates/jackin-oppicker/src/adapters.rs` — promote the crate-local `ModalOutcome` (:6) to the canonical shared enum (export from the crate root); minimal touch only — no other oppicker modernization (plan 013's territory).
- `crates/jackin-oppicker/src/lib.rs` — re-export the canonical `ModalOutcome`.

**Out of scope** (do NOT touch, even though related):

- Every other facade item (`Component`, `View`, `Subscription`, `SubscriptionPoll`, `Dirty`, `UpdateResult`, `NoEffect`, `SurfaceFocus`, `drive_frame`, `drive_render`, `runtime.rs`, `runtime/focus.rs`, `runtime/tests.rs`) — frozen remnant for capsule/launch/oppicker until their phases (spec remnant-frozen requirement).
- `crates/jackin-capsule`, `crates/jackin-launch` — other surfaces, untouched.
- ScrollArea/mouse cutover — plan 008.
- Collections/modal geometry adoption beyond what this contract swap requires — plan 009.
- `crates/jackin-oppicker` beyond the `ModalOutcome` promotion (it has its own `BlockingSubscription` and subscription duplicates) — plan 013.
- TUI docs pages — plan 014.
- `Cargo.toml` / `Cargo.lock` / `deny.toml` — no dependency changes in this plan.

The hub `plans/termrock-migration/README.md` and the roadmap item are protocol-writable and never listed in scope.

## Git workflow

Commit boundaries instantiate the hub's repo law for this plan (one branch `feature/termrock-console-modernization`, DCO sign-off, push after every commit — hub law, not restated here as procedure). N2 atomicity binds each cutover to one commit with all its call sites:

1. `refactor(jackin-tui)!: migrate operator_info off facade ModalOutcome onto its own outcome contract` — step 1.
2. `refactor(console)!: replace facade UpdateResult/Dirty/NoEffect with upstream EventResult/Redraw` — step 2.
3. `refactor(console)!: cut console focus from SurfaceFocus to FocusGraph` — step 3.
4. `refactor(console)!: replace ModalFlow with OverlayStack plus product-owned modal bookkeeping; delete facade ModalFlow` — step 4 (body records the real-geometry vs standalone-bookkeeping decision).
5. `refactor(console)!: split subscriptions — ReadySubscription for ready-once arms, product-owned blocking subscription` — step 5.
6. `refactor(console)!: inline View/drive_frame as plain render fn plus direct Terminal::draw` — step 6.
7. `refactor(jackin-oppicker)!: promote ModalOutcome to canonical shared enum; delete facade ModalOutcome` — step 7.

`!` marks the facade API deletions/removals (pre-release breaking-change policy per the hub). The workspace MUST compile green at every commit boundary — order steps so the tree is never broken between commits.

## Steps

### Step 1: Migrate `operator_info` off the facade `ModalOutcome`

In `crates/jackin-tui/src/operator_info.rs`: replace the public `ModalOutcome<()>` return on `handle_key` (:203, :241) and the `use crate::ModalOutcome;` (:15) with an operator_info-owned outcome contract (a small enum with the same `Continue`/`Cancel`/`Commit(())` semantics, or an equivalent shape already idiomatic in that module — keep it minimal; it is part of the settled end-state facade). Update the module's callers and its existing tests' imports only — expectations unchanged.

**Verify**: `cargo nextest run -p jackin-tui --locked` → all pass (operator_info tests green, behavior unchanged). Commit per boundary 1.

### Step 2: Update-path contracts — `UpdateResult`/`Dirty`/`NoEffect` out of the console

Replace the `ConsoleUpdate<E>` alias (`tui/update.rs:13-15`) and `ManagerUpdate` (`state/update.rs:83`) with direct upstream types: `termrock::interaction::EventResult`/`Redraw` where a result is meaningfully consumed, or the Rust unit type `()` where results are discarded (research ch07: every call site is `drop`/`let _unused`, the `ManagerEffect` channel dead — no `with_effect` anywhere). Remove `ManagerUpdate::redraw()` (`state/update.rs:307`) and the `update_manager` return-type change ripples (`state/update.rs:93`, ~15 discard sites in `input/dispatch.rs`, `adapter/run.rs`, `state/update.rs:972-1014`). Delete the aliases — no re-export may remain (N2).

**Verify**: `cargo check --workspace --all-targets --locked` → exit 0; `rg 'UpdateResult|Dirty|NoEffect' crates/jackin-console crates/jackin/src/console` → no facade imports remain (only hits, if any, are the frozen facade definitions in jackin-tui and launch's consumers — those paths are outside these two dirs). Then the parity pair: `cargo nextest run -p jackin-capsule -p jackin-console --locked` → all pass, zero snapshot diff; PNG check → zero diff. Commit per boundary 2.

### Step 3: Focus — `SurfaceFocus` → `FocusGraph` + console-owned identity enum

In jackin-console, introduce a console-owned identity enum (tab bar vs content target — the role `SurfaceFocusTarget` plays today) and drive `termrock::interaction::FocusGraph` + `FocusNode` directly. Port the two load-bearing semantics exactly: `focused()` falls back to the tab bar when the graph is empty (facade focus.rs:61-66), and zero-area registration keeps the graph keyboard-only (facade focus.rs:46-58 — register-per-mutation with zero rect). Migrate the consumer sites named in Starting state (state.rs, state/manager.rs, settings/model.rs, editor model + navigation) and the two test files' imports — test expectations unchanged.

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass, focus tests (tab-bar fallback, content focus, cursor visibility) unmodified in expectation; `rg 'SurfaceFocus' crates/jackin-console crates/jackin/src/console` → no hits. Parity pair → zero diff. Commit per boundary 3.

### Step 4: Modal bookkeeping — `ModalFlow` → `OverlayStack` + product-owned flow; delete facade `ModalFlow`

Replace `ModalFlow<ConsoleModal>` with product-owned `current/parents` bookkeeping in jackin-console (the 19-variant `ConsoleModal` enum stays product-owned). Decide and record in the commit body: real `OverlayStack` geometry adopted, or depth bookkeeping stands alone (research ch07: the old stack half is fake-depth — id `modal-{depth}`, zero rect, near-vestigial). Either way, do NOT carry the fake-depth pattern forward. Migrate the settings-model fields/ctor, `clear/open_sub/pop/is_open` paths, and the read sites (`view.rs`, `file_browser.rs`, `input/global_mounts.rs` incl. `take_current`). Then delete `crates/jackin-tui/src/runtime/modal_flow.rs` and its declarations/re-exports in `runtime.rs` (`:13`, `:16` at planning time).

**Verify**: Esc-cascade and focus-restore parity tests pass unmodified (`cargo nextest run -p jackin-console --locked` → all pass); `rg -n 'ModalFlow' crates/` → no hits; `test ! -f crates/jackin-tui/src/runtime/modal_flow.rs` → exit 0. Parity pair → zero diff. Commit per boundary 4.

### Step 5: Subscription split — ready-once upstream, blocking product-owned

Adopt `termrock::runtime::ReadySubscription`/`ready_subscription` for the ready-once producer (`ready_blocking_subscription`, `tui/runtime.rs:55-59`). Re-home the blocking tri-state as product-owned code inside `crates/jackin-console`: a local `Ready/Pending/Closed` poll enum plus the `BlockingSubscription` machinery, in a console module (not re-exported from jackin-tui). Migrate the poll sites and rx fields named in Starting state. If any blocking arm proves to be ready-once in fact, it MAY map to `ReadySubscription` instead — resolve per call site (research ch07 open unknown, MED).

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass (existing subscription tests unmodified); `rg 'jackin_tui::runtime::Subscription|SubscriptionPoll' crates/jackin-console crates/jackin/src/console` → no hits. Parity pair → zero diff. Commit per boundary 5.

### Step 6: Frame path — inline `View<ConsoleState>` and `drive_frame`

Replace the `View<ConsoleState>` impl (`crates/jackin-console/src/tui/runtime.rs:25-35`) with a plain render function, and the `drive_frame` call (`crates/jackin/src/console/adapter/run.rs:371`) with a direct `Terminal::draw` with the overlay closure inlined (exactly what `drive_frame` wraps, facade runtime.rs:152-155). Do NOT adopt TermRock `runner::run` — it owns the whole loop; the run loop stays surface-owned (arch gate). The facade `View`/`drive_frame` definitions stay (frozen remnant for capsule/launch).

**Verify**: `rg 'drive_frame|View<' crates/jackin-console crates/jackin/src/console` → no hits; `cargo xtask lint --strict` → exit 0 (arch gate green); `cargo nextest run -p jackin-console --locked` → all pass. Parity pair → zero diff. Commit per boundary 6.

### Step 7: Canonical `ModalOutcome` in jackin-oppicker; delete the facade copy

In `crates/jackin-oppicker`: promote the crate-local enum (`src/adapters.rs:6`) to the canonical shared `ModalOutcome<T>` (`Continue`/`Cancel`/`Commit(T)`) and re-export it from the crate root. Migrate every console consumer site named in Starting state (9 components, 3 planner files, `input/editor.rs`, 2 screen update files, plus the console test files) and oppicker's internal uses to import the canonical enum. Then delete `crates/jackin-tui/src/modal_outcome.rs` and the `lib.rs` re-export (`:15`, `:20` at planning time). Do not modernize anything else in oppicker (plan 013).

**Verify**: `cargo check --workspace --all-targets --locked` → exit 0 (no dependency cycle); `rg 'jackin_tui::ModalOutcome' --type rust` → no hits anywhere; `test ! -f crates/jackin-tui/src/modal_outcome.rs` → exit 0; all console components and jackin-oppicker import the same enum (`rg -n 'use jackin_oppicker::.*ModalOutcome|jackin_oppicker::ModalOutcome' crates/jackin-console` → hits; no competing definition remains). `cargo nextest run -p jackin-tui -p jackin-oppicker --locked` → all pass. Parity pair → zero diff. Commit per boundary 7.

### Step 8: Remnant-freeze sweep + full gates

Confirm the frozen remnant is intact and no new facade consumer appeared anywhere:

- `rg 'jackin_tui::runtime|jackin_tui::ModalOutcome' --type rust` → consumers only in `crates/jackin-capsule`, `crates/jackin-launch`, `crates/jackin-oppicker`, and `crates/jackin-tui` itself (spec scenario).
- `cargo nextest run -p jackin-capsule -p jackin-launch --locked` → all pass (capsule/launch consumers unchanged).

Then run the full gates: `cargo fmt --check`, `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings`, `cargo nextest run --workspace --all-features --locked`, `cargo xtask lint --strict`, and `cargo xtask ci --fast` → all exit 0. Final parity pair: text-snapshot lane → zero diff; PNG check → zero diff.

## Test plan

This is a behavior-preserving refactor: the proof is existing tests passing **unmodified in expectation** plus the two parity gates. No new test files are required; targeted adjustments only where a type import moves:

- **Focus semantics** (spec scenario "Focus behavior preserved"): the pre-migration focus tests (`state/update/tests.rs`, editor `model/tests.rs` — tab-bar fallback, content focus, cursor visibility) pass with only import edits. Zero-area keyboard-only pattern: assert the `FocusGraph` registration sites use zero-area rects exactly as the facade pattern did (facade focus.rs:46-58 is the reference implementation being ported).
- **Modal flows** (scenario "Modal flows unchanged"): the Esc-cascade and focus-restore parity tests (created in plan 001, `dialog/tests.rs` seams per ledger A4) pass unmodified.
- **Subscriptions** (scenario "Subscription behavior preserved"): existing subscription tests in jackin-console pass unmodified.
- **operator_info** (scenario "Single product-owned outcome enum"): its existing tests pass against the new outcome contract, expectations unchanged.
- **Parity gates** (B14/B16 via hub law): `cargo nextest run -p jackin-capsule -p jackin-console --locked` → every console text snapshot byte-identical (any diff = parity break, STOP — never re-bless); plan-005 PNG baseline check → zero diff. Both run after every step (see step verifications).
- **Independent source of truth**: expectations come from the pre-migration blessed snapshots/baselines and the unmodified test bodies — never recomputed from the migrated code.

**Verify**: `cargo nextest run --workspace --all-features --locked` → all pass.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `cargo check --workspace --all-targets --locked` exits 0
- [ ] `cargo nextest run --workspace --all-features --locked` exits 0; every pre-migration test passes unmodified in expectation
- [ ] `rg 'UpdateResult|Dirty|NoEffect' crates/jackin-console crates/jackin/src/console` finds no facade imports
- [ ] `rg 'SurfaceFocus' crates/jackin-console crates/jackin/src/console` finds no hits
- [ ] `rg -n 'ModalFlow' crates/` finds no hits; `crates/jackin-tui/src/runtime/modal_flow.rs` deleted
- [ ] No console file imports `jackin_tui::runtime::Subscription` or `SubscriptionPoll`
- [ ] `rg 'drive_frame|View<' crates/jackin-console crates/jackin/src/console` finds no console consumer; `cargo xtask lint --strict` exits 0 (arch gate: run loop surface-owned)
- [ ] `rg 'jackin_tui::ModalOutcome' --type rust` finds no hits; `crates/jackin-tui/src/modal_outcome.rs` and its `lib.rs` re-export deleted; console + oppicker share one canonical `ModalOutcome`
- [ ] Remnant freeze: `rg 'jackin_tui::runtime|jackin_tui::ModalOutcome' --type rust` shows consumers only in `crates/jackin-capsule`, `crates/jackin-launch`, `crates/jackin-oppicker`, `crates/jackin-tui`; `cargo nextest run -p jackin-capsule -p jackin-launch --locked` passes
- [ ] Text-snapshot lane (`cargo nextest run -p jackin-capsule -p jackin-console --locked`) byte-identical — zero `.snap` diff; PNG baseline check zero diff
- [ ] `cargo xtask ci --fast` exits 0
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status rows and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails, or "Starting state" does not match reality (a facade symbol renamed/deleted/moved, a new console facade consumer, a call site not where the inventory put it).
- A step's verification fails twice after a reasonable fix attempt.
- Any console text-snapshot diff or PNG baseline diff appears — that is a parity break under hub law (D16/D23): STOP for operator review; never re-bless in this plan.
- The work requires touching an out-of-scope file (a frozen remnant item, capsule, launch, oppicker beyond the `ModalOutcome` promotion) or violating a Must NOT.
- An upstream API cited in Starting state is renamed or removed at the pinned rev (ledger A5) — or the migration reveals a TermRock API misfit with no consumer-side route: mark BLOCKED per the hub's TermRock-misfit route, do not edit `<TERMROCK_CHECKOUT>`.
- Migrating `operator_info` or deleting the facade `ModalOutcome` would require jackin-tui to depend on jackin-oppicker (a layering inversion) — the sequencing in steps 1 and 7 exists to prevent exactly this.
- The assumption "console update results are discarded at every call site" (research ch07, HIGH) turns out false at a specific site — a live `ManagerEffect`/result consumer changes the step-2 shape.

## Maintenance notes

- **Dependents**: plans 008 and 009 build directly on this plan's foundations (focus on `FocusGraph`, modal bookkeeping on `OverlayStack`, event contracts upstream); plan 013 completes the oppicker half of D25 (its `BlockingSubscription` duplicate and the rest of the crate's modernization) — this plan only promotes the shared `ModalOutcome`.
- **Reviewer scrutiny**: (1) the step-4 commit body must record the real-geometry vs standalone-bookkeeping decision and the code must match it; (2) no fake-depth `modal-{depth}` pattern anywhere in the new modal bookkeeping; (3) step 5's per-site ready-once-vs-blocking calls — any blocking arm silently reframed as ready-once changes timing semantics and is a parity risk; (4) `operator_info`'s new outcome contract is minimal and its tests unchanged in expectation.
- **Deferred**: facade final retirement (`runtime.rs`, `runtime/focus.rs`, `runtime/tests.rs`, `drive_render`, the remnant set) waits for the capsule/launch phases per the settled end state; oppicker's `Subscription`/`SubscriptionPoll` consumption is the last remnant consumer after this plan and retires in plan 013.
- **Re-derivation**: all `file:line` anchors and the 14-test-file ModalOutcome count are planning-time snapshots; the executor re-runs the greps and treats fresh output as the authority.
