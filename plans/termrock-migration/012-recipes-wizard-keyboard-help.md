# Plan 012: Whole-screen recipes, create-prelude wizard on FormWizard, keyboard_help overlay

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/010-*.md, plans/011-*.md (plus the plans/005 PNG baseline harness)
- **Covers**: F5 (whole-screen recipes + form_wizard rows), F9, S2, N4, D24
- **Guardrails**: N2, N4 (inlined below)
- **Research basis**: research/termrock-head-adoption/04-component-adoption-candidates.md, research/jackin-verification-tooling/01-gates-and-commands.md
- **Planned at**: commit `f320b51f`, 2026-08-19

## Why this matters

Three console screens (workspaces, settings, auth forms) get re-expressed on the upstream whole-screen composition recipes so later surface phases copy one settled pattern; the create-prelude wizard's hand-rolled boolean-priority step resolver is replaced by the upstream `form_wizard` state machinery (`WizardGate`/`WizardPhase`/`WizardProgress`) with provably identical sequencing; and the console gains the item's single sanctioned new overlay — `keyboard_help` on `?` from every stage, whose content is generated from live keymap data so it can never drift from the actual bindings. After this lands, every console screen follows an upstream composition reference, the wizard has one sequencing authority, and operators can discover the full keymap from any stage. Parity law stands throughout: nothing about the current look or interaction changes except the sanctioned `? help` footer hint, which lands in one named, operator-reviewed step.

## Preconditions — run before anything else

One observable check per dependency. Discovery greps name capabilities, not plan-010/011-internal file names: if a grep is empty, the dependency has not landed the capability this plan builds on — STOP.

- Plan 010 landed (wizard step bodies exist on the C7/C8 pairings): `rg -l "FilePickerState|file_picker" crates/jackin-console/src` returns at least one file, and `rg -l "SelectState|widgets::select|combobox" crates/jackin-console/src` returns at least one file. The file browser and the picker family the prelude modals use must already render through the adopted upstream widgets.
- Plan 011 landed (keymap bridge is the dispatch/hint source): `rg -l "keymap_bridge|dispatch_keymap_action|UiIntent" crates/jackin-console/src` returns at least one file, and the console keymap statics still carry `Visibility` metadata: `rg -c "Visibility::" crates/jackin-console/src/tui/keymap.rs` reports matches (planning-time snapshot: 112 matches in one file — re-derive; the fresh count is the authority, only zero is a failure).
- Plan 005 landed (PNG baseline harness green): `rg -l "compare_png_pixels|termrock_raster" crates/jackin-console` returns at least one file — that file is the baseline harness; run the verify command documented in its header/tests (planning-time expectation: a nextest-invokable baseline suite; the harness source is the authority) → exit 0. From the same file, note the bless mechanism (environment variable per the upstream `TERMROCK_BLESS_PNGS=1` pattern, `<TERMROCK_CHECKOUT>/mise.toml:80`) — it is needed in steps 6 and 7 and is never guessed.
- Toolchain/workspace green: `cargo check --workspace --all-targets --locked` → exit 0.
- Drift check: `git diff --stat f320b51f..HEAD -- crates/jackin-console crates/jackin/src/console` — plans 005–011 legitimately rewrite large parts of these trees, so the check is per-excerpt: re-locate every "Starting state" excerpt below **by symbol name** in the live tree and confirm the code still matches the quoted body (line numbers will have drifted; that is expected and not a mismatch). The load-bearing existence check: `rg -n "pub const fn create_prelude_modal_step" crates/jackin-console/src` returns exactly one hit (the boolean-priority resolver this plan replaces). A body mismatch, or the resolver missing/renamed, is a STOP.

## Spec contract

The requirements this plan implements, inlined **verbatim** from the spec — the executor does not read `spec/`:

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

### Requirement: Whole-screen recipes and the create wizard

The workspaces screen SHALL adopt the `patterns/project_launcher`/`session_picker` composition, the settings screen SHALL adopt `patterns/settings_screen`, and auth forms SHALL adopt `patterns/auth_entry` + `password_input` — all as copy-adapt recipes (composition reference, never a type dependency). The create-prelude wizard SHALL adopt the `form_wizard` widget (`WizardGate`/`WizardPhase`/`WizardProgress`) in place of the boolean-priority step resolver, each step body supplied by the C7/C8 pairings.

Covers: F5 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md (recipes + form_wizard rows)

#### Scenario: Wizard step resolution equivalent

- **GIVEN** the create-prelude wizard re-hosted on `form_wizard`
- **WHEN** the wizard is walked forward and backward with every combination of skippable steps
- **THEN** the step sequence, gating, and progress display match the pre-cutover boolean-priority resolver exactly

### Requirement: keyboard_help overlay

The console SHALL gain the upstream `keyboard_help` overlay — the item's single sanctioned new overlay — opened by `?` from every console stage; its content MUST be sourced from the adopted `keymap_bridge` data so it can never drift from the actual bindings; discoverability MUST come via the footer hints per RULES.md label law; the overlay MUST join the PNG baseline set. No other new operator-visible screen or overlay is added.

Covers: F9, S2, N4 · Evidence: roadmap item §Decisions (keyboard_help ruling, 2026-08-19)

#### Scenario: Help content cannot drift

- **GIVEN** a keybinding changed in the keymap
- **WHEN** the `?` overlay opens from any console stage
- **THEN** the displayed binding reflects the keymap_bridge data without a hand-maintained copy

#### Scenario: Reachable from every stage

- **WHEN** `?` is pressed on each of the six console stage views
- **THEN** the keyboard_help overlay opens, and Esc dismisses it back to the stage with focus restored

#### Scenario: No other new UI

- **WHEN** the console phase completes
- **THEN** keyboard_help is the only added operator-visible overlay; every other upstream new-UI candidate (e.g. `notification_center`, `command_palette`) is absent

### From spec/png-baselines.md — the enumeration mechanism the new baseline rides

#### Scenario: Inventory complete

- **WHEN** the baseline suite runs
- **THEN** every stage view and every one of the 19 `ConsoleModal` variants has a committed baseline PNG at its canonical size
- **AND** adding a baseline for a new screen variant requires no harness change (the harness enumerates the inventory)

### The named parity exception (D24) — resolution, decided here, binding

