# Plan 011: Adopt upstream layout, chrome, and runtime machinery (panel_stack, kbd+hint_bar, SpinnerState, keymap_bridge, Presenter/FrameClock, resizable_panel_group)

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED (seam-drag parity route is decided — see Scope; footer-hint label re-verification is per-screen; the rest are low-churn pairings)
- **Depends on**: plans/008-*.md (panel layout, the resizable split seam, and the hint bar interact with the scroll/mouse machinery cutover — hub dependency note)
- **Covers**: F5 (C3 sidebar layout, C12 footer hints, C13 spinner, C15 keymaps, C16 event loop, C17 split drag), B14 (byte-identical console text snapshots), D16 (UI/UX parity invariant)
- **Guardrails**: N2, N4 inlined below
- **Research basis**: `research/termrock-head-adoption/04-component-adoption-candidates.md` (C3, C12, C13, C15, C16, C17 pairings), `research/termrock-head-adoption/06-mouse-subsystem-parity-matrix.md` (row 14 seam-drag verdict); commands from `research/jackin-verification-tooling/01-gates-and-commands.md`
- **Planned at**: commit `f320b51f`, 2026-08-19

## Why this matters

The console's layout engine, footer-hint assembly, spinner frames, static keymap enums, event-loop plumbing, and split-drag state are six hand-rolled subsystems with verified upstream carriers at the pinned rev. After this plan lands, block layout comes from `panel_stack`, footer hints from `kbd` + `hint_bar` fed by `keymap_bridge` data (with `Visibility` metadata surviving), spinners from `SpinnerState`/motion stepping, and frame pacing from `Presenter`/`FrameClock`/`ReadySubscription` — while the run loop stays in the surface crate (arch gate), the sidebar scroll/focus registry stays hand-rolled (no upstream carrier), and the split adopts `resizable_panel_group` with seam-drag parity preserved by the decided route below. Every step runs under the byte-identical-snapshot parity gate.

## Preconditions — run before anything else

Run each; any failure is a STOP.

1. **Plan 008 landed (interaction core cutover).** All checks:
   - `grep -E '^\| 008 \|' plans/termrock-migration/README.md | grep -q 'DONE'` → exit 0.
   - `rg -l 'ScrollAreaState' crates/jackin-console/src` → at least one file (planning time: zero hits — 008 introduces them).
   - Then open `plans/termrock-migration/008-*.md`, find the cheapest done criterion it names, and run it → passes. If no `008-*.md` file exists or it names no runnable criterion, STOP.
2. **Plan 006 landed** (008 depends on it; transitively required): `grep -E '^\| 006 \|' plans/termrock-migration/README.md | grep -q 'DONE'` → exit 0.
3. **Plan 005 landed (PNG baselines exist and gate this plan).** `grep -E '^\| 005 \|' plans/termrock-migration/README.md | grep -q 'DONE'` → exit 0. Then open `plans/termrock-migration/005-*.md`, find the cheapest done criterion it names, and run it → passes.
4. **Pin**: `grep -n 'rev = "29a16b5bff84ea8609854711b774e87acbc456cc"' Cargo.toml` → prints the pin line (planning time: line 118).
5. **TermRock input checkout**: `git -C <TERMROCK_CHECKOUT> rev-parse HEAD` → `29a16b5bff84ea8609854711b774e87acbc456cc`.
6. **Upstream symbols exist at the pin** (verify each before writing code; a miss is the misfit-BLOCKED route, hub law):
   - `grep -n 'pub fn panel_stack' <TERMROCK_CHECKOUT>/crates/termrock/src/layout/panel_stack.rs` → a hit (research ch04: `panel_stack.rs:37`).
   - `grep -n 'SpinnerState' <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/spinner.rs` → a hit (research ch04: `spinner.rs:183`).
   - `grep -n 'spinner_step' <TERMROCK_CHECKOUT>/crates/termrock/src/runtime/motion.rs` → a hit (research ch04: `motion.rs:69`).
   - `grep -n 'dispatch_keymap_action' <TERMROCK_CHECKOUT>/crates/termrock/src/interaction/keymap_bridge.rs` → a hit (research ch04: `keymap_bridge.rs:16`).
   - `grep -n 'UiIntent' <TERMROCK_CHECKOUT>/crates/termrock/src/interaction/intent.rs` → a hit (research ch04: `intent.rs:72`; `default_list_intent:171`).
   - `grep -n 'pub struct Presenter' <TERMROCK_CHECKOUT>/crates/termrock/src/runtime/presenter.rs` → a hit (research ch04: `presenter.rs:173`; `FrameRate:30`, `TickLadder:71`, `QuietBackend:337`).
   - `grep -n 'FrameClock' <TERMROCK_CHECKOUT>/crates/termrock/src/runtime/time.rs` → a hit (research ch04: `time.rs:60`).
   - `grep -n 'ReadySubscription' <TERMROCK_CHECKOUT>/crates/termrock/src/runtime/subscription.rs` → a hit (research ch04: `subscription.rs:22`).
   - `grep -n 'ResizablePanelGroup' <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/resizable_panel_group.rs` → a hit (research ch04: `resizable_panel_group.rs:85`).
   - `grep -n 'kbd' <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/kbd.rs` → a hit (research ch04: `kbd.rs:32-122`).
