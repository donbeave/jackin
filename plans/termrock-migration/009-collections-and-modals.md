# Plan 009: Cut console list geometry/selection and modal geometry to CollectionState/RovingFocusGroup/VirtualList and OverlayStack/DismissPolicy

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED (selection semantics and modal rect math are pixel-visible; the byte-identical snapshot + PNG gates are the whole acceptance)
- **Depends on**: plans/006-*.md (its PNG-baseline gate from plan 005 also binds every step)
- **Covers**: F5 (C2 list geometry, C4 selection helpers, C5 modal system), B14 (byte-identical console text snapshots), D16 (UI/UX parity invariant), B15 (no performance gate)
- **Guardrails**: N2, N4 inlined below
- **Research basis**: `research/termrock-head-adoption/04-component-adoption-candidates.md` (C2/C4, C5 pairings), `research/termrock-head-adoption/06-mouse-subsystem-parity-matrix.md` (rows 8, 9, 13); commands from `research/jackin-verification-tooling/01-gates-and-commands.md`
- **Planned at**: commit `f320b51f`, 2026-08-19

## Why this matters

The console's list geometry (column split, per-row widths, scroll clamps, scroll axes), its wrap-around selection helpers, and its per-modal rect spec system are hand-rolled machinery that upstream `CollectionState`/`RovingFocusGroup`/`VirtualList` and `OverlayStack`/`DismissPolicy` now cover. After this plan lands, flat selection movement runs on upstream collection primitives, the workspaces list's two-level cursor+instance-sub-row selection is a product wrapper over a flat `CollectionState` (upstream has no two-level model — decided carve-out), long-list windowing rides `VirtualListState`, and every modal's geometry, backdrop, stacking, and Esc/click-outside policy come from the post-006 `OverlayStack` with declarative `DismissPolicy` — while the 19-variant `ConsoleModal` flow enum stays product-owned (decided carve-out: upstream carries geometry/stacking only).

## Preconditions — run before anything else

Run each; any failure is a STOP.

1. **Plan 006 landed (console on upstream contracts).** All four checks:
   - `grep -E '^\| 006 \|' plans/termrock-migration/README.md | grep -q 'DONE'` → exit 0.
   - `rg -l 'FocusGraph' crates/jackin-console/src` → at least one file (planning time: zero hits — 006 introduces them).
   - `rg -l 'OverlayStack' crates/jackin-console/src` → at least one file (planning time: zero hits).
   - `rg -n 'ModalFlow' crates/jackin-console/src` → no hits (planning time: hits in `screens/settings/model.rs`, `screens/settings/model/env_impls.rs`, `screens/settings/model/auth_impls.rs`); `test ! -f crates/jackin-tui/src/runtime/modal_flow.rs` → exit 0 (006 deletes it).
2. **Plan 005 landed (PNG baselines pass).** `grep -E '^\| 005 \|' plans/termrock-migration/README.md | grep -q 'DONE'` → exit 0. Then open `plans/termrock-migration/005-*.md` (match by the `005-` prefix), find the cheapest done criterion it names, and run it → passes. If no `005-*.md` file exists or it names no runnable criterion, STOP.
3. **Pin**: `grep -n 'rev = "29a16b5bff84ea8609854711b774e87acbc456cc"' Cargo.toml` → prints the pin line (planning time: line 118).
4. **TermRock input checkout**: `git -C <TERMROCK_CHECKOUT> rev-parse HEAD` → `29a16b5bff84ea8609854711b774e87acbc456cc`.
5. **Toolchain**: `rustc --version` → `rustc 1.97.1`; `cargo nextest --version` → `cargo-nextest 0.9.140`.
6. **Drift check** (this plan edits pre-existing code): `git diff --stat f320b51f..HEAD -- crates/jackin-console crates/jackin/src/console` and `git log --oneline f320b51f..HEAD -- crates/jackin-console`. Changes from the landed commits of plans 005–008 are expected, not drift — plan 008 (if landed) replaces raw `u16` scroll-offset fields with `ScrollAreaState`, so this plan's geometry/scroll-clamp anchors may already read `offset_x()/offset_y()` instead of fields. For every in-scope file this plan edits, compare the "Starting state" anchors below against live code before editing: **symbol names are the authority; every line number in this plan is a planning-time snapshot**. A mismatch that changes the cutover shape — a renamed/deleted symbol, a moved lane, a changed guard — is a STOP.
7. **Parity gate starts green**: `cargo nextest run -p jackin-console --locked` → all pass; `cargo xtask ci --only snapshots` → exit 0.
8. **Clean tree**: `git status --porcelain` → empty.

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

### Requirement: Interaction core on upstream primitives

Console scrolling SHALL adopt `ScrollArea`; list geometry and selection SHALL adopt `CollectionState`/`RovingFocusGroup`/`VirtualList`; modal geometry and stacking SHALL adopt `OverlayStack`/`DismissPolicy`; mouse machinery SHALL adopt `UiContext`/HitRegion plus `ScrollArea` wheel handling. Horizontal char-precise scroll (no upstream analogue) MUST stay hand-rolled; the two-level cursor+instance-sub-row selection MUST be re-hosted as a product wrapper; the 19-variant `ConsoleModal` flow enum MUST stay product-owned (upstream carries geometry/stacking only). The mouse cutover is gated on the mouse-parity-matrix research chapter (Q1), whose verdict is proceed-with-compensations: `.wheel_steps(1, 1)` on every `ScrollAreaState` (upstream defaults 3/4 differ); Shift+wheel vertical-fallback retry in consumer dispatch on `ScrollOutcome::Ignored`; scrollbar drag stays consumer-side (no upstream drag lane); the routing precedence chain, pointer-shape cue, and deselect sentinel stay consumer code over `hit_test`/`route_pointer`.