The parity rule above says any text-snapshot diff is a STOP-for-review and never a silent re-bless, and hub law reserves PNG re-blesses for plans 005 and 014. The `? help` footer hint is an *intended* visual addition — D24's discoverability ruling ("keyboard_help: PNG-baselined, `?` trigger all console stages, keymap_bridge-sourced content, footer-hint discovery") cannot be satisfied without changing stage footers. Resolution: the footer-hint text-snapshot diffs **and** the matching stage-view PNG baseline re-blesses land in **this** plan, inside exactly one named, isolated step (step 7) with its own operator-review checkpoint — the single sanctioned exception to the byte-identical rule. The checkpoint honors the STOP: diffs are generated, inspected (each must show exactly the `? help` addition and nothing else), and presented to the operator; re-blessing happens only after operator approval. The keyboard_help overlay's own PNG baseline is **additive** (a new baseline entry, not a re-bless) and lands in step 6. Every other text snapshot and PNG baseline stays byte-identical; any other diff, anywhere, remains a parity break STOP.

Done means these scenarios hold; the test plan below exercises them.

## Screen contract

The S2 screen contract, inlined verbatim — the executor does not read the item:

### Screen: keyboard_help overlay (S2)

Mockup: none in item — visual truth owned by the PNG baseline (spec/png-baselines.md) and upstream `keyboard_help` rendering; layout intent: modal overlay listing keybindings, opened by `?`.

- **Regions**: overlay frame (upstream keyboard_help chrome); binding rows grouped per the keymap_bridge data; footer hint advertising `?` lives on each stage's hint bar (not inside the overlay)
- **States**: open (over any console stage) | dismissed — the only two states; content is a pure function of keymap_bridge data (specified here; item draws neither)
- **Interactions**: `?` → opens (exercises "Reachable from every stage"); Esc → dismisses with focus restore; content source → exercises "Help content cannot drift"
- **Navigation**: arrives from any of the six console stage views via `?`; exits back to the originating stage via Esc

The visual truth check enforcing this screen is the zero-tolerance PNG baseline added in step 6 (rendered open over the workspaces-list stage at its canonical size), plus the dispatch/focus tests in the test plan.

## Must NOT

Guardrails inlined verbatim from the must-not registry, with reasons. These override anything a step seems to imply:

- **N2**: No compatibility facades or shims over renamed TermRock APIs — repo latest-only law; upstream directive 0061/0331.
- **N4**: No new operator-visible screens or overlays beyond keyboard_help; no journey changes — amended D14 — amendment scope is exactly one overlay.

N4 applied concretely here: `notification_center`, `command_palette`, `theme_picker`, `keybinding_recorder`, and every other upstream new-UI candidate stay out — including when a recipe composes them upstream (`patterns/settings_screen` "Integrates KeybindingRecorder and ThemePicker" — those integrations are NOT copy-adapted).

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — the TermRock source checkout, read-only. On this machine it lives at `/Users/donbeave/Projects/tailrocks/termrock`, pinned at rev `29a16b5b` (verify: `git -C <TERMROCK_CHECKOUT> rev-parse --short HEAD` prints `29a16b5b`). Needed by steps 1–6 (recipe and widget source reading).
  - If absent: use `<TERMROCK_CHECKOUT>` as the placeholder, proceed by cloning `https://github.com/tailrocks/termrock` at rev `29a16b5b` anywhere readable; swap later by re-pointing the variable. Do NOT block waiting. Never edit the checkout; a needed upstream change is the hub's TermRock-misfit route (BLOCKED with a recommendation), never a local patch.

## Starting state

The facts, inlined — re-locate each excerpt by symbol; line numbers are planning-time snapshots (commit `f320b51f`).

**Planning-time measurements carry the re-derivation rule.** Counts and line numbers below (19 modal variants, 6 snapshots, keymap static positions, upstream line cites) are planning-time snapshots: re-run the counting command, treat the fresh number as the authority, stamp it in the output, note the delta — never reproduce a drifted planning number.

### The boolean-priority step resolver (what this plan replaces)

`crates/jackin-console/src/tui/model/create_prelude.rs:106-126`:

```rust
pub const fn create_prelude_modal_step(
    file_browser_src: bool,
    mount_dst_choice: bool,
    text_input_dst: bool,
    workdir_pick: bool,
    text_input_name: bool,
) -> CreatePreludeModalStep {
    if file_browser_src {
        CreatePreludeModalStep::FileBrowserSrc
    } else if mount_dst_choice {
        CreatePreludeModalStep::MountDstChoice
    } else if text_input_dst {
        CreatePreludeModalStep::TextInputDst
    } else if workdir_pick {
        CreatePreludeModalStep::WorkdirPick
    } else if text_input_name {
        CreatePreludeModalStep::TextInputName
    } else {
        CreatePreludeModalStep::Other
    }
}
```

Its only call site is `Modal::create_prelude_step()` (`crates/jackin-console/src/tui/model/modal.rs:233-257`), which maps the open modal variant onto the five booleans; that is consumed only by `handle_prelude_modal` (`crates/jackin-console/src/tui/input/prelude.rs:52-216`), the actual wizard step machine. The `CreatePreludeModalStep` enum sits at `create_prelude.rs:62-70` (`FileBrowserSrc`, `MountDstChoice`, `TextInputDst`, `WorkdirPick`, `TextInputName`, `Other`). The resolver's existing pin is `crates/jackin-console/src/tui/model/tests.rs:1058-1084` (`create_prelude_modal_step_routes_modal_facts_by_precedence`).

The wizard's observable behavior (the parity target — each rule cited to its current code):