7. **Toolchain**: `rustc --version` → `rustc 1.97.1`; `cargo nextest --version` → `cargo-nextest 0.9.140`.
8. **Drift check** (this plan edits pre-existing code): `git diff --stat f320b51f..HEAD -- crates/jackin-console crates/jackin/src/console` and `git log --oneline f320b51f..HEAD -- crates/jackin-console`. Changes from the landed commits of plans 005–010 are expected, not drift. For every in-scope file this plan edits, compare the "Starting state" anchors below against live code before editing: **symbol names are the authority; every line number in this plan is a planning-time snapshot**. A mismatch that changes a cutover shape — a renamed/deleted symbol, a moved lane, a changed guard — is a STOP.
9. **Parity gate starts green**: `cargo nextest run -p jackin-console --locked` → all pass.
10. **Clean tree**: `git status --porcelain` → empty.

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

### Requirement: Layout, chrome, and runtime on upstream machinery

Console layout SHALL adopt `panel_stack` for block rects (the scroll/focus registry half of the sidebar has no upstream carrier and stays hand-rolled); footer hints SHALL adopt `kbd` + `hint_bar` with hint priority orders and RULES.md keybinding-label rules re-verified per screen; spinners SHALL adopt `SpinnerState`/motion stepping; keymaps SHALL adopt `keymap_bridge`/`UiIntent` with the `Visibility` metadata feeding footer hints surviving the bridge; the event loop SHALL adopt `Presenter`/`FrameClock`/`ReadySubscription` with the run loop staying surface-owned per the arch gate and teardown drain heuristics staying hand-rolled; the split SHALL adopt `resizable_panel_group`, with seam-drag parity (±1 column hit slack, anchor-relative percentage delta, 20–80% clamp, mouse disabled below terminal width 40) preserved via an upstream change per the misfit rule or a recorded consumer seam-drag carve-out — research ch06 row 14 shows the unmodified widget is not behavior-parity.

Covers: F5 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md (C3, C12, C13, C15, C16, C17 pairings), research/termrock-head-adoption/06-mouse-subsystem-parity-matrix.md (row 14), `crates/jackin-xtask/src/arch.rs:253-275`

#### Scenario: Footer hints identical after bridge

- **WHEN** any console stage renders after the `keymap_bridge` cutover
- **THEN** the footer hint bar shows the same hints in the same priority order with RULES.md-conformant labels
- **AND** every hint's `Visibility` condition behaves as before

#### Scenario: Run loop ownership unchanged

- **WHEN** the runtime adoption lands
- **THEN** the console run loop remains in the surface crate (arch gate passes)
- **AND** teardown drain behavior is unchanged

#### Scenario: Split drag feel identical