Covers: F5 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md (C1, C2/C4, C5, C14 pairings), research/termrock-head-adoption/06-mouse-subsystem-parity-matrix.md

#### Scenario: Modal stack cutover

- **WHEN** a `ConsoleModal` variant opens over a stage view
- **THEN** geometry and stacking come from `OverlayStack`/`DismissPolicy`
- **AND** the modal flow (open/close/esc cascade/result) behaves exactly as the pre-cutover flow enum

### Requirement: No performance gate

The console phase SHALL carry no performance budget or gate; rendering-parity gates (byte-identical text snapshots, zero-tolerance PNG baselines, behavioral parity tests) are the whole acceptance.

Covers: B14, B15 · Evidence: roadmap item §Decisions (parity rule ruling, 2026-08-19)

#### Scenario: Virtualization adoption without perf sign-off

- **WHEN** `VirtualList` adoption lands on a long console list
- **THEN** acceptance is the parity gates alone — no latency or throughput measurement is required or recorded

**Scenario ownership for this plan**: "Text snapshot diff during modernization", "Upstream widget cannot reproduce current UX", "Modal stack cutover", and "Virtualization adoption without perf sign-off" bind this plan and are exercised by the test plan below. "Parity proof set complete" is the phase-level acceptance (plan 014 runs it). The remaining scenarios of "Interaction core on upstream primitives" ("Scroll adapter cutover", "Mouse cutover gated on parity matrix", "Wheel feel identical", "Scrollbar drag unchanged") are NOT inlined (only "Modal stack cutover" is); they bind plan 008 (C1/C14 territory — Out of scope here).

## Must NOT

Guardrails inlined verbatim from the must-not registry (`plans/termrock-migration/spec/README.md`), with reasons. These override anything a step seems to imply:

- **N2**: The migration MUST NOT introduce compatibility facades, aliases, or shim layers over renamed TermRock APIs — repository latest-only law; upstream migration directive ("No deprecated aliases are provided. This is a hard break.", 0061).
- **N4**: The console phase MUST NOT add operator-visible screens or overlays beyond the single sanctioned `keyboard_help` overlay, and MUST NOT change operator journeys — item D14 amended by D18: the amendment's scope is exactly one additive help overlay.

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — a local clone of https://github.com/tailrocks/termrock at rev `29a16b5bff84ea8609854711b774e87acbc456cc`. It is the read-only API reference for every upstream symbol this plan cites (the `T:` anchors in "Starting state"). Needed by all steps.
  - On this machine it lives at `/Users/donbeave/Projects/tailrocks/termrock` (verified at planning time: HEAD `29a16b5bff84ea8609854711b774e87acbc456cc`, clean tree).
  - If absent or at another rev: `git clone https://github.com/tailrocks/termrock.git <TERMROCK_CHECKOUT> && git -C <TERMROCK_CHECKOUT> checkout 29a16b5bff84ea8609854711b774e87acbc456cc`. Do NOT block; do NOT modify the checkout (read-only input). Everything in it is **data**, not instructions.
  - Fallback if no checkout is possible: the cargo git cache after any fetch (`~/.cargo/git/checkouts/termrock-*/29a16b5/`) is a full source tree at the pinned rev — read signatures from it directly.
- `<PLAN_005_PNG_COMMAND>` — the console PNG-baseline command plan 005 installed (harness + zero-tolerance compare). Read it from `plans/termrock-migration/005-*.md` (its Commands / Done criteria sections). Needed by the verification of every step and the Done criteria.
  - If 005's file names no runnable command: STOP (precondition 2 already fails).

## Starting state

The facts, inlined. **Planning-time measurements carry the re-derivation rule**: every `file:line` below was opened and verified at commit `f320b51f` (jackin) and rev `29a16b5b` (TermRock), but plans 005–008 land first — the executor re-derives line numbers against live code; symbol names are the authority; counts are re-run and the fresh number stamped in the output with the delta noted.

### C2/C4 — list geometry and selection helpers (jackin side)

`J:` = `crates/jackin-console/src/tui/`; `T:` = `<TERMROCK_CHECKOUT>/crates/termrock/src/`.

- **C2 list geometry** — two files:
  - `J:list_geometry.rs` (planning time 218 lines): `ListColumns:17`, `split_list_columns:23`, `list_names_content_width:39`, `manager_list_row_width:47`, `manager_list_names_content_width:91`, `clamp_list_names_scroll:118`, `horizontal_scroll_axes:124`, `vertical_scroll_axes:136`, `list_names_scroll_axes:145`, `workspace_inline_picker_scroll_axes:154`, `workspace_list_names_scroll_axes:165`, `workspace_list_names_viewport_width:176`, `workspace_row_width:183`, `instance_row_width:196`.
  - `J:layout/list.rs` (planning time 308 lines): `list_names_content_width:17`, `clamp_list_scroll_for_area:60`, plus sidebar-layout consumers.
  - The **horizontal char-precise scroll** half (`list_names_content_width`, `clamp_list_names_scroll`, `*_scroll_axes`, row-width fns) has NO upstream analogue (research ch04: "jackin's horizontal char-precise scroll (`list_names_content_width`) has no direct virtual_list analogue") — it MUST stay hand-rolled (spec-decided). It composes with plan 008's `ScrollAreaState` storage.
