# Plan 001: Pin Esc-cascade, focus-restore, and diff-scroll behavior with parity tests that pass at the old TermRock pin

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED — one step rewrites live loop code (`inspect_surface_loop`) that has no test covering it today; everything else is additive tests.
- **Depends on**: none
- **Covers**: spec requirement "Parity tests precede the bump" (all three scenarios); ledger IDs B5 (pre-bump half), A4, W1
- **Guardrails**: N2 (inlined below)
- **Research basis**: `research/termrock-head-adoption/01-compile-break-inventory.md`, `research/jackin-verification-tooling/01-gates-and-commands.md`
- **Planned at**: commit `d554dca8`, 2026-08-19

## Why this matters

The next plan moves the TermRock pin to upstream head, which makes
`FocusRing`/`ModalStack` private and strips `DiffViewState`'s public
`offset` setter. Those three call sites cannot be migrated by rename — they
are redesigns, and a redesign inside a PR labelled "mechanical" is exactly
where an operator-visible regression hides. This plan writes
characterization tests that pass **before** the pin moves, so plan 002 has
an objective witness: the same tests, unmodified, must still pass at head.
Two of the three behaviors already have test seams; the third (launch diff
scrolling) is function-local state in a 260-line run loop with no seam at
all, so this plan first hoists that state into a testable jackin❯-owned
model without changing behavior, then pins it.

## Preconditions — run before anything else

Run each from the repository root. Any failed precondition is a STOP.

1. **The pin has NOT moved.** These tests are only meaningful at the old pin.

   ```sh
   grep -n 'rev = "5ff94ee117fd4a1b72fdd0d1b1847815055a93ac"' Cargo.toml
   ```

   → prints one line (`Cargo.toml:118`). If the rev differs, plan 002 already
   ran: STOP.

2. **Toolchain present.**

   ```sh
   rustc --version        # → rustc 1.97.1
   cargo nextest --version # → cargo-nextest 0.9.140
   ```

   Mismatch → run `mise install` from the repository root, then re-check.
   Still mismatched → STOP.

3. **Drift check** (this plan edits pre-existing code):

   ```sh
   git diff --stat d554dca8..HEAD -- \
     crates/jackin-launch/src/tui/run.rs \
     crates/jackin-launch/src/tui.rs \
     crates/jackin-launch/README.md \
     crates/jackin-capsule/src/tui/components/dialog.rs \
     crates/jackin-capsule/src/tui/components/dialog/tests.rs \
     crates/jackin-tui/src/runtime.rs \
     crates/jackin-tui/src/runtime/focus.rs \
     crates/jackin-tui/src/runtime/modal_flow.rs \
     crates/jackin-tui/src/runtime/tests.rs \
     crates/jackin-console/src/tui/screens/editor/model.rs \
     crates/jackin-console/src/tui/screens/editor/model/state_impl/navigation.rs \
     crates/jackin-console/src/tui/screens/editor/model/tests.rs
   ```

   → expected: empty output. On any listed change, compare the "Starting
   state" excerpts below against the live code; a mismatch is a STOP.

4. **Baseline is green** — record the pass counts, they are the comparison
   basis for step 1:

   ```sh
   cargo nextest run -p jackin-launch -p jackin-capsule -p jackin-tui -p jackin-console --locked
   ```

   → all pass. Write down the total test count from the summary line. A red
   baseline is a STOP (this plan cannot prove "behavior preserved" against a
   broken baseline).

## Spec contract

The requirement this plan implements, inlined **verbatim** from the spec —
the executor does not read `spec/`:

### Requirement: Parity tests precede the bump
Characterization tests SHALL exist and pass against the OLD pin (`5ff94ee`) before any bump work, covering: (a) modal Esc-cascade — `open_sub` preserves the parent modal, `pop` restores parent and focus scope, `clear` closes the chain (console `ModalFlow` consumers; capsule ExitDirty → ExitInspect walk-back including its "Esc is ignored" rule — existing seam at `crates/jackin-capsule/src/tui/components/dialog/tests.rs:2338-2349`); (b) focus restore — `SurfaceFocus` owner transitions on tab/content moves and modal close (existing seams in `crates/jackin-tui/src/runtime/` tests); (c) launch diff scrolling — the offset handling is function-local in the launch run loop with NO existing test seam (`crates/jackin-launch/src/tui/run.rs:866-874` local state, writes at `:981-1085`), so this capability SHALL first extract it into a behavior-preserving, testable unit at the old pin, then pin its behavior. Old-pin type is termrock `DiffState` with `pub offset` (`widgets/diff.rs:27-31` at `5ff94ee`); the head renames/re-shapes it (`DiffViewState`, accessor-only offset).

#### Scenario: Esc cascade parity witness
- **GIVEN** a capsule ExitDirty dialog open with ExitInspect reachable
- **WHEN** the operator walks forward and presses Esc at each stage
- **THEN** the test asserts the exact pre-bump modal/focus outcome at each step, including Esc being ignored where the pre-bump dialog doc says so

#### Scenario: Focus restore parity witness
- **GIVEN** a console editor screen with a modal opened from a focused content block
- **WHEN** the modal closes via cancel and via commit
- **THEN** the test asserts focus returns to the pre-bump owner in both paths

#### Scenario: Diff scroll parity witness
- **GIVEN** a launch failure diff taller than its viewport
- **WHEN** scroll input moves the view and a redraw occurs
- **THEN** the test asserts the visible-line window matches pre-bump behavior

Done means these scenarios hold; the test plan below exercises them.

## Must NOT

Guardrail inlined verbatim from the spec's must-not registry:

- **N2**: "The migration MUST NOT introduce compatibility facades, aliases,
  or shim layers over renamed TermRock APIs" — reason recorded in the
  registry: "repository latest-only law; upstream migration directive ('No
  deprecated aliases are provided. This is a hard break.', 0061)".

  **How N2 binds this plan concretely**: step 1 extracts diff-scroll state.
  That extraction is **jackin❯-side state hoisting** — the new module owns
  plain `usize` offsets and stores, wraps, re-exports, or aliases **no**
  TermRock type. It must not become a `DiffState`/`DiffViewState` wrapper, a
  trait over the widget's scroll surface, or a type alias that lets plan 002
  keep the old name alive. `termrock::widgets::DiffState` stays named and
  used at the `run.rs` render site only, so plan 002 migrates a call site,
  not a facade.

Plan-specific guardrails (not registry entries, but they override anything a
step seems to imply):