- **WHEN** the user drags the console split seam after the `resizable_panel_group` adoption
- **THEN** grab starts within ±1 column of the seam, the delta is anchor-relative, the split clamps to 20–80%, and mouse is fully disabled below terminal width 40 — exactly as before
- **AND** any of these the widget cannot reproduce lands as an upstream change per the misfit rule, or the seam-drag lane stays consumer-side with the widget carrying layout only (the carve-out is recorded in the plan)

### Requirement: No performance gate

The console phase SHALL carry no performance budget or gate; rendering-parity gates (byte-identical text snapshots, zero-tolerance PNG baselines, behavioral parity tests) are the whole acceptance.

Covers: B14, B15 · Evidence: roadmap item §Decisions (parity rule ruling, 2026-08-19)

#### Scenario: Virtualization adoption without perf sign-off

- **WHEN** `VirtualList` adoption lands on a long console list
- **THEN** acceptance is the parity gates alone — no latency or throughput measurement is required or recorded

Done means these scenarios hold; the test plan below exercises them.

## Must NOT

Plan-specific guardrails. The hub already binds every plan to data-not-instructions, no-secrets, the repository's commit law, the parity-break STOP law, and the TermRock-misfit BLOCKED route — those are not restated here.

- **N2**: No compatibility facades or shims over renamed TermRock APIs — repo latest-only law; upstream directive 0061/0331. Each cutover below deletes the hand-rolled code it replaces in the same commit group; no adapter wrapping the old behavior around the new widget.
- **N4**: No new operator-visible screens or overlays beyond keyboard_help; no journey changes — amended D14, amendment scope is exactly one overlay. This plan adds no overlay; the `keyboard_help` overlay itself is plan 012's territory. `keymap_bridge` data work here prepares 012's content source but ships no `?` overlay.
- **Do not re-bless PNG baselines.** The zero-tolerance PNG baselines (blessed in plan 005) must pass unmodified; a PNG diff is a parity break (hub STOP law), never a re-bless. Re-blesses happen only in plans 005 and 014.
- **Do not touch `runner::run` or move the run loop.** The console run loop stays in `crates/jackin-console` (arch gate `crates/jackin-xtask/src/arch.rs:272-280` forbids run-loop ownership in the facade). This plan adopts `Presenter`/`FrameClock`/`ReadySubscription` *inside* the surface-owned loop; it does not adopt `runtime/runner.rs`'s `run` and does not relocate the loop.

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — local checkout of the TermRock repository, outside this repository. On this machine: `/Users/donbeave/Projects/tailrocks/termrock` (research ch04/ch06 read it there). Needed by preconditions 5–6 and by every step that reads upstream sources to match API shapes.
  - If absent: any clone of `https://github.com/tailrocks/termrock` at rev `29a16b5bff84ea8609854711b774e87acbc456cc` (the pin at `Cargo.toml:118`) is a valid substitute — re-point the name and re-run precondition 5. Do NOT block waiting; do NOT edit the checkout (misfit route is hub law).

## Starting state

The facts, inlined. Symbol names are the authority; line numbers are planning-time snapshots (plans 005–010 may shift them). Planning-time measurements carry the re-derivation rule: re-run the counting command, the fresh number is the authority.

Console hand-rolled machinery this plan replaces (research ch04, console machinery inventory — each file read at planning time):

