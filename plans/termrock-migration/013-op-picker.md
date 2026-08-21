# Plan 013: Re-base the op-picker breadcrumb on widgets/breadcrumbs and modernize jackin-oppicker

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/006-*.md (which chains 005; PNG gate from 005)
- **Covers**: spec/console-modernization.md "UI/UX parity invariant" + "Op-picker wholly in the console phase"; coverage ledger F5 (op-picker), B14, D16, D25
- **Guardrails**: N2 inlined below (N4 noted, not engaged)
- **Research basis**: research/termrock-head-adoption/04-component-adoption-candidates.md (op-picker + small-surfaces rows), research/termrock-head-adoption/07-facade-trait-retirement-inventory.md (ModalOutcome + Subscription rows)
- **Planned at**: commit `f320b51f`, 2026-08-19

## Why this matters

The console's 1Password op-picker is a hand-rolled staged drill-down (Account → Vault → Item → Section → Field, plus naming sub-stages) whose state machine lives in the pure `jackin-oppicker` crate. Upstream TermRock now ships three pieces this surface duplicates or should consume: `widgets/breadcrumbs` for the ancestor-trail title, `runtime/subscription`'s `ReadySubscription` for the ready-once load arm, and `interaction/collection` for selection state. The crate also still rides the retiring facade: its `BlockingSubscription` implements `jackin_tui::runtime::Subscription` and is the last consumer blocking that facade trait's deletion, while its `ModalOutcome` enum is the canonical home the console's facade enum was retired onto (plan 006). After this lands, the drill-down state machine stays product-owned with identical behavior, selection rides `CollectionState` with wrap/clamp semantics preserved, the ready-once load arm speaks the upstream subscription contract, the worker arm is product-owned, `jackin-tui` drops out of the crate's dependency set, and the breadcrumb title renders through `widgets/breadcrumbs` — or, if no consumer configuration reproduces the current title byte-identically, the breadcrumb half lands as a BLOCKED misfit with a concrete upstream-change recommendation while steps 1–3 stay landed.

## Preconditions — run before anything else

- Plan 006 landed: the hub `plans/termrock-migration/README.md` status row for 006 reads `DONE`; per the hub protocol, re-run the cheapest done criterion recorded in plan 006 before building on it. Observable substrate checks:
  - `rg -n "pub enum ModalOutcome" crates/jackin-tui/src` → **no hits** (006 deleted the facade enum).
  - `rg -n "crate::ModalOutcome" crates/jackin-tui/src/operator_info.rs` → **no hits** (006 migrated operator_info to its own outcome contract).
  - `rg -n "jackin_oppicker::.*ModalOutcome" crates/jackin-console/src` → **at least one hit** (006 switched console consumers to the canonical oppicker enum).
- Plan 005 landed: the hub status row for 005 reads `DONE`, and the PNG-baseline comparison command recorded in plan 005's Done criteria exits 0 on the current tree (the pixel gate this plan runs after steps 2–4).
- Drift check: `git diff --stat f320b51f..HEAD -- crates/jackin-oppicker crates/jackin-console/src/tui/op_picker.rs crates/jackin-console/src/tui/op_picker crates/jackin-console/src/tui/components/op_picker` — changes since the planned-at SHA are expected **only** from this package's plans 005–012 on the execution branch (the oppicker crate itself should be untouched). For every changed file, `git log --oneline f320b51f..HEAD -- <file>` must show only this branch's plan commits; any other commit is a STOP. Where a dependency plan legitimately rewrote a file, the live file is the authority — re-read it and treat every "Starting state" line number below as a planning-time snapshot to re-derive, not a target.

Any failed precondition is a STOP.

## Spec contract

The requirements this plan implements, inlined **verbatim** from `plans/termrock-migration/spec/console-modernization.md` — the executor does not read `spec/`:

### Requirement: UI/UX parity invariant

The console modernization SHALL preserve every console screen's current look and interaction behavior; any upstream visual or behavioral divergence from the pre-migration UX MUST be compensated — consumer configuration first, an upstream TermRock change per the misfit rule when a widget cannot reproduce the current UX — and MUST NOT be silently accepted.

Covers: F5, W2, B16 · Evidence: roadmap item §Decisions (parity invariant ruling, 2026-08-19)

#### Scenario: Text snapshot diff during modernization

- **GIVEN** a console screen has been re-platformed onto upstream components
- **WHEN** the console text snapshot suite runs
- **THEN** every existing console snapshot is byte-identical to its pre-modernization bless
- **AND** any diff is treated as a parity break: the executor STOPs for operator review and MUST NOT re-bless

#### Scenario: Upstream widget cannot reproduce current UX

