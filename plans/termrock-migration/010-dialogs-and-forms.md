# Plan 010: Adopt the dialog and form layer on upstream TermRock widgets

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: plans/009-collections-and-modals.md (which chains 006; PNG gate from 005)
- **Covers**: spec/console-modernization.md "UI/UX parity invariant" + "Dialog and form layer on upstream widgets"; coverage ledger F5 (C6, C7, C8, C10, C11, C19), B14, D16
- **Guardrails**: N2, N4 inlined below (N3 noted, not engaged)
- **Research basis**: research/termrock-head-adoption/04-component-adoption-candidates.md (C6, C7, C8, C10, C11, C19 rows)
- **Planned at**: commit `f320b51f`, 2026-08-19

## Why this matters

The console carries six hand-rolled dialog/form subsystems — bespoke confirm/save-discard/error/status state structs, a domain-heavy file browser, eight near-identical picker states, pinned-width form rows, a semantic save preview, and a container-info projection. Upstream now ships purpose-built widgets for each (`alert_dialog`/`confirm_prompt`/`error_state`/`loading_overlay`, `file_picker`/`file_tree`/`path_input`, `select`/`combobox`, `form`/`field_row`/`key_value_table`/`password_input`, `diff`, `link`). Adopting them deletes product-maintained anatomy that upstream now owns, under the phase's hard law: the substrate changes, the experience does not — every adoption is gated on byte-identical text snapshots, passing PNG baselines, and green component tests, and anything a widget cannot reproduce is compensated in consumer configuration first and escalated as an upstream-misfit BLOCKED second, never silently accepted. After this lands, every console dialog and form renders through upstream widgets with product wording, product outcome enums, and product domain rules intact.

## Preconditions — run before anything else