| # | Machinery | jackin location | Upstream carrier (verified at pin) |
|---|---|---|---|
| C3 | Sidebar layout engine: hand-computed block heights, scroll-area registry, focus targets | `crates/jackin-console/src/tui/sidebar_layout.rs:21-514` (`SidebarLayout`, `SidebarScrollAreas`, `compute_sidebar_layout:274`, `env_block_height:418`) | `layout/panel_stack.rs:37` `panel_stack` — **rects only**; the scroll/focus registry half (`SidebarScrollAreas:52`) has no upstream carrier and stays hand-rolled |
| C12 | Footer hint assembly per screen/modal | `crates/jackin-console/src/tui/components/footer_hints/{common,editor,modals,settings,workspace}.rs`; `view.rs:360` `render_footer` | `widgets/hint_bar.rs` (pre-pin, in use), `widgets/kbd.rs:32-122` |
| C13 | Spinner frames | `crates/jackin-console/src/tui/components/spinner.rs:7` `SPINNER_FRAMES` | `widgets/spinner.rs:183` `SpinnerState` (+`ActivityPhase:55`), `runtime/motion.rs:69` `spinner_step` |
| C15 | Static per-screen keymap action enums | `crates/jackin-console/src/tui/keymap.rs:17-257` (`EditorGlobalAction`, `EditorTabBarAction`, `EditorContentAction`, `SettingsTabBarAction`, …) | `interaction/keymap_bridge.rs:16` `dispatch_keymap_action`, `interaction/intent.rs:72` `UiIntent` (`default_list_intent:171`) |
| C16 | Event loop plumbing: 50 ms tick, event drain/teardown heuristics, blocking-subscription adapters, subscription registry | `crates/jackin-console/src/tui/terminal.rs:12-65`; `runtime.rs:41-99` (`BlockingSubscription:41`, spawn helpers); `subscriptions.rs:24-31`; `run.rs` | `runtime/presenter.rs:173` `Presenter` (`FrameRate:30`, `TickLadder:71`, `QuietBackend:337`), `runtime/time.rs:60` `FrameClock`, `runtime/subscription.rs:22` `ReadySubscription` |
| C17 | Split drag state | `crates/jackin-console/src/tui/split.rs:11` `DragState` | `widgets/resizable_panel_group.rs:85-176` — layout carrier only; **not** seam-drag parity (see decided route below) |

Key facts governing the cutovers:

- **C15 `Visibility` metadata**: jackin keymap statics carry `Visibility` metadata feeding footer hints; the bridge must preserve the hint pipeline (research ch04 C15 row). After the cutover, `Visibility` lives **on the product keymap table entries the console feeds into `dispatch_keymap_action`** — the console keeps its per-screen action enums and their `Visibility` conditions as product data; `keymap_bridge`/`UiIntent` carries dispatch only, and `hint_bar` reads the same table so hints and bindings cannot drift.
- **C16 arch gate**: run-loop ownership is per-surface (`crates/jackin-xtask/src/arch.rs:272-279` forbids `run.rs` in jackin-tui) — adoption is `Presenter`/`FrameClock`/`ReadySubscription` inside the console's own loop; `runner::run` is NOT adopted. `ReadySubscription` covers only the immediately-ready case — the console's spawned tokio oneshot workers (`spawn_named_blocking_subscription:69`) still need a consumer executor adapter, and teardown drain heuristics (`terminal.rs:14-17`) have no upstream analogue: both stay hand-rolled (research ch04 C16 row + no-equivalent inventory).
- **C12 RULES.md re-verification**: footer-hint labels and keybinding forms are jackin law — RULES.md:27-40 (TUI Labels: full word, not abbreviation; established short forms `dst`/`src`/`git`/`op` only), RULES.md:42-54 (TUI Keybindings: plain letters, numbers, `Enter`, `Esc`, `Tab`, arrows; avoid `Ctrl`/`Alt`/`Cmd`/`Shift`), RULES.md:63 (footer format: single line, separator-delimited, plain-word actions). Whether upstream `kbd` glyph forms match these is unverified at planning time (research ch04 C12 row) — step 2 verifies per screen; a glyph-form misfit with no consumer config is the hub's BLOCKED route.
- **C17 seam-drag verdict (research ch06 row 14)**: jackin rule — Down within ±1 col of seam starts drag; anchor-relative pct delta; clamp 20–80%; terminal width <40 disables all mouse (`J:layout.rs:13,17-18,35-39,96-108`, `J:split.rs:16-26`, `J:screens/workspaces/update.rs:933-969`, `J:mouse.rs:106-108`; tests `mouse/tests.rs` rows 227-333, 494). Upstream `ResizablePanelGroup::handle_mouse` (`T:widgets/resizable_panel_group.rs:802-870`): exact 1-cell handle hit (`hit_handle` 258-262), absolute (non-anchor) positioning, per-panel min-size clamp, no width gate. Verdict: DIFFERS.
- **Seam-drag route is DECIDED** (spec, "Layout, chrome, and runtime" requirement): `resizable_panel_group` is adopted as the layout carrier; seam-drag parity (±1 column hit slack, anchor-relative percentage delta, 20–80% clamp, mouse disabled below terminal width 40) is preserved via the **recorded consumer seam-drag carve-out**: the seam-drag lane (hit slack, anchor-relative delta, pct clamp, width<40 gate) stays consumer code — plan 008's recorded carve-out for the same lane — and the widget carries layout only. This is a spec-sanctioned decision, not an open question. The alternative (upstream change adding slack + anchor-relative option) is operator territory; the executor does NOT attempt it and does NOT treat the carve-out as a misfit BLOCK.
- Conventions to match: keymap sibling test suite at `crates/jackin-console/src/tui/keymap/tests.rs` (repo test-layout rule: tests in own file); footer-hint priority orders live in the five `footer_hints/*.rs` modules today — the cutover must reproduce each module's order exactly.