- **C4 selection helpers** — `J:focus.rs` (planning time 62 lines): `moved_selection:18` (wrap-around move: `last = row_count.saturating_sub(1)`, delta-clamped wrap) and `follow_cursor_y:33` (already rides upstream `termrock::scroll::cursor_follow_offset`) + `cursor_scroll_for_panel:49`. Consumers of `moved_selection`/`follow_cursor_y` (planning-time `rg -l`): `update.rs`, `screens/settings/update.rs`, `screens/settings/model/general_impls.rs`, `screens/workspaces/update.rs`, `screens/workspaces/view.rs`, `screens/editor/update.rs`.
- **Two-level selection (the wrapper target)**: `J:state.rs:235` `pub selected: usize` on `ManagerState`; logical-row enum `ManagerListRow` at `J:screens/workspaces/model.rs:13` — variants `CurrentDirectory`, `CurrentDirectoryInstance(usize)`, `SavedWorkspace(usize)`, `WorkspaceInstance(usize, usize)`, `NewWorkspace`. The flat `selected` index maps onto a row list that mixes workspace rows and per-workspace instance sub-rows — upstream `CollectionState` is flat (`T:interaction/collection.rs:107`: `roving + offset + viewport_len + total_len`), so the two-level semantics MUST be re-hosted as a product wrapper: the wrapper owns the `Vec<ManagerListRow>` projection and the `ManagerListRow` ↔ flat-index mapping; `CollectionState` carries active-index movement, wrap policy, and viewport windowing underneath (spec-decided carve-out, not an open question).
- **Modal/picker selection (ch06 row 9 — DECIDED here)**: picker and file-browser modal selection uses upstream `termrock::widgets::ListState` already (`J:components/file_browser/state.rs:14` `use termrock::widgets::ListState;` — `cycle_index` at `T:widgets/list.rs:943` wraps, `move_index` at `T:widgets/list.rs:966` saturates). Keyboard navigation wraps (`select_next`/`select_prev` → `cycle_index`, `file_browser/state.rs:115-122`); wheel moves SELECTION saturating with no wrap (`scroll_selection` → `move_index`, `file_browser/state.rs:124-133`, with the WHY comment at `:126-131`); `J:input/mouse/modal_scroll.rs:20-33` is vertical-only step-1. **Decision recorded: modal/picker selection STAYS on upstream `ListState` and does NOT migrate to `CollectionState`** — `CollectionState`'s single `.wrap(bool)` policy (`T:interaction/collection.rs:139-143`) cannot express the wheel-saturates/keyboard-wraps split per input source, and `ListState` is already the upstream carrier. `modal_scroll.rs` and every picker's `ListState` stay untouched by this plan.

### C5 — modal system (jackin side)

- **Flow enum (stays product)**: `ConsoleModal` 19-variant enum at `J:model/modal.rs:24` (variants listed at `:48-114`: TextInput, FileBrowser, MountDstChoice, WorkdirPick, Confirm, SaveDiscardCancel, GithubPicker, ConfirmSave, ErrorPopup, ContainerInfo, StatusPopup, OpPicker, RolePicker, RoleOverridePicker, AuthRolePicker, SourcePicker, AuthSourcePicker, ScopePicker, AuthForm). It encodes jackin flow logic upstream does not model — spec-decided: the enum and the open/close/result flow stay product-owned; ONLY geometry/stacking/dismiss-policy move upstream.
- **Rect specs (the replacement surface)**: `J:components/modal_rects.rs` (planning time 402 lines): `ModalRectSpec:16` (TextInput, SourcePicker, ScopePicker, OpPicker, RolePicker{filtered_len}, Confirm{width_pct,height}, MountChoice, AuthForm{required_height}, Fixed{width_pct,height}, Exact{width,height}, MaxWidthMin…), `ModalRectMode:168` + `ModalRectMode::spec:188`, `modal_rect:241` dispatching per-spec rect fns. Consumers (planning-time `rg -l 'modal_rect|ModalRectMode'`): `input/mouse/modal_scroll.rs`, `input/mouse.rs`, `run.rs`, `screens/settings/model.rs`, `screens/settings/view.rs`, `components/file_browser.rs`, `components.rs`, `model/modal/display.rs`, `model/modal/auth_impls.rs`, `view.rs` (+ test files `model/tests.rs`, `run/tests.rs`).
- **Backdrop + modal render**: `render_modal_backdrop` at `J:view.rs:392`, `render_modal` at `J:view.rs:424`; called from the frame composition at `view.rs:630-650`. Dialog body composition `J:dialog_layout.rs:22` `dialog_content_and_actions` already rides upstream `termrock::layout::bottom_rows`; dialog chrome already uses upstream `render_dialog_shell` (`T:layout/dialog.rs:15`; call sites e.g. `components/github_picker.rs:88`, `components/mount_dst_choice.rs:95`, `components/source_picker.rs:87`) — both stay.
- **Modal-open inertness (ch06 rows 8, 13 — already gated)**: modal wheel captures before background (`J:input/mouse.rs:140-146`; tests `mouse/tests.rs:375-471,1580,1669-1736,1765`) and the background is inert while any modal is open (`J:input/mouse/scroll_pan.rs:147-149` etc., `scroll_bars.rs:22,75,111,148,197,212`) — post-006 `OverlayStack` facts (`OverlayPolicy.wheel_captures` `T:interaction/overlay_stack.rs:191-192`, `wheel_captured(position)` `:877-879`, `route_pointer` `:954-968`) may back these guards where equivalent; the mouse lanes themselves are plan 008's territory. This plan's obligation: the geometry/stacking cutover MUST NOT change those behaviors — the named mouse tests are the gate.