- Step sequence: `FileBrowserSrc → MountDstChoice → [TextInputDst only on the Edit branch] → WorkdirPick → TextInputName` (`input/prelude.rs:4-6` doc header; arms at :65, :101, :138, :159, :192).
- `MountDstChoice::SamePath` skips the destination text input and chains straight to `WorkdirPick` (`input/prelude.rs:108-116`); `MountDstChoice::Edit` opens `TextInputDst` pre-filled and sets `used_edit_dst = true` (`input/prelude.rs:117-127`).
- Rewind rules: Esc on `MountDstChoice` re-opens `FileBrowser` at the last browser cwd (`create_prelude.rs:20-22`, `input/prelude.rs:128-134`); Esc on `TextInputDst` re-opens `MountDstChoice` (`input/prelude.rs:152-155`); Esc on `WorkdirPick` rewinds to `TextInputDst` when `used_edit_dst`, else `MountDstChoice` (`create_prelude.rs:23-25`, `create_prelude_workdir_cancel_plan` at `create_prelude.rs:261-269`, `input/prelude.rs:165-189`); Esc on `TextInputName` re-opens `WorkdirPick` (`input/prelude.rs:205-209`); Esc on `FileBrowserSrc` (step 1) cancels the whole prelude (`input/prelude.rs:79-85`).
- No gating blocks advance: validation lives inside the step bodies; the resolver itself has no invalid/pending concept.
- No step-progress chrome exists today: the prelude footer is the static `"Create workspace — follow the prompts · Esc cancel"` (`crates/jackin-console/src/tui/components/footer_hints/workspace.rs:239-247`, with the `UNREGISTERABLE(create-prelude-no-keymap)` comment — the prelude has no dedicated keymap). Progress display equivalence therefore means: which step modal is visible, and no added stepper/nav chrome.
- Completion: `create_prelude_completion_status` (`create_prelude.rs:280-291`) — modal closed + `completed()` `Some` ⇒ `Complete` (transition to Editor), modal closed + `None` ⇒ `Cancelled` (reload to List); consumed at `input/dispatch.rs:350-383`.
- Domain step tracker `CreateStep` (`crates/jackin-console/src/tui/screens/editor/model.rs:514-520`: `PickFirstMountSrc`, `PickFirstMountDst`, `PickWorkdir`, `NameWorkspace`) lives on `ConsoleCreatePreludeState.step` (`create_prelude.rs:13`) and is advanced by `accept_mount_src`/`accept_mount_dst`/`accept_workdir` (`create_prelude.rs:315-342`). Its only non-test readers are the debug projection below and `create_prelude.rs` internals (verified by grep: consumers are `model/create_prelude.rs`, `state.rs:41` re-export, and tests).
- Debug projection: `create_prelude_stage_debug` (`create_prelude.rs:38-47`) formats `step` via `Debug` into `ConsoleStageDebug::CreatePrelude { step, .. }` (`debug.rs:98-101`), rendered as `create-prelude step={step} modal={...}` (`debug.rs:148-153`) and pinned with the literal `"PickFirstMountSrc"` at `model/tests.rs:873`. This output is `--debug` troubleshooting surface; it stays byte-identical.

The per-step outcome planners (`create_prelude_file_browser_plan`, `create_prelude_mount_dst_choice_plan`, `create_prelude_text_input_dst_plan`, `create_prelude_workdir_pick_plan`, `create_prelude_text_input_name_plan`, `create_prelude_key_plan` — `create_prelude.rs:173-277`) are **not** the resolver and stay.

### Upstream form_wizard (`<TERMROCK_CHECKOUT>/crates/termrock/src/widgets/form_wizard.rs`)