## Commands you will need

All commands proven by `research/jackin-verification-tooling/01-gates-and-commands.md` (chapter 01):

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Build/check | `cargo check --workspace --all-targets --locked` (ch01, tests partition step 1) | exit 0 |
| Console tests (parity gate) | `cargo nextest run -p jackin-console --locked` (ch01, "One package") | all pass |
| Snapshot lane (text snapshots byte-identical) | `cargo xtask ci --only snapshots` = `cargo nextest run -p jackin-capsule -p jackin-console --locked` (ch01, snapshots partition) | all pass, zero snapshot diffs |
| One module | `cargo nextest run -p jackin-console -E 'test(/keymap::tests/)'` (ch01, behavioral seams) | all pass |
| Arch gate (run-loop ownership) | `cargo xtask lint --strict` (ch01, lint partition step 4 — includes the arch lint) | exit 0 |
| Clippy | `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` (ch01, lint partition) | exit 0 |
| Format | `cargo fmt --check` (ch01, lint partition) | exit 0 |
| Full merge-readiness (final) | `cargo xtask ci --fast` (ch01: lint + policy + tests + docs + snapshots) | exit 0 |

PNG baselines: run via plan 005's harness command — open `plans/termrock-migration/005-*.md` and use the baseline-comparison command it defines; expected result: zero diffs, **no re-bless**.

## Scope

**In scope** (the only files to create or modify):

- `crates/jackin-console/src/tui/sidebar_layout.rs` — rect computation onto `panel_stack`; `SidebarScrollAreas` registry stays
- `crates/jackin-console/src/tui/components/footer_hints/{common,editor,modals,settings,workspace}.rs` — re-host on `kbd` + `hint_bar`, priority orders preserved
- `crates/jackin-console/src/tui/view.rs` (`render_footer`) — hint_bar render path
- `crates/jackin-console/src/tui/components/spinner.rs` — `SPINNER_FRAMES` deleted, `SpinnerState` adopted
- `crates/jackin-console/src/tui/keymap.rs` + `crates/jackin-console/src/tui/keymap/tests.rs` — `keymap_bridge`/`UiIntent` dispatch; `Visibility` table preserved as product data
- `crates/jackin-console/src/tui/runtime.rs`, `subscriptions.rs`, `run.rs`, `terminal.rs` — `Presenter`/`FrameClock`/`ReadySubscription` inside the surface-owned loop; teardown drain heuristics stay
- `crates/jackin-console/src/tui/split.rs`, `crates/jackin-console/src/tui/layout.rs`, `crates/jackin-console/src/tui/screens/workspaces/update.rs` (seam section), `crates/jackin-console/src/tui/input/mouse.rs` (seam guard) — `resizable_panel_group` for split layout; seam-drag lane stays consumer
- Test files sibling to the above (repo layout rule)
- `crates/jackin/src/console/` adapter files only where the runtime adoption changes the binding surface