### Upstream API surface (verified at `29a16b5b`)

- **`CollectionState<Id>`** — `T:interaction/collection.rs:107`. Constructors/config: `Default` impl (:114-118), `.orientation():134`, `.wrap(bool):141`. Movement/outcome: `reconcile(items):223` → `CollectionOutcome`, `reconcile_window:239`, `move_by(items, steps):254`, `move_next:264` / `move_previous:269` / `move_first:274` / `move_last:284`, `move_page:294`, `scroll_by:304`, `ensure_active_visible:325`, `set_viewport(offset, viewport_len, total_len):200`, `active_index(items):391`, `handle_intent:352`, `handle_key:376`. Items: `CollectionItem::new(id, label):36`, `.enabled():47`, `.parent():54` (planning-time line numbers; symbols are authority).
- **`RovingFocusGroup<Id>`** — `T:interaction/roving.rs:89` (`active`, `orientation`, `wrap`, `typeahead`). `move_by(entries, steps):226`, `reconcile(entries):189`, `typeahead_char:353`, `handle_key:323`. Does NOT own external focus — pairs with `FocusNode::roving_collection` on the post-006 `FocusGraph` (doc at `roving.rs:86-88`).
- **`VirtualListState<Id>`** — `T:widgets/virtual_list.rs:150`. `new():175`, `set_logical_len:311`, `set_viewport_extent:327`, `scroll_by:332`, `set_offset:341`, `visible_slice:354`, `visible_range:382`, `reveal:394`, `set_overscan:279`, `regions():413` (painted `HitRegion`s), `hover:418` / `click:430`, `handle_intent:448`.
- **`OverlayStack`** — `T:interaction/overlay_stack.rs:22-123`: `OverlayId:22`, `OverlayKind:53` (Dialog, AlertDialog, …), `PlacementPrefer:83` (Center, …), `BackdropPolicy:110` (None, Dim, Occlude), `NarrowFallback:121`. Bookkeeping lives post-006 in the console state (precondition 1); routing helpers `wheel_captured:877-879`, `route_pointer:954-968`.
- **`DismissPolicy`** — `T:interaction/dismissable.rs:72`: fields `escape`, `outside`, `focus_leave`, `parent_closed`, `explicit` (each a `DismissAction`: Dismiss/Trap/Bubble); presets `dismissible()` (Esc + outside dismiss), `critical()` (Esc + outside TRAP, parent cascades), `light()`. Esc/click-outside become declarative per modal variant.

### Conventions to match

- Comments: non-obvious WHY only. Carve-out seams get a one-line WHY comment naming the decision (exemplar: `file_browser/state.rs:126-131` wheel-vs-keyboard comment).
- Tests live in the sibling `tests.rs` of their module (repo test-layout rule); no new test files outside that layout.
- The 001-merged `trparity_*` tests are the flow/focus parity gate (planning-time locations: `crates/jackin-tui/src/runtime/tests.rs:69-135` `trparity_modal_flow_open_sub_preserves_parent`, `trparity_modal_flow_pop_restores_parent_and_clears_chain`, `trparity_modal_flow_clear_closes_whole_chain`, `trparity_surface_focus_*`; `crates/jackin-console/src/tui/screens/editor/model/tests.rs:1845,1870` `trparity_editor_focus_owner_survives_modal_cancel/commit`). Plan 006 re-homes `ModalFlow` — re-derive locations with `rg -ln 'trparity' crates/`; wherever they live post-006, they MUST stay green unmodified in expectation.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Build | `cargo check --workspace --all-targets --locked` | exit 0 |
| Console suite | `cargo nextest run -p jackin-console --locked` | all pass |
| Mouse module (row 8/9/13 gates) | `cargo nextest run -p jackin-console --locked -E 'test(/tui::input::mouse::tests/)'` | all pass (planning-time count 56; re-derive) |
| List input module | `cargo nextest run -p jackin-console --locked -E 'test(/tui::input::list::tests/)'` | all pass (planning-time count 30; re-derive) |
| State update module | `cargo nextest run -p jackin-console --locked -E 'test(/tui::state::update::tests/)'` | all pass (planning-time count 37; re-derive) |
| Flow/focus parity tests | `cargo nextest run --workspace --locked -E 'test(/trparity/)'` | all pass (locations re-derived via `rg -ln 'trparity' crates/`) |
| Snapshot lane (byte-identical gate) | `cargo xtask ci --only snapshots` | exit 0 |
| PNG baseline lane | `<PLAN_005_PNG_COMMAND>` | zero-tolerance pass |
| Clippy | `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` | exit 0 |
| Format | `cargo fmt --check` | exit 0 |
| Final fast gate | `cargo xtask ci --fast` | exit 0 |

