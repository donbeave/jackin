# Plan 002: Bump TermRock to head `e1d61f4d` and get the workspace compiling with the non-snapshot suite green

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: HIGH
- **Depends on**: plans/termrock-migration/001-*.md (parity characterization tests at the old pin)
- **Covers**: "Pin moves to head rev in the current style", "Lockfile wave and supply-chain gate", "Workspace compiles at head", "Suite green post-bump", "Wrappers re-host on head primitives without public-contract change", "Screen-set preservation", "Flow preservation" · ledger IDs F1, B1, B2, B7, B8, D1, D9, D14, D15, W1, S1
- **Guardrails**: N1, N2 (inlined below)
- **Research basis**: research/termrock-head-adoption/01-compile-break-inventory.md, research/termrock-head-adoption/02-migration-doc-map.md, research/jackin-verification-tooling/01-gates-and-commands.md
- **Planned at**: commit `d554dca8`, 2026-08-19

## Why this matters

The workspace pins TermRock at rev `5ff94ee1`, roughly 300 upstream migrations behind head. Every later modernization phase (console, capsule, launch, small surfaces) is blocked until the workspace builds against head, so this plan is the gate for the whole item. After it lands, `Cargo.toml` pins rev `e1d61f4d`, the lockfile and `cargo deny` absorb the forced supply-chain wave, all six consuming crates compile against the head API with no aliases or shims, the three forced redesigns (focus ring, modal stack, diff scroll offsets) are re-hosted on head primitives behind unchanged product contracts, and the only failing tests in the workspace are the insta snapshot assertions that plan 003 re-blesses.

## Preconditions — run before anything else

Run each; any failure is a STOP.

1. **Plan 001 landed (parity tests exist and pass).** Open `plans/termrock-migration/001-parity-tests.md` (the 001 plan file in this package — match by the `001-` prefix). It names the parity test filter and the parity test file paths it created. Run that filter exactly as 001 names it, e.g. `cargo nextest run -E '<filter from 001>'` → all parity tests pass, 0 failures. If no `001-*.md` file exists, or it names no runnable filter, that is a STOP (this plan cannot prove parity across the bump without it).
2. **Old pin still in place** (this plan has not already run): `grep -n 'rev = "5ff94ee117fd4a1b72fdd0d1b1847815055a93ac"' Cargo.toml` → prints line 118. If it prints nothing, the pin already moved — STOP and report.
3. **Toolchain**: `rustc --version` → `rustc 1.97.1`; `cargo deny --version` → `cargo-deny 0.20.2`; `cargo nextest --version` → `cargo-nextest 0.9.140`. Version mismatch → STOP (the deny measurement in "Starting state" was taken with cargo-deny 0.20.2).
4. **Rev fetchable (assumption A1)**: `git ls-remote https://github.com/tailrocks/termrock.git main` → at planning time this printed `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`. If upstream `main` has moved on, that is NOT a failure — the rev is pinned by full sha and stays fetchable; the authoritative check is `cargo fetch` succeeding in step 1. A1 is falsified only when `cargo fetch`/`cargo update` cannot resolve the rev at all — then STOP.
5. **Drift check** (this plan edits pre-existing code): `git diff --stat d554dca8..HEAD -- Cargo.toml Cargo.lock deny.toml crates/jackin-tui crates/jackin-launch crates/jackin-capsule crates/jackin-console crates/jackin-oppicker crates/jackin/src/console` — for any in-scope file listed, compare the "Starting state" excerpts below against live code before editing it. Excerpt mismatch that changes the migration shape is a STOP. (Files created by plan 001 are expected to appear here; that is not drift.)
6. **Clean tree**: `git status --porcelain` → empty.

## Spec contract

The requirements this plan implements, inlined **verbatim** from the spec — the executor does not read `spec/`.

### Requirement: Pin moves to head rev in the current style

The workspace `Cargo.toml` SHALL pin `termrock = { version = "=0.11.0", git = "https://github.com/tailrocks/termrock.git", rev = "e1d61f4d67ea6f0f3adee578caa2c5dba642217e", features = ["crossterm", "serde"] }` — only the rev changes; version string, git source, and features stay (upstream head keeps 0.11.0 and both features).

#### Scenario: Pin line after the bump

- **WHEN** the bump commit lands
- **THEN** `Cargo.toml:118`'s termrock entry carries rev `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`, version `=0.11.0`, features `["crossterm", "serde"]`
- **AND** `Cargo.lock` resolves termrock from that rev

### Requirement: Lockfile wave and supply-chain gate

The bump SHALL absorb the forced lock deltas — serde/serde_core/serde_derive to 1.0.229, `syn 3.0.3` added, `base64 0.23.1` added, `web-time` added — and `cargo deny check` SHALL pass with exactly two new bans skips (`base64@0.22.1`, `syn@2.0.119`); licenses and sources need no change.

#### Scenario: Bans gate green after skips

- **GIVEN** the bumped lockfile
- **WHEN** `cargo deny check bans` runs with the two skip entries added to `deny.toml`
- **THEN** it exits 0 with no duplicate-version errors

#### Scenario: No third skip smuggled in

- **WHEN** `git diff deny.toml` is reviewed
- **THEN** exactly two new skip entries exist and no license or source allowlist changed

### Requirement: Workspace compiles at head

All six consuming crates (jackin, jackin-capsule, jackin-console, jackin-launch, jackin-oppicker, jackin-tui) SHALL compile — lib and test targets — against rev `e1d61f4d`, with every renamed API migrated directly per the upstream migration docs (no aliases): `termrock::Theme` → `style::DesignSystem`/`RolePalette` (305 measured errors), `PanelEmphasis` → `PanelChrome`, `focused` → `cursor` on ChoiceDialog/ActionBar state, struct literals → builders/constructors (StatusSlot, Tab/TabsState, ListRow, DiffLine, DialogSpec), scroll offsets → `ScrollAreaState`, `ListState::for_count` const-loss absorbed.

#### Scenario: Workspace compiles at head

- **WHEN** `cargo check` runs for all six crates including `--tests`
- **THEN** it exits 0 with zero errors

### Requirement: Suite green post-bump

After the bump, `cargo nextest run --workspace --all-features --locked` SHALL pass with the ONLY failures being insta snapshot assertions in the three snapshot modules (`crates/jackin-capsule/src/tui/components/dialog/tests.rs`, `crates/jackin-capsule/src/tui/components/branch_context_bar/tests.rs`, `crates/jackin-console/src/tui/view/tests.rs`), each failure enumerated by test name in the run output; those failures are expected pending visual-rebaseline.md, and the bump PR's CI stays red between this requirement and the re-baseline by design. There is no repo-proven "exclude snapshots" filter — the xtask `snapshots` partition runs the whole capsule+console packages, so exclusion would also skip this package's parity tests.

#### Scenario: Suite green post-bump

- **WHEN** `cargo nextest run --workspace --all-features --locked` runs after the bump
- **THEN** every failure in the output is an insta snapshot assertion in one of the three named modules, and nothing else fails
- **AND** after visual-rebaseline lands, the same command exits 0

### Requirement: Wrappers re-host on head primitives without public-contract change

`jackin-tui`'s `SurfaceFocus`/`ModalFlow` (and the launch diff-scroll ownership) SHALL be re-implemented on the head's `InteractionScene`/`FocusGraph`/`OverlayStack` and `DiffViewState` accessor surface while keeping their existing public product contracts, so the parity tests pass unmodified after the bump. The facade keeps its product runtime traits (D15 — facade end-state decision deferred; this is an internal re-host, not a contract change).