- Plan 009 landed: the hub `plans/termrock-migration/README.md` status row for 009 reads `DONE`; per the hub protocol, re-run the cheapest done criterion recorded in plan 009 before building on it. Observable substrate check: `rg -n "OverlayStack|DismissPolicy" crates/jackin-console/src/tui --type rust` → at least one hit (plan 009 put modal geometry/stacking on the upstream overlay machinery; this plan's dialogs stack on it).
- Plan 005 landed: the hub status row for 005 reads `DONE`, and the PNG-baseline comparison command recorded in plan 005's Done criteria exits 0 on the current tree (the pixel gate this plan runs after every step).
- Drift check: `git diff --stat f320b51f..HEAD -- crates/jackin-console/src/tui crates/jackin-tui/src/operator_info.rs` — changes since the planned-at SHA are expected **only** from this package's plans 005–009 on the execution branch. For every changed file, `git log --oneline f320b51f..HEAD -- <file>` must show only this branch's plan commits; any other commit is a STOP. Where a dependency plan legitimately rewrote a file, the live file is the authority — re-read it and treat every "Starting state" line number below as a planning-time snapshot to re-derive, not a target.

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

Done means these scenarios hold; the test plan below exercises them.

## Must NOT

Guardrails inlined verbatim from the must-not registry (`plans/termrock-migration/coverage.md`), with reasons. These override anything a step seems to imply:

- **N2**: No compatibility facades or shims over renamed TermRock APIs — repo latest-only law; upstream directive 0061/0331.
- **N4**: No new operator-visible screens or overlays beyond keyboard_help; no journey changes — amended D14 — amendment scope is exactly one overlay.

Note on **N3** (Usage-limits-only rule beats adoption: `context_meter`/`metric_tile` not wired if their render-path read fails it — root AGENTS.md hard rule): this plan wires **no** usage-surface widgets — `context_meter`/`metric_tile` are out of scope here — so N3 is not engaged by any step below.

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — a local checkout of the TermRock repository at rev `29a16b5b`, read-only. On this machine it lives at `/Users/donbeave/Projects/tailrocks/termrock` (`git -C <TERMROCK_CHECKOUT> rev-parse --short HEAD` must print `29a16b5b`). Needed by steps 1–6 to re-verify upstream APIs before each cutover.
  - If absent: use the cargo git checkout of the pinned dependency (under `~/.cargo/git/checkouts/`, the termrock clone whose HEAD is `29a16b5b`) as `<TERMROCK_CHECKOUT>`; any clone at that rev satisfies the contract. Verify the rev the same way. Do NOT block waiting. Never edit the checkout — an upstream misfit is a BLOCKED outcome per the hub's misfit rule, not a local edit.

## Starting state

The facts, inlined — every citation below was re-opened and verified at planning time on commit `f320b51f` (jackin) and rev `29a16b5b` (TermRock). All jackin paths are repo-relative; upstream paths are relative to `<TERMROCK_CHECKOUT>/crates/termrock/src/`.

**Planning-time measurements carry the re-derivation rule.** Every line number, count, and grep total below is a planning-time snapshot; plans 005–009 land before this plan executes and will shift lines. The executor re-runs the locating grep, the fresh number is the authority — stamp it in the output, note the delta, and never treat a drifted planning number as a target to reproduce.

### C6 — dialog state primitives (step 1)

Current product states, all in `crates/jackin-console/src/tui/components/dialogs.rs`:

- `TextInputState` (:69) — already a thin wrapper over upstream `TextInput` (import at :19); **no adoption target, stays as-is**.
- `ConfirmState` (:193): `new()` (:201-209) and `details()` (:212-227) both construct `ChoiceDialogState::new(Some(false))` (:207, :225) — **default focus is already No for every console confirm**. `with_focus_yes` (:230) opts out; `with_focus_no` (:236) re-asserts. Direct `y`/`n` keys commit (:251-256); Tab/BackTab cycle the choice (:262-272); actions are `Yes`/`No` (`confirm_actions`, :304-319). Renders as a modal via upstream `Dialog` + `ChoiceDialog` with `PanelChrome::Focused` emphasis (`render_confirm_dialog`, :343-355). `ConfirmKind::Details` carries product wording rows + notes (:283-289).
- `SaveDiscardState` (:371): three-way focus Save/Discard/Cancel, **`new()` defaults focus to Cancel** (:378-383); `s`/`d` commit, Esc/`c` cancels (:385-396); product enum `SaveDiscardChoice { Save, Discard }` (:358-361). Constructor `components/save_discard.rs:6-7`; opened from `screens/editor/model/state_impl/navigation.rs:382`.
- `ErrorPopupState` (:460), rendered by `render_error_dialog` (:499); plumbed via `update.rs:37` and `state/manager.rs:1039 open_error_popup_modal`.
- `StatusPopupState` (:515), rendered by `render_status_popup` (:530); held at `state.rs:242 status_overlay`, set via `state/manager.rs:1026`. **Carve-out (research C6)**: StatusPopup is also a progress reporter — `components/status_popup.rs:17 role_resolution_status_popup_state` ("Resolving agent role") and `:23 role_loading_status_popup_state` ("Loading role") — so mapping it to `BusyBoundaryState` changes dismissal semantics; dismissal is product-controlled (`Option` overlay), and that behavior must survive.

Destructive-confirm call sites (the default-focus-No scenario): `screens/workspaces/update.rs:1097 workspace_delete_confirm_state` (`Delete "{name}"?`) and `:1102 instance_purge_confirm_state` (`Purge "{label}"?…`) — both plain `ConfirmState::new`, hence No-focused. Non-destructive exit confirm: `run.rs:221-222 quit_confirm_state` uses `.with_focus_yes()` — focus Yes is intentional there and must survive. Settings-side confirms: `screens/settings/view/text_helpers.rs:38` (global-mount confirm) and `:200 settings_env_delete_confirm_state`. Stage wiring: `model/stage.rs:12 ConsoleManagerStage`, `:17 ConfirmDelete`, `:21 ConfirmInstancePurge`. Launch handoff prompts render through the same dialog states: `prompts.rs:35 draw_role_resolution_dialog`, `:55 show_role_resolution_error`, `:87 prompt_agent_for_launch`. Modal variants: `model/modal.rs:63 Confirm`, `:67 SaveDiscardCancel`, `:76 ErrorPopup`, `:82 StatusPopup` (enum at :24, 19 variants :48-114).

Upstream anchors (verified at `29a16b5b`):

- `widgets/confirm_prompt.rs` — `ConfirmFocus` enum (:22-30) with `Cancel` as `#[default]` (:26-27); `ConfirmPrompt::new` (:94-105) sets `focus: ConfirmFocus::Cancel` (:102). **Default focus IS the safe side — verified.** But it is a stateless two-row bottom-of-pane strip (`CONFIRM_PROMPT_ROWS: 76` = 2; `paint` paints "into the last two rows of `area`", :142-143; "the prompt is stateless and the host owns activation", :198-199) — no title, no details rows, no keyboard handling. No console site has that shape today.
- `widgets/alert_dialog.rs` — modal-class: `AlertKind` (:62), `AlertReversibility` (:133), `AlertConfirmGates` (:265, typed-phrase + countdown), `AlertDialogOutcome` (:316), `AlertDialogState` (:350). `new()` (:496-523) sets the safe default: cancel id as action cursor **and** default action (:502-505) — **default focus IS the safe action — verified**; Esc yields `Cancelled{id}` (:684-694); opens on `OverlayStack` (`open_on_stack`, :558-585) — the plan-009 substrate. Its painted body is a fixed risk anatomy (Target/Scope/Consequence/Reversibility/Safer bullets, `build_body_text` :1008-1033) with per-kind default titles/labels (:89-121) — reproducing the console's free-text prompt + details rows byte-for-byte is the open parity question.
- `widgets/error_state.rs` — `ErrorKind` (:51), `RetrySafety` (:172), `ErrorRecipe` (:209); inline/compact geometry constants (:42-44).
- `widgets/loading_overlay.rs` — `BusyMode` (:56), `BusyRoute` (:125), `BusyBoundaryOutcome` (:141), `BusyBoundaryState` (:158).
- `widgets/question_flow.rs` — `Question` (:99) with `Question::single` (:121) single-choice constructor; candidate for the 3-way save/discard/cancel choice.

### C7 — file browser (step 2)

- State: `components/file_browser/state.rs:17 FileBrowserState` — `$HOME` clamp (:18-19, "the browser cannot navigate above this path"), selection rejection incl. `$HOME` itself and `~/.jackin/...` (:26-28 `rejected_reason`), per-flow hidden toggle (:29-33 `show_hidden`; mounts flow hides dotfiles, auth source-folder flow shows them), git-repo prompt fields (:35 `pending_git_prompt`, :40-41 `pending_git_url_rx`, :43 `pending_git_focus`). Module docs (:6-7): directory scanning, sandbox policy, and git-origin inspection live in `services::file_browser` — **domain logic stays product**.
- Prompt overlay: `components/file_browser/git_prompt.rs` — async origin resolution (:56-77 `attach_git_url_resolution`/`poll_git_url_resolution`), rect helpers (:146 `git_prompt_rect`, :171).
- Module root `components/file_browser.rs` is now a 46-line shell (`page_rows_for_modal` at :42); **orchestration moved post-bump** to `crates/jackin-console/src/tui/file_browser.rs` (850 lines): open constructors (:36, :50, :64, :78, :89 `start_*_open`), listing application (:117), outcome execution (:258, :281), commit validation (:345, :426), git-url resolution (:733, :804). Render `components/file_browser/render.rs` (162 lines), input `input.rs` (147), listing `listing.rs` (27).
- Modal variant `model/modal.rs:52 FileBrowser`; tests exist at `components/file_browser/{state,input,render,git_prompt}/tests.rs`.
- Upstream: `widgets/file_picker.rs` — `FileEntryKind` (:56), `FileEntry` (:92), `FileBreadcrumb` (:195), `FilePreview` (:215), `FilePickerMode` (:257, `OpenFile` default / `OpenDirectory`); `widgets/file_tree.rs` — `FileTreeKind` (:35), `FileGitStatus` (:110); `widgets/path_input.rs` — `PathStyle` (:40), `expand_tilde` (:138, host-provided home string). Research carve-out: upstream has **no git-prompt affordance** — the prompt is re-hosted as domain logic around the widget, never deleted.

### C8 — picker family (step 3)

Eight product picker states: `components/role_picker.rs:15 RolePickerState`, `source_picker.rs:12 SourceChoice` + `:18 SourcePickerState`, `scope_picker.rs:12 ScopeChoice` + `:18 ScopePickerState`, `provider_picker.rs:13 ProviderPickerState` + `:45 ProviderPickerOutcome`, `agent_choice.rs:32 AgentChoiceState`, `workdir_pick.rs:14 WorkdirChoice` + `:24 WorkdirPickState`, `mount_dst_choice.rs:32 MountDstChoice` + `:48 MountDstChoiceState`, `github_picker.rs:18 GithubPickerState` + `:24 GithubOpenPlan`. **Product outcome/choice enums stay product** (parity of flow, not just render). Modal variants: `model/modal.rs:70 GithubPicker`, `:89 RolePicker`, `:92 RoleOverridePicker`, `:95 AuthRolePicker`, `:98 SourcePicker`, `:102 AuthSourcePicker`, `:105 ScopePicker`, `:56 MountDstChoice`, `:60 WorkdirPick`. Render dispatch: `view.rs:424 render_modal` (picker arms around :469-478). Inline (non-modal) pickers live in the workspaces sidebar: `screens/workspaces/view.rs:136-140` (`inline_provider_picker_open`, `inline_new_session_picker_open`, `inline_agent_picker_open`, `inline_role_picker_open`), consumed at :180-189.

Upstream: `widgets/select.rs` — `SelectRecipe` (:53), `SelectPresentation` (:78: `Closed` default / `Popover` / `Fullscreen` — **no dedicated inline presentation; `Popover` is the only anchored variant**), `SelectOption` (:123); `widgets/combobox.rs:168 ComboboxState`; `widgets/multi_select.rs:107 MultiSelectState` (no console multi-toggle site identified — adopt only if one surfaces). Research carve-out: the inline sidebar pickers need Select's inline presentation verified — if `Popover` cannot reproduce the current inline look byte-identically, that is consumer-configuration-exhausted → misfit route.

### C10 — form/table rows (step 4)

- `components/editor_rows.rs` — pinned label-column constants `AUTH_LABEL_COL_WIDTH` (:17), `SECRET_LABEL_COL_WIDTH` (:18); `labeled_field_line` (:44); `SecretValueDisplay` enum (:79-82: `Plain`, `OpRefPath`).
- `components/mount_rows.rs` — product column widths `MOUNT_MODE_COL_WIDTH` (:13), `MOUNT_ISOLATION_COL_WIDTH` (:16); render fns :19, :35, :71, :82.
- `components/env_value.rs:6 secret_display` — secret masking.
- Auth form: `components/auth_panel.rs:51 CredentialInput`, `:58 AuthFormKeyPlan`, `:195 AuthForm` (spans op-refs, literals, source folders, generated tokens — product flow stays).
- Consumers: editor tabs `screens/editor/view/{general_tab,mounts_tab,roles_tab,secrets_tab,auth_tab}.rs`, settings view `screens/settings/view.rs`, editor modals `screens/editor/view/modals.rs`.
- Upstream: `widgets/form.rs` — `FieldStatus` (:45), `Field` (:96; `:124 new`, `:142 masked`, `:149 unset`), `FormOutcome`; `widgets/field_row.rs:63 FieldRow`; `widgets/key_value_table.rs` — `KvtValidation` (:50), `KvtMode` (:83, incl. edit), `KvtRowKind` (:105), `KvtField` (:117; `:155 pair`, `:245 href`); `widgets/password_input.rs` — `RevealPolicy` (:42), `ClipboardPolicy` (:70), `PasswordInputOutcome` (:194), `PasswordInputState` (:226). Research carve-outs: KVT auto-layout vs the pinned label/mode/isolation widths is the parity risk; `password_input` clipboard policy interacts with jackin❯'s OSC 52 copy rules — copy behavior stays consumer-side.

### C11 — save preview / confirm-save (step 5)

- Semantic computation (stays product, never touched by the widget swap): `components/save_preview.rs` — `WorkspaceToggleSet` (:29), `WorkspaceSavePreview` (:35), `WorkspaceSaveMode` (:54), `workspace_save_preview` (:71), `build_workspace_save_lines` (:144), mount-diff projection (:194-230), `WorkspaceMountDiff` (:234: Added/Removed/Modified/Unchanged).
- Flow (stays product): `components/confirm_save.rs` — `SaveChoice` (:34), `ConfirmSaveAction` (:39), `ConfirmSaveFocus` (:136), `ConfirmSaveState` (:162, `handle_key` :194), `prepare_for_render` (:265); render (:277) already builds on upstream `render_dialog_shell` (:278) + `render_lines_with_offset_in_area` (:303).
- Consumers: `input/save.rs:15` (imports `build_workspace_save_lines as build_confirm_save_lines`) + `:195`, `input/global_mounts.rs:998`, `screens/edit_save.rs:11 EditSaveDisposition`; dispatch `view.rs:451-452`.
- Upstream: `widgets/diff.rs` — `DiffKind` (:45), `DiffWordKind` (:108), `DiffWordSpan` (:131), `DiffSyntaxSpan` (:148), `DiffMode` (:175), `DiffEffectiveMode` (:200); `widgets/preview_card.rs` (candidate only — constants :49-61). The `29a16b5b` pin's head commit adds `DiffViewState::scroll_mut` host scroll injection (jackin-authored PR #35) — the sanctioned seam for the preview's scroll parity. Research carve-out: preview rows are **semantic** (mount add/remove/change), not textual diffs — the diff widget fits **only the rendering layer**; if semantic rows cannot map onto it byte-identically, that is the misfit route, not a behavior change.

### C19 — container-info projection (step 6)

- Console projection: `components/container_info.rs:14 debug_run_info_state`; alias `components.rs:11 pub use jackin_tui::operator_info as container_info_surface;`.
- Shared product composition (stays product): `crates/jackin-tui/src/operator_info.rs` — `ContainerInfoRow` (:25; `.hyperlink()` builder :63), `ContainerInfoState` (:164), and the current substrate `render_container_info` (:410).
- Dispatch: `view.rs:457-461` (`Modal::ContainerInfo` arm, variant `model/modal.rs:79`).
- Capsule and launch also project this composition (capsule ContainerInfo/GitHubContext dialogs; launch container-info dialog) — they are **not edited**, but the substrate swap in `operator_info.rs` changes what they render, so the cross-crate snapshot gate (`cargo xtask ci --only snapshots`, capsule + console) binds this step.
- Upstream: `widgets/key_value_table.rs` (`KvtField::pair` :155, `href` :245), `widgets/link.rs` — `LinkDestination` (:36; `osc8_eligible` :69), `LinkVariant` (:79), `LinkStyle` (:107), `LinkParts` (:166), `LinkOutcome` (:183); `osc/encode.rs:41 encode_hyperlink_open` for the hyperlink bytes.

### Cross-cutting facts

- Modal chrome after plan 009: `view.rs:392 render_modal_backdrop`, `:424 render_modal`, call sites :630/:636/:643/:650. This plan swaps dialog **state + body anatomy**, not geometry/stacking (009's `OverlayStack`/`DismissPolicy` owns that).
- Text snapshots (the byte-identical gate): exactly 6 console insta snapshots under `crates/jackin-console/src/tui/view/snapshots/` — `list_empty_80x24`, `settings_general_90x20`, `editor_general_90x20`, `editor_mounts_tab_90x20`, `global_mounts_110x30`, `editor_auth_tab_90x20` — asserted at `view/tests.rs:767, :796, :809, :839, :1445, :1459`. Modal rendering is covered by component test suites (`components/*/tests.rs` — one per component, e.g. `role_picker/tests.rs`, `confirm_save/tests.rs`, `save_preview/tests.rs`, `file_browser/*/tests.rs`) and by plan 005's PNG baselines over the 19-modals inventory. `components/dialogs.rs` has **no** `tests.rs` sibling today — step 1 creates `components/dialogs/tests.rs` per the workspace test-file rule (sibling `tests.rs`, `#[cfg(test)] mod tests;` in `dialogs.rs`).
- Conventions to match: effects-as-data (the console emits effect types; no direct runtime calls — `crates/jackin-console/AGENTS.md`); tests in own file, self-named module layout, no `mod.rs` (`crates/AGENTS.md`); pure decisions stay pure, side-effect adapters thin.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Console suite (component tests + 6 text snapshots; any insta diff = parity break = STOP, never re-bless) | `cargo nextest run -p jackin-console --locked` | all pass, exit 0 |
| One module's tests | `cargo nextest run -p jackin-console -E 'test(/file_browser/)'` (adjust module per step) | all pass |
| Cross-crate snapshot lane (binds step 6; runs both crates' suites) | `cargo xtask ci --only snapshots` | exit 0 |
| PNG baselines (per step, after the suite) | the baseline-comparison command recorded in plan 005's Done criteria | exit 0 / all baselines match |
| Clippy (inner loop) | `cargo clippy -p jackin-console --all-targets -- -D warnings` | exit 0 |
| Clippy (step 6 also) | `cargo clippy -p jackin-tui --all-targets -- -D warnings` | exit 0 |
| Format | `cargo fmt --check` (fix: `cargo fmt`, re-check) | exit 0 |
| Final merge-readiness (non-e2e) | `cargo xtask ci --fast` | exit 0 |

(Proven by research/jackin-verification-tooling/01-gates-and-commands.md — partition mapping, nextest filter forms, and the snapshots-partition definition all come from that chapter. The PNG command name is plan 005's delegation, ledger B13.)

## Scope

**In scope** (the only files to create or modify):

- `crates/jackin-console/src/tui/components/dialogs.rs` and **new** `crates/jackin-console/src/tui/components/dialogs/tests.rs`
- `crates/jackin-console/src/tui/components/{error_popup,status_popup,save_discard}.rs` + their `tests.rs`
- `crates/jackin-console/src/tui/components/file_browser.rs`, `components/file_browser/{state,listing,render,input,git_prompt}.rs` + their `tests.rs`, and `crates/jackin-console/src/tui/file_browser.rs` (only where widget adoption forces signature changes)
- `crates/jackin-console/src/tui/components/{role_picker,source_picker,scope_picker,provider_picker,agent_choice,workdir_pick,mount_dst_choice,github_picker}.rs` + their `tests.rs`
- `crates/jackin-console/src/tui/components/{editor_rows,mount_rows,env_value,auth_panel}.rs` + their `tests.rs`
- `crates/jackin-console/src/tui/components/{save_preview,confirm_save,container_info}.rs` + their `tests.rs`
- `crates/jackin-tui/src/operator_info.rs` + its tests (C19 substrate only)
- Wiring files, only where a swapped type forces the touch: `tui/state.rs`, `tui/update.rs`, `tui/message.rs`, `tui/view.rs` (modal dispatch arms), `tui/run.rs`, `tui/prompts.rs`, and the `tui/screens/**` + `tui/input/**` files that construct the swapped states (incl. `screens/workspaces/view.rs` inline pickers, `screens/workspaces/update.rs`, `screens/settings/view/text_helpers.rs`)

**Out of scope** (do NOT touch, even though related):

- `<TERMROCK_CHECKOUT>` — read-only; an API misfit is a BLOCKED row with an upstream-change recommendation (hub misfit rule), never a local edit.
- `TextInputState` / upstream `TextInput` — already adopted pre-pin; no target here.
- `crates/jackin-capsule/**`, `crates/jackin-launch/**`, `crates/jackin-oppicker/**` (013 owns oppicker), `crates/jackin/src/**` — capsule/launch consume `operator_info` but are not edited; their suites gate step 6.
- Plan 005's territory: PNG harness, baseline fixtures, CI lane. Plan 006: facade contracts/traits. Plan 007: BrandHeader. Plan 008: `ScrollArea`/mouse machinery. Plan 009: `CollectionState`/`RovingFocusGroup`/`VirtualList`, selection wrapper, `OverlayStack`/`DismissPolicy` geometry, modal rect specs. Plan 011: `panel_stack`, `kbd`/`hint_bar`, `SpinnerState`, `keymap_bridge`/`UiIntent`, `Presenter`/`FrameClock`, `resizable_panel_group`. Plan 012: whole-screen recipes, `form_wizard`, `keyboard_help`. Plan 013: op-picker drill-down + breadcrumbs. Plan 014: docs pages under `docs/content/**`, final proof pass, artifact strip.
- `docs/content/**` — same-PR docs law is plan 014's; this plan notes drift in its commit messages only.
- `widgets/question_flow` beyond the save/discard/cancel candidate use; `widgets/preview_card`, `widgets/multi_select`, `widgets/data_table` — candidates only; wire nothing without a parity-passing call site.

The hub `plans/termrock-migration/README.md` and the roadmap item are protocol-writable and never listed in scope.

## Git workflow

One commit per pairing family, in step order, each pushed immediately (hub law). Concrete messages:

1. `refactor(console): adopt upstream dialog widgets for confirm, save-discard, error, and status modals`
2. `refactor(console): adopt file_picker/file_tree/path_input in the file browser`
3. `refactor(console): adopt select/combobox across the picker family`
4. `refactor(console): adopt form/field_row/key_value_table/password_input in editor and settings forms`
5. `refactor(console): render the save preview through the upstream diff widget`
6. `refactor(console): adopt key_value_table and link for container-info displays`

If a step ends in a misfit BLOCKED instead of a cutover, no code commit for that family — the hub row is marked `BLOCKED (termrock API misfit — recommend upstream change: <one line>)` per the hub's misfit rule and the loop stops.

## Steps

Order constraint keeping the workspace green: each step lands one family's cutover behind the parity gates, so the tree is never broken between steps. Within each step: re-verify the upstream API in `<TERMROCK_CHECKOUT>` first (drift guard), port the state, switch the render, then run the gates. **Gate order per step**: `cargo nextest run -p jackin-console` → PNG baseline comparison (plan 005's command) → `cargo clippy -p jackin-console --all-targets -- -D warnings` → `cargo fmt --check`. Any insta snapshot diff or PNG mismatch = STOP (parity break; never re-bless, never `INSTA_UPDATE`).

### Step 1: Adopt upstream dialog widgets (C6)

Re-verify the upstream default-focus guarantees before any cutover (the spec's "verified against upstream before cutover" clause):

- `sed -n '22,30p' <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/confirm_prompt.rs` → `ConfirmFocus::Cancel` carries `#[default]`
- `sed -n '94,105p' <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/confirm_prompt.rs` → `new()` sets `focus: ConfirmFocus::Cancel`
- `sed -n '496,508p' <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/alert_dialog.rs` → `new()` sets the action cursor and default action to the cancel id

If any of these no longer holds, that is the spec's misfit case: STOP with a BLOCKED row naming the upstream change (safe-default focus on the confirm/alert widgets), per the hub misfit rule.

Then, in `crates/jackin-console/src/tui/components/dialogs.rs`:

- Port `ConfirmState` (:193) onto `AlertDialogState` (upstream `widgets/alert_dialog.rs:350`) as the modal carrier: map the product title/prompt (incl. `ConfirmKind::Details` rows + notes, :283-289) onto the alert body, keep the `Yes`/`No` labels (:304-319), keep default focus No (upstream safe-default, verified above), keep direct `y`/`n` commits and Tab/BackTab cycling as the consumer keymap layer on top of the widget's `handle_key` (:612), keep Esc → cancel. `run.rs:221-222 quit_confirm_state`'s `with_focus_yes()` must still yield a Yes-focused dialog (non-destructive confirm is the intentional exception). `confirm_prompt` (`widgets/confirm_prompt.rs:80`) is the bottom-strip variant: no console site renders a two-row pane-bottom prompt today, so it gets **no call site** in this cutover — record that in the commit message rather than inventing one (N4).
- Port `SaveDiscardState` (:371) — three actions, Cancel-default (:378-383), `s`/`d`/`c`/Esc keys (:385-396) — onto the upstream 3-option single-choice candidate `question_flow` (`Question::single`, `widgets/question_flow.rs:121`) if its rendering can match byte-for-byte; otherwise keep the current `ChoiceDialog`-based body and record the carve-out in the commit message. `SaveDiscardChoice` (:358) stays product either way.
- Port `ErrorPopupState` (:460) onto `error_state` anatomy (`ErrorKind` :51, `RetrySafety` :172, `ErrorRecipe` :209) preserving the current rendered lines and key behavior.
- Port `StatusPopupState` (:515) toward `loading_overlay`'s `BusyBoundaryState` (:158) **only as far as dismissal semantics survive**: the status overlay is product-dismissed (`state.rs:242`, `state/manager.rs:1026`) and doubles as a progress reporter (`status_popup.rs:17`, `:23`). If `BusyBoundaryState`'s dismissal model cannot reproduce that, keep the state product-side, adopt only `BusyMode`/spinner-adjacent anatomy that is behavior-preserving, and record the carve-out.
- Update the render fns (:343-355, :416, :499, :530), the modal dispatch arms in `view.rs`, and the constructors listed in Starting state (`workspaces/update.rs:1097/:1102`, `text_helpers.rs:38/:200`, `save_discard.rs:6-7`, `prompts.rs:35/:55/:87`, `run.rs:221-222`) to the swapped types. Geometry stays plan 009's — do not touch rect specs or `render_modal_backdrop`.
- Create `components/dialogs/tests.rs` (+ `#[cfg(test)] mod tests;` in `dialogs.rs`) with the new behavioral tests from the Test plan.

**Verify**: gate order above → console suite all pass with zero snapshot diffs; PNG baselines match; clippy/fmt exit 0. Commit with message 1.

### Step 2: Adopt file_picker/file_tree/path_input in the file browser (C7)

Re-verify upstream anchors: `grep -n "pub enum FilePickerMode\|pub struct FileEntry\b\|pub struct FileBreadcrumb\|pub struct FilePreview" <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/file_picker.rs` and `sed -n '136,150p' <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/path_input.rs` (`expand_tilde`).

- Port the listing/selection/preview anatomy of `components/file_browser/` (`state.rs:17`, `listing.rs`, `render.rs`, `input.rs`) onto `file_picker` (`FileEntry` :92, `FileEntryKind` :56, `FileBreadcrumb` :195, `FilePreview` :215, `FilePickerMode::OpenDirectory` :257 — the console picks directories); adopt `file_tree` (`FileTreeKind` :35) only where the current flat listing maps — if it does not, record the non-adoption with the reason in the commit message; adopt `path_input`'s path normalization (`expand_tilde` :138, `PathStyle` :40) in place of ad-hoc string handling.
- **Re-host, never delete, the domain rules**: the `$HOME` root clamp (`state.rs:18-19`), selection rejection incl. `$HOME` itself and `~/.jackin/...` (`state.rs:26-28`), the per-flow hidden toggle (`state.rs:29-33`), and the git-repo prompt with async origin lookup (`state.rs:35-43`, `git_prompt.rs:46-77`, orchestration `tui/file_browser.rs:733`/:804`) stay product logic wrapped around the widget — upstream has no git-prompt affordance (research carve-out). Sandbox policy and git-origin inspection in `services::file_browser` (module docs `state.rs:6-7`) are untouched.
- Touch `tui/file_browser.rs` orchestration only where widget types force signature changes.

**Verify**: gate order → suite pass (the four `file_browser/*/tests.rs` suites are the domain-rule proof), zero snapshot diffs, PNG match, clippy/fmt clean. Commit with message 2.

### Step 3: Adopt select/combobox across the picker family (C8)

Re-verify upstream anchors: `grep -n "pub enum SelectRecipe\|pub enum SelectPresentation\|pub struct SelectOption" <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/select.rs` and `grep -n "pub struct ComboboxState" <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/combobox.rs`.

- Collapse the eight picker states (`role_picker.rs:15`, `source_picker.rs:18`, `scope_picker.rs:18`, `provider_picker.rs:13`, `agent_choice.rs:32`, `workdir_pick.rs:24`, `mount_dst_choice.rs:48`, `github_picker.rs:18`) onto the `select` option-list contract (`SelectRecipe` :53, `SelectOption` :123), using `combobox` (`ComboboxState` :168) where a picker's filter-input behavior matches it. Filter + keyboard behavior standardizes on the widget; per-picker key maps that are product contracts stay as the consumer layer.
- **Product outcome/choice enums stay product**: `ProviderPickerOutcome` (`provider_picker.rs:45`), `GithubOpenPlan` (`github_picker.rs:24`), `SourceChoice` (`source_picker.rs:12`), `ScopeChoice` (`scope_picker.rs:12`), `MountDstChoice` (`mount_dst_choice.rs:32`), `WorkdirChoice` (`workdir_pick.rs:14`). Map them at the widget boundary; do not retype them to upstream ids.
- Inline sidebar pickers (`screens/workspaces/view.rs:136-140`, consumed :180-189): attempt `SelectPresentation::Popover` (:78); if the anchored popover cannot reproduce the current inline rendering byte-identically, keep the inline rendering product-side, adopt `select` for the modal pickers only, and record the carve-out — or, if the gap is a missing upstream inline presentation, STOP with the misfit BLOCKED naming it.
- Modal dispatch arms in `view.rs` (around :469-478) follow the swapped types.

**Verify**: gate order → suite pass (per-picker `tests.rs` suites green), zero snapshot diffs, PNG match, clippy/fmt clean. Commit with message 3.

### Step 4: Adopt form/field_row/key_value_table/password_input in forms (C10)

Re-verify upstream anchors: `grep -n "pub struct Field\b\|pub enum FieldStatus" <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/form.rs`, `grep -n "pub struct KvtField\|pub enum KvtMode" <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/key_value_table.rs`, `grep -n "pub enum RevealPolicy\|pub enum ClipboardPolicy\|pub struct PasswordInputState" <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/password_input.rs`.

- Port `labeled_field_line` (`editor_rows.rs:44`) call sites across the five editor tabs and settings view onto `form`/`field_row` anatomy (`Field` :96/:124, `FieldStatus` :45, `FieldRow` :63). The pinned label widths (`editor_rows.rs:17-18`) are a visual contract: configure the widget to reproduce them exactly; if KVT/field_row auto-layout cannot, consumer configuration is exhausted → misfit route.
- Port mount tables (`mount_rows.rs:13-82`) onto `key_value_table`/`data_table`-class anatomy only if the product columns (mode :13, isolation :16 widths) reproduce byte-identically; otherwise keep the product rows and record the carve-out.
- Port secret masking (`SecretValueDisplay` `editor_rows.rs:79-82`, `secret_display` `env_value.rs:6`, auth credentials in `auth_panel.rs:51`/:195) onto `password_input` (`PasswordInputState` :226, `RevealPolicy` :42). Clipboard behavior stays consumer-side per jackin❯'s OSC 52 copy rules — configure `ClipboardPolicy` (:70) to never copy on its own; record the interaction in the commit message.
- Auth form (`auth_panel.rs:195 AuthForm`, `:58 AuthFormKeyPlan`) keeps its product flow (op-refs, literals, source folders, generated tokens); only field anatomy swaps.

**Verify**: gate order → suite pass, zero snapshot diffs (`editor_general_90x20`, `editor_mounts_tab_90x20`, `editor_auth_tab_90x20`, `settings_general_90x20` are the text-snapshot witnesses for this family), PNG match, clippy/fmt clean. Commit with message 4.

### Step 5: Render the save preview through the upstream diff widget (C11, render-only)

Re-verify upstream anchors: `grep -n "pub enum DiffKind\|pub enum DiffMode\|pub struct DiffWordSpan\|scroll_mut" <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/diff.rs`.

- **Semantic diff computation stays product, untouched**: `workspace_save_preview` (`save_preview.rs:71`), `WorkspaceMountDiff` (:234), the mount-diff projection (:194-230), and `build_workspace_save_lines` (:144) keep computing exactly what they compute today.
- Swap only the rendering layer of `confirm_save.rs` (:277-303, currently `render_dialog_shell` + `render_lines_with_offset_in_area`) to paint the preview body through the `diff` widget (`DiffKind` :45, `DiffWordSpan` :131, `DiffMode` :175), mapping each semantic row (Added/Removed/Modified/Unchanged) onto the corresponding diff-line anatomy. Use `DiffViewState::scroll_mut` (the pin's head-commit seam) for the preview's scroll injection so scroll behavior is unchanged.
- `ConfirmSaveState` flow (`confirm_save.rs:162`) — `SaveChoice` (:34), focus model (:136), `handle_key` (:194), hint spans (:241-246) — stays product. Consumers (`input/save.rs:15`/:195, `input/global_mounts.rs:998`, `screens/edit_save.rs`) change only where render types force it.
- `preview_card` (`widgets/preview_card.rs`) is a candidate only: wire it nowhere unless a parity-passing call site exists (none identified at planning).

**Verify**: gate order → suite pass (`confirm_save/tests.rs`, `save_preview/tests.rs` green), zero snapshot diffs, PNG match, clippy/fmt clean. Commit with message 5.

### Step 6: Adopt key_value_table + link for container info (C19)

Re-verify upstream anchors: `grep -n "pub fn pair\|pub const fn href" <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/key_value_table.rs`, `grep -n "pub enum LinkDestination\|osc8_eligible" <TERMROCK_CHECKOUT>/crates/termrock/src/widgets/link.rs`, `grep -n "pub fn encode_hyperlink_open" <TERMROCK_CHECKOUT>/crates/termrock/src/osc/encode.rs`.

- Swap the substrate of `render_container_info` (`crates/jackin-tui/src/operator_info.rs:410`) onto `key_value_table` rows (`KvtField::pair` :155, `href` :245) + `link` (`LinkDestination` :36, `osc8_eligible` :69), emitting hyperlink bytes through `encode_hyperlink_open` (`osc/encode.rs:41`).
- The composition stays product: `ContainerInfoRow` (:25) incl. `.hyperlink()` (:63), `ContainerInfoState` (:164), and the console projection `debug_run_info_state` (`components/container_info.rs:14`) are unchanged unless a signature forces it.
- This substrate is shared: capsule and launch render through it. Do not edit those crates; their suites gate the swap.

**Verify**: `cargo nextest run -p jackin-console` → `cargo xtask ci --only snapshots` (both crates green, zero diffs) → PNG comparison → `cargo clippy -p jackin-console --all-targets -- -D warnings` and `cargo clippy -p jackin-tui --all-targets -- -D warnings` → `cargo fmt --check`. Commit with message 6.

## Test plan

- **New tests** in the new `crates/jackin-console/src/tui/components/dialogs/tests.rs` (per the workspace test-file rule), covering the spec scenarios:
  - *Confirm default focus preserved*: `workspace_delete_confirm_state("demo")` and `instance_purge_confirm_state("demo")` (imported from `screens/workspaces/update.rs:1097`/`:1102`) each produce an adopted dialog state whose focused/default action is the safe one; Enter at rest yields cancel, not confirm. `quit_confirm_state()` (`run.rs:221-222`) yields the Yes-focused exception. Expected values come from the pre-cutover behavior (No-default / Yes-exception), asserted literally — never recomputed through the new widget's own defaults.
  - *Esc and direct keys*: Esc on a destructive confirm yields the cancel outcome; `y` commits confirm, `n` commits cancel; Tab/BackTab move focus without committing — mirroring the current `handle_key` contract (`dialogs.rs:251-272`).
  - Save/discard/cancel: `s`/`d` commit their choices, Esc/`c` cancels, resting focus is Cancel.
- **File browser domain rules survive**: the existing suites `components/file_browser/{state,input,render,git_prompt}/tests.rs` are the proof and must stay green unmodified in expectation; add boundary tests only where the widget hand-off created a new seam (e.g. `$HOME` clamp enforced above the widget, `~/.jackin` rejection surfaced as `rejected_reason`, git prompt opening on a repo row with origin lookup pending).
- **Picker family**: per-picker outcome mapping — activating a row in the adopted select/combobox yields the same product outcome enum value as before (`ProviderPickerOutcome`, `GithubOpenPlan`, `SourceChoice`, `ScopeChoice`, `MountDstChoice`, `WorkdirChoice`); existing per-picker `tests.rs` suites stay green.
- **Forms**: masking parity — a `SecretValueDisplay::Plain`/`OpRefPath` row and a `password_input` field render the same masked glyphs as `secret_display` produced; pinned label widths (`editor_rows.rs:17-18`) asserted in the rendered line.
- **Save preview**: semantic rows unchanged — `workspace_save_preview`/`build_workspace_save_lines` outputs are byte-identical pre/post (these functions are untouched; the test pins the contract), and the rendered confirm-save body through the diff widget matches the pre-swap lines.
- Structural pattern to model after: the existing sibling suites, e.g. `components/confirm_save/tests.rs`, `components/role_picker/tests.rs`, `components/file_browser/input/tests.rs`.
- **Verify**: `cargo nextest run -p jackin-console` → all pass, including the new tests; zero insta snapshot diffs.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `cargo xtask ci --fast` exits 0
- [ ] `cargo nextest run -p jackin-console` exits 0; the new `components/dialogs/tests.rs` tests for both spec scenarios exist and pass; all six console text snapshots byte-identical (no `.snap` file modified — `git status` shows none under `crates/jackin-console/src/tui/view/snapshots/`)
- [ ] The PNG-baseline comparison command from plan 005 exits 0 (all 6 stage views + 19 modals pixel-identical)
- [ ] `cargo xtask ci --only snapshots` exits 0 (capsule + console; binds the step-6 shared substrate)
- [ ] Every C6/C7/C8/C10/C11/C19 console consumer site enumerated in Starting state renders through the upstream widget named for its pairing — or the family carries a recorded carve-out in its commit message (behavior-preserving non-adoption), or the plan ended in a misfit BLOCKED row per the hub rule
- [ ] Destructive confirms (`workspace_delete_confirm_state`, `instance_purge_confirm_state`) open No-focused, proven by the new tests; `quit_confirm_state` stays Yes-focused
- [ ] `$HOME` sandbox and git-repo prompt behave per the pre-cutover domain logic, proven by the file_browser suites
- [ ] Product outcome enums (`ProviderPickerOutcome`, `GithubOpenPlan`, `SourceChoice`, `ScopeChoice`, `MountDstChoice`, `WorkdirChoice`, `SaveDiscardChoice`, `SaveChoice`) still live in `crates/jackin-console` — `rg -n "pub enum (ProviderPickerOutcome|GithubOpenPlan|SaveDiscardChoice|SaveChoice)" crates/jackin-console` prints hits
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status rows and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails, or "Starting state" does not match reality (after the sanctioned 005–009 drift re-derivation).
- **Any console text-snapshot diff appears — the hub's parity law: this is a parity break. STOP for operator review; never re-bless, never run with `INSTA_UPDATE`.** Same for any PNG baseline mismatch.
- The upstream safe-default-focus guarantees re-checked in step 1 no longer hold at `29a16b5b`, or any adopted widget cannot reproduce the current UX after consumer configuration is exhausted — mark the row `BLOCKED (termrock API misfit — recommend upstream change: <one line>)` per the hub misfit rule and stop.
- Assumption A5 from the coverage ledger turns out false: a cited upstream API (`alert_dialog`, `confirm_prompt`, `error_state`, `loading_overlay`, `file_picker`, `file_tree`, `path_input`, `select`, `combobox`, `form`, `field_row`, `key_value_table`, `password_input`, `diff`, `link`) is renamed or removed at the pinned rev.
- A step's verification fails twice after a reasonable fix attempt.
- The work requires touching an out-of-scope file (incl. any capsule/launch source, the TermRock checkout, or another plan's territory) or violating a Must NOT.
- `<TERMROCK_CHECKOUT>` is unavailable in any of the replacement-contract forms.

## Maintenance notes

- Plan 012 consumes this plan's C7/C8 step bodies as the `form_wizard` step bodies; keep the adopted widget boundaries clean (product enums at the seam) so the wizard re-hosting is a composition, not a re-port.
- Plan 011's `kbd`/`hint_bar` adoption re-derives footer hints — dialog-state changes here must keep the hint-span constructors (`confirm_hint_spans`, `error_popup_hint_spans`, `confirm_save.rs:241-246`) behaviorally stable or 011 inherits drift.
- Plan 014 runs the final parity proof set and the docs alignment; this plan's commit messages carry the drift notes 014 needs (adopted widgets, recorded carve-outs, non-adoptions like `confirm_prompt`).
- A misfit BLOCKED on any family is a correct outcome: the operator lands the upstream TermRock change, re-pins, and resumes or re-plans; downstream plans 012/014 note the dependency.
- Reviewer scrutiny: the alert-dialog body mapping (fixed risk anatomy vs free-text prompts) is the likeliest silent-drift point — diff the rendered modal text, not just the test names; the `password_input` clipboard policy must be confirmed inert against the OSC 52 copy rules.
- Deferred: `confirm_prompt` adoption (no console call-site-shaped need today); `multi_select`, `data_table`, `preview_card` (no parity-passing call site identified); `file_tree` if the flat listing does not map — each recorded in its family's commit message rather than forced.