- `WizardGate` (:53) — `Valid`/`Invalid`/`Pending`; `allows_advance` (:76).
- `WizardPhase` (:89) — `Step`/`Review`/`Failed`.
- `WizardProgress` (:156) — serializable `{ step_index, phase, completed, skipped, failure_message }`; `WizardProgress::start()` (:172).
- `FormWizardState::with_steps` (:317), `with_review` (:367), `with_allow_skip` (:374), `with_linear` (:381); `step()` (:396), `phase()` (:408), `progress()` (:447).
- `next()` (:626): gate-blocked → `BlockedInvalid`/`BlockedPending`; on last step with review disabled → `SubmitRequested`; else advances. `skip()` (:704): marks the **current** optional step skipped and advances. `back()` (:670): from `Step` decrements the index unconditionally (:687-701) — it does **not** skip over skipped steps; recorded compensation below. `jump_to` (:738): backward jumps (`index <= self.index`) are allowed even under `linear` (:746-764 blocks only forward jumps past incomplete steps). `handle_key` (:795): bare Esc always yields `Cancelled` (:806-808).
- Steps are `WizardStep = StepItem` (:48) with `optional` flag; `FormWizard` widget chrome (`paint` :953, stepper :1085, nav row :1156) is **not** adopted — see step 5 (parity: the prelude's current modal-per-step chrome stays).

### Upstream keyboard_help (`<TERMROCK_CHECKOUT>/crates/termrock/src/widgets/keyboard_help.rs`)

- `help_entries_from_keymap` (:318): builds `Vec<HelpEntry>` from a live `Keymap<A>`; skips `Visibility::Internal` (:331-333); chord text always from the live binding (:339-343). `HelpEntry` (:221), `merge_help_entries` (:485).
- `KeyboardHelpState` (:585), `KeyboardHelpState::modal()` (:629); `handle_key` (:745): `?` opens from footer mode (:750-755), Esc closes the modal (:763-765); list navigation via `default_keyboard_help_intent` (:892). "host rebuilds each frame" — entries are per-frame data (:219 comment).
- Overlay plumbing: `place_keyboard_help` (:90), `open_keyboard_help_overlay` (:103, takes `opener_focus: Option<FocusId>`), `dismiss_keyboard_help_overlay` (:120); `KeyboardHelpSize::default()` = 64×18 (:66-73). Focus restore on Esc is upstream-proven: test `overlay_dismiss_restores_focus` (:1624-1641) — `stack.handle_escape()` ⇒ `Dismissed { focus: Some("editor"), .. }`.
- Paint: `KeyboardHelp::new(&entries, &system).title(..)` (:922-937); modal paint :1060.
- Content-purity precedent test: `remap_changes_chord_text` (:1483-1512) — remap a binding, regenerated entries show the new chord.

### Upstream recipes (copy-adapt — composition reference, never a type dependency)

Each recipe header carries the law, e.g. `<TERMROCK_CHECKOUT>/crates/termrock/src/patterns/project_launcher.rs:27-28`: "Copy-adapt: keep the widget composition and the focus routing; replace the domain types, the wording, and the effects with your own." (Same sentence in `session_picker.rs`, `settings_screen.rs`, `auth_entry.rs` headers.) jackin❯ code never `use`s `termrock::patterns::*` — it re-expresses the composition with jackin❯ domain types.

- `patterns/project_launcher.rs` — pane model + `focus_order()` (:98); list + detail/preview + actions composition for a launcher surface.
- `patterns/session_picker.rs` — selector composition (search + list + preview; cancel-safe confirm).
- `patterns/settings_screen.rs` — `SettingsRegion` + `focus_order()` (:83), `SettingsScreenState` (:191); category nav + form sections + dirty cues. Its header notes it "Integrates KeybindingRecorder and ThemePicker" — excluded per N4.
- `patterns/auth_entry.rs` — `AuthEntryState` (:213); credential field/error anatomy, composes `PasswordInput`.
- `widgets/password_input.rs` — `RevealPolicy` (:42), `ClipboardPolicy` (:70), `PasswordInputState` (:226); adopted for credential fields in plan 010 (C10 row), this plan aligns the surrounding form composition.

### Console keymaps, dispatch, and footers (keyboard_help attachment points)

- Keymap statics in `crates/jackin-console/src/tui/keymap.rs` (positions are planning-time): `EDITOR_GLOBAL_KEYMAP` (:41), `EDITOR_TAB_BAR_KEYMAP` (:92), `EDITOR_CONTENT_KEYMAP` (:206), `SETTINGS_TAB_BAR_KEYMAP` (:257), `SETTINGS_CONTENT_SHELL_KEYMAP` (:299), `SETTINGS_GENERAL_TAB_KEYMAP` (:378), `SETTINGS_ENV_TAB_KEYMAP` (:505), `SETTINGS_TRUST_TAB_KEYMAP` (:606), `SETTINGS_GLOBAL_MOUNTS_TAB_KEYMAP` (:792), `INLINE_PICKER_SHELL_KEYMAP` (:843), hint-only `Keymap<()>` statics (:861-938 incl. `AUTH_MANAGE_KEYMAP` :929, `AUTH_EDIT_SOURCE_KEYMAP` :938), `WORKSPACE_LIST_KEYMAP` (:1212), `PREVIEW_PANE_KEYMAP` (:1289). The module doc (:4-9) states the coupling: "`Keymap::dispatch(chord)` replaces plan-function calls in `input/*.rs`; `Keymap::hint_spans()` derives footer hints."
- Central key dispatcher: `handle_key` (`crates/jackin-console/src/tui/input/dispatch.rs:47`). Precedence: modals/pickers first via `console_input_dispatch_plan` (`model/stage.rs:197-237`, facts struct `ConsoleInputDispatchFacts` at `stage.rs:71-86` — twelve `*_open` booleans + `stage_route`, with a `clippy::struct_excessive_bools` expect whose reason text names the count); when no modal is open, `ConsoleInputDispatchPlan::Stage(route)` (`dispatch.rs:95-118`) routes to per-stage handlers for the six routes.
- The six stages: `ConsoleManagerStage` — `List`, `Editor`, `Settings`, `CreatePrelude`, `ConfirmDelete`, `ConfirmInstancePurge` (`model/stage.rs:12-26`); routes at `stage.rs:28-36`.
- Console-global key precedent (Ctrl+Q): pure planner `should_open_quit_confirm` (`run.rs:204-218`) consulted centrally at `crates/jackin/src/console/adapter/run.rs:746` before `handle_key`; Shift-tolerant modifier idiom at `run.rs:214` — `(key.modifiers - KeyModifiers::SHIFT).is_empty()`; keymap documents the interception (`keymap.rs:1201` comment); per-screen planners never see the key (`screens/workspaces/update.rs:370` comment). `?` differs from Ctrl+Q in one way that matters: it must NOT fire while any modal/picker owns input (a text input types `?`), so its consult point is **inside** the `Stage(route)` arm, not beside the quit check.
- `?` today: routed to a no-op — pinned at `crates/jackin-console/src/tui/screens/workspaces/update/tests.rs:611` (`workspace_list_key_plan(KeyCode::Char('?'), false)` ⇒ `WorkspaceListKeyPlan::Continue`).
- Footer assembly: `crates/jackin-console/src/tui/components/footer_hints/{common,editor,modals,settings,workspace}.rs`; stage footers built by `workspace_list_footer_items` (`workspace.rs:310`), `destructive_confirm_footer_items` (`workspace.rs:234`, shared by both confirm stages), `create_prelude_footer_items` (`workspace.rs:239`), `tab_bar_footer_items`/`content_footer_items` (`common.rs:15-60`), settings footers (`settings.rs`), editor footers (`editor.rs`). Footer render: `render_footer` (`view.rs:365-386`) over `termrock::widgets::wrapped_hint_lines`.
- RULES.md label law (inline, binding): "User-facing TUI labels (column headers, tab names, button text, footer hints, modal titles, status badges) use **full word**, not abbreviation." (RULES.md:29); footer form: "single line, separator-delimited: `↑↓ navigate · type filter · Enter <action> · Esc cancel` … Use plain words for action" (RULES.md:63); keybinding law: "TUI keybindings use plain letters, numbers, `Enter`, `Esc`, `Tab`, or arrows. Avoid `Ctrl`/`Alt`/`Cmd`/`Shift` modifiers" (RULES.md:42-44). **Resolution for `?`**: D24's "`?` trigger all console stages" is the item-level sanction and matches upstream keyboard_help's own open key (`keyboard_help.rs:750-755`); `?` is this surface's single sanctioned non-plain-letter binding. The hint label is the glyph `?` + the full word `help`.
- State: `ManagerState` (`crates/jackin-console/src/tui/state.rs:230`) holds the stage, `list_modal: Option<Modal>` (:238), inline pickers (:243-262); the concrete modal alias `Modal<'a> = ConsoleModal<...>` (:200-223) with 19 variants enumerated at `model/modal.rs:24-114` (re-derive the count). `CreatePreludeState<'a> = ConsoleCreatePreludeState<Modal<'a>>` (`state.rs:225`).
- Text snapshots (6, planning-time count — re-derive with `ls crates/jackin-console/src/tui/view/snapshots/`): `list_empty_80x24`, `settings_general_90x20`, `editor_general_90x20`, `editor_mounts_tab_90x20`, `editor_auth_tab_90x20`, `global_mounts_110x30`; asserted in `crates/jackin-console/src/tui/view/tests.rs` (:767, :796, :809, :839, :1445, :1459). All six render stage footers, so all six are in step 7's exception scope. Re-bless path (repo-documented at `view/tests.rs:559-568`): `INSTA_UPDATE=new cargo nextest run -p jackin-console -E 'test(view::tests)' --no-capture`.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Build | `cargo check --workspace --all-targets --locked` | exit 0 |
| Full test suite | `cargo nextest run --workspace --all-features --locked` | all pass |
| Console package tests | `cargo nextest run -p jackin-console --locked` | all pass |
| One module | `cargo nextest run -p jackin-console -E 'test(/prelude/)' --locked` | all pass |
| Snapshot lane (both TUI crates) | `cargo nextest run -p jackin-capsule -p jackin-console --locked` | all pass, no `.pending-snap` |
| Text snapshot re-bless (step 7 only, after operator approval) | `INSTA_UPDATE=new cargo nextest run -p jackin-console -E 'test(view::tests)' --no-capture` | snapshots regenerated |
| Clippy | `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` | exit 0 |
| Format | `cargo fmt --check` | exit 0 |
| Lint umbrella | `cargo xtask lint --strict` | exit 0 |
| Fast merge gate (plan end) | `cargo xtask ci --fast` | exit 0 |
| PNG baseline verify | the verify command documented in the 005 harness file discovered in preconditions | exit 0 |
| PNG bless (steps 6–7 only) | the harness's bless mechanism (env var per the upstream pattern) discovered in preconditions | baselines written, visible in `git status` |

(Proven by research/jackin-verification-tooling/01-gates-and-commands.md: build/tests/lint rows from `ci.rs:159-272`; package and module filter forms from TESTING.md:161,184 and :28-32; snapshot lane = `cargo nextest run -p jackin-capsule -p jackin-console --locked` from `ci.rs:258-272`; `INSTA_UPDATE=new` form repo-documented at `view/tests.rs:559-568`. PNG harness commands are plan-005-owned; discovered in preconditions, never invented.)

## Scope

**In scope** (the only files to create or modify):

- `crates/jackin-console/src/tui/model/create_prelude.rs` (+ its tests via `model/tests.rs`)
- `crates/jackin-console/src/tui/model/modal.rs` (delete `create_prelude_step`)
- `crates/jackin-console/src/tui/model/stage.rs` (one new dispatch fact + plan arm)
- `crates/jackin-console/src/tui/model/tests.rs`
- `crates/jackin-console/src/tui/input/prelude.rs` + `crates/jackin-console/src/tui/input/prelude/tests.rs`
- `crates/jackin-console/src/tui/input/dispatch.rs`
- `crates/jackin-console/src/tui/screens/editor/model.rs` (delete `CreateStep`)
- `crates/jackin-console/src/tui/state.rs` (keyboard_help state + wiring)
- `crates/jackin-console/src/tui/run.rs` + `crates/jackin-console/src/tui/run/tests.rs` (the `?` planner beside the quit planner)
- `crates/jackin-console/src/tui/keymap.rs` + `crates/jackin-console/src/tui/keymap/tests.rs` (console-global keymap)
- `crates/jackin-console/src/tui/components/keyboard_help.rs` + `crates/jackin-console/src/tui/components/keyboard_help/tests.rs` (new; entries builder, pure)
- `crates/jackin-console/src/tui/components/footer_hints/{common,editor,settings,workspace}.rs` (+ their test files where present)
- `crates/jackin-console/src/tui/screens/workspaces/**`, `crates/jackin-console/src/tui/screens/settings/**`, `crates/jackin-console/src/tui/screens/editor/**`, `crates/jackin-console/src/tui/components/auth_panel.rs` (recipe composition passes; view/update/model files only as the composition demands)
- `crates/jackin-console/src/tui/view.rs`, `crates/jackin-console/src/tui/view/tests.rs`, `crates/jackin-console/src/tui/view/snapshots/*.snap` (step 7 exception only)
- `crates/jackin-console/src/tui/debug.rs` (only if the step-projection mapping needs it — prefer keeping it untouched)
- `crates/jackin-console/src/tui/screens/workspaces/update/tests.rs` (the `?` pin at :611)
- `crates/jackin/src/console/adapter/run.rs` (only if overlay open/dismiss wiring requires an adapter touch beside the quit consult)
- The plan-005 PNG baseline harness file(s) (additive: one inventory entry + one new baseline PNG in step 6; stage-view re-blesses in step 7 only after the checkpoint)
- `crates/jackin-console/README.md` (structure table gains the new `components/keyboard_help.rs` module — same-PR crate README law)

**Out of scope** (do NOT touch, even though related):

- `<TERMROCK_CHECKOUT>` — read-only; API misfits take the hub's TermRock-misfit route.
- `docs/content/reference/tui/**` — docs alignment is plan 014's territory; note drift in the plan's status, do not edit.
- `crates/jackin-capsule/**`, `crates/jackin-launch/**`, `crates/jackin-tui/**`, `crates/jackin-oppicker/**` (plan 013 owns the op-picker), other plans' cutover territories (008–011 machinery: do not re-do or "improve" their adoptions).
- `deny.toml`, `Cargo.lock`, root `Cargo.toml` — no dependency changes in this plan.
- Upstream new-UI widgets beyond keyboard_help (`notification_center`, `command_palette`, `keybinding_recorder`, `theme_picker`, …) — N4.
- The `FormWizard` widget's visual chrome (stepper/nav paint) — adopting it would be a visual change; the parity invariant forbids it.

The hub `plans/termrock-migration/README.md` and the roadmap item are protocol-writable and never listed in scope.

## Git workflow

Commit boundaries for this plan (each pushed immediately per hub law; every commit leaves the tree green — the exception step is deliberately a single commit so no commit carries an unblessed snapshot diff):

1. `refactor(console): align workspaces screen with upstream launcher recipe composition`
2. `refactor(console): align settings screen with upstream settings recipe composition`
3. `refactor(console): align auth forms with auth_entry + password_input composition`
4. `test(console): pin create-prelude wizard step-walk golden sequences`
5. `refactor(console): re-host create-prelude wizard on FormWizard state`
6. `feat(console): keyboard_help overlay on ? from every console stage`
7. `feat(console): advertise ? help in stage footers and re-bless baselines (D24 exception)`

## Steps

### Step 1: Workspaces screen — copy-adapt the launcher recipe composition

Re-express the workspaces screen (`crates/jackin-console/src/tui/screens/workspaces.rs`, `screens/workspaces/view.rs`, `view/list.rs`, `view/footer.rs`) on the `patterns/project_launcher.rs` + `patterns/session_picker.rs` composition: map the screen onto the recipe's regions — sidebar workspace/instance list (recipe: master list pane), the detail/preview pane (recipe: preview region), the inline pickers (recipe: popover selectors), the footer action hints (recipe: action bar) — and align the focus routing with the recipe's `focus_order()` pattern (`project_launcher.rs:98`): an explicit ordered pane list the focus cycle walks. Concrete target shape: a module-level composition comment in `screens/workspaces/view.rs` naming the recipe and the region mapping, and the focus-owner chain expressed as one ordered sequence mirroring `focus_order()`. Replace nothing visual; move no domain logic across crate boundaries; introduce no `termrock::patterns` import (copy-adapt law).

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass; `cargo nextest run -p jackin-capsule -p jackin-console --locked` → all pass with zero snapshot diffs; PNG harness verify → exit 0 (zero pixel diffs).

### Step 2: Settings screen — copy-adapt the settings recipe composition

Same pass for `screens/settings/{model,update,view}.rs`: map the five `SettingsTab`s (`screens/settings/model.rs:48-55`: General, Mounts, Environments, Auth, Trust) onto the recipe's category/section model (`SettingsRegion` + `focus_order()` at `settings_screen.rs:83`, `SettingsScreenState` at :191): tab bar = category nav, tab bodies = form sections (already on plan 010's `form`/`field_row`/`key_value_table`), dirty cue = recipe's modified-field cue (already present — do not restyle). Add the composition comment naming `patterns/settings_screen.rs` and the region mapping; express the focus cycle as one ordered region sequence. Do NOT copy-adapt the recipe's KeybindingRecorder/ThemePicker integrations (N4).