#### Scenario: Parity tests green across the bump

- **GIVEN** the parity tests from this capability passing at the old pin
- **WHEN** the bump lands with the re-hosted wrappers
- **THEN** the same tests pass without modification (renamed internal symbols aside)

### Requirement: Screen-set preservation

The bump phase SHALL introduce no new operator-visible screens, dialogs, or overlays, and SHALL remove none; every screen in the existing inventory (console stages + 19 modals, capsule multiplexer + 15 dialogs, launch cockpit + overlays + standalone prompts, small surfaces) keeps its purpose, regions, states, interactions, and navigation.

#### Scenario: Dialog census unchanged

- **GIVEN** the pre-bump dialog/modal census (`ConsoleModal` 19 variants at `crates/jackin-console/src/tui/model/modal.rs:24-114`; capsule `Dialog` 15 variants at `crates/jackin-capsule/src/tui/components/dialog.rs:147-287`)
- **WHEN** the bump lands
- **THEN** both enums carry the same variant sets (renames of upstream types inside them notwithstanding)

### Requirement: Flow preservation

The bump phase SHALL change no operator journey: every flow's steps, screens, and failure points remain as before; flow-adjacent behavior moved by forced redesigns is proven unchanged by the parity scenarios in forced-redesigns.md.

#### Scenario: Existing non-snapshot tests as journey witnesses

- **GIVEN** the pre-bump test suite (keymap, dialog, input tests across the six crates)
- **WHEN** the bump lands
- **THEN** every pre-existing non-snapshot test passes unmodified except where a test names a renamed upstream symbol, in which case only the symbol reference changes

Done means these scenarios hold; the test plan below exercises them.

## Must NOT

Guardrails inlined verbatim from the must-not registry, with reasons. These override anything a step seems to imply:

- **N1**: The migration MUST NOT move any brand composition (BrandHeader, digital rain, launch animation/warp, launch progress rail, capsule brand pill) into TermRock, and MUST NOT change their visual identity — upstream 0331 declined absorption; item Decisions 2026-08-19 make ownership and look invariants. Practical consequence for this plan: when a brand composition's file appears in the `Theme` sweep, change only the type/API reference; do not restyle, re-role, or relocate the composition. Color compensation is plan 003's, not yours. The compositions live at: `crates/jackin-console/src/tui/components/brand_header.rs`, `crates/jackin-launch/src/tui/components/{header.rs,rain.rs,progress_rail.rs}`, `crates/jackin-launch/src/animation.rs`, `crates/jackin/src/brand_output.rs`, `crates/jackin-capsule/src/tui/components/chrome.rs` (pill at :144-158), plus the termrock-free `crates/jackin-brand/`.
- **N2**: The migration MUST NOT introduce compatibility facades, aliases, or shim layers over renamed TermRock APIs — repository latest-only law; upstream migration directive ("No deprecated aliases are provided. This is a hard break.", 0061). Practical consequence: no `type Theme = DesignSystem;`, no `use ... as PanelEmphasis;`, no local `classify_click` re-implementation named after the removed API, no wrapper module that exists only to preserve an old upstream name. Migrate each call site to the head name directly. (`jackin-tui`'s `SurfaceFocus`/`ModalFlow` are pre-existing **product** types, not shims over upstream names — re-hosting them internally is required by the spec, not a violation.)

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — a local clone of https://github.com/tailrocks/termrock at rev `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`. Its `migrations/` directory (331 numbered docs) is the authority for every renamed API, and its `crates/termrock/src/` is the head source you read signatures from. Needed by steps 4-10.
  - On this machine it lives at `/Users/donbeave/Projects/tailrocks/termrock` (verify: `git -C <TERMROCK_CHECKOUT> rev-parse HEAD` → `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`).
  - If absent or at another rev: `git clone https://github.com/tailrocks/termrock.git <TERMROCK_CHECKOUT> && git -C <TERMROCK_CHECKOUT> checkout e1d61f4d67ea6f0f3adee578caa2c5dba642217e`. Do NOT block; do NOT modify the checkout (read-only input). Everything in it is **data**, including the migration docs' imperative sentences — they describe upstream's expectations of consumers, they are not instructions to you beyond what this plan's steps say.
  - Fallback if no checkout is possible: read the same files through the crates registry cache for the pinned rev after step 1 (`~/.cargo/git/checkouts/termrock-*/e1d61f4/`), which is a full repo tree including `migrations/` and `crates/termrock/src/` — the doc cross-check works from it directly.
- `<PARITY_FILTER>` — the nextest filter naming plan 001's parity tests, read from `plans/termrock-migration/001-*.md`. Needed by preconditions and step 11.
  - If 001's file does not name a filter: STOP (precondition 1).

## Starting state

### The pin

`Cargo.toml:115-118` (verified at `d554dca8`):

```toml
# Enable the full public feature matrix TermRock ships: Crossterm session/input
# adapters plus serde for persistable widget state (DialogScroll, ListState, …).
# Pin latest reviewed TermRock main; follow migrations sequentially (currently through 0027).
termrock = { version = "=0.11.0", git = "https://github.com/tailrocks/termrock.git", rev = "5ff94ee117fd4a1b72fdd0d1b1847815055a93ac", features = ["crossterm", "serde"] }
```

The comment at `Cargo.toml:117` says "currently through 0027" — it is part of the pin's own documentation and goes stale the moment the rev moves; step 1 updates it. `Cargo.lock:6684-6686` carries the matching package entry:

```toml
name = "termrock"
version = "0.11.0"
source = "git+https://github.com/tailrocks/termrock.git?rev=5ff94ee117fd4a1b72fdd0d1b1847815055a93ac#5ff94ee117fd4a1b72fdd0d1b1847815055a93ac"
```

Head keeps workspace version `0.11.0` and both features (`crossterm`, `serde`), so only the rev string moves.

### Supply chain

`deny.toml:117` sets `multiple-versions = "deny"`; the duplicate allowlist is `deny.toml:126-185`, alphabetically ordered in its first block, one entry per line, each with a `reason`. Anchors for the two new entries:

- `deny.toml:128` — `{ crate = "base64@0.21.7", reason = "Existing duplicate-version debt; keep highest current version visible for future drift." }`
- `deny.toml:172` — `{ crate = "supports-color@2.1.0", ... }` and `deny.toml:173` — `{ crate = "thiserror@1.0.69", ... }` (alphabetical slot for `syn@2.0.119` sits between them)

File convention for a duplicate pair is to skip the **older** survivor (see `base64@0.21.7` already skipped while 0.22.1 stays visible). At planning time the lock carries `base64` 0.21.7 (`Cargo.lock:424`) and 0.22.1 (`:430`), `syn` 1.0.109 (`:6540`) and 2.0.119 (`:6551`), `serde` 1.0.228 (`:5942`), and `web-time` 1.1.0 (`:7826`). `web-time` therefore already exists as a package — the spec's "`web-time` added" is a new dependency **edge** under the termrock package entry, not a new package; do not expect a new `[[package]]` block for it.

Measured with cargo-deny 0.20.2 on a patched clone (research/termrock-head-adoption/01-compile-break-inventory.md, finding 0): after the bump `cargo deny check bans` fails with exactly two duplicates — `base64` 0.22.1+0.23.1 and `syn` 2.0.119+3.0.3 — and passes with exactly the two skips above. `check licenses sources` passes unchanged.

### Break inventory (planning-time measurement — re-derive)

Measured 2026-08-19 on a disposable clone at commit `3089538d` with rustc 1.97.1: **384** compiler-measured lib errors across the five TUI crates (tui 8, oppicker 1, launch 66, capsule 58, console 251), plus 2 more in the `jackin` crate measured post-sweep. Summary table (research ch01 "Summary table"):

| Break class | Errors (lib, measured) | Crates | Migration doc(s) |
|---|---|---|---|
| Cargo.lock: serde ≥1.0.229 required (resolver failure) | build-blocking | workspace | none (build prerequisite) |
| `termrock::Theme` root path/type removed → `style::DesignSystem`/`RolePalette` | 305 (+tests; 323 swept sites) | tui 4, launch 41, capsule 46, console 214, jackin 7 (static) | 0060, 0061, 0331 |
| `widgets::PanelEmphasis` → `PanelChrome` | 24 | tui 1, launch 2, capsule 3, console 17 (+1 tui test) | 0061 |
| `FocusRing`/`FocusTarget`/`FocusOutcome` private | 2 | jackin-tui only (`SurfaceFocus`) | 0062, 0060 |
| `ModalStack` private | 1 | jackin-tui only (`ModalFlow`) | 0065 |
| `classify_click`/`ModalClickResult` removed | 6 | capsule 2, console 4 | 0065 |
| `ListState::for_count` no longer `const` | 1 | oppicker | 0083 |
| `StatusSlot` +4 required fields | 8 | launch 6, capsule 1, jackin 1 | 0110 (0298) |
| `StatusBarState` literal → `::new()` | 3 | launch, capsule, jackin | 0110 |
| `ListRow` +`status`/`actions`/`custom` fields | 10 | console 7, capsule 2, launch 1 | 0185 (0039, 0057) |
| `Tab` +`badge`/`closable`/`status`; `TabsState` literal → `::new()` | 2 + 2 | capsule, console | 0152 |
| `ChoiceDialogState.focused`/`ActionBarState.focused` → `cursor` | 3 + 4 | launch 1, console 6 | 0073 |
| `DialogSpec` +`preferred_reference_pct` | 3 | launch, capsule, console | 0263 |
| `DiffLine` literal → builders | 1 | launch | 0196 |
| `DiffViewState.offset` field → getter, no public setter | 12 | launch (1 file) | 0085, 0196 |

**Planning-time measurements carry the re-derivation rule.** Every number above (384 total, 305 Theme errors, the per-class counts) is a planning-time snapshot taken on a different commit with a path patch rather than a rev bump. Re-run the counting commands in step 3, stamp the fresh numbers in your report, note the delta from the planned figures, and treat the fresh output as the authority. Never treat a drifted planning number as a target to reproduce. A count that differs is fine; a **kind** that differs (a break class not in this table) is a STOP (assumption A2).

The 40 applicable upstream migration docs are mapped per API in research/termrock-head-adoption/02-migration-doc-map.md; the doc numbers in the table above are the entry points. Read the numbered doc in `<TERMROCK_CHECKOUT>/migrations/` for each class before sweeping it.

### Representative break sites (verified present at `d554dca8`)

- Theme: `crates/jackin-tui/src/operator_info.rs:414` (`let theme = termrock::Theme::default();`), `crates/jackin-launch/src/tui/components/failure_dialog.rs:15`, `crates/jackin-console/src/tui/view.rs`
- PanelEmphasis: `crates/jackin-tui/src/operator_info.rs:21` (`    Panel, PanelEmphasis,`), `crates/jackin-console/src/tui/components/file_browser/render.rs:16`, `crates/jackin-capsule/src/tui/components/chrome.rs:21`
- StatusSlot literals: `crates/jackin-launch/src/tui/components/footer.rs:43` (`    let left = [StatusSlot {`), `:53,62,118,138,157`; `crates/jackin-capsule/src/tui/components/branch_context_bar.rs:146` (`    StatusSlot {`); `crates/jackin/src/console/adapter/run.rs:400`
- StatusBarState literals: `crates/jackin-launch/src/tui/components/footer.rs:202`, `crates/jackin-capsule/src/tui/components/branch_context_bar.rs:336`, `crates/jackin/src/console/adapter/run.rs:429`
- ListRow literals: `crates/jackin-console/src/tui/components/agent_choice.rs:110` (`        .map(|(id, agent)| ListRow {`), `crates/jackin-console/src/tui/components/file_browser/render.rs:138`, `crates/jackin-capsule/src/tui/components/dialog_widgets.rs:665,672`, `crates/jackin-launch/src/tui/components/prompts.rs:123`
- Tab / TabsState literals: `crates/jackin-capsule/src/tui/components/dialog_widgets.rs:574` (`        .map(|(id, (label, active))| Tab {`) and `:585`; `crates/jackin-console/src/tui/components/editor_rows.rs:211,223`
- `focused` → `cursor`: `crates/jackin-console/src/tui/components/dialogs.rs:231` (`        self.choice.focused = Some(true);`) and `:237`; `crates/jackin-launch/src/tui/components/prompts.rs:201`; ActionBarState at `crates/jackin-console/src/tui/components/confirm_save.rs:323`, `mount_dst_choice.rs:166`, `scope_picker.rs:115`, `source_picker.rs:123`
- DialogSpec literals: `crates/jackin-launch/src/tui/components/dialog.rs:22` (`        termrock::layout::DialogSpec {`), `crates/jackin-capsule/src/tui/components/modal_rects.rs:283`, `crates/jackin-console/src/tui/components/modal_rects.rs:389`
- `ListState::for_count` in a const fn: `crates/jackin-oppicker/src/state.rs:265-267`:

  ```rust
  pub(crate) const fn list_state_for_count(count: usize) -> ListState<usize> {
      ListState::for_count(count)
  }
  ```

- `classify_click`: `crates/jackin-capsule/src/tui/components/dialog.rs:938-939`; `crates/jackin-console/src/tui/run.rs:436-437` (inside `fn mouse_down_outside_rect`) and `:451-452` (inside `pub fn should_dismiss_list_modal_for_outside_click`). Both jackin sites compare the result against `ModalClickResult::OutsideDismiss`. At the old pin `classify_click(modal_rect, col, row)` returns `InsideHit` when `modal_rect.contains(Position { x: col, y: row })` and `OutsideDismiss` otherwise — pure rect containment, verified in the old-pin source at planning time.

### The three forced redesigns

**1. `SurfaceFocus` — `crates/jackin-tui/src/runtime/focus.rs`.** Public product contract to preserve exactly: `SurfaceFocusTarget<Content>` (`TabBar` / `Content(Content)`), and on `SurfaceFocus<Content>`: `tab_bar`, `content`, `focused`, `focused_content`, `focus_tab_bar`, `focus_content`, `is_tab_bar`, `is_content`, `show_cursor_for`. Internals at `focus.rs:6,19-22`:

```rust
use termrock::interaction::FocusRing;
...
pub struct SurfaceFocus<Content> {
    ring: FocusRing<SurfaceFocusTarget<Content>, ()>,
    content: Content,
}
```

with a `register()` helper (`focus.rs:45-54`) that calls `ring.begin_frame()` then `ring.register_order((), [(TabBar, None, true), (Content(self.content), None, true)])`, and construction at `:37,41` (`FocusRing::new((), Some(focused))`, then `drop(state.ring.reconcile())`).

**2. `ModalFlow` — `crates/jackin-tui/src/runtime/modal_flow.rs`.** Public product contract to preserve exactly: `new` (+ the `Default` impl), `current`, `current_mut`, `parents`, `parents_mut`, `is_open`, `has_parent`, `open`, `open_sub`, `pop`, `clear`, `take_current`, `set_current`, `open_pair`. Internals at `modal_flow.rs:6,10-15`:

```rust
use termrock::interaction::{FocusRing, ModalStack};

pub struct ModalFlow<Modal> {
    current: Option<Modal>,
    parents: Vec<Modal>,
    stack: ModalStack<()>,
    focus: FocusRing<(), usize>,
}
```

with the scope calls at `:66` (`self.focus.open_modal(&mut self.stack, (), 1)`), `:73-74` (`let scope = self.stack.depth() + 1; self.focus.open_submodal(&mut self.stack, (), scope)`), `:83` (`self.focus.pop_modal(&mut self.stack)`), `:89` (`self.focus.clear_modals(&mut self.stack)`).

**3. Launch diff scroll — `crates/jackin-launch/src/tui/run.rs`.** At planning time the offset is function-local: `:866` `let mut diff_scroll_y: usize = 0;`, the diff struct at `:868-872` holding `state: DiffState`, the write at `:981` `diff.state.offset = diff_scroll_y.min(diff.lines.len().saturating_sub(1));`, the `DiffLine` literal at `:985` `.map(|(text, kind)| DiffLine { text, kind: *kind })`, and further mixed reads/writes at `:1007,1042,1043,1066-1085` (research ch01, finding 14 — 12 measured errors, all in this one file). **Plan 001 extracted this into a testable unit**; that extraction is your seam. Re-read the extracted unit before editing — the line numbers above are pre-extraction.

### Head API facts (read from `<TERMROCK_CHECKOUT>` at `e1d61f4d`)

Paths below are relative to `<TERMROCK_CHECKOUT>/crates/termrock/src/`:

- `style/tokens.rs:703` — `impl Default for DesignSystem` → `Self::phosphor()`; `style/tokens.rs:795` — `DesignSystem::from_palette(palette: RolePalette)`; `style/mod.rs:362` — `RolePalette::tailrocks_phosphor()`; `style/tokens.rs:985` — `with_role(mut self, role: Role, style: Style) -> Self`; `style/tokens.rs:1002` — `style(&self, role: Role) -> Style`. Widget constructors take `&DesignSystem` with unchanged arity, so the type swap alone type-checked with zero secondary method errors in the research clone.
- `interaction/scene.rs:257` — `pub struct InteractionScene<Id, LayerId, Action>`; `interaction/focus_graph.rs:203` — `pub struct FocusGraph<Id>` with `new()` `:223`, `begin_frame()` `:243`, `register(node)` `:253`, `focused()` `:283`, `is_focused(id)` `:289`, `owns_keyboard(id)` `:298`, `panel_chrome_for(id)` `:307`, `reconcile()` `:407`, `focus_next()` `:436`, `request_focus(id)` `:498`, `focus_at(position)` `:510`; `FocusNode::leaf(id, area)` `:90`, `roving_collection(id, area)` `:105`, builders `parent`/`zone`/`tab_index`/`enabled`/`focusable` `:120-148`.
- `interaction/overlay_stack.rs:755` — `pub struct OverlayStack<FocusId = ()>` with `new()` `:778`, `entries()` `:827`, `top()` `:833`, `is_empty()` `:839`, `open(bounds, spec)` `:980`, `handle_escape()` `:1158`, `handle_outside_click(position)` `:1180`, `clear()` `:945`, `dismiss(id)` `:1247`, `sync_scene_layers(scene)` `:1255`, `sync_scene_layers_unit(scene)` `:1276`; `OverlaySpec::dialog(...)` `:421`, `OverlayOutcome::restored_focus()` `:726` (inside `impl<FocusId> OverlayOutcome<FocusId>` at `:711`).
- Migration 0065's "Removed surface" table maps `FocusRing::open_modal(&mut ModalStack, …)` to `push_modal_scope`/`pop_modal_scope` on the **crate-private** ring — i.e. not a public replacement. `OverlayStack` plus its `OverlayOutcome` (which carries the focus to restore on dismissal) is the public authority.
- `widgets/diff.rs:516` — `pub struct DiffViewState`; `:562` — `pub type DiffState = DiffViewState;` (the old name survives as an alias); `:606` — `pub const fn offset(&self) -> u16`; `:612` — `pub const fn scroll(&self) -> &ScrollAreaState`. No public offset setter.
- `widgets/diff.rs:325-346` — `DiffLine<'a> { id, kind, text, old_no, new_no, words, syntax, … }`; `:354` — `pub const fn new(id: &'a str, kind: DiffKind, text: &'a str) -> Self`.
- `widgets/status_bar.rs:199` — `StatusSlot::new(id: Id, content: &'a str)`; `:413` — `StatusBarState::new()`.
- `widgets/list.rs:119-146` — `ListRow<'a, Id>` with 13 fields (`id, label: Line<'a>, leading, secondary, status, badge, shortcut, actions, trailing, custom, role, enabled, loading`); `:151` — `ListRow::item(id: Id, label: Line<'a>)`; `:358` — `ListState::new(selected)`; `:928` — `pub fn for_count(...)` (no longer `const`).
- `widgets/tabs.rs:226-243` — `Tab<'a, Id> { id, label, glyph, badge, status, active, enabled, closable }`; `:248` — `pub const fn new(id: Id, label: &'a str)`; `:396` — `TabsState::new()`; `:447` — `with_selected(id)`.
- `layout/mod.rs:64` — `pub preferred_reference_pct: Option<u16>` on `DialogSpec`; `:83` — `pub const fn preferred_pct_of_reference(mut self, pct: u16) -> Self`.
- `widgets/action_bar.rs:33-38` — `ActionBarState<Id> { pub cursor: Option<Id>, pub regions: Vec<HitRegion<Id>> }`; `widgets/dialog.rs:1521-1529` — `ChoiceDialogState<Id> { pub cursor: Option<Id>, pub regions, loading (private), accepts_input (private), dialog (private) }`.

### Conventions to match

- Test layout: tests live in a sibling `tests.rs`, never inline `#[cfg(test)] mod tests { … }`, and `tests.rs` never declares child modules (exemplar: `crates/jackin-tui/src/runtime/tests.rs` beside `runtime/focus.rs`).
- Rust 2024 self-named modules, no `mod.rs` (exemplar: `crates/jackin-capsule/src/tui/components/dialog.rs` + `dialog/tests.rs`).
- Lint baseline is deny-by-default at CI (`cargo clippy --workspace --all-targets --all-features --locked -- -D warnings`); `unused_qualifications` is denied, so import moves that leave a fully-qualified path behind will fail the lint gate (research ch01 flags this as expected fallout).

## Commands you will need

Proven by research/jackin-verification-tooling/01-gates-and-commands.md (the "Partition selection" step table, `crates/jackin-xtask/src/ci.rs` line cites in that chapter, and the toolchain probes) — except four rows that are standard cargo forms not in the chapter: `cargo fetch`, `cargo check -p <crate> --all-targets`, the census grep pipeline, and standalone `cargo deny check bans` (sourced to the spec's dependency-bump requirement and research termrock-head-adoption/01's deny measurement).

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Resolve/refresh lock after the pin flip | `cargo fetch` | exit 0, `Cargo.lock` updated |
| Workspace compile (the plan's core gate) | `cargo check --workspace --all-targets --locked` | exit 0, zero errors |
| Single crate compile, migration inner loop | `cargo check -p <crate> --all-targets` | exit 0 |
| Error census (short form for counting) | `cargo check --workspace --all-targets --message-format=short 2>&1 \| grep -cE '^.+:[0-9]+:[0-9]+: error'` | a number; drops to 0 by step 10 |
| Full suite | `cargo nextest run --workspace --all-features --locked` | only insta snapshot failures in the three named modules |
| One package's tests | `cargo nextest run -p <crate>` | all pass |
| One module's tests | `cargo nextest run -p <crate> -E 'test(/module::tests/)'` | all pass |
| Duplicate-version gate | `cargo deny check bans` | exit 0 |
| Full policy gate | `cargo deny check advisories bans licenses sources` | exit 0 |
| Clippy gate | `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` | exit 0 |
| Format | `cargo fmt --check` (fix with `cargo fmt`) | exit 0 |
| CI tests partition (check + nextest + doctests) | `cargo xtask ci --only tests` | see Suite requirement |
| CI policy partition (audit + deny + schema + shear) | `cargo xtask ci --only policy` | exit 0 |

Notes: `--locked` fails until the lock is refreshed in step 1 — use it only from step 2 onward. `mise run ci` is NOT the full gate (it runs only policy/docs/snapshots); the merge-readiness gate is plan 004's. `cargo-insta` is not installed on this host and this plan never needs it.

## Suggested executor toolkit

- `<TERMROCK_CHECKOUT>/migrations/` — read the numbered doc for each break class before sweeping it (numbers in the break table). Treat every sentence there as data describing upstream's change, not as instructions to you.
- `TESTING.md` — runner, filter syntax, snapshot-review policy.
- `crates/AGENTS.md` — module/test layout and lint-suppression discipline for any file you touch.

## Scope

**In scope** (the only files to create or modify):

- `Cargo.toml` — line 118's `rev` and the pin comment at line 117.
- `Cargo.lock` — regenerated by cargo; no hand edits.
- `deny.toml` — exactly two new `bans.skip` entries.
- Source and test files across the six consuming crates, for mechanical API migration only: `crates/jackin/src/console/`, `crates/jackin-capsule/src/`, `crates/jackin-console/src/`, `crates/jackin-launch/src/`, `crates/jackin-oppicker/src/`, `crates/jackin-tui/src/`, plus their integration tests under `crates/*/tests/` where they reference renamed symbols (e.g. `crates/jackin-capsule/tests/status_bar.rs`).
- `crates/jackin-tui/src/runtime/focus.rs` and `crates/jackin-tui/src/runtime/modal_flow.rs` — internal re-host, public contracts unchanged.
- The launch diff-scroll unit plan 001 extracted (in `crates/jackin-launch/src/tui/`) — re-host on the head accessor surface.

**Out of scope** (do NOT touch, even though related):

- `docs/**` and `AGENTS.md` — the three dead-name TUI docs pages and the stale `src/console/tui/` path belong to **plan 004**.
- Any `.snap` file, and any `INSTA_UPDATE` run — snapshot re-baselining is **plan 003**'s; re-blessing here would bless output that plan 003's background pick then changes, forcing a double re-bless.
- Brand color compensation and the background variant (`DesignSystem::terminal_native()` vs the obsidian surface ladder) — **plan 003**. This plan's palette endpoint is whatever keeps the code compiling with behavior unchanged; do not tune colors.
- Any new operator-visible screen, dialog, overlay, keybinding, or hint — forbidden by the screen-set/flow-preservation constraints above. If a head API's shape tempts a UI change, it belongs to a later modernization phase.
- Optional adoptions the head offers but nothing forces: `ModalSpec`/`modal_rect` (0323), `KeyValueTable` (0191), `DetailTable::measure`/`panel_stack` (0268), `Kbd`/`ShortcutHint` (0120), `context_meter`/`metric_tile`. Adopting them is per-surface modernization work, not this bump.
- Crates that do not depend on termrock.

The hub `plans/termrock-migration/README.md` and the roadmap item are protocol-writable and never listed in scope.

## Git workflow

Only what instantiates the hub's repo law for this plan:

- **The pin/lock/deny commit is atomic** — `Cargo.toml`, `Cargo.lock`, and `deny.toml` land together (steps 1-2), subject `build(deps): bump termrock to head e1d61f4d`.
- **The compile wave commits in class-sized chunks**, largest class first, one commit per class or per tightly-related class group. The tree does **not** compile between the pin commit and the last class commit — that is expected and unavoidable for a hard-break dependency bump (N2 forbids the shim layer that would keep it green mid-flight); the PR is a draft through this plan. Suggested subjects:
  - `refactor(tui): migrate termrock::Theme to style::DesignSystem`
  - `refactor(tui): migrate PanelEmphasis to PanelChrome`
  - `refactor(tui): migrate widget struct literals to head constructors`
  - `refactor(tui): migrate ChoiceDialog/ActionBar focused to cursor`
  - `refactor(console): re-host outside-click dismissal on head geometry`
  - `refactor(jackin-tui): re-host SurfaceFocus on FocusGraph`
  - `refactor(jackin-tui): re-host ModalFlow on OverlayStack`
  - `refactor(launch): re-host diff scrolling on DiffViewState accessors`
  - `style(tui): satisfy lint gate after the termrock head migration` (only if step 11 needs a separate commit)
- Every commit is signed off and pushed immediately per the hub.

## Steps

### Step 1: Flip the pin and refresh the lock

Edit `Cargo.toml:118`: replace `rev = "5ff94ee117fd4a1b72fdd0d1b1847815055a93ac"` with `rev = "e1d61f4d67ea6f0f3adee578caa2c5dba642217e"`. Change nothing else on that line — `version = "=0.11.0"`, the git URL, and `features = ["crossterm", "serde"]` all stay. Update the stale comment at `Cargo.toml:117` so it names the head state (e.g. `# Pin latest reviewed TermRock main; follow migrations sequentially (currently through 0331).`).

Refresh the lock with `cargo fetch`. If resolution fails with "failed to select a version for `serde`" (head requires `serde ^1.0.229`, the lock pins 1.0.228), run `cargo update serde --precise 1.0.229` and re-run `cargo fetch`.

**Verify**:

- `grep -n 'e1d61f4d67ea6f0f3adee578caa2c5dba642217e' Cargo.toml Cargo.lock` → at least one hit in each file
- `grep -n 'termrock' -A 3 Cargo.lock | grep 'source = '` → the termrock source line names `rev=e1d61f4d67ea6f0f3adee578caa2c5dba642217e`
- `git diff Cargo.toml` → exactly two changed lines (the rev, the comment); `version = "=0.11.0"` and the feature list unchanged
- `git diff Cargo.lock | grep '^[+-]name' | sort -u` → shows the forced wave only (serde family, syn, base64, termrock); stamp the actual list in your report

### Step 2: Absorb the supply-chain wave

Run `cargo deny check bans`. Expect failure with duplicate-version errors. Read them: the planned pairs are `base64` 0.22.1+0.23.1 and `syn` 2.0.119+3.0.3.

Add **exactly two** entries to the `skip` list in `deny.toml` (`:126-185`), skipping the older survivor of each pair per the file's convention, in the block's alphabetical position (`base64@0.22.1` immediately after `base64@0.21.7` at `:128`; `syn@2.0.119` between `supports-color@2.1.0` and `thiserror@1.0.69`), each with a `reason` naming the cause — e.g. `reason = "termrock head pulls base64 0.23.1; older transitive survivor kept visible for future drift."` and `reason = "serde_derive 1.0.229 pulls syn 3.0.3; older transitive survivor kept visible for future drift."`.

Touch nothing else in `deny.toml` — no license exception, no source allowlist change, no third skip.

**Verify**:

- `cargo deny check bans` → exit 0, no duplicate-version errors
- `cargo deny check advisories bans licenses sources` → exit 0
- `git diff deny.toml | grep -c '^+[^+]'` → exactly 2 added content lines (the `^+[^+]` pattern excludes the `+++` file header)
- `git diff deny.toml | grep '^+[^+]' | grep -c 'licenses\|allow-git\|allow-registry'` → 0

(Base-ref note for all diff checks in this plan: before step 1, record `START_SHA=$(git rev-parse HEAD)` and stamp it in your report. Working-tree `git diff` forms above apply pre-commit; after committing, the equivalent committed-state check is `git diff "$START_SHA"..HEAD -- <same paths>`.)

Commit steps 1-2 together: `build(deps): bump termrock to head e1d61f4d`. Push.

### Step 3: Take the error census and validate the break inventory

Run the census in dependency order, because a crate that fails to build hides its dependents' errors: `cargo check -p jackin-tui --all-targets`, then `-p jackin-oppicker`, `-p jackin-launch`, `-p jackin-capsule`, `-p jackin-console`, `-p jackin`, then the whole workspace.

Record: total error count, and the count per break class. Classify with the short format, e.g.

```sh
cargo check --workspace --all-targets --message-format=short 2>&1 | grep -E '^.+:[0-9]+:[0-9]+: error' > <scratch>/census.txt
grep -c 'Theme' <scratch>/census.txt
grep -cE 'PanelEmphasis' <scratch>/census.txt
grep -cE 'E0063|E0560|E0615|E0603|E0015' <scratch>/census.txt
```

Write the census outside the repository (a scratch directory, never a repo path).

Compare every observed error **kind** against the break table in "Starting state". Counts may drift — stamp the fresh numbers and note the delta. A break class with no row in that table is a STOP (assumption A2 falsified in kind).

**Verify**: the census's distinct error kinds are a subset of the table's rows; the fresh total is recorded alongside the planned 384.

### Step 4: Sweep the Theme class (largest — 305 planned errors)

Read `<TERMROCK_CHECKOUT>/migrations/0060*`, `0061*`, `0331*` first.

Replace every `termrock::Theme` path and import with the head surface: the type is `termrock::style::DesignSystem`, and its call shape survives (`style(Role)`, `with_role(Role, Style)`). For construction sites, `DesignSystem::default()` is `DesignSystem::phosphor()` at head (`style/tokens.rs:703`); the upstream-named endpoint is `DesignSystem::from_palette(RolePalette::tailrocks_phosphor())` (0331). Default to `DesignSystem::default()` (fewest tokens; identical resolution) unless a call site already names a palette explicitly — plan 003 owns the operator's background-variant pick and will retarget construction sites if needed; do not tune colors (N1 — plan 003 owns compensation). Fix any `unused_qualifications` fallout as you go: after moving an import, do not leave a fully-qualified path behind.

Sweep all six crates including `#[cfg(test)]` sibling test modules and `crates/*/tests/` integration tests. Per the flow-preservation scenario, test files change **only** in the symbol they name — never in an assertion.

**Verify**:

- `grep -rn 'termrock::Theme\|Theme::default' crates/ --include='*.rs'` → no hits outside `crates/jackin-xtask/src/arch/tests.rs:250` (a string-literal fixture for the arch gate, not a compile break — leave it alone)
- census re-run → the Theme class count is 0; total dropped by the planned ~305 ±10% (stamp the actual delta; a delta beyond that band means the inventory drifted in kind — treat as the A2 STOP, not a target to force)

Commit: `refactor(tui): migrate termrock::Theme to style::DesignSystem`. Push.

### Step 5: Sweep PanelEmphasis → PanelChrome (24 planned errors)

Per 0061, `widgets::PanelEmphasis` is now `style::PanelChrome`, re-exported from `widgets`. `Panel` keeps both `.emphasis(PanelChrome)` and `.chrome(...)`, so only the type name and imports change. No alias imports (N2): rename the identifier at each site.

**Verify**: `grep -rn 'PanelEmphasis' crates/ --include='*.rs'` → no hits; census re-run shows the class at 0.

Commit: `refactor(tui): migrate PanelEmphasis to PanelChrome`. Push.

### Step 6: Migrate the struct-literal and field-rename classes

Read `<TERMROCK_CHECKOUT>/migrations/0110*` (+`0298*`), `0185*` (+`0039*`, `0057*`), `0152*`, `0263*`, `0196*`, `0073*`, `0083*`. Work class by class, verifying after each:

1. **StatusSlot** (8 sites): replace literals with `StatusSlot::new(id, content)` plus the builders the site needs (`.priority(..)`, `.style(..)`); the new `region`/`kind`/`glyph`/`style_explicit` fields keep their defaults unless the old literal set an equivalent. 0298 governs glyph semantics — do not invent a glyph where the pre-bump slot had none.
2. **StatusBarState** (3 sites): `StatusBarState::new()`, then assign the still-public `hovered`/`regions` fields as before.
3. **ListRow** (10 sites): head has 13 fields; use `ListRow::item(id, label)` plus builders, keeping exactly the `trailing`/`role`/`enabled` values the literal set. `label` is `Line<'a>` at head. Leave `status`/`actions`/`custom` unset — populating them would add operator-visible content (screen-set constraint).
4. **Tab / TabsState** (2 + 2 sites): `Tab::new(id, label)` plus builders for the fields the literal set; `TabsState::new()` / `.with_selected(id)`, then the still-public `selected`/`hovered`/`focused`/`regions` as before.
5. **DialogSpec** (3 sites): add the new `preferred_reference_pct` field, or switch to the builder `preferred_pct_of_reference(pct)`. Preserve the pre-bump geometry — `None` keeps the old behavior unless the site clearly wants the reference percentage.
6. **DiffLine** (1 site): `DiffLine::new(id, kind, text)` — the head type carries a stable `id`; derive it from data already at the site (e.g. the line index), never from new operator-visible content.
7. **`focused` → `cursor`** (3 + 4 sites): `ChoiceDialogState.cursor` and `ActionBarState.cursor` (both `Option<Id>`). Field rename only; the value semantics are unchanged.
8. **`ListState::for_count` const loss** (1 site): drop `const` from `crates/jackin-oppicker/src/state.rs:265`'s `list_state_for_count` wrapper. Check the wrapper's callers still compile in whatever const context they used; if a caller genuinely requires const context (a `const`/`static` initializer), hoist that caller's initialization to runtime (e.g. `Default`/constructor path) — never re-implement `ListState` construction to fake constness (N2 territory), and note the hoist in the commit body.

**Verify** after each sub-class: `cargo check -p <affected crate> --all-targets --message-format=short 2>&1 | grep -c 'error'` → the class's errors are gone and the total dropped by that class's count. After all eight: census re-run shows only the redesign classes (FocusRing, ModalStack, classify_click, DiffViewState.offset) remaining.

Commit: `refactor(tui): migrate widget struct literals to head constructors` and `refactor(tui): migrate ChoiceDialog/ActionBar focused to cursor` (split as the diffs make reviewable). Push after each.

### Step 7: Re-host outside-click dismissal (6 planned errors)

`interaction::classify_click` and `ModalClickResult` are removed (0065); the named replacement is `OverlayStack::handle_outside_click`, which requires an `OverlayStack` the host owns. jackin does not own one at bump time (D15 defers the facade end-state), and introducing one here would change modal ownership — out of scope for this plan.

Both jackin sites are pure rect predicates over `(rect, col, row)`: `crates/jackin-console/src/tui/run.rs` `mouse_down_outside_rect` (`:434-438`) and `should_dismiss_list_modal_for_outside_click` (`:441-453`), and `crates/jackin-capsule/src/tui/components/dialog.rs:938-939`. Re-host each on plain geometry with identical semantics — outside = `!rect.contains(Position { x: col, y: row })` — keeping every function name, signature, and caller unchanged. This is not a facade over a removed API (N2): do not name anything `classify_click`, do not define a `ModalClickResult`-shaped enum, and do not add a module whose only purpose is to preserve the old upstream names.

**Verify**:

- `grep -rn 'classify_click\|ModalClickResult' crates/ --include='*.rs'` → no hits
- `cargo check -p jackin-console -p jackin-capsule --all-targets` → this class's errors gone
- `cargo nextest run -p jackin-console -E 'test(/run::tests/)'` and the capsule dialog tests → the pre-existing outside-click tests pass unmodified

Commit: `refactor(console): re-host outside-click dismissal on head geometry`. Push.

### Step 8: Re-host `SurfaceFocus` on the head focus primitives

`interaction::FocusRing`/`FocusTarget`/`FocusOutcome` are no longer public (0062). Re-implement `SurfaceFocus<Content>`'s internals on the head's `FocusGraph<Id>` (`interaction/focus_graph.rs:203`) — or `InteractionScene` (`interaction/scene.rs:257`) if the two-node registration reads better through the scene — while keeping every public item listed in "Starting state" byte-identical in name, signature, and meaning:

- construction (`tab_bar`, `content`) → `FocusGraph::new()`, register both nodes, request the initial focus, reconcile
- `register()` → `begin_frame()` then `register(FocusNode::leaf(id, area))` per target (a zero `Rect` is acceptable where jackin has no area to attach; do not invent geometry that changes hit testing)
- `focused()` / `focused_content()` → `FocusGraph::focused()` mapped back to `SurfaceFocusTarget`, keeping the existing `unwrap_or(SurfaceFocusTarget::TabBar)` fallback
- `focus_tab_bar()` / `focus_content(content)` → `request_focus(..)`
- `is_tab_bar()` / `is_content(..)` / `show_cursor_for(..)` → `is_focused(..)` with the same mapping

Derived traits on the public types (`Debug`, `Clone`, `PartialEq`, `Eq`) must survive — downstream crates rely on them.

**Verify**:

- `cargo check -p jackin-tui --all-targets` → exit 0
- `cargo nextest run -p jackin-tui` → all pass, including `crates/jackin-tui/src/runtime/tests.rs` and 001's focus-restore parity tests, **unmodified**
- `git diff -- crates/jackin-tui/src/runtime/focus.rs | grep '^[-+]    pub fn\|^[-+]pub '` → no public signature changed

Commit: `refactor(jackin-tui): re-host SurfaceFocus on FocusGraph`. Push.

### Step 9: Re-host `ModalFlow` on `OverlayStack`

`interaction::ModalStack` is no longer public (0065). Re-implement `ModalFlow<Modal>`'s internals on `OverlayStack` (`interaction/overlay_stack.rs:755`), keeping every public item listed in "Starting state" identical:

- `open(modal)` → open a root overlay entry; clear parents
- `open_sub(modal)` → open a child entry (the head stack tracks depth itself; `entries()`/`top()` replace `stack.depth()`), pushing the previous `current` onto `parents`
- `pop()` → dismiss the top entry and restore the parent (`OverlayOutcome`'s `restored_focus` carries the focus to restore — preserve the pre-bump restore behavior exactly)
- `clear()` → `OverlayStack::clear()`; `current = None`, parents empty
- `current` / `current_mut` / `parents` / `parents_mut` / `is_open` / `has_parent` / `take_current` / `set_current` / `open_pair` unchanged

Per 0065, `push_modal_scope`/`pop_modal_scope` live on a crate-private ring and are not available to you — the overlay stack is the public authority. Keep the derived traits.

The Esc cascade is the behavior 001 pinned: `open_sub` preserves the parent, `pop` restores parent and focus scope, `clear` closes the chain, and the capsule's ExitDirty → ExitInspect walk-back keeps its "Esc is ignored" rule. If the head's `handle_escape()` outcome ordering would change any of that, keep jackin's product behavior — the parity tests are the contract.

**Verify**:

- `cargo check -p jackin-tui --all-targets` → exit 0
- `cargo nextest run -p jackin-tui` → all pass
- `cargo nextest run -p jackin-capsule -E 'test(/dialog::tests/)'` → the Esc-cascade tests (including 001's) pass unmodified; snapshot assertions in that module may fail (expected, plan 003)
- `git diff -- crates/jackin-tui/src/runtime/modal_flow.rs | grep '^[-+]    pub'` → no public signature changed

Commit: `refactor(jackin-tui): re-host ModalFlow on OverlayStack`. Push.

### Step 10: Re-host launch diff scrolling on the head accessor surface (12 planned errors)

`DiffViewState.offset` is now a read-only getter (`widgets/diff.rs:606`) with no public setter; scrolling is owned by the widget's `ScrollAreaState` (`:612`, doc 0085 + 0196). Work on the unit plan 001 extracted from the launch run loop — re-read it first; it is your seam and its tests are your contract.

Move the offset ownership from "assign `state.offset`" to the head's scroll surface: keep jackin's own `diff_scroll_y` as the product's scroll position if that is what the extracted unit models, and drive the widget through the supported path (`ScrollAreaState`, the widget's scroll intents/keys) instead of writing the removed field. Clamp behavior at the ends and the visible-line window must match pre-bump exactly — 001's diff-scroll parity test asserts the visible window.

**Verify**:

- `cargo check -p jackin-launch --all-targets` → exit 0
- `cargo nextest run -p jackin-launch` → all pass, including 001's diff-scroll parity tests **unmodified**
- `grep -rn '\.offset = ' crates/jackin-launch/src/tui/ --include='*.rs'` → no assignment to a termrock diff state's offset remains

Commit: `refactor(launch): re-host diff scrolling on DiffViewState accessors`. Push.

### Step 11: Close the compile and lint gates

Run the workspace gates and fix the residue (import hygiene, `unused_qualifications`, formatting). Do not silence a finding with a blanket `allow`; the repo requires narrow `#[expect(..., reason = "...")]` when a suppression is genuinely right.

**Verify**:

- `cargo check --workspace --all-targets --locked` → exit 0, zero errors
- `cargo fmt --check` → exit 0
- `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` → exit 0
- `cargo deny check advisories bans licenses sources` → exit 0 (re-confirm after all edits)

If step 11 needed edits beyond the class commits, commit `style(tui): satisfy lint gate after the termrock head migration` and push.

### Step 12: Run the suite and enumerate the expected failures

Run `cargo nextest run --workspace --all-features --locked`, capturing the output to a scratch file outside the repository.

Every failure must be an insta snapshot assertion in one of exactly these three modules. Mechanical check: capture nextest's `FAIL` lines; every failing test's module path (the part before the final `::test_name`) must start with `jackin_console::tui::view::tests`, `jackin_capsule::tui::components::dialog::tests`, or `jackin_capsule::tui::components::branch_context_bar::tests`, and re-running one such failure with `--no-capture` must print an insta snapshot mismatch (not an ordinary assert). Any failure outside those prefixes is a STOP. The three modules:

- `crates/jackin-capsule/src/tui/components/dialog/tests.rs`
- `crates/jackin-capsule/src/tui/components/branch_context_bar/tests.rs`
- `crates/jackin-console/src/tui/view/tests.rs`

Enumerate the failing tests by name in your report — that list is plan 003's re-baseline worklist. Any failure outside those three modules, or any failure inside them that is not an insta snapshot assertion (those modules also carry geometry and behavior assertions), is a STOP: it means behavior changed, not just paint.

Also re-run plan 001's full parity command form (`cargo nextest run --workspace --all-features --locked -E '<PARITY_FILTER>'`) and confirm the parity tests pass with **no** modification to their assertions: `git diff "$START_SHA"..HEAD -- <001's parity test files>` (base = this plan's own start, so 001's commits are excluded) shows either no change or only renamed upstream symbol references.

**Verify**: the failure list is non-empty only within the three modules and only for snapshot assertions; `<PARITY_FILTER>` → all pass.

## Test plan

This plan adds **no** new tests — plan 001 owns the parity tests and plan 003 owns the snapshots. Its witnesses are the tests that already exist:

- **Parity scenarios** (`Parity tests green across the bump`): 001's Esc-cascade, focus-restore, and diff-scroll tests run unmodified after steps 8-10. Their expected values come from behavior recorded at the OLD pin — an independent source of truth relative to the head code you are writing.
- **Flow-preservation scenario** (`Existing non-snapshot tests as journey witnesses`): every pre-existing non-snapshot test across the six crates passes; the only permitted diff in a test file is a renamed upstream symbol. Prove it: `git diff "$START_SHA"..HEAD -- 'crates/*/src/**/tests.rs' 'crates/*/tests/*.rs'` contains no changed assertion, only symbol references.
- **Screen-set scenario** (`Dialog census unchanged`): `ConsoleModal` at `crates/jackin-console/src/tui/model/modal.rs:24-114` and capsule `Dialog` at `crates/jackin-capsule/src/tui/components/dialog.rs:147-287` carry the same variant sets before and after. Prove it: `git diff "$START_SHA"..HEAD -- crates/jackin-console/src/tui/model/modal.rs crates/jackin-capsule/src/tui/components/dialog.rs` shows no added or removed enum variant.
- **Compile scenario**: `cargo check --workspace --all-targets --locked` exit 0.
- **Supply-chain scenarios**: `cargo deny check bans` exit 0; `git diff deny.toml` shows exactly two added skip lines and no license/source change.
- **Suite scenario**: `cargo nextest run --workspace --all-features --locked` fails only on insta snapshot assertions in the three named modules.

**Verify**: `cargo nextest run --workspace --all-features --locked` → failures confined as above; `cargo nextest run -E '<PARITY_FILTER>'` → all pass.

## Done criteria

Machine-checkable. ALL must hold, each confirmed against command output from this session:

- [ ] `grep -n 'rev = "e1d61f4d67ea6f0f3adee578caa2c5dba642217e"' Cargo.toml` prints line 118, and that line still carries `version = "=0.11.0"` and `features = ["crossterm", "serde"]`
- [ ] `Cargo.lock`'s termrock package source names `rev=e1d61f4d67ea6f0f3adee578caa2c5dba642217e`
- [ ] `cargo deny check advisories bans licenses sources` exits 0
- [ ] `git diff "$START_SHA"..HEAD -- deny.toml | grep '^+[^+]'` shows exactly two added lines, both `bans.skip` entries (`base64@0.22.1`, `syn@2.0.119`), and no license/source change
- [ ] `cargo check --workspace --all-targets --locked` exits 0
- [ ] `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` exits 0
- [ ] `cargo fmt --check` exits 0
- [ ] `cargo nextest run --workspace --all-features --locked` fails ONLY on insta snapshot assertions in `crates/jackin-capsule/src/tui/components/dialog/tests.rs`, `crates/jackin-capsule/src/tui/components/branch_context_bar/tests.rs`, `crates/jackin-console/src/tui/view/tests.rs`, with the failing test names enumerated in the report
- [ ] `cargo nextest run -E '<PARITY_FILTER>'` passes with 001's parity test assertions unmodified
- [ ] `grep -rn 'termrock::Theme\|PanelEmphasis\|classify_click\|ModalClickResult' crates/ --include='*.rs'` returns no hits outside `crates/jackin-xtask/src/arch/tests.rs` (arch-gate string fixture)
- [ ] No alias, `type` alias, `use … as <old name>`, or shim module preserving a removed TermRock name exists in the diff (N2)
- [ ] The public items of `SurfaceFocus`, `SurfaceFocusTarget`, and `ModalFlow` are unchanged in name and signature (`git diff "$START_SHA"..HEAD --` on the two runtime files: every `-pub` line has a matching `+pub` line with identical name and signature)
- [ ] `ConsoleModal` and capsule `Dialog` variant sets unchanged (`git diff "$START_SHA"..HEAD --` on the two enum files: no added/removed variant lines)
- [ ] The fresh error census and its delta from the planned 384/305 figures are stamped in the report
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status rows and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails, or "Starting state" does not match reality.
- **The first `cargo check` after the pin flip reveals break CLASSES not in the break table** — assumption A2 is falsified in kind (counts drifting is fine; a new kind is not). Report the unlisted class, its error code, and a representative `file:line`.
- **`cargo deny check bans` reports duplicates beyond the two planned skips** — assumption A3 falsified. Report every duplicate pair; do NOT add a third skip.
- **The rev is unfetchable** — assumption A1 falsified (`cargo fetch` cannot resolve `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`).
- **001's parity tests cannot pass unmodified** after the re-host — the forced redesign broke behavioral parity. Report which parity test fails and the observed vs expected behavior; do NOT edit the parity test to match the new behavior.
- The suite's failures are not confined to insta snapshot assertions in the three named modules.
- A step's verification fails twice after a reasonable fix attempt.
- The work requires touching an out-of-scope file (a `.snap`, a docs page, `AGENTS.md`) or violating a Must NOT — in particular, if a break cannot be migrated without introducing an alias/shim (N2) or without changing a brand composition's visual identity (N1).
- A required input is missing with no replacement contract (e.g. no TermRock checkout **and** no registry-cache fallback).

## Maintenance notes

- **Plan 003 depends on this plan's failure list.** The enumerated snapshot failures are its re-baseline worklist; the background-variant pick (`DesignSystem::terminal_native()` vs the obsidian surface ladder from 0261) and brand color compensation both assume the palette endpoint you chose in step 4 — state that endpoint explicitly in your report.
- **Plan 004 depends on the API names you landed.** The three TUI docs pages pinning dead names and the `hint.rs:25` `chord_glyph` mirror check are its work; do not fix them here.
- **What a reviewer should scrutinize**: the three re-hosts (steps 8-10) — everything else is mechanical. Specifically: whether `ModalFlow::pop` restores the same focus scope the pre-bump `FocusRing::pop_modal` did; whether the diff-scroll clamp still matches at both ends; whether the outside-click predicates are semantically identical to old-pin `classify_click`. Also: exactly two deny skips, and no operator-visible change anywhere.
- **Deferred on purpose**: every optional head adoption (`ModalSpec`, `KeyValueTable`, `Kbd`/`ShortcutHint`, `DetailTable::measure`, `panel_stack`) — they belong to the per-surface modernization phases, which the roadmap item gates behind each surface's finalization. Behavioral head sweeps that need no consumer edit (0288 selection chrome, 0291 scrollbar language, 0327-0330 tabs/choice-dialog paint) land visually with this bump and are absorbed by plan 003's re-baseline, not by code here.