- Do **not** change the TermRock pin, `Cargo.lock`, or `deny.toml`. This plan
  runs entirely at rev `5ff94ee117fd4a1b72fdd0d1b1847815055a93ac`; the pin
  flip and its lock/deny wave belong to plan 002.
- Do **not** change any operator-visible behavior. Step 1 is a pure
  behavior-preserving hoist; steps 2–4 add tests only. If preserving a
  behavior looks wrong or buggy, pin it anyway and say so in the report —
  characterization tests record what the code does today, not what it should
  do.
- Do **not** add, delete, re-bless, or hand-edit any `.snap` file, and do not
  run any `INSTA_UPDATE=…` command. Snapshots belong to plan 003.
- Do **not** rename or delete existing tests. New tests are added alongside
  them; overlap with an existing test is acceptable and intended.

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — a checkout of the TermRock repository, used only to
  **read** the old-pin widget source while writing step 2 (understanding the
  widget's own clamp). On the planning machine this was
  `/Users/donbeave/Projects/tailrocks/termrock`; it is outside this
  repository, so never hard-code it.
  - If absent: **do not block**. Clone it read-only anywhere convenient
    (`git clone https://github.com/tailrocks/termrock.git <TERMROCK_CHECKOUT>`)
    and read the old-pin file with
    `git -C <TERMROCK_CHECKOUT> show 5ff94ee117fd4a1b72fdd0d1b1847815055a93ac:crates/termrock/src/widgets/diff.rs`.
    If cloning is not possible, skip it entirely — every expected value in
    this plan is produced by **rendering through the pinned dependency**, not
    by reading TermRock source, so the plan is fully executable without it.

Everything else is inside the repository and is referenced repo-relative.

## Starting state

### 1. Capsule exit-dialog Esc cascade — seam exists

`crates/jackin-capsule/src/tui/components/dialog.rs:268-269` documents the
rule the spec calls "Esc is ignored":

```rust
    /// Last-session dirty-exit modal (in-capsule). Shows a per-repo summary plus
    /// the four choice rows. `Esc` is ignored — the operator must pick a row.
    ExitDirty {
```

and `:279-281`:

```rust
    /// Read-only changed-files list opened from the `ExitDirty` modal's Inspect
    /// row. `Esc` walks back to the exit modal (modal stack).
    ExitInspect {
```

The implementation of "ignored" is a redirect, not a swallow —
`crates/jackin-capsule/src/tui/components/dialog.rs:666-673`:

```rust
            Some(FilterListAction::Dismiss) => match self {
                // Esc / Ctrl+C on the dirty-exit modal = keep changes and exit
                // (never lose work). The read-only Inspect list and every other
                // dialog dismiss normally; Inspect pops back to the modal
                // underneath via the dialog stack.
                Self::ExitDirty { .. } => DialogAction::ExitDirty(ExitDirtyRow::Keep),
                _ => DialogAction::Dismiss,
            },
```

Row order is fixed at `dialog.rs:303-308` (`EXIT_DIRTY_ROWS`:
`StartNewAgent`, `Inspect`, `Keep`, `Discard`), Enter maps the focused row at
`:870-871`, and arrow navigation for both variants returns
`DialogAction::Redraw` (`:705-716` up, `:768-780` down, with `ExitInspect`
clamping at `lines.len()`).

The daemon side of the walk-back is `crates/jackin-capsule/src/tui/daemon/input_dispatch.rs:103-113`
— `ExitDirtyRow::Inspect` does `self.dialog_push(Dialog::new_exit_inspect(rows))`,
and Esc's `DialogAction::Dismiss` pops that push. **The dialog stack is a
plain `Vec<Dialog>` (`crates/jackin-capsule/src/daemon.rs:328`).**
`crates/jackin-capsule/src/daemon/tests.rs` exists (large suite; it pushes
ExitDirty via `mux.dialog_push(Dialog::new_exit_dirty(...))` at :8496/:8521
and has daemon-level exit-dirty tests from :8493) but contains zero
`ExitInspect`/walk-back coverage, and `tui/daemon/dialog_mgmt.rs` (where
`dialog_push`:70 / `dialog_pop_one`:143 live) has no sibling tests — so this
plan pins the cascade at the `Dialog` level, the level the pin bump actually
touches.

Existing tests to model after and extend, in
`crates/jackin-capsule/src/tui/components/dialog/tests.rs`:

- `:2335-2353` `exit_dirty_enter_routes_each_row` — walks down with `b"\x1b[B"` and confirms with `b"\r"`.
- `:2355-2370` `exit_dirty_esc_and_ctrl_c_keep_and_exit`.
- `:2372-2390` `exit_dirty_navigation_clamps_at_ends`.
- `:2392-2399` `exit_inspect_esc_walks_back`.

Key-byte vocabulary used by that file: Esc `b"\x1b"`, Ctrl+C `b"\x03"`,
Enter `b"\r"`, Down `b"\x1b[B"`, Up `b"\x1b[A"`. Constructors:
`Dialog::new_exit_dirty(Vec<String>, Arc<[InspectRow]>)` and
`Dialog::new_exit_inspect(Arc<[InspectRow]>)`; the handler signature is
`handle_key(&mut self, key: &[u8], github: Option<…>) -> DialogAction`, called
in tests as `d.handle_key(b"\x1b", None)`.

### 2. Focus restore and modal chain — seams exist

`crates/jackin-tui/src/runtime/modal_flow.rs:6-15` is one of only two files
in the workspace that touch the soon-private TermRock types (research ch01,
findings 3 and 4 — every other crate consumes the `SurfaceFocus`/`ModalFlow`
wrappers):

```rust
use termrock::interaction::{FocusRing, ModalStack};

/// Modal chain coordinated with `TermRock` focus scopes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ModalFlow<Modal> {
    current: Option<Modal>,
    parents: Vec<Modal>,
    stack: ModalStack<()>,
    focus: FocusRing<(), usize>,
}
```

Its public surface (`modal_flow.rs:34-108`): `current()`, `current_mut()`,
`parents()`, `parents_mut()`, `is_open()`, `has_parent()`, `open()`,
`open_sub()`, `pop()`, `clear()`, `take_current()`, `set_current()`,
`open_pair()`. The `focus`/`stack` fields are private — **the observable
focus-scope contract at this seam is the product modal chain**, so parity
tests assert on `current()`/`parents()`/`is_open()`/`has_parent()`.

`crates/jackin-tui/src/runtime/focus.rs:17-22` is the other:

```rust
/// Two-level tab/content focus backed by `TermRock`'s canonical focus mechanics.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SurfaceFocus<Content> {
    ring: FocusRing<SurfaceFocusTarget<Content>, ()>,
    content: Content,
}
```

Public surface (`focus.rs:24-102`): `tab_bar(content)`, `content(content)`,
`focused()`, `focused_content()`, `focus_tab_bar()`, `focus_content(c)`,
`is_tab_bar()`, `is_content(c)`, `show_cursor_for(&c)`. Note the shape:
`register()` (`focus.rs:45-54`) only ever registers `TabBar` plus
`Content(self.content)` — exactly **one** content identity is live at a time.

Existing tests in `crates/jackin-tui/src/runtime/tests.rs:34-66`
(`surface_focus_switches_between_tabs_and_product_content`,
`modal_flow_keeps_product_chain_and_termrock_scope_in_sync`) show the exact
import style: `use super::{ModalFlow, SurfaceFocus, SurfaceFocusTarget, UpdateResult, drive_render};`.

The console-side consumer named by the spec scenario is the editor screen.
`crates/jackin-console/src/tui/screens/editor/model.rs:262-272` holds both
halves:

```rust
    pub mode: EditorMode,
    pub active_tab: EditorTab,
    /// W3C ARIA Tabs: focus is either on the tab list or exactly one content block.
    pub focus_owner: SurfaceFocus<EditorFocusTarget>,
```

with `pub modal: Option<Modal>` / `pub modal_parents: Vec<Modal>`. The editor
keeps its own chain rather than a `ModalFlow`; its methods are in
`crates/jackin-console/src/tui/screens/editor/model/state_impl/navigation.rs`:
`focus_owner()` `:118-121`, `set_focus_owner()` `:123-128`,
`open_sub_modal()` `:375-380`, `pop_modal_chain()` `:396-398`,
`clear_modal_chain()` `:400-403`, `dismiss_active_modal()` `:405-407`,
`has_modal_parent()` `:410-412`. `EditorFocusTarget` has two variants,
`WorkspaceMounts` and `TabContent` (`model.rs:52-55`), and `new_edit`
constructs with `SurfaceFocus::tab_bar(EditorFocusTarget::TabContent)`
(`navigation.rs:87`).

Test fixtures already exist in
`crates/jackin-console/src/tui/screens/editor/model/tests.rs`: `TestEditor`
(`:18`), `TestStatusModal` (`:19-23`), `TestEditorWithStatusModal` (`:57-58`),
and worked examples at `:309-333` (`dismiss_active_modal_preserves_modal_stack`,
`has_modal_parent_tracks_modal_stack_presence`) plus `:186-200`
(`editor_apply_scroll_focus_plan_updates_focus_owner`).

### 3. Launch diff scrolling — NO seam; two offsets, not one

Everything below is inside one function,
`RichRenderer::inspect_surface_loop` (`crates/jackin-launch/src/tui/run.rs:830`),
whose imports are local (`run.rs:835`):

```rust
        use termrock::widgets::{DiffKind, DiffLine, DiffState, DiffView};
```

State declarations, `run.rs:866-872`:

```rust
        let mut diff_scroll_y: usize = 0;

        #[derive(Clone)]
        struct InspectDiff {
            lines: Vec<(String, DiffKind)>,
            state: DiffState,
        }
```

`build_diff` (`:874-896`) returns `InspectDiff { lines, state: DiffState::default() }`
— always at least two lines (a `--- HEAD/<path>` and a `+++ working/<path>`
header). The loop clones the state per frame (`:914`
`let mut diff_cloned = diff_state.clone();`) and the render closure does
(`:980-1008`):

```rust
                if let Some(diff) = diff_cloned.as_mut() {
                    diff.state.offset = diff_scroll_y.min(diff.lines.len().saturating_sub(1));
```

…builds `DiffLine { text, kind: *kind }` values, renders
`frame.render_stateful_widget(&DiffView::new(&lines, &diff_theme), diff_area, &mut diff.state);`
and reads back:

```rust
                    diff_scroll_y = diff.state.offset;
                }
```

Key handling (`:1028-1087`) mutates the **original** `diff_state`, never the
clone:

- `Up`/`k`/`K` under `InspFocus::Diff` (`:1040-1045`):
  `d.state.offset = d.state.offset.saturating_sub(1); diff_scroll_y = d.state.offset;`
- `Down`/`j`/`J` under `InspFocus::Diff` (`:1064-1073`):
  `d.state.offset = d.state.offset.saturating_add(1).min(d.lines.len().saturating_sub(1)); diff_scroll_y = d.state.offset;`
- `PageUp`/`PageDown` (`:1075-1087`) — **not** gated on focus, they fire in
  any pane — `±10` with the same `saturating_sub` / `min(len-1)` clamps, then
  `diff_scroll_y = d.state.offset;`
- Repo/file selection changes (`:1030-1038`, `:1048-1063`) rebuild the diff
  (`state` back to `DiffState::default()`) and set `diff_scroll_y = 0;`

**The load-bearing fact**: there are two independent offsets.
`d.state.offset` (call it the *key offset*) is advanced by key input and
clamped only against `lines.len() - 1`. `diff_scroll_y` (the *render offset*)
is what the widget receives, and after each draw it is overwritten with the
value the widget kept **after clamping to the viewport**. The widget's clamp
is real — old-pin `DiffView::render` starts with
`state.offset = state.offset.min(crate::scroll::max_offset(self.lines.len(), usize::from(area.height)))`
and then renders `lines.iter().skip(state.offset).take(area.height)`
(`crates/termrock/src/widgets/diff.rs:48-76` at rev `5ff94ee`, with
`max_offset(content_len, viewport_len)` returning `0` when
`content_len <= viewport_len`, else `content_len - viewport_len`,
`crates/termrock/src/scroll/mod.rs:163-171` at the same rev). Because the
render clamp writes back only to `diff_scroll_y`, an over-scrolled key offset
survives the clamp and the next Up/Down resumes from it. Pin that; do not
"fix" it.

Old-pin `DiffState` (`crates/termrock/src/widgets/diff.rs:24-32` at rev
`5ff94ee`) is:

```rust
pub struct DiffState {
    /// Whether this item is selected.
    pub selected: Option<usize>,
    /// Offset in terminal cells or rows.
    pub offset: usize,
}
```

Research ch01 finding 14 records what plan 002 will face: 12 `E0615` errors,
all in this one file, because at head `offset` is a getter with **no public
setter** — "This is the one wave-2 class that is a behavioral migration, not
a rename". That is why tests here must assert the **rendered window**, not
the offset field.

`DiffView` is rendered straight into `diff_area` with no surrounding block
(`run.rs:1002-1006`), so the widget's viewport height equals the rect height —
a test may render into any `Rect`.

### 4. Conventions to match

- **Test file rule** (`crates/AGENTS.md`, hard rule): a module `foo.rs`
  declares exactly `#[cfg(test)] mod tests;` and all its tests live inline in
  `foo/tests.rs`, which never declares child modules. Exemplar:
  `crates/jackin-tui/src/runtime.rs:170-171` + `crates/jackin-tui/src/runtime/tests.rs`.
- **No `mod.rs`** (`crates/AGENTS.md`, hard rule): self-named module files
  only.
- **File header**: every source file starts with the two SPDX lines, e.g.
  `crates/jackin-tui/src/runtime/focus.rs:1-2`.
- **Module registration**: `crates/jackin-launch/src/tui.rs:6-16 (mods; `#[cfg(test)] mod tests;` at :18-19)` lists
  `pub mod …;` alphabetically, then `#[cfg(test)] mod tests;`.
  `crates/jackin-launch/src/lib.rs:13` has `pub mod tui;`, so `pub` items in a
  new `tui::` submodule are reachable and do not trip `unreachable_pub`.
- **Lints** (`crates/AGENTS.md`): workspace denies `dead_code`,
  `unused_qualifications`, `unreachable_pub`; `missing_debug_implementations`
  is `deny` in the live workspace table (root `Cargo.toml:188`; the
  `crates/AGENTS.md` prose saying `warn` is stale), so every new public type
  needs `#[derive(Debug)]`. Clippy runs `pedantic`, so public items need doc
  comments and `#[must_use]` where they return a value without side effects.
- **Comments** (root `AGENTS.md`): non-obvious WHY only, never narrating WHAT.

### 5. Naming convention for this plan's tests — load-bearing

**Every test this plan adds is named with the prefix `trparity_`.** Plan 002
selects the whole set with one nextest filter
(`-E 'test(trparity_)'`) to prove parity across the pin flip, so a test without
the prefix is invisible to it. Do not rename existing tests to add the
prefix — add new ones. The prefix is deliberately `trparity_`, not `parity_`:
nextest `test()` is a contains-match and the repo already has five tests
matching `parity_` (`op_picker/tests.rs:1845,1887,1940,1985`,
`jackin-env/src/resolve/tests.rs:272` — verified 2026-08-19); `trparity_` has
zero pre-existing matches (`rg -c trparity crates/` → no hits). Before
writing tests, re-run `rg -c trparity crates/` — any hit means the
uniqueness assumption drifted: pick a longer prefix and stamp it in the
report and the hub notes so plan 002 reads the right filter.

**Planning-time measurement, re-derive it**: this plan is written to add
**19** `trparity_`-prefixed tests (7 launch, 5 capsule, 5 jackin-tui, 2
console). That is a planning snapshot. Re-run the counting command in step 5,
stamp the fresh number in your report, and note any delta — the fresh number
is the authority, never a target to reproduce.

## Commands you will need

All proven in `research/jackin-verification-tooling/01-gates-and-commands.md`
(chapter 01, sections "Merge-readiness gates", "Partition selection", "Test
runner and profiles", "Lint/format/deny"). Run from the repository root.

| Purpose | Command | Expected on success |
|---|---|---|
| One crate's tests | `cargo nextest run -p <crate>` | all pass (ch01 "One package", TESTING.md:161 — proven form carries no `--locked`) |
| One module's tests | `cargo nextest run -p jackin-launch -E 'test(/tui::diff_scroll::tests/)'` | all pass (ch01 "One test / one module", TESTING.md:28-32) |
| This plan's parity set | `cargo nextest run --workspace --all-features --locked -E 'test(trparity_)'` | all pass; count matches step 5 (filterset form per ch01 "One test / one module") |
| Compile check incl. tests | `cargo check --workspace --all-targets --locked` | exit 0 (ch01 tests partition, `ci.rs:185-189`) |
| Whole suite | `cargo xtask ci --only tests` | exit 0 — runs the check above + `cargo nextest run --workspace --all-features --locked` + `cargo test --doc --workspace --locked` (ch01 partition table) |
| Format | `cargo fmt --check` | exit 0 (ch01 "Lint/format/deny"); fix with `cargo fmt` |
| Clippy, one crate | `cargo clippy -p <crate> --all-targets -- -D warnings` | exit 0 (TESTING.md:161) |
| Full lint partition | `cargo xtask ci --only lint` | exit 0 — actionlint + `cargo fmt --check` + workspace clippy + `cargo xtask lint --strict` (ch01 partition table) |
| Snapshot lane (must stay untouched) | `cargo xtask ci --only snapshots` | exit 0 — `cargo nextest run -p jackin-capsule -p jackin-console --locked` (ch01 partition table) |
| File-size gate | `cargo xtask lint files` | exit 0 (TESTING.md:169) |
| README freshness | `cargo xtask lint readme-freshness --base origin/main` | exit 0 (TESTING.md:170) |

Do **not** run `mise run ci` expecting the full gate — chapter 01 "Dead ends
and contradictions" proves it is only the policy + docs + snapshots subset.

## Suggested executor toolkit

- Read `docs/content/reference/tui/index.mdx` (TUI Design) before touching
  any TUI file — repository law requires it for TUI changes. This plan
  changes no rendered output, so no docs page is due here.
- `crates/jackin-launch/README.md`, `crates/jackin-capsule/README.md`,
  `crates/jackin-tui/README.md` are the crate maps; the launch one is edited
  in step 1.

## Scope

**In scope** (the only files to create or modify):

- `crates/jackin-launch/src/tui/diff_scroll.rs` — **new**, the extracted model.
- `crates/jackin-launch/src/tui/diff_scroll/tests.rs` — **new**, its tests.
- `crates/jackin-launch/src/tui.rs` — one `pub mod diff_scroll;` line.
- `crates/jackin-launch/src/tui/run.rs` — rewire `inspect_surface_loop` onto the model.
- `crates/jackin-launch/README.md` — one Structure-row wording update (freshness gate).
- `crates/jackin-capsule/src/tui/components/dialog/tests.rs` — append parity tests.
- `crates/jackin-tui/src/runtime/tests.rs` — append parity tests.
- `crates/jackin-console/src/tui/screens/editor/model/tests.rs` — append parity tests.

**Out of scope** (do NOT touch, even though related):

- `Cargo.toml`, `Cargo.lock`, `deny.toml` — the pin flip and its lock/deny
  wave are **plan 002**'s. Touching them here invalidates the "passes at the
  old pin" property this plan exists to establish.
- `crates/jackin-tui/src/runtime/focus.rs`, `crates/jackin-tui/src/runtime/modal_flow.rs`
  — the re-host onto `InteractionScene`/`OverlayStack` is **plan 002**'s;
  this plan only tests them as they are.
- `crates/jackin-capsule/src/tui/components/dialog.rs` and every non-test
  file under `crates/jackin-console/src/` — read for facts, never edited.
- Any `.snap` file and any snapshot re-bless — **plan 003**'s.
- `docs/content/reference/tui/*`, `AGENTS.md`, `crates/jackin-capsule/src/tui/components/dialog/hint.rs`
  — **plan 004**'s docs and drift-check territory.
- The launch failure dialog, prompts, cockpit, and animation code — unrelated
  to the three forced redesigns.

## Git workflow

Four commits, in step order; each is pushed per the hub's law. The hub's
draft-PR trigger fires on this plan's first push — follow the hub for that.

1. After step 1: `refactor(launch): hoist inspect diff-scroll state into a testable model`
2. After step 2: `test(launch): pin inspect diff-scroll parity at the old termrock pin`
3. After step 3: `test(capsule): pin exit-dialog esc cascade parity at the old termrock pin`
4. After steps 4–5: `test(tui): pin focus-restore and modal-chain parity at the old termrock pin`

Commit 4 spans `jackin-tui` and `jackin-console` test files; keep them
together — they are one behavior (`SurfaceFocus` owner survival across modal
close) proven at the wrapper and at its consumer.

## Steps

### Step 1: Hoist the launch diff-scroll state into a testable model

**1a. Create `crates/jackin-launch/src/tui/diff_scroll.rs`** with the two SPDX
header lines, a module doc comment, and a `DiffScroll` type that mirrors the
loop's two offsets exactly. Target shape (adjust only for lint compliance):

```rust
/// Lines moved by one PageUp / PageDown press on the inspect surface.
pub const PAGE_STEP: usize = 10;

/// Diff scroll state of the launch inspect surface.
///
/// Two offsets, matching the loop this was hoisted from: key input advances
/// one, the renderer clamps and writes back the other.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct DiffScroll {
    key_offset: usize,
    render_offset: usize,
}
```

with these methods, each reproducing the cited `run.rs` expression verbatim:

| Method | Reproduces | Body |
|---|---|---|
| `new() -> Self` | `run.rs:866` + `:894` | both offsets `0` |
| `offset_for_render(&self, line_count: usize) -> usize` | `run.rs:981` | `self.render_offset.min(line_count.saturating_sub(1))` |
| `record_rendered(&mut self, offset: usize)` | `run.rs:1007` | `self.render_offset = offset;` — **key offset untouched** |
| `line_up(&mut self)` | `run.rs:1042-1043` | `self.key_offset = self.key_offset.saturating_sub(1); self.render_offset = self.key_offset;` |
| `line_down(&mut self, line_count: usize)` | `run.rs:1066-1071` | `self.key_offset = self.key_offset.saturating_add(1).min(line_count.saturating_sub(1)); self.render_offset = self.key_offset;` |
| `page_up(&mut self)` | `run.rs:1077-1078` | as `line_up` but `saturating_sub(PAGE_STEP)` |
| `page_down(&mut self, line_count: usize)` | `run.rs:1080-1084` | as `line_down` but `saturating_add(PAGE_STEP)` |
| `reset(&mut self)` | `run.rs:1033`/`:1038`/`:1053`/`:1061` + `build_diff`'s `DiffState::default()` | `*self = Self::new();` |

The struct stores `usize` only — no TermRock type, no wrapper, no alias
(guardrail N2 above). End the file with `#[cfg(test)] mod tests;`.

**1b. Register it**: add `pub mod diff_scroll;` to
`crates/jackin-launch/src/tui.rs` in the existing alphabetical `pub mod` block
(between `pub mod components;` and `pub mod effect;`).

**1c. Rewire `inspect_surface_loop`** in `crates/jackin-launch/src/tui/run.rs`,
changing nothing else in the function:

- `:866` — replace `let mut diff_scroll_y: usize = 0;` with
  `let mut diff_scroll = crate::tui::diff_scroll::DiffScroll::new();`
- `:981` — `diff.state.offset = diff_scroll.offset_for_render(diff.lines.len());`
- `:1007` — `diff_scroll.record_rendered(diff.state.offset);`
- `:1033`, `:1038`, `:1053`, `:1061` — replace each `diff_scroll_y = 0;` with
  `diff_scroll.reset();`
- `:1040-1045` — the `InspFocus::Diff` Up arm becomes
  `if diff_state.is_some() { diff_scroll.line_up(); }`
- `:1064-1073` — the `InspFocus::Diff` Down arm becomes
  `if let Some(d) = diff_state.as_ref() { diff_scroll.line_down(d.lines.len()); }`
- `:1075-1087` — the PageUp/PageDown arm becomes
  `if let Some(d) = diff_state.as_ref() { if key.code == KeyCode::PageUp { diff_scroll.page_up(); } else { diff_scroll.page_down(d.lines.len()); } }`
  — keep it ungated by focus, exactly as today.

Leave `InspectDiff` (including its `state: DiffState` field), `build_diff`,
the `diff_cloned` clone at `:914`, the `DiffLine` construction, and the
`diff_theme` block untouched. `d.state.offset` is now written only by the
render closure; that is equivalent, because the original's `state.offset` was
`0` at build and reset time and the key offset now lives in `DiffScroll`.

**1d. Refresh the crate map**: in `crates/jackin-launch/README.md:24`, extend
the `tui.rs · tui/` row's **Owns** cell to mention the inspect diff-scroll
model (the Structure table lists top-level modules only, so no new row is
due). This satisfies the same-PR README rule for a structural `src/` addition.

**Verify** (all must pass before step 2):

```sh
cargo fmt
cargo check --workspace --all-targets --locked          # → exit 0
cargo clippy -p jackin-launch --all-targets -- -D warnings   # → exit 0
cargo nextest run -p jackin-launch --locked             # → all pass, same count as the precondition baseline
cargo xtask lint files                                  # → exit 0
cargo xtask lint readme-freshness --base origin/main    # → exit 0
grep -rn "diff_scroll_y" crates/jackin-launch/src       # → no matches
grep -rn "DiffState\|DiffViewState" crates/jackin-launch/src/tui/diff_scroll.rs  # → no matches (N2)
```

### Step 2: Write the diff-scroll parity tests

Create `crates/jackin-launch/src/tui/diff_scroll/tests.rs` (SPDX header,
`use super::*;` in the style of `crates/jackin-launch/src/tui/run/tests.rs:5`).

**The single migration-sensitive helper.** Write exactly one helper that
renders through the real widget and returns what the operator sees. It is the
only place in the file naming a TermRock type, so plan 002 edits one function:

```rust
/// Renders one frame the way `inspect_surface_loop` does and returns the
/// visible diff rows. Single place naming TermRock's diff types.
fn draw(lines: &[String], scroll: &mut DiffScroll, width: u16, height: u16) -> Vec<String> {
    // 1. let mut state = DiffState { offset: scroll.offset_for_render(lines.len()), ..Default::default() };
    // 2. build Vec<DiffLine> from `lines` with DiffKind::Context
    // 3. Terminal::new(TestBackend::new(width, height)); term.draw(|f| f.render_stateful_widget(
    //        &DiffView::new(&diff_lines, &termrock::Theme::default()), f.area(), &mut state));
    // 4. scroll.record_rendered(state.offset);
    // 5. read the backend buffer row by row, trim_end each row, return the rows
}
```

Steps 1 and 4 must match `run.rs:981` and `run.rs:1007` — that is what makes
this a parity witness rather than a widget test. Read the buffer the way
`crates/jackin-capsule/src/tui/components/dialog/tests.rs:2402-2420`
(`exit_dirty_selection_marker_moves_on_down_arrow`) does: `term.backend().buffer()`,
then index cells and collect `symbol()`.

**Fixture**: 50 lines with distinguishable text — `L00`, `L01`, … `L49` — and
a viewport of `width = 20, height = 10`. With those numbers the widget's own
clamp is `max_offset(50, 10) == 40`, and the key clamp is `49`; both matter.

**Expected values are hand-derived** and written as literals in the test — do
not compute them by calling `offset_for_render` or re-deriving `max_offset` in
the test body, which would prove nothing.

Tests to write (all `trparity_`-prefixed):

1. `trparity_diff_scroll_starts_at_top` — a fresh `DiffScroll`, one `draw` →
   first row `"L00"`, exactly 10 rows, last row `"L09"`.
2. `trparity_diff_scroll_down_moves_window_one_line` — `line_down(50)` ×3 with a
   `draw` after each → first rows `"L01"`, `"L02"`, `"L03"`.
3. `trparity_diff_scroll_up_clamps_at_top` — `line_down(50)` once, then
   `line_up()` ×3, `draw` → first row `"L00"` (never panics, never wraps).
4. `trparity_diff_scroll_page_keys_move_ten_lines` — `page_down(50)` then `draw`
   → first row `"L10"`; `page_up()` then `draw` → first row `"L00"`.
5. `trparity_diff_scroll_bottom_window_shows_last_viewport_lines` —
   `page_down(50)` ×6 (key offset would reach 49) then `draw` → first row
   `"L40"`, last row `"L49"`: the widget clamp to `max_offset` binds.
6. `trparity_diff_scroll_reset_returns_to_top` — scroll away, `reset()`, `draw`
   → first row `"L00"`.
7. `trparity_diff_scroll_over_scroll_resumes_from_key_offset` — the two-offset
   behavior: `page_down(50)` ×6, `draw` (window pinned at `L40`), then
   `line_up()` and `draw` → first row is still `"L40"`, because the key offset
   was at 49 and one step up lands at 48, which the widget re-clamps to 40.
   Add a WHY comment naming this as the pre-bump two-offset behavior being
   characterized.

**Verify**:

```sh
cargo nextest run -p jackin-launch -E 'test(/tui::diff_scroll::tests/)'
```

→ 7 tests, all pass. Then `cargo clippy -p jackin-launch --all-targets -- -D warnings` → exit 0.

### Step 3: Write the capsule Esc-cascade parity tests

Append to `crates/jackin-capsule/src/tui/components/dialog/tests.rs` (do not
touch the existing tests; use the same key-byte vocabulary and constructors
listed in "Starting state" §1):

1. `trparity_capsule_exit_dirty_esc_keeps_and_exits` — `Dialog::new_exit_dirty(vec!["jackin   1 changed".to_owned()], Arc::from([]))`,
   `handle_key(b"\x1b", None)` → `DialogAction::ExitDirty(ExitDirtyRow::Keep)`.
   Comment: this is how "Esc is ignored" (`dialog.rs:269`) is implemented — the
   dialog never returns `Dismiss`, so the operator cannot lose work.
2. `trparity_capsule_exit_dirty_ctrl_c_keeps_and_exits` — same with `b"\x03"`.
3. `trparity_capsule_exit_dirty_enter_on_inspect_row_requests_inspect` — one
   `b"\x1b[B"` (cursor from `StartNewAgent` to `Inspect`), then `b"\r"` →
   `DialogAction::ExitDirty(ExitDirtyRow::Inspect)`. This is the forward walk
   whose action makes the daemon push `ExitInspect`
   (`input_dispatch.rs:103-113`).
4. `trparity_capsule_exit_inspect_esc_walks_back_with_dismiss` —
   `Dialog::new_exit_inspect(Arc::from([InspectRow::Repo("jackin".to_owned()), InspectRow::File("M a.rs".to_owned())]))`,
   `handle_key(b"\x1b", None)` → `DialogAction::Dismiss` (the daemon pops one
   level, restoring the `ExitDirty` modal underneath), and `b"\x03"` →
   `DialogAction::Dismiss` too.
5. `trparity_capsule_exit_inspect_arrows_scroll_without_dismissing` — from the
   same two-row Inspect dialog: `b"\x1b[B"` → `DialogAction::Redraw`, a second
   `b"\x1b[B"` → `Redraw` (clamped at the last row), `b"\x1b[A"` → `Redraw`.
   The dialog must never dismiss on navigation.

**Verify**:

```sh
cargo nextest run -p jackin-capsule -E 'test(trparity_capsule_)'
cargo xtask ci --only snapshots
git status --porcelain -- '*.snap'
```

→ 5 tests pass; the snapshot lane exits 0; `git status` prints nothing (no
`.snap` file changed).

### Step 4: Write the focus-restore and modal-chain parity tests

**4a. `crates/jackin-tui/src/runtime/tests.rs`** — append (the file already
imports `ModalFlow`, `SurfaceFocus`, `SurfaceFocusTarget` at `:6`):

1. `trparity_modal_flow_open_sub_preserves_parent` — `open("root")`,
   `open_sub("child")` → `current() == Some(&"child")`,
   `parents() == ["root"]`, `is_open()`, `has_parent()`.
2. `trparity_modal_flow_pop_restores_parent_and_clears_chain` — from that state,
   `pop()` → `current() == Some(&"root")`, `parents()` empty,
   `!has_parent()`; a second `pop()` → `current().is_none()`, `!is_open()`.
3. `trparity_modal_flow_clear_closes_whole_chain` — build a three-deep chain
   (`open` + `open_sub` + `open_sub`), `clear()` → `!is_open()`, `parents()`
   empty. Also cover `open_pair(parent, child)` → same two-level state as
   test 1, then `pop()` → parent restored.
4. `trparity_surface_focus_moves_between_tab_bar_and_content` —
   `SurfaceFocus::tab_bar("editor")`: `is_tab_bar()`, `focused_content().is_none()`;
   `focus_content("settings")` → `focused() == SurfaceFocusTarget::Content("settings")`,
   `focused_content() == Some("settings")`, `is_content("settings")`,
   `show_cursor_for(&"settings")`, and `!is_content("editor")` (only one
   content identity is registered at a time — `focus.rs:45-54`);
   `focus_tab_bar()` → `is_tab_bar()` and `!show_cursor_for(&"settings")`.
5. `trparity_surface_focus_survives_modal_open_and_close` — the composite the
   spec scenario describes at the wrapper level: focus content, then
   `ModalFlow::open`/`open_sub`/`pop`/`clear` around it, asserting
   `focused()` is the same `Content(...)` value before opening, while open,
   and after both the `pop` (cancel) and the `clear` (commit) paths.

**4b. `crates/jackin-console/src/tui/screens/editor/model/tests.rs`** — append
the consumer-level witness named by the spec scenario, using the existing
`TestEditorWithStatusModal` fixture (`:57-58`) and `TestStatusModal` (`:19-23`).
Reference `EditorFocusTarget` as `super::EditorFocusTarget` and
`SurfaceFocusTarget` as `jackin_tui::runtime::SurfaceFocusTarget` (or add both
to the existing `use super::{…}` block — either is fine, but do not reorder
the existing imports):

1. `trparity_editor_focus_owner_survives_modal_cancel` —
   `TestEditorWithStatusModal::new_edit("alpha".into(), WorkspaceConfig::default())`;
   `set_focus_owner(SurfaceFocusTarget::Content(EditorFocusTarget::WorkspaceMounts))`;
   `open_sub_modal(TestStatusModal::Other)`; assert `focus_owner()` is still
   `Content(WorkspaceMounts)` while the modal is open; cancel with
   `dismiss_active_modal()`; assert `modal.is_none()` **and** `focus_owner()`
   is still `Content(WorkspaceMounts)`.
2. `trparity_editor_focus_owner_survives_modal_commit` — same setup, but open a
   two-level chain (`open_sub_modal` twice) and close it the commit way with
   `clear_modal_chain()`; assert `modal.is_none()`, `!has_modal_parent()`, and
   `focus_owner()` unchanged. Add a third leg using `pop_modal_chain()` from
   the two-level chain to assert the parent modal is restored **and** focus is
   still `Content(WorkspaceMounts)`.

**Verify**:

```sh
cargo nextest run -p jackin-tui -E 'test(trparity_)'
cargo nextest run -p jackin-console -E 'test(trparity_editor_)'
cargo clippy -p jackin-tui --all-targets -- -D warnings
cargo clippy -p jackin-console --all-targets -- -D warnings
```

→ 5 and 2 tests pass respectively; both clippy runs exit 0.

### Step 5: Full-suite gate and parity-set inventory

```sh
cargo fmt --check
cargo xtask ci --only tests
cargo xtask ci --only lint
cargo xtask ci --only snapshots
cargo nextest run --workspace --all-features --locked -E 'test(trparity_)'
git status --porcelain
```

Expected: every command exits 0; the parity filter reports the full set (19
at planning time — **stamp the fresh number and note the delta**); `git status`
lists only the eight in-scope files plus the hub/roadmap protocol writes.

Record in your report: the fresh parity-test count, the baseline test count
from precondition 4 versus the post-change count for the four touched crates,
and confirmation that no `.snap` file appears in `git status`.

## Test plan

| Spec scenario | Tests | File |
|---|---|---|
| Esc cascade parity witness | `trparity_capsule_exit_dirty_esc_keeps_and_exits`, `trparity_capsule_exit_dirty_ctrl_c_keeps_and_exits`, `trparity_capsule_exit_dirty_enter_on_inspect_row_requests_inspect`, `trparity_capsule_exit_inspect_esc_walks_back_with_dismiss`, `trparity_capsule_exit_inspect_arrows_scroll_without_dismissing` | `crates/jackin-capsule/src/tui/components/dialog/tests.rs` |
| Esc cascade parity witness (`open_sub`/`pop`/`clear` half) | `trparity_modal_flow_open_sub_preserves_parent`, `trparity_modal_flow_pop_restores_parent_and_clears_chain`, `trparity_modal_flow_clear_closes_whole_chain` | `crates/jackin-tui/src/runtime/tests.rs` |
| Focus restore parity witness | `trparity_surface_focus_moves_between_tab_bar_and_content`, `trparity_surface_focus_survives_modal_open_and_close`; consumer half: `trparity_editor_focus_owner_survives_modal_cancel`, `trparity_editor_focus_owner_survives_modal_commit` | `crates/jackin-tui/src/runtime/tests.rs`, `crates/jackin-console/src/tui/screens/editor/model/tests.rs` |
| Diff scroll parity witness | `trparity_diff_scroll_starts_at_top`, `trparity_diff_scroll_down_moves_window_one_line`, `trparity_diff_scroll_up_clamps_at_top`, `trparity_diff_scroll_page_keys_move_ten_lines`, `trparity_diff_scroll_bottom_window_shows_last_viewport_lines`, `trparity_diff_scroll_reset_returns_to_top`, `trparity_diff_scroll_over_scroll_resumes_from_key_offset` | `crates/jackin-launch/src/tui/diff_scroll/tests.rs` |

Named edge cases covered: clamp at the top of a diff, clamp at the bottom of a
diff (widget viewport clamp, not the key clamp), the over-scrolled key offset
resuming past a viewport clamp, `ExitInspect` navigation clamping at its last
row, and a `SurfaceFocus` content identity that is not the registered one.

**Independent expected values**: every diff-scroll assertion is a hand-derived
literal row label (`"L00"`, `"L03"`, `"L10"`, `"L40"`) read out of a rendered
terminal buffer, never a value recomputed by calling the code under test. Every
dialog assertion is an exact `DialogAction` variant. Every focus assertion is
an exact `SurfaceFocusTarget` variant.

**Structural patterns to model after**:
`crates/jackin-capsule/src/tui/components/dialog/tests.rs:2335-2399` for the
dialog key-byte tests, `:2402-2420` for reading a `TestBackend` buffer,
`crates/jackin-tui/src/runtime/tests.rs:34-66` for the wrapper tests, and
`crates/jackin-console/src/tui/screens/editor/model/tests.rs:309-333` for the
editor fixture usage.

**Verify**: `cargo nextest run --workspace --all-features --locked -E 'test(trparity_)'`
→ all pass, 19 tests at planning time (re-derive).

## Done criteria

Machine-checkable. ALL must hold, each cited from output produced in this
session:

- [ ] `cargo check --workspace --all-targets --locked` exits 0
- [ ] `cargo xtask ci --only tests` exits 0
- [ ] `cargo xtask ci --only lint` exits 0 (includes `cargo fmt --check`, workspace clippy, `cargo xtask lint --strict`)
- [ ] `cargo xtask ci --only snapshots` exits 0 and `git status --porcelain -- '*.snap'` is empty
- [ ] `cargo nextest run --workspace --all-features --locked -E 'test(trparity_)'` exits 0; the fresh count is stamped in the report with its delta from 19
- [ ] Scenario "Esc cascade parity witness": `cargo nextest run -p jackin-capsule -E 'test(trparity_capsule_)'` → 5 pass; `cargo nextest run -p jackin-tui -E 'test(trparity_modal_flow_)'` → 3 pass
- [ ] Scenario "Focus restore parity witness": `cargo nextest run -p jackin-tui -E 'test(trparity_surface_focus_)'` → 2 pass; `cargo nextest run -p jackin-console -E 'test(trparity_editor_)'` → 2 pass
- [ ] Scenario "Diff scroll parity witness": `cargo nextest run -p jackin-launch -E 'test(/tui::diff_scroll::tests/)'` → 7 pass
- [ ] `grep -rn "diff_scroll_y" crates/jackin-launch/src` returns nothing (the hoist is complete, not duplicated)
- [ ] `grep -rn "DiffState\|DiffViewState\|termrock" crates/jackin-launch/src/tui/diff_scroll.rs` returns nothing (guardrail N2: the model wraps no TermRock API)
- [ ] `grep -n 'rev = "5ff94ee117fd4a1b72fdd0d1b1847815055a93ac"' Cargo.toml` still matches (the pin never moved)
- [ ] `cargo xtask lint files` and `cargo xtask lint readme-freshness --base origin/main` exit 0
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status rows and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails — in particular if `Cargo.toml` no longer pins rev
  `5ff94ee117fd4a1b72fdd0d1b1847815055a93ac`, or if the baseline suite is red
  before any edit.
- "Starting state" does not match reality: the cited `run.rs` offset
  expressions, the `dialog.rs:666-673` dismiss arm, the `ModalFlow`/`SurfaceFocus`
  public surfaces, or the console editor's modal/focus methods differ from the
  excerpts above.
- A step's verification fails twice after a reasonable fix attempt.
- The work requires touching an out-of-scope file or violating a Must NOT — in
  particular, if making the diff-scroll model testable seems to require
  wrapping or aliasing a TermRock type (that is N2; report instead).
- **Assumption A4 fails**: "the diff-scroll seam does NOT exist and is created
  in plan 001 by behavior-preserving extraction from the launch run loop
  (old-pin type `DiffState`, `pub offset`)" — falsified if the extraction
  cannot compile, or cannot be shown to preserve behavior at the old pin
  (e.g. `jackin-launch`'s suite regresses against the precondition baseline,
  or an offset expression has no equivalent in the hoisted model). Report
  which behavior could not be preserved and what was observed.
- A required input is missing with no replacement contract (note:
  `<TERMROCK_CHECKOUT>` is optional by design and never a STOP).

## Maintenance notes

- **What plan 002 depends on from here**: the `trparity_` prefix and the nextest
  filter `-E 'test(trparity_)'`. If a test is added later without the prefix, it
  drops out of the parity gate silently.
- **Single migration point in the diff-scroll tests**: the `draw` helper in
  `crates/jackin-launch/src/tui/diff_scroll/tests.rs` is the only place naming
  `DiffState`/`DiffView`/`DiffLine`. Plan 002 rewrites that one function for
  the head's `DiffViewState` accessor-only surface; every assertion above it
  is on rendered rows and must survive untouched. The spec allows exactly this
  ("the same tests pass without modification (renamed internal symbols
  aside)").
- **Known divergence risk for plan 002 — flag, do not pre-solve**:
  `trparity_diff_scroll_over_scroll_resumes_from_key_offset` pins the pre-bump
  two-offset quirk (key offset clamped at `len-1`, render offset clamped to the
  viewport, only the latter written back). At head the widget owns scrolling
  through its `ScrollAreaState` and there is no public setter, so a
  single-offset model may make this quirk disappear. If plan 002 finds it
  cannot reproduce this test's outcome, that is a deliberate operator-visible
  behavior change, not a test to quietly edit — route it to the operator.
- **What a reviewer should scrutinize**: that step 1 changed no behavior. The
  highest-value check is reading `run.rs:1028-1090` against the `DiffScroll`
  method table in step 1a, expression by expression, and confirming the
  PageUp/PageDown arm is still ungated by focus.
- **Deliberately deferred**: no daemon-level test of the ExitInspect
  walk-back (`dialog_push`/`dialog_pop_one`) — `daemon/tests.rs` covers
  exit-dirty pushes but not the walk-back, `dialog_mgmt.rs` has no sibling
  tests, and building that fixture is out of proportion to
  the pin bump's risk; the `Dialog`-level actions this plan pins are the layer
  the bump actually touches. No parity test for the console **settings**
  screen's `ModalFlow` panels (`GlobalMountsState` and siblings) — they call
  the same `ModalFlow` methods the jackin-tui tests pin, and adding one would
  require a new `tests.rs` under `screens/settings/model/`, widening scope.