**Verify**: same three commands as step 1 → all green, zero diffs.

### Step 3: Auth forms — copy-adapt auth_entry + password_input composition

Same pass for the auth form surfaces (`components/auth_panel.rs` — `CredentialInput` at :51, `AuthFormKeyPlan`/`auth_form_key_plan` at :58-104 — plus the `ConsoleModal::AuthForm` render path in the editor and settings auth tabs): align the field/error anatomy with `patterns/auth_entry.rs` (`AuthEntryState` :213): labeled credential field with validation feedback, mode switch, submit/cancel — with the secret field on plan 010's `password_input` adoption (`RevealPolicy` :42, `ClipboardPolicy` :70). Composition comment naming the recipe. The jackin❯ auth domain spans op-refs, literals, source folders, and generated tokens (research ch04 auth row) — the recipe covers field anatomy only; all domain branches stay.

**Verify**: same three commands as step 1 → all green, zero diffs.

### Step 4: Pin the wizard step-walk golden sequences (before touching the resolver)

Add golden characterization tests to `crates/jackin-console/src/tui/input/prelude/tests.rs` driving `handle_prelude_modal` (and the state methods it calls) through every walk below, asserting the **observable step sequence** (which `CreatePreludeModalStep` is active after each key, via the existing `Modal::create_prelude_step()`), the pending-field accumulation, and the final `create_prelude_completion_status`. Expected values are hand-written literals derived from the cited current arms (Starting state), never recomputed through the code under test. Walks (every skippable-step combination — the only optional step is `TextInputDst`, gated by the `MountDstChoice` branch):