(All from `research/jackin-verification-tooling/01-gates-and-commands.md`: ci.rs partition map for `check`/`nextest`/`ci --only snapshots`/`clippy`/`fmt`/`ci --fast`; TESTING.md:22-32 for the `-E 'test(...)'` filter forms. `cargo xtask ci --only snapshots` = `cargo nextest run -p jackin-capsule -p jackin-console --locked` — the repo-proven snapshot gate; any `.snap` diff is a parity break per the spec scenario, NEVER re-bless.)

## Scope

**In scope** (the only files to create or modify):

- `crates/jackin-console/src/tui/list_geometry.rs` (+ its sibling tests) — delete the superseded vertical-window/clamp half; keep the horizontal char-precise half
- `crates/jackin-console/src/tui/layout/list.rs` (+ `layout/tests.rs`) — same split
- `crates/jackin-console/src/tui/focus.rs` — delete `moved_selection` after migration; keep `follow_cursor_y`/`cursor_scroll_for_panel` unless superseded
- `crates/jackin-console/src/tui/state.rs`, `state/update.rs` (+ tests) — selection storage cutover to the wrapper
- `crates/jackin-console/src/tui/screens/workspaces/{model.rs,update.rs,view.rs,view/list.rs}` (+ sibling tests) — two-level wrapper + `VirtualListState` windowing on the workspaces/instance list
- `crates/jackin-console/src/tui/screens/{editor,settings}/**` — ONLY files consuming `moved_selection`/`follow_cursor_y` or modal rect specs, and their sibling test files
- `crates/jackin-console/src/tui/components/modal_rects.rs` — deleted or reduced to nothing as specs move to `OverlayStack` placement
- `crates/jackin-console/src/tui/components.rs`, `components/file_browser.rs` (geometry call sites only), `model/modal.rs`, `model/modal/{display,auth_impls}.rs` — spec/mode plumbing removal; the 19-variant enum itself STAYS
- `crates/jackin-console/src/tui/view.rs` — `render_modal_backdrop`/`render_modal` re-pointed at `OverlayStack` geometry/backdrop
- `crates/jackin-console/src/tui/run.rs`, `input/mouse.rs`, `input/mouse/modal_scroll.rs` — ONLY if a rect-spec signature they consume moves (expected: mechanical re-point, no behavior change)
- ONE new sibling module for the two-level selection wrapper (e.g. `crates/jackin-console/src/tui/screens/workspaces/selection.rs`) + its sibling tests

**Out of scope** (do NOT touch, even though related):

- Scroll/mouse machinery beyond the mechanical re-points above (`ScrollArea`, wheel dispatch, scrollbar drag, hover, seam drag) — plan 008's territory (C1/C14)
- Dialog/form widget adoptions (`confirm_prompt`, `file_picker`, `select`, `form`, …) — plan 010; they STACK ON this plan's geometry cutover
- Layout/chrome/runtime (`panel_stack`, hint bar, spinner, keymap bridge, presenter, resizable split) — plan 011
- Picker/file-browser modal SELECTION model — decided above: stays upstream `ListState`; do not migrate to `CollectionState`, do not touch `modal_scroll.rs` behavior
- `crates/jackin-capsule`, `crates/jackin-launch`, `crates/jackin-tui`, `crates/jackin-oppicker` — other phases/plans (oppicker is plan 013; its `interaction/collection` filtering adoption is plan 013's, not this plan's)
- `docs/content/**` — plan 014 owns the same-PR docs alignment; this plan only NOTES drift (step 5)
- `<TERMROCK_CHECKOUT>` — read-only input; an API misfit follows the hub's BLOCKED route, never a local edit
- `plans/`, `roadmap/`, `research/` — protocol writes only, per the hub

## Git workflow

Commit boundaries for this plan (each commit keeps the tree green — byte-identical snapshot lane included):

1. Step 1 → `refactor(console): move flat selection movement onto CollectionState/RovingFocusGroup`
2. Step 2 → `refactor(console): re-host two-level workspaces selection as a product wrapper over CollectionState`
3. Step 3 → `refactor(console): window the workspaces list through VirtualListState`
4. Step 4 → `refactor(console): cut modal geometry and dismiss policy to OverlayStack/DismissPolicy`
5. Step 5 → `chore(console): record collection/modal carve-outs and sweep superseded geometry helpers`

Steps may be committed individually or gathered, but never reordered; the byte-identical snapshot gate runs after each.

## Steps

### Step 1: Flat selection movement onto `CollectionState`/`RovingFocusGroup` (C4)