- **GIVEN** an adopted upstream widget whose rendered output or interaction differs from the current console UX
- **WHEN** consumer configuration options are exhausted
- **THEN** the divergence is resolved by an upstream TermRock change per the misfit rule
- **AND** the divergence is never shipped as an accepted behavior change

#### Scenario: Parity proof set complete

- **WHEN** the console phase finishes
- **THEN** parity is proven by all of: the bump-phase text snapshots (byte-identical), the named behavioral parity tests, the zero-tolerance PNG baselines on the full console inventory, and the BrandHeader PNG crop

### Requirement: Op-picker wholly in the console phase

The op-picker staged drill-down SHALL stay hand-rolled (no upstream equivalent) with its breadcrumb re-based on `widgets/breadcrumbs`; the `jackin-oppicker` crate SHALL be modernized in the same phase: `ReadySubscription` replaces the `BlockingSubscription` duplicate, filtering adopts `interaction/collection`, and the `ModalOutcome` duplicate is removed.

Covers: F5, D25 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md (op-picker pairing), research/termrock-head-adoption/07-facade-trait-retirement-inventory.md (canonical `ModalOutcome` home; facade `Subscription` blocked by oppicker)

#### Scenario: Drill-down behavior preserved

- **WHEN** the op-picker drill-down is navigated after the breadcrumb re-base
- **THEN** staging, filtering, and back-navigation behave exactly as before
- **AND** the breadcrumb renders through `widgets/breadcrumbs` with identical content

Done means these scenarios hold; the test plan below exercises them.

## Must NOT

Guardrails inlined verbatim from the must-not registry (`plans/termrock-migration/coverage.md`), with reasons. These override anything a step seems to imply:

- **N2**: No compatibility facades or shims over renamed TermRock APIs — repo latest-only law; upstream directive 0061/0331.

Note on **N4** (No new operator-visible screens or overlays beyond keyboard_help; no journey changes — amended D14 — amendment scope is exactly one overlay): this plan adds **no** screen, overlay, or journey — the breadcrumb re-base renders identical content on an existing modal, and the crate modernization is invisible — so N4 is not engaged by any step below.

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — a local checkout of the TermRock repository at rev `29a16b5b`, read-only. On this machine it lives at `/Users/donbeave/Projects/tailrocks/termrock` (`git -C <TERMROCK_CHECKOUT> rev-parse --short HEAD` must print `29a16b5b`). Needed by steps 2–4 to re-verify upstream APIs before each cutover.
  - If absent: use the cargo git checkout of the pinned dependency (under `~/.cargo/git/checkouts/`, the termrock clone whose HEAD is `29a16b5b`) as `<TERMROCK_CHECKOUT>`; any clone at that rev satisfies the contract. Verify the rev the same way. Do NOT block waiting. Never edit the checkout — an upstream misfit is a BLOCKED outcome per the hub's misfit rule, not a local edit.

## Starting state

The facts, inlined — every citation below was re-opened and verified at planning time on commit `f320b51f` (jackin) and rev `29a16b5b` (TermRock). All jackin paths are repo-relative; upstream paths are relative to `<TERMROCK_CHECKOUT>/crates/termrock/src/`.

**Planning-time measurements carry the re-derivation rule.** Every line number, count, and grep total below is a planning-time snapshot; plans 005–012 land before this plan executes and will shift lines. The executor re-runs the locating grep, the fresh number is the authority — stamp it in the output, note the delta, and never treat a drifted planning number as a target to reproduce.

### The canonical `ModalOutcome` (step 1)