1. Same-path forward: FileBrowser commit → MountDstChoice `SamePath` → WorkdirPick commit → TextInputName commit ⇒ `Complete`.
2. Edit-dst forward: FileBrowser commit → MountDstChoice `Edit` → TextInputDst commit → WorkdirPick commit → TextInputName commit ⇒ `Complete`.
3. Same-path full rewind: walk 1 to `TextInputName`, then Esc at each step ⇒ TextInputName→WorkdirPick→MountDstChoice→FileBrowser (at last cwd) → Esc ⇒ `Cancelled`.
4. Edit-dst full rewind: walk 2 to `TextInputName`, then Esc at each ⇒ TextInputName→WorkdirPick→**TextInputDst** (used_edit_dst rule)→MountDstChoice→FileBrowser→Esc ⇒ `Cancelled`.
5. Direction-change walks: forward 2 steps, back 1, forward again (both branches) ⇒ sequence and pending fields identical to the uninterrupted walks.
6. Esc at `FileBrowserSrc` immediately ⇒ `Cancelled`.

**Verify**: `cargo nextest run -p jackin-console -E 'test(/prelude/)' --locked` → all pass, including the new golden tests.

### Step 5: Re-host the wizard on FormWizardState

Replace the sequencing authority; keep every step body and modal chrome:

- In `ConsoleCreatePreludeState` (`model/create_prelude.rs`): replace `pub step: CreateStep` with `pub wizard: termrock::widgets::FormWizardState`, built as `FormWizardState::with_steps([...]).with_review(false).with_allow_skip(true).with_linear(true)` with steps `mount-src`, `mount-dst-choice`, `mount-dst-edit` (`.optional(true)`), `workdir`, `name`. Gates stay `WizardGate::Valid` throughout (the resolver has no gating — gate equivalence is the all-Valid invariant); `WizardPhase` stays `Step` (no review screen today); `WizardProgress` is the test-observable navigation snapshot.
- Advance mapping (in `handle_prelude_modal`, `input/prelude.rs`): FileBrowser commit ⇒ `wizard.next()`; MountDstChoice `SamePath` ⇒ `next()` then `skip()` (lands on `workdir` with `mount-dst-edit` marked skipped — `skip()` only marks the *current* step, form_wizard.rs:704-736, so the two-call sequence is required); MountDstChoice `Edit` ⇒ `next()`; TextInputDst / WorkdirPick / TextInputName commit ⇒ `next()` (the last yields `SubmitRequested` — map to the existing completion path, `input/dispatch.rs:350-383`, unchanged).
- Rewind mapping: MountDstChoice Esc ⇒ `back()`; TextInputDst Esc ⇒ `back()`; WorkdirPick Esc ⇒ `jump_to(2)` when `used_edit_dst` else `jump_to(1)` — **recorded consumer compensation**: upstream `back()` decrements unconditionally and would land on the skipped `mount-dst-edit` (form_wizard.rs:687-701); backward `jump_to` is permitted under `linear` (:746-764), so consumer configuration suffices — no upstream change needed. TextInputName Esc ⇒ `back()`. FileBrowser Esc ⇒ `wizard.cancel()` ⇒ the existing cancelled path. The per-step outcome planners and modal open/close mechanics stay exactly as they are; the wizard state and `prelude.modal` must agree on the active step — assert the agreement in a `debug_assert!` at the top of `handle_prelude_modal`.
- Delete (N2, latest-only — no shim): `create_prelude_modal_step` (`create_prelude.rs:106-126`, with its `#[expect(clippy::fn_params_excessive_bools)]` block at :97-104), `CreatePreludeModalStep` (:62-70), `Modal::create_prelude_step` (`model/modal.rs:233-257`), the `CreatePreludeFileBrowserTarget`/`CreatePreludeTextInputTarget` traits if they become dead (:72-95), `CreateStep` (`screens/editor/model.rs:514-520`) and its `state.rs:41` re-export, and the precedence pin `model/tests.rs:1058-1084`. The step-active dispatch in `handle_prelude_modal` switches from matching `CreatePreludeModalStep` to matching `wizard.step()` index.
- Debug output byte-identical: `create_prelude_stage_debug` (`create_prelude.rs:38-47`) maps the wizard step index back to the legacy strings — `mount-src` ⇒ `"PickFirstMountSrc"`, `mount-dst-choice`/`mount-dst-edit` ⇒ `"PickFirstMountDst"`, `workdir` ⇒ `"PickWorkdir"`, `name` ⇒ `"NameWorkspace"` — so `debug.rs` and the pin at `model/tests.rs:873` hold unchanged.
- Extend the step-4 golden tests: re-point the observation from `create_prelude_step()` to `wizard.step()`/`wizard.progress()`; the literal sequences, completion statuses, and rewind targets are unchanged. Add one equivalence assertion per walk comparing `WizardProgress { step_index, phase, completed, skipped }` at each walk position to hand-written literals (walk 1 after SamePath: `skipped == ["mount-dst-edit"]`; walk 2: `skipped` empty, all prior `completed`).
- Update `crates/jackin-console/README.md` if the module table changes.

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass including the re-pointed golden walks; `cargo nextest run -p jackin-capsule -p jackin-console --locked` → zero snapshot diffs; PNG harness verify → exit 0; `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` → exit 0.