Migrate every `moved_selection(selected, row_count, delta)` call site (`J:focus.rs:18`; consumers: `update.rs`, `screens/settings/update.rs`, `screens/settings/model/general_impls.rs`, `screens/editor/update.rs` — re-derive with `rg -n 'moved_selection' crates/jackin-console/src`) to `CollectionState` movement: construct/keep a `CollectionState` per list with `.wrap(true)` (today's `moved_selection` wraps — verify per call site; any call site whose current behavior does NOT wrap keeps `.wrap(false)` and that difference is gated by its existing tests), drive it with `move_by(items, delta)` (`T:interaction/collection.rs:254`), and read back `active_index(items)` (`:391`). Where a screen's selection is consumed by the post-006 `FocusGraph`, register the group via `FocusNode::roving_collection` per the `RovingFocusGroup` doc (`T:interaction/roving.rs:86-88`). `follow_cursor_y` (`J:focus.rs:33`) already rides upstream `cursor_follow_offset` — keep it unless `ensure_active_visible` (`T:interaction/collection.rs:325`) reproduces it byte-identically; if adopted, the snapshot lane decides. Delete `moved_selection` once consumerless. Tests: mechanical substitution only — expected values (wrap at both ends, empty-list, delta overshoot) MUST NOT change.

**Verify**: `cargo check --workspace --all-targets --locked` → exit 0; `cargo nextest run -p jackin-console --locked` → all pass (zero expectation changes); `cargo xtask ci --only snapshots` → exit 0; `<PLAN_005_PNG_COMMAND>` → pass.

### Step 2: Two-level workspaces selection as a product wrapper over `CollectionState` (C2 selection half)

Add ONE new sibling module (e.g. `screens/workspaces/selection.rs`) owning: (a) the `Vec<ManagerListRow>` projection built from the same inputs today's row builder uses (`ManagerListRow` enum at `screens/workspaces/model.rs:13` — `CurrentDirectory`, `CurrentDirectoryInstance(idx)`, `SavedWorkspace(idx)`, `WorkspaceInstance(w, i)`, `NewWorkspace`); (b) the `ManagerListRow` ↔ flat-index mapping in both directions; (c) a `CollectionState<ManagerListRow>`-keyed (or index-keyed) flat state carrying movement/wrap/window underneath. `ManagerState.selected: usize` (`state.rs:235`) stays the public read shape (flat index) — the wrapper translates — so render, click, and keymap consumers see no change. Wrap policy MUST match today's `moved_selection` behavior on this list (wraps; gated by existing list navigation tests). Cut every workspace-list selection mutation (`screens/workspaces/update.rs`, `state/update.rs`) onto the wrapper. One-line WHY comment at the wrapper header: two-level cursor+instance-sub-row selection re-hosted over flat `CollectionState` — upstream has no two-level model (spec carve-out).

**Verify**: `cargo nextest run -p jackin-console --locked -E 'test(/tui::input::list::tests/)'` → all pass; `-E 'test(/tui::state::update::tests/)'` → all pass; full console suite → all pass; `cargo xtask ci --only snapshots` → exit 0; `<PLAN_005_PNG_COMMAND>` → pass.

### Step 3: `VirtualListState` windowing on the workspaces/instance list (C2 geometry half; B15 scenario)

Adopt `VirtualListState` (`T:widgets/virtual_list.rs:150`) for the workspaces list's vertical window: `set_logical_len` (`:311`) from the wrapper's row count, `set_viewport_extent` (`:327`) from the list pane height, `visible_slice`/`visible_range` (`:354`/`:382`) replacing the hand-computed visible window in `layout/list.rs` and the vertical half of `clamp_list_scroll_for_area` (`layout/list.rs:60`); drive scroll through `scroll_by`/`set_offset`/`reveal` (`:332`/`:341`/`:394`) — or through plan 008's `ScrollAreaState` where 008 already owns the offset (if 008 landed, VirtualList's window MUST read the same offset as paint; a dual-source offset is a STOP). Delete the superseded vertical-window math in `list_geometry.rs`/`layout/list.rs`. The **horizontal char-precise half stays hand-rolled exactly as today** (`list_names_content_width`, `clamp_list_names_scroll`, `horizontal_scroll_axes`, `workspace_row_width`, `instance_row_width` — no upstream analogue, spec carve-out; one-line WHY comment at `list_geometry.rs` header). No performance measurement of any kind — acceptance is the parity gates alone (B15 spec scenario).

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass; `cargo xtask ci --only snapshots` → exit 0 (byte-identical — windowing must render identically); `<PLAN_005_PNG_COMMAND>` → pass.

### Step 4: Modal geometry/stacking/dismiss onto `OverlayStack`/`DismissPolicy` (C5)