**Out of scope** (do NOT touch, even though related):

- Scroll/mouse machinery itself (`input/mouse/*` scroll lanes, `ScrollArea` states) — plan 008's territory, landed; this plan only consumes it.
- Collections/selection wrapper/modal geometry (`CollectionState`, `RovingFocusGroup`, `VirtualList`, `OverlayStack` modal cutover) — plan 009.
- Dialogs/forms (`confirm_prompt`, `file_picker`, `select`, `form`, `diff`, `key_value_table`+`link`) — plan 010.
- `keyboard_help` overlay, whole-screen recipes, create wizard (`form_wizard`) — plan 012. This plan prepares `keymap_bridge` data but ships no overlay.
- Op-picker and `jackin-oppicker` — plan 013 (including its `ReadySubscription`/`BlockingSubscription` duplicate — do not "fix" the oppicker twin here).
- Docs pages under `docs/content/reference/tui/` — plan 014 (note drift in the commit/PR, do not edit pages here).
- The `<TERMROCK_CHECKOUT>` tree — never edited (hub misfit law).

## Git workflow

One execution branch `feature/termrock-console-modernization` (hub law); this plan is a commit group on it. Suggested commit boundaries, one per landed cutover, each pushed immediately with DCO sign-off:

1. `refactor(console): adopt panel_stack for sidebar block layout`
2. `refactor(console): re-host footer hints on kbd + hint_bar`
3. `refactor(console): adopt SpinnerState and motion stepping`
4. `refactor(console): bridge keymaps through keymap_bridge/UiIntent`
5. `refactor(console): adopt Presenter/FrameClock/ReadySubscription in surface-owned run loop`
6. `refactor(console): adopt resizable_panel_group layout with consumer seam-drag carve-out`

Hub status-row updates ride the commits they record (hub protocol).

## Steps

Order keeps the tree green between steps: each cutover is independently verifiable. Run the parity gate (`cargo nextest run -p jackin-console --locked`) after every step; run the snapshot lane after steps 1, 2, 3, and 6 (render-path changes).

### Step 1: Sidebar block rects onto `panel_stack` (C3)

Replace the hand-computed block-height functions in `sidebar_layout.rs` (`compute_sidebar_layout` and the per-block `*_block_height` helpers) with a `panel_stack` composition producing the same block rects in the same order. Keep `SidebarScrollAreas` — the per-block scroll/focus registry — exactly as-is (no upstream carrier; spec). Delete the height helpers only after every caller reads rects from the new path.

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass; `cargo xtask ci --only snapshots` → all pass, zero diffs. Any text-snapshot diff: parity break — STOP.

### Step 2: Footer hints onto `kbd` + `hint_bar` (C12)

Re-host the five `footer_hints/*.rs` modules onto `hint_bar` entries with `kbd` key glyphs, fed from the keymap table (the same data step 4 bridges — if step 4 not yet landed, read the existing keymap statics; the table is the single source either way). Preserve each screen's/modal's hint **priority order exactly** as the current modules emit it. Re-verify every label against RULES.md:27-40 (full-word labels; only `dst`/`src`/`git`/`op` short forms), RULES.md:42-54 (modifier-free keybindings; `Enter`/`Esc`/`Tab`/arrows), RULES.md:63 (single-line separator-delimited footer, plain-word actions). If an upstream `kbd` glyph form violates a RULES.md label form and no consumer config fixes it: hub misfit-BLOCKED route.

**Verify**: `cargo xtask ci --only snapshots` → all pass, zero diffs (footer text is in the snapshots — byte-identical is the parity proof); `cargo nextest run -p jackin-console --locked` → all pass.

### Step 3: Spinner onto `SpinnerState` + `spinner_step` (C13)