### Step 6: keyboard_help overlay — state, dispatch, render, PNG baseline

- Global keymap: in `tui/keymap.rs` add `ConsoleGlobalAction::OpenKeyboardHelp` and `CONSOLE_GLOBAL_KEYMAP` with one binding: `KeyChord::plain(KeyCode::Char('?'))`, hint `"help"`, `Visibility::Shown`, glyph `"?"`. Document beside it (mirroring the `keymap.rs:1201` Ctrl+Q comment) that `?` is intercepted centrally before per-screen planners.
- Pure planner: in `tui/run.rs` beside `should_open_quit_confirm` add `should_open_keyboard_help(key: KeyEvent) -> bool` — `KeyCode::Char('?')` with `(key.modifiers - KeyModifiers::SHIFT).is_empty()` (the run.rs:214 idiom). No state argument: the consult point guarantees no modal owns input.
- Dispatch: add `keyboard_help_open: bool` to `ConsoleInputDispatchFacts` (`model/stage.rs:71-86` — bump the expect reason text from twelve to thirteen flags) and a `ConsoleInputDispatchPlan::KeyboardHelp` arm at the **top** of `console_input_dispatch_plan`'s precedence (before `list_modal_open`: while help is open it owns keys). In `handle_key` (`input/dispatch.rs:47`): in the new arm, route the key to the help state (`KeyboardHelpState::handle_key`); in the `Stage(route)` arm, consult `should_open_keyboard_help` first — on hit, open the overlay (below) and return `InputOutcome::Continue` without routing to the stage handler.
- State: hang `KeyboardHelpState` (modal mode) plus the opener-record on `ManagerState` (`state.rs:230`). Open = open on the console's post-009 `OverlayStack` via `open_keyboard_help_overlay` (keyboard_help.rs:103) passing the current focus id from the plan-008 focus machinery as `opener_focus`; dismiss = Esc inside `handle_key` ⇒ `Closed` ⇒ dismiss on the stack — focus restore is the stack's `Dismissed { focus }` outcome (upstream-proven, keyboard_help.rs:1624-1641). If 008/009 landed a canonical overlay-state home, use it instead of a bare field; the discovery is part of the step.
- Content (pure function of keymap data): new module `crates/jackin-console/src/tui/components/keyboard_help.rs` with `pub fn help_entries_for_stage(route: ConsoleManagerStageRoute, .../* the stage's active keymap statics */, system: &DesignSystem) -> Vec<HelpEntry>`: per stage, `help_entries_from_keymap` (keyboard_help.rs:318) over the keymaps that feed that stage's footer today — List: `WORKSPACE_LIST_KEYMAP` + `PREVIEW_PANE_KEYMAP`; Editor: `EDITOR_GLOBAL_KEYMAP` + `EDITOR_TAB_BAR_KEYMAP` + `EDITOR_CONTENT_KEYMAP`; Settings: `SETTINGS_TAB_BAR_KEYMAP` + `SETTINGS_CONTENT_SHELL_KEYMAP` + the active tab's keymap; CreatePrelude / ConfirmDelete / ConfirmInstancePurge: no stage keymap (the prelude's is explicitly absent — `UNREGISTERABLE(create-prelude-no-keymap)`) ⇒ global entries only — plus `CONSOLE_GLOBAL_KEYMAP` on every stage, merged with `merge_help_entries` (:485). The `describe` closure reuses each binding's own hint text (never a hand-maintained copy) and assigns categories per keymap group (e.g. `Workspace list`, `Editor`, `Settings`, `Global`). Entries are rebuilt every frame (upstream law, keyboard_help.rs:219).
- Render: in the console's overlay render path (post-009 machinery), when the help overlay is open, place it with `place_keyboard_help` (`KeyboardHelpSize::default()`, 64×18, keyboard_help.rs:66-100) over the stage and paint `KeyboardHelp::new(&entries, &system).title("Keyboard shortcuts")` in modal mode. Keyboard-only interaction (arrow/j-k/Home/End navigation and the filter input come free in `handle_key`); mouse hit/scroll wiring is deferred — record it in `TODO.md` per the repo's `TODO(<topic>)` convention.
- PNG baseline (additive): add the keyboard_help overlay to the 005 harness's inventory enumeration (the mechanism whose contract is inlined above: "adding a baseline for a new screen variant requires no harness change") — rendered open over the workspaces-list stage at the canonical list size; bless via the discovered bless mechanism; confirm the new PNG appears in `git status` and the REUSE annotation convention of the existing baselines is followed (copy an existing baseline's annotation sidecar).
- Update the `?` pin at `screens/workspaces/update/tests.rs:611`: keep the pure-planner assertion (`workspace_list_key_plan` still returns `Continue` for `?` — it never sees the key) and add a dispatch-level test proving interception (below).

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass; `cargo nextest run -p jackin-capsule -p jackin-console --locked` → **zero** snapshot diffs (footers untouched in this step); PNG harness verify → exit 0 with the new baseline present; `rg -n "notification_center|command_palette|keybinding_recorder|theme_picker" crates/jackin-console/src` → no new hits (N4 guard).

### Step 7 (NAMED EXCEPTION — operator-review checkpoint): footer `? help` on every stage + baseline re-blesses

This is the single sanctioned exception to the byte-identical rule (resolution in Spec contract). Sequence matters — do not re-bless before the checkpoint:

1. Add a shared `append_keyboard_help_hint` helper in `components/footer_hints/common.rs` emitting the `CONSOLE_GLOBAL_KEYMAP`-derived `?` glyph span + `HintSpan::Text("help")` (separator-delimited, full word — RULES.md:29,63), and call it from every stage footer builder: `workspace_list_footer_items`, editor footers (`tab_bar_footer_items`/`content_footer_items`), settings footers, `create_prelude_footer_items`, `destructive_confirm_footer_items` (covers both confirm stages).
2. Run `cargo nextest run -p jackin-capsule -p jackin-console --locked`. Expect insta failures on exactly the six stage snapshots. For each, inspect the pending diff: it MUST show exactly the added `? help` hint and nothing else. Run the PNG harness verify: expect failures on exactly the baselined stage views, each diff confined to the footer rows.
3. **CHECKPOINT — STOP for operator review.** Present: the list of changed snapshots, one representative text diff, the list of affected PNG baselines. This is the parity rule's operator-review STOP, honored; approval of exactly this diff set is the sanction. If the operator rejects or asks for changes, do not re-bless: revert the hint edits, set the row per the hub's STOP protocol, and stop.
4. Only after approval: re-bless text snapshots with `INSTA_UPDATE=new cargo nextest run -p jackin-console -E 'test(view::tests)' --no-capture`, confirm `find crates -name '*.pending-snap'` is empty, and review the `.snap` diff once more (only the hint). Re-bless the affected stage PNG baselines via the discovered bless mechanism. Update any footer-hint unit expectations (footer_hints tests, `keymap/tests.rs` hint-pipeline assertions) in the same commit.
5. Commit as the single isolated commit 7 above — the diff contains only: footer hint code, the six `.snap` files, the affected PNG baselines, and footer/hint unit-test expectations. Nothing else.

