# Console modernization

## Purpose

Re-platform the console surface (`crates/jackin-console` + the adapter half in `crates/jackin/src/console/`) on the TermRock head component set per the settled adoption map, under the strict UI/UX parity invariant: substrate changes, experience does not. This is the first modernization phase and sets the patterns the capsule, launch, and small-surface phases copy.

Anchors: F5, F9, W2, S2, B14, B15, B16, N4 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md, research/termrock-head-adoption/06-mouse-subsystem-parity-matrix.md, roadmap item §Decisions 2026-08-19 (console finalization rulings)

## Requirements

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

#### Scenario: Scroll adapter cutover

- **GIVEN** the console scroll adapter currently wraps hand-rolled scroll state
- **WHEN** the cutover lands
- **THEN** all console scroll views render through `ScrollArea` with byte-identical text snapshots
- **AND** horizontal char-precise scrolling behavior is unchanged (hand-rolled half preserved)

#### Scenario: Modal stack cutover

- **WHEN** a `ConsoleModal` variant opens over a stage view
- **THEN** geometry and stacking come from `OverlayStack`/`DismissPolicy`
- **AND** the modal flow (open/close/esc cascade/result) behaves exactly as the pre-cutover flow enum

#### Scenario: Mouse cutover gated on parity matrix

- **WHEN** the mouse machinery cutover is attempted
- **THEN** every rule in research chapter 06's parity matrix is MATCH or has a recorded compensation
- **AND** a rule verdict of DIFFERS with no compensation route is a STOP, not a cutover

#### Scenario: Wheel feel identical

- **GIVEN** the `ScrollArea` cutover landed
- **WHEN** the user scrolls any console block with the wheel, with or without Shift
- **THEN** step size is 1 line/col per tick on both axes (consumer `.wheel_steps(1, 1)` config)
- **AND** Shift+wheel scrolls horizontally first and falls back to vertical when horizontal cannot move (consumer retry on `ScrollOutcome::Ignored`)
- **AND** wheel events route to the block under the pointer (consumer hit-test dispatch; registration order mirrors paint z-order)

#### Scenario: Scrollbar drag unchanged

- **WHEN** the user drags a console scrollbar after the cutover
- **THEN** the pointer-in-track absolute offset jump, per-stage targets, modal suppression, and focus-set-on-drag all behave exactly as before (consumer-side drag lane — upstream has no carrier)

### Requirement: Dialog and form layer on upstream widgets

Console dialogs SHALL adopt `confirm_prompt`/`alert_dialog`/`error_state`/`loading_overlay` (default-focus-No verified against upstream before cutover — an upstream change per the misfit rule if it cannot); the file browser SHALL adopt `file_picker`/`file_tree`/`path_input` with the $HOME sandbox and git-repo prompt re-hosted as domain logic; the picker family SHALL adopt `select`/`combobox` (product outcome enums stay); forms SHALL adopt `form`/`field_row`/`key_value_table`/`password_input`; the save preview SHALL adopt the `diff` widget at the rendering layer only (semantic diff computation stays product); key-value displays with links SHALL adopt `key_value_table` + `link`.

Covers: F5 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md (C6, C7, C8, C10, C11, C19 pairings)

#### Scenario: Confirm default focus preserved

- **GIVEN** a destructive-action confirm dialog (confirm-delete, confirm-instance-purge)
- **WHEN** it opens after the cutover
- **THEN** the default focus is No, exactly as before
- **AND** if upstream cannot reproduce that, the fix lands upstream per the misfit rule before the cutover ships

#### Scenario: File browser domain rules survive

- **WHEN** the file picker opens in the mounts editor after adopting `file_picker`
- **THEN** the $HOME sandbox restriction and the git-repo prompt behave exactly as the pre-cutover domain logic

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

### Requirement: Whole-screen recipes and the create wizard

The workspaces screen SHALL adopt the `patterns/project_launcher`/`session_picker` composition, the settings screen SHALL adopt `patterns/settings_screen`, and auth forms SHALL adopt `patterns/auth_entry` + `password_input` — all as copy-adapt recipes (composition reference, never a type dependency). The create-prelude wizard SHALL adopt the `form_wizard` widget (`WizardGate`/`WizardPhase`/`WizardProgress`) in place of the boolean-priority step resolver, each step body supplied by the C7/C8 pairings.

Covers: F5 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md (recipes + form_wizard rows)

#### Scenario: Wizard step resolution equivalent

- **GIVEN** the create-prelude wizard re-hosted on `form_wizard`
- **WHEN** the wizard is walked forward and backward with every combination of skippable steps
- **THEN** the step sequence, gating, and progress display match the pre-cutover boolean-priority resolver exactly

### Requirement: Op-picker wholly in the console phase

The op-picker staged drill-down SHALL stay hand-rolled (no upstream equivalent) with its breadcrumb re-based on `widgets/breadcrumbs`; the `jackin-oppicker` crate SHALL be modernized in the same phase: `ReadySubscription` replaces the `BlockingSubscription` duplicate, filtering adopts `interaction/collection`, and the `ModalOutcome` duplicate is removed.

Covers: F5 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md (op-picker rows), roadmap item §Decisions (D25 ruling)

#### Scenario: Drill-down behavior preserved

- **WHEN** the op-picker drill-down is navigated after the breadcrumb re-base
- **THEN** staging, filtering, and back-navigation behave exactly as before
- **AND** the breadcrumb renders through `widgets/breadcrumbs` with identical content

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

### Requirement: No performance gate

The console phase SHALL carry no performance budget or gate; rendering-parity gates (byte-identical text snapshots, zero-tolerance PNG baselines, behavioral parity tests) are the whole acceptance.

Covers: B14, B15 · Evidence: roadmap item §Decisions (parity rule ruling, 2026-08-19)

#### Scenario: Virtualization adoption without perf sign-off

- **WHEN** `VirtualList` adoption lands on a long console list
- **THEN** acceptance is the parity gates alone — no latency or throughput measurement is required or recorded

## Screen: keyboard_help overlay (S2)

Mockup: none in item — visual truth owned by the PNG baseline (spec/png-baselines.md) and upstream `keyboard_help` rendering; layout intent: modal overlay listing keybindings, opened by `?`.

- **Regions**: overlay frame (upstream keyboard_help chrome); binding rows grouped per the keymap_bridge data; footer hint advertising `?` lives on each stage's hint bar (not inside the overlay)
- **States**: open (over any console stage) | dismissed — the only two states; content is a pure function of keymap_bridge data (specified here; item draws neither)
- **Interactions**: `?` → opens (exercises "Reachable from every stage"); Esc → dismisses with focus restore; content source → exercises "Help content cannot drift"
- **Navigation**: arrives from any of the six console stage views via `?`; exits back to the originating stage via Esc