Delete `SPINNER_FRAMES` (`components/spinner.rs`) and advance a `SpinnerState` via `runtime/motion.rs` `spinner_step` from the loop's tick. The tick source today is the 50 ms loop tick (C16); after step 5 lands it is `FrameClock` — wire whichever the loop owns at the time this step runs, and if both orders are viable, do this step after step 5 to avoid rewiring.

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass; `cargo xtask ci --only snapshots` → zero diffs (spinner glyphs appear in snapshots — a frame-shape change is a parity break; if `SpinnerState`'s frame set differs from `SPINNER_FRAMES` with no consumer frame override, hub misfit-BLOCKED route).

### Step 4: Keymaps through `keymap_bridge`/`UiIntent` (C15)

Route dispatch of the per-screen action enums (`EditorGlobalAction`, `EditorTabBarAction`, `EditorContentAction`, `SettingsTabBarAction`, …) through `dispatch_keymap_action` with `UiIntent` where the intent granularity matches; where a product action has no matching intent, keep the product action enum as the bridge's action payload (research ch04: intent granularity may not match 1:1 — product actions stay). **Preserve the `Visibility` metadata**: the per-screen keymap tables keep their `Visibility` conditions as product data feeding both dispatch and the footer hint pipeline (step 2). Extend `keymap/tests.rs` with cases proving: each bridged binding dispatches to the same action as before; each `Visibility` condition shows/hides the same hint as before.

**Verify**: `cargo nextest run -p jackin-console -E 'test(/keymap::tests/)'` → all pass, including the new cases; `cargo nextest run -p jackin-console --locked` → all pass.

### Step 5: `Presenter`/`FrameClock`/`ReadySubscription` inside the surface-owned loop (C16)

Adopt `Presenter` (frame pacing replaces the fixed 50 ms tick), `FrameClock` (tick source for step 3's spinner), and `ReadySubscription` (replaces the console `BlockingSubscription` immediately-ready adapter in `runtime.rs`). The run loop **stays in `crates/jackin-console`** — do not adopt `runtime/runner.rs`'s `run`, do not move loop code into jackin-tui (arch gate). Keep hand-rolled: teardown drain heuristics (`terminal.rs`), the executor adapter for spawned tokio oneshot workers (`spawn_named_blocking_subscription`), the subscription registry shape in `subscriptions.rs` where it is product flow. No performance measurement is taken or recorded (spec: no performance gate).

**Verify**: `cargo xtask lint --strict` → exit 0 (arch gate passes — run-loop ownership unchanged); `cargo nextest run -p jackin-console --locked` → all pass; teardown/drain behavior tests (existing, in the console suite) pass unmodified.

### Step 6: Split onto `resizable_panel_group` layout; seam drag stays consumer (C17 — decided route)

Adopt `ResizablePanelGroup` as the layout carrier for the console split (percentage sizing maps from the current single-percentage model). The seam-drag lane stays consumer code per the decided carve-out: Down within ±1 column of the seam starts the drag (`layout.rs` hit test), the delta is anchor-relative (`split.rs` `DragState`), the split clamps to 20–80%, and all mouse is disabled below terminal width 40 (`mouse.rs` guard) — do not route seam drags through `ResizablePanelGroup::handle_mouse` (research ch06 row 14: exact 1-cell hit, absolute positioning, min-size clamp, no width gate — not parity). Record the carve-out in the commit message body: "seam-drag lane stays consumer-side; widget carries layout only (spec-sanctioned carve-out, research ch06 row 14)".

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass, including the seam-drag tests (`mouse/tests.rs`, planning-time rows 227-333 and 494 — re-derive with `rg -n 'seam|split' crates/jackin-console/src/tui/input/mouse/tests.rs`); `cargo xtask ci --only snapshots` → zero diffs.

### Step 7: Final gates

Run the full non-Docker gate and the PNG baseline comparison:

**Verify**: `cargo xtask ci --fast` → exit 0; plan 005's PNG baseline command → zero diffs, no re-bless.

## Test plan

- New tests in `crates/jackin-console/src/tui/keymap/tests.rs`: bridged dispatch equivalence per screen enum; `Visibility` show/hide equivalence per hint (spec scenario "Footer hints identical after bridge"). Expected values come from the **pre-cutover behavior captured in existing tests and snapshots**, not recomputed from the new code.
- Footer-hint parity: the existing console view snapshots (byte-identical gate) are the primary proof; add no new snapshots.
- Seam-drag: existing `mouse/tests.rs` seam tests pass unmodified (spec scenario "Split drag feel identical"); if step 6 forces any seam-test edit, that is evidence of a behavior change — STOP.
- Run loop: existing teardown/drain tests pass unmodified (spec scenario "Run loop ownership unchanged"); arch lint passes.
- Structural pattern: sibling-suite layout per repo rule (tests in own file), exemplar `keymap/tests.rs`.
- **Verify**: `cargo nextest run -p jackin-console --locked` → all pass, including the new keymap tests; `cargo xtask ci --only snapshots` → all pass, zero diffs.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `cargo check --workspace --all-targets --locked` exits 0
- [ ] `cargo nextest run -p jackin-console --locked` exits 0; keymap bridge + Visibility tests exist and pass
- [ ] `cargo xtask ci --only snapshots` exits 0 with zero snapshot diffs (text snapshots byte-identical — B14/D16)
- [ ] PNG baseline comparison (plan 005's command) reports zero diffs; **no re-bless performed** (D16)
- [ ] `rg -n 'SPINNER_FRAMES' crates/jackin-console` → no hits
- [ ] `rg -n 'panel_stack|SpinnerState|dispatch_keymap_action|Presenter|FrameClock|ReadySubscription|ResizablePanelGroup' crates/jackin-console/src` → hits for each adopted symbol
- [ ] `cargo xtask lint --strict` exits 0 (arch gate: run loop still surface-owned; `run.rs` still in `crates/jackin-console`)
- [ ] Seam-drag lane is consumer code: `rg -n 'DragState' crates/jackin-console/src/tui/split.rs` → hit; seam tests unmodified vs pre-plan (`git diff f320b51f..HEAD -- crates/jackin-console/src/tui/input/mouse/tests.rs` shows no seam-test edits)
- [ ] `cargo xtask ci --fast` exits 0
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status row and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails, or "Starting state" does not match reality.
- A step's verification fails twice after a reasonable fix attempt.
- Any console text-snapshot or PNG baseline diffs — parity break; STOP for operator review, never re-bless (hub law).
- An upstream symbol cited in precondition 6 is renamed/removed at the pin, or `kbd` glyph forms / `SpinnerState` frames / `hint_bar` ordering cannot reproduce current UX via consumer configuration — hub misfit-BLOCKED route (`BLOCKED (termrock API misfit — recommend upstream change: <one line>)`).
- The seam-drag carve-out turns out insufficient — i.e. `resizable_panel_group` cannot carry even the *layout* half without changing behavior. (The seam-drag lane itself staying consumer is decided, not a STOP.)
- The arch gate fails after step 5, or the run loop would have to move to satisfy an upstream API.
- The assumption "A5" (pairing APIs verified at `e1d61f4d` persist at pin `29a16b5b`) turns out false — report A5 with what was observed.
- The work requires touching an out-of-scope file (plans 008/009/010/012/013 territory, docs pages, TermRock checkout).
- A required input is missing with no replacement contract.

## Maintenance notes

- Plan 012 consumes the bridged keymap table as the `keyboard_help` content source — keep the table's shape stable and documented in `keymap.rs`.
- Plan 013 modernizes `jackin-oppicker`'s own `BlockingSubscription` duplicate; do not pre-empt it here.
- The consumer seam-drag carve-out is the recorded answer for research ch06 row 14; a future upstream change (hit slack + anchor-relative option) would let the lane move upstream — that is operator/TermRock territory, not a follow-up this package schedules.
- Reviewer scrutiny: footer-hint priority orders (easy to reorder silently; snapshots catch text but not order-within-equal-text), the `Visibility` survival path, and that no `runner::run` import crept in.
- Deferred: executor-backed upstream subscription (replacing `spawn_named_blocking_subscription`) — research ch04 open unknown, consumer adapter stays.