**Verify**: `cargo nextest run -p jackin-capsule -p jackin-console --locked` → all pass; PNG harness verify → exit 0; `git show --stat HEAD` → only the named file groups.

## Test plan

New tests, all in the crate's existing test files per the one-test-surface rule:

- **Wizard step resolution equivalent** (spec scenario): the step-4 golden walks 1–6, re-pointed at `wizard.step()`/`wizard.progress()` in step 5 — forward and backward through every skippable-step combination (same-path vs edit-dst × forward, full rewind, direction-change), asserting step sequence, gating (all-`Valid`, no `Blocked*` outcome ever occurs), and progress (`WizardProgress` literals) exactly. Independent source of truth: hand-written literals derived from the pre-cutover arms cited in Starting state.
- **Help content cannot drift** (spec scenario): in `components/keyboard_help/tests.rs` — build a `Keymap` with a binding, generate entries, remap the binding's chord, regenerate: the entry chord changes (structural twin of upstream `remap_changes_chord_text`, keyboard_help.rs:1483-1512); and an assertion that no entry carries a chord absent from the source keymap (twin of upstream `generators_use_live_bindings_only`, :1709-1732). Also: `help_entries_for_stage` output for every one of the six routes is non-empty and every entry's `source` is `HelpEntrySource::Keymap`.
- **Reachable from every stage** (spec scenario): for each of the six `ConsoleManagerStageRoute`s, with no modal open, `handle_key` on a `?` press yields the help-open state (dispatch plan = `KeyboardHelp` on the next key); Esc yields `Closed` and the recorded opener focus is what the stack restores. Plus the Shift-tolerance table (modifiers `NONE` and `SHIFT` both open; `CTRL` does not — mirrors `run/tests.rs:134-147` for the quit planner).
- **Modal ownership**: with a text-input modal open, `?` reaches the modal (typed), not the help overlay — the dispatch precedence test pins `KeyboardHelp` below "no modal open" construction (plan arm only reachable via `Stage`).
- **No other new UI** (spec scenario): grep guard in done criteria; no test.
- **Footer discovery**: each stage footer builder's items contain the `?` glyph span and the `help` label (step 7).
- Structural model: existing planner tests in `model/tests.rs`, `input/prelude/tests.rs`, `run/tests.rs`, `keymap/tests.rs`.

**Verify**: `cargo nextest run -p jackin-console --locked` → all pass, including the new tests.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `cargo check --workspace --all-targets --locked` exits 0
- [ ] `cargo nextest run --workspace --all-features --locked` exits 0; tests for every spec scenario exist and pass
- [ ] `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` and `cargo fmt --check` exit 0
- [ ] `rg -n "create_prelude_modal_step|CreatePreludeModalStep|CreateStep" crates/jackin-console/src` returns no hits (resolver fully retired; `CreateStep` only tolerable inside the deleted-code's own history — zero live hits)
- [ ] `rg -n "FormWizardState" crates/jackin-console/src` returns at least one hit (wizard re-hosted)
- [ ] Wizard golden walks 1–6 pass against the FormWizard-driven machine
- [ ] `rg -n "CONSOLE_GLOBAL_KEYMAP" crates/jackin-console/src` returns at least one hit; `?` opens the overlay from all six stage routes in tests; Esc dismisses with focus restore
- [ ] The keyboard_help PNG baseline exists, is REUSE-annotated, and the harness verify exits 0
- [ ] Text snapshots byte-identical except the six stage snapshots whose diffs are exactly the `? help` addition (operator-approved at the step-7 checkpoint); PNG baselines identical except the keyboard_help addition and the approved stage footer re-blesses
- [ ] `rg -n "notification_center|command_palette|keybinding_recorder|theme_picker" crates/jackin-console/src` shows no new hits (N4)
- [ ] `cargo xtask ci --fast` exits 0
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status rows and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails — in particular a discovery grep coming back empty (010's step bodies, 011's keymap bridge, or the 005 PNG harness not observable) or the `create_prelude_modal_step` resolver missing/renamed.
- Any "Starting state" excerpt does not match the live code (re-located by symbol).
- Any text-snapshot or PNG diff appears outside step 7, or step 7's diffs show anything beyond the `? help` footer addition. (Inside step 7, the checkpoint STOP is part of the step.)
- `FormWizardState` cannot reproduce a cited wizard behavior via consumer configuration (gate, phase, rewind target) — that is the hub's TermRock-misfit route: mark BLOCKED with the concrete API gap and the upstream change you would make; never patch `<TERMROCK_CHECKOUT>`.
- The assumption "A5" (pairing APIs verified at `e1d61f4d` persist at pin `29a16b5b`) turns out false for `form_wizard` or `keyboard_help` — e.g. a cited upstream symbol is absent or renamed in `<TERMROCK_CHECKOUT>`.
- The work requires touching an out-of-scope file or violating a Must NOT (e.g. the overlay seems to need a second new screen, or a recipe pulls in a forbidden upstream integration).
- The operator rejects the step-7 checkpoint diff set.
- A required input is missing with no replacement contract.

## Maintenance notes

- Plan 014 owns the TUI reference docs alignment: this plan adds `?` to every console stage's keybinding surface and a new overlay — note the drift for 014 (keybinding pages and the footer-hints conventions page will need the `? help` row).
- The keyboard_help content builder keys off the same keymap statics plan 011 bridged; any future keymap restructuring must keep `help_entries_for_stage` compiling against the live statics — the content-drift tests are the guard.
- The recorded consumer compensation (WorkdirPick rewind via backward `jump_to` because upstream `back()` does not skip skipped steps, form_wizard.rs:687-701) is the candidate to retire if upstream `FormWizardState::back()` ever learns skip-aware rewind; until then it is documented behavior, not a bug.
- Mouse interaction inside the help overlay (row hits, wheel scroll) is deferred — recorded in `TODO.md` in step 6.
- A reviewer should scrutinize: the step-7 diff isolation (only footer-hint code + six snaps + affected PNGs + hint unit tests), the wizard goldens (literals must not be recomputed through the new machine), and that no `termrock::patterns` import appears anywhere (copy-adapt law).