- `crates/jackin-oppicker/src/adapters.rs:6-10` — `#[derive(Debug, Clone, PartialEq, Eq)] pub enum ModalOutcome<T> { Continue, Commit(T), Cancel }`. Per research ch07, the canonical product modal-outcome enum homes in jackin-oppicker (cycle-free: the console already depends on oppicker), and this enum is the precedent.
- The facade twin at `crates/jackin-tui/src/modal_outcome.rs:9-16` (deleted by plan 006) declares the same variant **set** in different order (`Continue / Cancel / Commit(T)` vs oppicker's `Continue / Commit(T) / Cancel`). Declaration order is not API-visible (no explicit discriminants; match arms are order-independent), so the oppicker enum serves former facade consumers unchanged.
- Re-exported at `crates/jackin-oppicker/src/lib.rs:13-16`: `pub use adapters::{BlockingSubscription, ModalOutcome, TextInputState, ready_blocking_subscription, spawn_named_blocking_subscription};`
- Consumers inside oppicker: `input.rs:25` `handle_key(...) -> ModalOutcome<OpPickerCoreSelection>`; `adapters.rs:13-45` `TextInputState::handle_key -> ModalOutcome<String>`.
- Console consumers (switched to this enum by plan 006; precondition-verified): `crates/jackin-console/src/tui/update.rs` op_picker planners (:611 `op_picker_inline_plan`, :726 `create_op_picker_plan`), `input/editor/modal.rs:115`, `input/global_mounts/auth.rs:366`, and the suites `tui/op_picker/tests.rs`, `tui/components/op_picker/tests.rs`.

### Subscriptions (step 2)

Current product code:

- `adapters.rs:2` and `load.rs:7` are the **only** two `jackin_tui` imports in the oppicker crate (grep-verified: `rg -n "jackin_tui" crates/jackin-oppicker/src`).
- `adapters.rs:48-58` — `pub struct BlockingSubscription<T>(tokio::sync::oneshot::Receiver<T>)` implementing the facade `jackin_tui::runtime::Subscription` (tri-state `SubscriptionPoll::{Ready, Pending, Closed}` via `try_recv`).
- `adapters.rs:60-64` — `ready_blocking_subscription(value)`: pre-filled oneshot (sender dropped after send).
- `adapters.rs:65-84` — `spawn_named_blocking_subscription(name, worker)`: spawns the worker on a named, join-tracked thread via `jackin_telemetry`, result delivered over the oneshot.
- `state.rs:81` — `pub rx: Option<BlockingSubscription<LoadResult>>` — the single in-flight load slot.
- `load.rs:207` — `attach_load_receiver(rx: BlockingSubscription<LoadResult>)`; `load.rs:229-344` — `poll_load(&mut self) -> bool` matches `rx.poll_next()` over `SubscriptionPoll::{Ready, Pending, Closed}` and clears the slot on Ready/Closed. Design invariant (comment near `load.rs:90-93`): cache hits and misses both route through one-shot subscriptions so `poll_load` stays the **single completion path** — this invariant MUST survive the rework.
- Console side: `crates/jackin-console/src/tui/op_picker/load.rs:24-37` — `start_load(cached, request, runner) -> BlockingSubscription<LoadResult>`: cached arm → `jackin_oppicker::ready_blocking_subscription(result)`; miss arm → `jackin_oppicker::spawn_named_blocking_subscription("jackin-op-picker-load", ...)`. Driven by `tui/op_picker.rs:97 poll_picker_loads` and `:128-139 execute_op_picker_pending_load`.

Upstream (verified at `29a16b5b`):

- `runtime/subscription.rs:9-14` — `#[non_exhaustive] pub enum ReadySubscriptionPoll<T> { Ready(T), Closed }` — bi-state, **no `Pending`**.
- `runtime/subscription.rs:22-46` — `pub struct ReadySubscription<T> { value: Option<T> }` with `new(value)` (:29), `poll_next(&mut self) -> ReadySubscriptionPoll<T>` (:36; yields once, then Closed), `is_closed()` (:42); plus ctor `ready_subscription(value)` (:49-52). Runtime-neutral: does not spawn, block, or depend on an executor.
- Research ch07 verdict (quoted): the facade tri-state vs the upstream bi-state means blocking arms stay product-owned; "only ready-once producers … map cleanly to `ready_subscription` (subscription.rs:49)"; the facade `Subscription`/`SubscriptionPoll` are blocked by oppicker only (stays-until-later table) — after this plan they have zero consumers (see Maintenance notes).

### Collection adoption (step 3)

Current product code:

- `state.rs:30` `OpPickerState` carries **five** `termrock::widgets::ListState<usize>` selection fields: `account_list_state` (:35), `vault_list_state` (:39), `item_list_state` (:43), `field_list_state` (:47), `section_list_state` (:48). (`ListState` here is already the upstream `termrock::widgets::ListState`, not a facade type.)
- Movement policies to preserve **exactly**:
  - Keyboard arrows: `input.rs:605-607` `cycle_select` → `ListState::cycle_index(count, delta)` — **WRAPS** at the ends (upstream `widgets/list.rs:943-963`; returns `next != current`; clears selection when count == 0).
  - Mouse wheel: `state.rs:235-261 scroll_selection` / `:269 scroll_select` → `ListState::move_index(count, delta)` — **CLAMPS** at the ends (upstream `widgets/list.rs:966-984`).
  - `input.rs:615` `clamp_selection` — product clamp helper already present.
  - Filter edits reset selection to the first row of the filtered projection: `input.rs` `reset_selection_for_filter` → `filter_reset_selection_for_stage`.
  - `lib.rs:30-32` `first_selection(count)` — `None` when 0, else `Some(0)`.
  - `state.rs:265 list_state_for_count` — constructor helper; `.select(...)` call sites in `load.rs` (e.g. `vault_list_state.select(selected)` in the vaults-loaded arm of `poll_load`).
- Filtering: `lib.rs:34-42` `matches_filter(filter, haystacks)` — case-insensitive any-haystack substring; the `filtered_*` projections in `lib.rs`/`state.rs` feed both painting and selection. These **stay product** (see the upstream contract note below).
- Selection reads: `components/op_picker/render_state.rs` `.selected().copied()` (:58, :70, :83, :90, :106) and `selected_index_for_stage` (:110-119); `render.rs:122-126` paints the list per-frame with a fresh `ListState::new(state.selected_index())` — the List **rendering** path is unchanged by this plan.

Upstream (verified at `29a16b5b`):

- `interaction/collection.rs` — `CollectionItem::new(id, label)` (:36); `CollectionOutcome` (:63) with `changed()` (:80) and `active_changed()` (:86); `CollectionState` (:107): `new()` (:123, `wrap` defaults to **true**), builder `wrap(bool)` (:141), `set_active(Option<Id>)` (:190), `reconcile(&items)` (:223), `move_by(&items, steps)` (:254), `active_index(&items)` (:391). Contract note (:238, paraphrase anchor — re-read the line): host owns filtering/sorting; pass only the painted/virtual slice.
- `interaction/roving.rs:103-109` — wrap default true; `:226-249` `move_by` wraps via `rem_euclid` when `wrap` is set, clamps to `0..=len-1` otherwise; empty items or `steps == 0` → `reconcile`.
- `widgets/list.rs:928-930` `for_count` — the constructor pattern being replaced (`None` if 0 else `Some(0)` ≡ product `first_selection`).

### The drill-down breadcrumb (step 4)

Current product code:

- `crates/jackin-oppicker/src/lib.rs:963-997` — `breadcrumb_title(stage, multi_account, account_email, vault_name, item_name) -> String`, the exact per-stage trail (separator is `" \u{2192} "` — U+2192 with single spaces):
  - `Account` → `"1Password"`
  - `Vault` → multi-account: `account_email`; single: `"1Password"`
  - `Item | NewItemName | FieldLabel | NewSectionName` → multi: `"{account_email} → {vault_name}"`; single: `vault_name`
  - `Section | Field` → multi: `"{account_email} → {vault_name} → {item_name}"`; single: `"{vault_name} → {item_name}"`
- Rendered as the dialog-shell **title** in both ready and loading states: `components/op_picker/render.rs:42-55` and `:132-145` (loading via `loading_title_stage`) → `termrock::layout::render_dialog_shell(frame, area, Some(&title), PanelChrome::Focused, &DesignSystem::default())`.
- Title paint path: `layout/dialog.rs:15-33` → `panel.title(title)`; `widgets/panel.rs:823` paints the title as **one uniform span** `Span::styled(format!(" {clipped} "), recipe.title)` where the `PanelChrome::Focused` title role is `Role::TextStrong` with **no bold** (`style/tokens.rs` `panel_recipe_at`, :1075-1100), whole-string clip to width-4, leading+trailing space padding.

Upstream (verified at `29a16b5b`):

- `widgets/breadcrumbs.rs` — `BreadcrumbItem<Id>` (:87); `BreadcrumbSeparator` (:182-204): the `Arrow` non-ascii glyph is exactly `" → "` (:201) — byte-identical to the product separator; `BREADCRUMBS_COLLAPSE_MAX_WIDTH = 40` (:39) and collapse triggers only when `area.width < 40 && items.len() > 3` (:765) — op-picker trails have at most 3 items, so collapse can never trigger; `pub fn crumbs_from_labels(labels: &[&str]) -> Vec<BreadcrumbItem<String>>` (:975) marks the last item current.
- Paint (:740-880): separators in `Role::TextMuted`; current crumb `Role::TextStrong` **+ BOLD** (:858-861, reinforced :870-874); non-current enabled crumbs `Role::TextMuted`; per-item truncation `take_display_cols(label, 24)` (max_w at :844); no leading/trailing padding; paints into a 1-row body `Rect` — it is **not** a panel-title-slot renderer.
- Planning-time misfit analysis (re-verify at execution): no consumer configuration makes `Breadcrumbs` reproduce the current title byte-identically — (a) the shell title slot takes `Option<&str>` (one plain string, one style) while the widget paints mixed styles into a body rect; (b) the current crumb is programmatically BOLD upstream while today's title has no bold; (c) separators render `TextMuted` vs today's uniform `TextStrong`; (d) per-item 24-col truncation and missing `" "` padding differ from the title's whole-string clip with padding. Any of (b)–(d) alone breaks the zero-tolerance PNG gate; (a) moves the text off the title row, breaking the text snapshots.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Local merge-readiness gate | `cargo xtask ci --fast` | exit 0 (lint + policy + tests + docs + snapshots; ch01:21) |
| Text-snapshot parity lane | `cargo xtask ci --only snapshots` | exit 0, zero snapshot diffs (= `cargo nextest run -p jackin-capsule -p jackin-console --locked`, runs ALL tests in both crates — misnomer, ch01:91) |
| Crate tests | `cargo nextest run -p jackin-oppicker` / `cargo nextest run -p jackin-console` | all pass (ch01:83) |
| Focused op-picker tests | `cargo nextest run -p jackin-console -E 'test(/op_picker/)'` | all pass (filter form ch01:161) |
| Lint | `cargo clippy -p jackin-oppicker --all-targets -- -D warnings` and `-p jackin-console` | exit 0 (oppicker README verify block) |
| Format | `cargo fmt --check` | exit 0 |
| Unused-dependency gate | `cargo shear --deny-warnings` | exit 0 (ch01:119; runs in the policy partition, ci.rs:220) |
| Pixel parity | the PNG-baseline comparison command recorded in plan 005's Done criteria | exit 0 |

(Commands proven by research/jackin-verification-tooling/01-gates-and-commands.md, cited as ch01 above.)

## Suggested executor toolkit

- `tailrocks-rust-best-practices` — before writing the new subscription enum and the CollectionState wiring in steps 2–3.
- `<TERMROCK_CHECKOUT>` module docs: `crates/termrock/src/widgets/breadcrumbs.rs`, `runtime/subscription.rs`, `interaction/collection.rs` — re-read each before its step; the excerpts above are planning-time snapshots.

## Scope

**In scope** (the only files to create or modify):

- `crates/jackin-oppicker/src/**` — `adapters.rs`, `load.rs`, `state.rs`, `input.rs`, `lib.rs` (and a sibling tests file only if the executor adds crate-level tests under the repo's test-layout rule)
- `crates/jackin-oppicker/Cargo.toml` (drop `jackin-tui`), `crates/jackin-oppicker/README.md` (dependency/adapter wording, same commit as the Cargo.toml change)
- `crates/jackin-console/src/tui/op_picker.rs` and `crates/jackin-console/src/tui/op_picker/**` (`load.rs`, `state.rs`, `model.rs`, `input.rs`, `tests.rs`, `input/tests.rs`) — only where the subscription type/ctor renames and the plan's new tests force the touch
- `crates/jackin-console/src/tui/components/op_picker/**` (`render.rs`, `render_state.rs`, `tests.rs`, `lines.rs`)
- `Cargo.lock` — rides the step-2 commit (hub lock-rides-source law)

**Out of scope** (do NOT touch, even though related):

- `crates/jackin-tui/**` — the facade `ModalOutcome` deletion was plan 006; the facade `Subscription`/`SubscriptionPoll` deletion belongs to the facade-remnant phase (see Maintenance notes), not this plan.
- Console consumers of `ModalOutcome` beyond what already compiles — the switch to the oppicker enum was plan 006.
- `crates/jackin-console/src/tui/op_breadcrumb.rs` and `crates/jackin-console/src/tui/components/op_breadcrumb.rs` — the `OpRef.path` **form-row** display breadcrumb (editor/auth rows), a different surface from the drill-down modal title this plan re-bases; form-row rendering is plan 010 territory.
- Console modal geometry/stacking (plan 009), the scroll cutover (plan 008), other console screens, dialogs/forms (plan 010), layout/chrome (plan 011).
- `<TERMROCK_CHECKOUT>` — read-only.
- `docs/**` — plan 014.

The hub `plans/termrock-migration/README.md` and the roadmap item are protocol-writable and never listed in scope.

## Git workflow

Commit boundaries for this plan (one commit per landed step; the hub's commit/push law applies unmodified):

- Step 1 (only if the doc-comment change lands; otherwise fold verification into step 2's commit): `docs(oppicker): mark ModalOutcome as the canonical product modal outcome`
- Step 2 (atomic: crate rework + console `start_load` + Cargo.toml/Cargo.lock + README): `refactor(oppicker): adopt upstream ReadySubscription and re-home the worker load subscription`
- Step 3: `refactor(oppicker): adopt interaction CollectionState for drill-down selection`
- Step 4: on success only — `refactor(console): render the op-picker breadcrumb through termrock Breadcrumbs`. On the misfit outcome there is **no code commit** for this step; the hub's BLOCKED protocol carries it.

## Steps

### Step 1: Verify and finalize the canonical `ModalOutcome` inside oppicker

1. Run the precondition checks for plan 006 (facade enum gone, operator_info clean, console consumers on the oppicker enum).
2. In `crates/jackin-oppicker/src/adapters.rs`, add a rustdoc line on `ModalOutcome` recording its canonical role — the non-obvious WHY: this enum is the product's single shared modal-outcome contract; the console's facade twin was retired onto it (plan 006). Do **not** reorder, rename, or re-derive the variants — the set `Continue / Commit(T) / Cancel` already serves every consumer, and declaration order is not API-visible.
3. Confirm no oppicker-internal consumer needs adjustment: `input.rs` `handle_key` and `adapters.rs` `TextInputState::handle_key` already return this enum.

**Verify**: `rg -n "pub enum ModalOutcome" crates/jackin-tui/src` → no hits; `cargo nextest run -p jackin-oppicker` → exit 0; `cargo clippy -p jackin-oppicker --all-targets -- -D warnings` → exit 0; `cargo fmt --check` → exit 0.

### Step 2: Replace `BlockingSubscription` with `ReadySubscription` + a product-owned worker subscription

Target shape (the pattern to produce; exact names may follow crate conventions but the semantics are fixed):

1. In `adapters.rs`:
   - Add `pub enum LoadPoll<T> { Ready(T), Pending, Closed }` — the product-owned tri-state poll (upstream `ReadySubscriptionPoll` has no `Pending`, by design).
   - Add `pub struct WorkerSubscription<T>(tokio::sync::oneshot::Receiver<T>)` — the spawn/delivery mechanics of today's `BlockingSubscription`, minus the facade trait impl.
   - Add `pub enum LoadSubscription<T> { Ready(ReadySubscription<T>), Worker(WorkerSubscription<T>) }` with `poll_next(&mut self) -> LoadPoll<T>` translating both arms into the one tri-state poll. The upstream poll enum is `#[non_exhaustive]` — the translation arm must compile with a wildcard.
   - Replace `ready_blocking_subscription` with `ready_load_subscription(value)` (= `LoadSubscription::Ready(ready_subscription(value))`) and `spawn_named_blocking_subscription` with `spawn_named_worker_subscription(name, worker)` (same `jackin_telemetry` named-spawn mechanics, returning `LoadSubscription::Worker`). Keep the WHY comment about the single completion path.
   - Delete `BlockingSubscription`, its facade `Subscription` impl, and both `jackin_tui` imports (`adapters.rs:2`, `load.rs:7`). No alias, no shim (N2).
2. `state.rs:81`: `rx: Option<LoadSubscription<LoadResult>>`. `load.rs`: `attach_load_receiver` takes `LoadSubscription<LoadResult>`; `poll_load` matches `LoadPoll::{Ready, Pending, Closed}` with the **same arm structure** as today — behavior parity lives here.
3. `lib.rs:13-16`: update the re-export set (drop `BlockingSubscription`/`ready_blocking_subscription`/`spawn_named_blocking_subscription`; export the new types).
4. Console `tui/op_picker/load.rs:24-37`: `start_load(...) -> LoadSubscription<LoadResult>`; cached arm → `jackin_oppicker::ready_load_subscription(result)`; miss arm → `jackin_oppicker::spawn_named_worker_subscription("jackin-op-picker-load", ...)`. Keep the worker name string identical.
5. `crates/jackin-oppicker/Cargo.toml`: remove `jackin-tui = { workspace = true }` (:16). `cargo build -p jackin-oppicker` regenerates `Cargo.lock` in the same commit.
6. `crates/jackin-oppicker/README.md`: dependency line drops `jackin-tui` and fixes the pre-existing drift (the README says `jackin-diagnostics`; the actual dep is `jackin-telemetry`, Cargo.toml:15); the "Async receiver adapters" bullet now describes the upstream `ReadySubscription` ready arm + product worker receiver; the Structure table's `adapters.rs` Tests cell says "inline" but the crate has no test modules (grep-verified) — set it to `—` in the same edit. `AGENTS.md` lists no dependencies — confirm its two bullets stay true and leave it unchanged.

**Verify** (in order): `cargo nextest run -p jackin-oppicker` → exit 0; `cargo nextest run -p jackin-console -E 'test(/op_picker/)'` → all pass; `cargo xtask ci --only snapshots` → exit 0 with zero snapshot diffs; the plan-005 PNG comparison command → exit 0; `cargo clippy -p jackin-oppicker --all-targets -- -D warnings` and `-p jackin-console` → exit 0; `cargo fmt --check` → exit 0; `cargo shear --deny-warnings` → exit 0 (the `jackin-tui` removal is registered).

### Step 3: Adopt `interaction/collection` for drill-down selection

1. `state.rs`: replace the five `ListState<usize>` fields with five `CollectionState<usize>` fields, keyed by index into the stage's **filtered projection** (id = filtered-list index). Construction: `CollectionState::new()` (leave `wrap` at its default `true` — it serves the keyboard path) + `set_active(first_selection(count))`, replacing `list_state_for_count` / `for_count`.
2. Keyboard cycle (`input.rs:605-607` `cycle_select`): build the stage's filtered projection as `Vec<CollectionItem<usize>>` (`enumerate()` the filtered list; label = the display label already computed for painting) and call `move_by(&projection, delta)`; where the old code branched on `cycle_index`'s `next != current` return, branch on `outcome.active_changed()`. Empty projection → `active_changed()` is false — same as today's count-0 behavior.
3. Mouse wheel (`state.rs` `scroll_selection`/`scroll_select`): keep **clamp** semantics via the existing product `clamp_selection` helper (`input.rs:615`) + `set_active`. Recorded carve-out: `CollectionState`'s `wrap` flag is state-level; one state must serve wrap (keyboard) and clamp (wheel), so the clamp half stays a ~5-line product helper. Do **not** flip the `wrap` flag per event.
4. Filter resets: keep the explicit first-selection reset (`reset_selection_for_filter` → `filter_reset_selection_for_stage`) — behavior parity. Audit every `.select(...)` / `.selected()` site (`load.rs` poll arms, `render_state.rs` reads, `selected_index_for_stage`): `.select` → `set_active`; `.selected().copied()` → `.active().copied()`. Where a load arm replaces the underlying list while intending to keep a selection, call `reconcile(&projection)`; where it resets, keep the explicit reset — match today's behavior site by site.
5. `matches_filter` and the `filtered_*` projections stay product-owned (upstream contract: host owns filtering/sorting).
6. `render.rs:122-126` keeps painting through the `List` widget with a per-frame `ListState::new(state.selected_index())` — only the source of `selected_index` changes (now the CollectionState active index).

**Verify**: same battery as step 2, in the same order (oppicker nextest → focused console op_picker tests → snapshot lane with zero diffs → PNG comparison → clippy both crates → fmt). `rg -n "ListState" crates/jackin-oppicker/src` → no hits after the step (the console render path's per-frame `ListState` is out of this path's scope).

### Step 4: Re-base the drill-down breadcrumb on `widgets/breadcrumbs`

The spec scenario requires the breadcrumb to **render through** `widgets/breadcrumbs` with identical content; the parity invariant requires byte-identical snapshots and zero PNG diff. Attempt, in order, verifying after each:

1. Build the trail per stage as `Vec<BreadcrumbItem<String>>` via `crumbs_from_labels` (or manual items, last marked current), `BreadcrumbSeparator::Arrow`, non-ascii profile. The per-stage label lists come from the same per-stage table `breadcrumb_title` implements (quoted in Starting state). The planning-time analysis (Starting state, step-4 section) predicts every consumer configuration fails parity; that prediction must be re-verified, not trusted — run each attempt against the gates.
2. Attempt consumer configurations: (a) check whether `Panel`/the dialog shell exposes any span-accepting or widget-accepting title API (inspect `<TERMROCK_CHECKOUT>/crates/termrock/src/widgets/panel.rs` and `layout/dialog.rs` — planning-time read says the title slot is `Option<&str>` only); (b) paint the `Breadcrumbs` widget over the panel title row rect; (c) paint it as a body row and drop the title. After each attempt: `cargo xtask ci --only snapshots` → byte-identical required, and the plan-005 PNG comparison → exit 0 required.
3. If any configuration passes both gates: keep it, delete the now-dead `breadcrumb_title` arms the widget replaces (no dead code — N2/latest-only), commit per the Git workflow.
4. If all consumer configurations fail (the predicted outcome): consumer configuration is exhausted. Revert the working tree for this step — **no code commit** — and take the hub's misfit route: hub row BLOCKED `(termrock API misfit — recommend upstream change: a uniform-style title presentation for Breadcrumbs (e.g. a title-slot mode painting the whole trail in one host-chosen style with host-controlled padding, or a helper returning the joined trail for panel-title slots))`. `breadcrumb_title` stays the title source in the BLOCKED outcome; steps 1–3 remain landed. A misfit BLOCKED is a correct outcome per the hub.

**Verify**: per attempt, the two gates above; on success additionally `cargo nextest run -p jackin-console -E 'test(/op_picker/)'` → all pass, clippy both crates → exit 0, `cargo fmt --check` → exit 0.

## Test plan

New tests in `crates/jackin-console/src/tui/op_picker/tests.rs` (the established model-behavior seam — oppicker itself has no test modules today; its behavior is driven through these console suites), covering the spec scenario "Drill-down behavior preserved" plus the named edge cases:

- **Breadcrumb content matrix** — for each stage × {single-account, multi-account}, assert the rendered modal title content equals hand-written expected literals (e.g. Account → `"1Password"`; multi-account Section → `"alice@example.com → Work → Login"`). Expected values are literals written from the spec scenario's "identical content", not recomputed through `breadcrumb_title` — the test must fail if the mapping table changes. These tests hold under both step-4 outcomes (BLOCKED keeps `breadcrumb_title`; success keeps identical content through the widget).
- **Wrap vs clamp** — keyboard arrow past the last row wraps to the first (and up from the first wraps to the last); wheel scroll past the last row stays on the last (and above the first stays on the first); both at count 0 leave no selection.
- **Filter reset** — editing the filter resets selection to the first row of the filtered projection; clearing the filter restores the full list with first-row selection; back-navigation (stage pop) restores the parent stage's selection.
- **Subscription paths** — a cached load resolves on the first `poll_load` (Ready arm, upstream `ReadySubscription`); a worker load reports Pending until the injected runner delivers, then Ready; the `rx` slot is cleared after Ready and after Closed (dropped worker).

Structural pattern to model after: the existing tests in `crates/jackin-console/src/tui/op_picker/tests.rs`, which already drive staged navigation and loads through the injected `OpStructRunner`.

**Verify**: `cargo nextest run -p jackin-console -E 'test(/op_picker/)'` → all pass, including the new tests; `cargo xtask ci --only snapshots` → exit 0 with zero diffs.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `cargo xtask ci --fast` exits 0
- [ ] `cargo nextest run -p jackin-oppicker` exits 0; `cargo nextest run -p jackin-console -E 'test(/op_picker/)'` exits 0 with the new drill-down behavior tests present and passing
- [ ] `rg -n "BlockingSubscription|jackin_tui" crates/jackin-oppicker/src crates/jackin-oppicker/Cargo.toml` → no hits
- [ ] `rg -n "BlockingSubscription|ready_blocking_subscription|spawn_named_blocking_subscription" crates/` → no hits
- [ ] `rg -n "ReadySubscription" crates/jackin-oppicker/src/adapters.rs` → at least one hit
- [ ] `rg -n "CollectionState" crates/jackin-oppicker/src/state.rs` → at least one hit; `rg -n "ListState" crates/jackin-oppicker/src` → no hits
- [ ] `rg -n "pub enum ModalOutcome" crates/jackin-tui/src` → no hits (plan 006's deletion remains intact)
- [ ] `cargo shear --deny-warnings` exits 0 (oppicker's `jackin-tui` removal registered)
- [ ] `cargo xtask ci --only snapshots` exits 0 with zero snapshot diffs (byte-identical text parity)
- [ ] The PNG-baseline comparison command recorded in plan 005's Done criteria exits 0
- [ ] Breadcrumb outcome resolved one of two ways: `rg -n "Breadcrumbs" crates/jackin-console/src/tui/components/op_picker/render.rs` → at least one hit with both parity gates green; OR the hub's misfit BLOCKED route was taken for step 4 (recorded per the hub protocol) with steps 1–3 landed and green
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status rows and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails — in particular: the facade `ModalOutcome` still exists (006 incomplete), `operator_info.rs` still consumes `crate::ModalOutcome`, or console consumers do not import the oppicker enum — or "Starting state" does not match reality.
- Any text-snapshot diff or PNG-baseline diff appears at any step — the hub's parity law applies: STOP for operator review, never re-bless.
- Step 4's consumer configurations are exhausted without byte-identical parity — take the hub's misfit BLOCKED route with the recommendation line quoted in step 4; do not ship the divergence and do not edit `<TERMROCK_CHECKOUT>`.
- The assumption "A5" (upstream APIs at the pinned rev match the researched surface) turns out false — e.g. `ReadySubscription`, `CollectionState`, or `Breadcrumbs` renamed/removed/changed signature at rev `29a16b5b`.
- The work requires touching an out-of-scope file (facade deletion, `op_breadcrumb.rs` form rows, 009 modal geometry, other console screens) or violating a Must NOT.
- A step's verification fails twice after a reasonable fix attempt.

## Maintenance notes

- **Facade `Subscription`/`SubscriptionPoll` deletion**: after this plan, research ch07's last blocker (oppicker) is gone — the facade trait and poll enum have zero consumers. Deletion is routed to the facade-remnant phase (capsule/launch adapters still occupy that seam); do not delete them here. The next `tailrocks-plan` re-run should pick this up; if none is scheduled, flag it in the hub.
- **Plan 014 (docs alignment)**: TUI reference pages under `docs/content/reference/tui/` that mention the op-picker or breadcrumb machinery are 014's sweep; this plan updates only the crate-local README (dependency/API change law).
- **Reviewer scrutiny**: the wrap-vs-clamp split (keyboard wraps via `CollectionState::move_by` with default `wrap = true`; wheel clamps via the product helper — never per-event flag flips); the single-completion-path invariant in `poll_load`; the filter-reset behavior; the README dependency list.
- **Deferred follow-up**: if TermRock later grows a Pending-capable subscription contract, oppicker's `WorkerSubscription`/`LoadPoll` are the seam to revisit — no action now.