Replace the `ModalRectSpec`/`ModalRectMode` system (`components/modal_rects.rs:16-241`) with post-006 `OverlayStack` placement: each of the 19 `ConsoleModal` variants maps to an overlay entry carrying `OverlayKind::Dialog` (or `AlertDialog` for the confirm/purge blockers), `PlacementPrefer::Center` (today's specs are all centered — verify per spec fn before deleting), `BackdropPolicy` matching today's backdrop (`render_modal_backdrop`, `view.rs:392` — verify Dim vs Occlude by what the backdrop paints), and `NarrowFallback` reproducing each spec's small-terminal clamp behavior. `render_modal` (`view.rs:424`) reads the rect from the stack entry instead of `modal_rect(outer, spec)`. Esc/click-outside become per-variant `DismissPolicy` (`T:interaction/dismissable.rs:72`): `escape`/`outside` set to reproduce TODAY's per-variant behavior exactly — e.g. variants where Esc closes get `DismissAction::Dismiss`; any variant where Esc is trapped today gets `Trap` (the `critical()` preset traps Esc + outside while parent cascades). The per-variant dismiss mapping is derived from the CURRENT keymap/update behavior, never invented; each variant's mapping is gated by its existing Esc/close tests and the `trparity_modal_flow_*` chain tests. The `ConsoleModal` enum, its open/close/result flow, and `dialog_content_and_actions` (`dialog_layout.rs:22`) stay product-owned and untouched. Delete `modal_rects.rs` once consumerless (its consumers re-point in the same commit — planning-time list in "Starting state"). Mouse modal lanes (`input/mouse.rs:140-146`, `modal_scroll.rs`) get only mechanical signature re-points; rows 8/13 behaviors (capture-before-background, background-inert) MUST NOT change.

**Verify**: `cargo nextest run -p jackin-console --locked -E 'test(/tui::input::mouse::tests/)'` → all pass (rows 8/9/13 gates at planning-time anchors `:375-471,1580,1669-1736,1765,1556,1799,1823`); `cargo nextest run --workspace --locked -E 'test(/trparity/)'` → all pass; full console suite → all pass; `cargo xtask ci --only snapshots` → exit 0; `<PLAN_005_PNG_COMMAND>` → pass.

### Step 5: Carve-outs recorded, superseded helpers swept, drift noted

1. **Carve-out WHY comments** (one line each, at the seam): horizontal char-precise scroll in `list_geometry.rs` header (no upstream analogue — spec carve-out); two-level wrapper header in the new selection module (spec carve-out — flat `CollectionState`); `ConsoleModal` enum header in `model/modal.rs` (flow enum stays product — upstream carries geometry/stacking only, spec carve-out); modal/picker selection in `file_browser/state.rs` near the existing `:126-131` comment (ch06 row 9 decision recorded: `ListState` stays — wheel saturates/keyboard wraps, `CollectionState` single wrap policy cannot express both).
2. **Sweep**: `rg -n 'moved_selection' crates/jackin-console/src` → no hits; `rg -n 'ModalRectSpec|ModalRectMode|modal_rect\(' crates/jackin-console/src` → no hits (or every survivor justified in the commit message); dead vertical-clamp helpers from step 3 gone.
3. **Docs drift note (for plan 014, no docs edits)**: `rg -ln 'modal|dialog|list|selection|virtual' docs/content/reference/tui/` → list the pages whose described machinery this plan re-platformed (planning-time candidates: `dialogs.mdx`, `components.mdx`, `navigation.mdx`); record the list + what changed in the final commit message body.

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass; `cargo xtask ci --only snapshots` → exit 0; `<PLAN_005_PNG_COMMAND>` → pass; `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` → exit 0; `cargo fmt --check` → exit 0; `cargo xtask ci --fast` → exit 0.

## Test plan

- **The parity gate (MUST pass, unmodified in expectation)** — the full console suite, with these named anchors mapped to this plan's risks:
  - Modal wheel capture / background inert (ch06 rows 8, 13 — geometry cutover must not move them): `list_github_picker_wheel_scrolls_modal_selection` (`mouse/tests.rs:375`), `editor_workdir_picker_wheel_scrolls_modal_selection_not_background` (`:405`), `settings_role_picker_wheel_scrolls_modal_selection_not_background` (`:438`), `editor_file_browser_wheel_scrolls_modal_selection_not_background` (`:1580`), `create_prelude_file_browser_wheel_scrolls_modal_selection` (`:1669`), `file_browser_wheel_at_edge_is_consumed_before_background_scroll` (`:1765`), `editor_vertical_wheel_ignores_background_when_modal_open` (`:1556`), `editor_vertical_scrollbar_drag_ignores_background_when_modal_open` (`:1799`), `settings_vertical_scrollbar_drag_ignores_background_when_modal_open` (`:1823`).
  - Row 9 selection split (unchanged — the decision's gate): the file-browser keyboard-wrap (`cycle_index`) vs wheel-saturate (`move_index`) coverage in `components/file_browser/` tests and the picker wheel tests above; `esc_at_root_cancels_modal` (`components/file_browser/input/tests.rs:187`), `auth_form_esc_clears_modal_parent_stack` (`input/auth/tests.rs:967`).
  - Flow/focus chain parity: `trparity_modal_flow_open_sub_preserves_parent`, `trparity_modal_flow_pop_restores_parent_and_clears_chain`, `trparity_modal_flow_clear_closes_whole_chain`, `trparity_surface_focus_*` (planning-time `crates/jackin-tui/src/runtime/tests.rs:69-135`; post-006 location re-derived with `rg -ln 'trparity' crates/`), `trparity_editor_focus_owner_survives_modal_cancel/commit` (`screens/editor/model/tests.rs:1845,1870`).
  - List navigation: all of `input/list/tests.rs` (planning-time count 30) and `state/update/tests.rs` (37), plus the click-row selection anchors `click_on_first_row_sets_selected_to_zero` (`mouse/tests.rs:1040`), `click_on_fifth_row_sets_selected_to_four` (`:1049`), `click_on_workspace_list_spacer_does_not_change_selected` (`:1072`), `click_outside_list_rows_does_not_change_selected` (`:1080`).
  - Test edits are mechanical substitution ONLY; expected values come from independent sources (fixed geometry fixtures, fixed row fixtures) — never recomputed through `CollectionState`/`VirtualListState` themselves.
- **New tests** (in the new selection module's sibling `tests.rs`, plus `model/tests.rs` for the dismiss mapping; modeled on the existing `ManagerListRow` and modal-fixture patterns):
  1. Wrapper round-trip: every `ManagerListRow` variant maps to a flat index and back losslessly across mixed workspace/instance expansions (including collapsed workspaces and the `NewWorkspace` tail row).
  2. Wrapper wrap parity: moving up from flat index 0 lands on the last row; moving down from the last lands on 0 — matching the pre-cutover `moved_selection` behavior on the same fixed row fixture.
  3. `VirtualList` window parity: a fixed row-count + pane-height fixture yields the same first/last visible row indices the pre-cutover clamp produced (expected values stated as literals, not recomputed).
  4. Per-variant `DismissPolicy` mapping: each `ConsoleModal` variant's policy `escape`/`outside` actions equal the pre-cutover behavior table (one assertion per variant; the table in the test is written from reading the CURRENT keymap/update code, cited in a comment).
- **Verify**: `cargo nextest run -p jackin-console --locked` → all pass, including the new tests; `cargo nextest run --workspace --locked -E 'test(/trparity/)'` → all pass; `cargo xtask ci --only snapshots` → exit 0 (byte-identical — the spec scenario's gate).

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `cargo check --workspace --all-targets --locked` exits 0
- [ ] `cargo nextest run -p jackin-console --locked` exits 0; every named parity-gate test above exists and passes; the new tests exist and pass
- [ ] `cargo nextest run --workspace --locked -E 'test(/trparity/)'` exits 0 — modal-flow and focus-restore parity intact
- [ ] `cargo xtask ci --only snapshots` exits 0 — every console text snapshot byte-identical to its pre-modernization bless (no re-bless, no `*.pending-snap`)
- [ ] `<PLAN_005_PNG_COMMAND>` exits 0 — zero-tolerance PNG baselines pass (never re-blessed here)
- [ ] `rg -ln 'CollectionState' crates/jackin-console/src` non-empty; `rg -n 'moved_selection' crates/jackin-console/src` → no hits; `rg -n 'ModalRectSpec|ModalRectMode' crates/jackin-console/src` → no hits (or each survivor justified in the commit message)
- [ ] `rg -n 'DismissPolicy' crates/jackin-console/src` non-empty; the 19-variant `ConsoleModal` enum still exists (`rg -n 'pub enum ConsoleModal' crates/jackin-console/src/tui/model/modal.rs` → 1 hit) with all 19 variants
- [ ] Carve-out WHY comments present: horizontal scroll (`list_geometry.rs`), two-level wrapper (new module), flow enum (`model/modal.rs`), row-9 `ListState` decision (`file_browser/state.rs`)
- [ ] No performance measurement recorded anywhere in the diff (B15)
- [ ] `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` and `cargo fmt --check` exit 0; `cargo xtask ci --fast` exits 0
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status rows and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails, or "Starting state" does not match reality (a cited symbol renamed/deleted/moved after plans 005–008; remember line numbers are planning-time, symbols are authority).
- ANY console text-snapshot diff appears at any step — that is a parity break per the spec scenario: STOP for operator review, NEVER re-bless.
- A test needs more than mechanical substitution to pass, or an expected value must change.
- `CollectionState`/`RovingFocusGroup`/`VirtualList`/`OverlayStack`/`DismissPolicy` cannot reproduce current behavior through consumer configuration (wrap policy, window, placement, dismiss actions) — that is an upstream misfit: take the hub's BLOCKED route (recommend the concrete upstream change), do not shim it jackin-side (N2). Any cited upstream API missing or renamed at the pin falsifies ledger assumption **A5** — STOP and report it.
- The two-level wrapper cannot preserve `selected: usize` semantics for every consumer, or the `VirtualList` window cannot be driven from the same single offset source paint uses.
- A modal variant's current Esc/click-outside behavior cannot be expressed as a `DismissPolicy` (upstream misfit → BLOCKED route).
- The work requires touching an out-of-scope file (008/010/011/013 territory, capsule/launch/oppicker, `jackin-tui`, `docs/`, the TermRock checkout) or violating a Must NOT.
- `<PLAN_005_PNG_COMMAND>` fails with no intended paint change, or a required input is missing with no replacement contract.

## Maintenance notes

- **Plan 010** stacks directly on this plan's geometry cutover: its dialog widgets (`confirm_prompt`/`alert_dialog`/`file_picker`/`select`/…) mount into the `OverlayStack` entries and `DismissPolicy` mappings this plan installs — the per-variant table in step 4 is its contract. **Plan 012**'s keyboard_help overlay joins the same stack. **Plan 014** needs this plan's docs drift list (step 5.3).
- **Reviewer scrutiny**: (a) test diffs are mechanical substitution only; (b) the per-variant `DismissPolicy` mapping is derived from current behavior, never from the presets' convenience — a `dismissible()` default where today Esc is trapped is a silent parity break; (c) the wrapper preserves `selected: usize` for ALL consumers (render, click, keymap, hover); (d) the `VirtualList` window and paint share one offset source; (e) the horizontal char-precise half of `list_geometry.rs` survives untouched; (f) row-9 modal selection still on `ListState` with the wheel-saturate/keyboard-wrap split intact.
- **Deferred (recorded, not forgotten)**: picker-modal `CollectionState` migration is rejected for this phase (row-9 decision above — revisit only if upstream gains per-input-source wrap policy); `ModalRectSpec` had a near-twin in capsule (`components/modal_rects.rs` there) — its deletion waits for the capsule phase; the upstream `VirtualList` paint widget is adopted for windowing only where byte-identical output holds — any paint-level divergence routes through the parity-break STOP, not acceptance.
