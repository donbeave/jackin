// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

//! Tests for `prelude`.
//! Create-wizard tests: the prelude's multi-step modal sequence
//! (`FileBrowserSrc` → `MountDstChoice` → `TextInputDst` → `WorkdirPick` →
//! `TextInputName`) and its step-back / Esc semantics.
use super::super::test_support::key;
use super::{
    PreludeModalOutcome, create_prelude_mount_dst_choice_state, create_prelude_workdir_pick_state,
    create_prelude_workspace_name_input_state, handle_prelude_modal as raw_handle_prelude_modal,
};
use crate::tui::model::{
    CreatePreludeCompletionStatus, CreatePreludeModalStep, create_prelude_completion_status,
};
use crate::tui::state::{FileBrowserTarget, Modal};
use crossterm::event::KeyCode;
use ratatui::layout::Rect;

/// Seed a `CreatePreludeState` whose `MountDstChoice` modal is open
/// for `src`. Mirrors the state the `FileBrowserSrc::Commit` branch of
/// `handle_prelude_modal` leaves the prelude in, without needing to
/// synthesise a `FileBrowser` `Commit(path)` event (no public way to do
/// that cleanly from outside the widget).
fn prelude_with_browser_committed(src: &str) -> crate::tui::state::CreatePreludeState<'static> {
    let mut prelude = crate::tui::state::CreatePreludeState::new();
    prelude.accept_mount_src(std::path::PathBuf::from(src));
    prelude.modal = Some(Modal::MountDstChoice {
        target: FileBrowserTarget::CreateFirstMountSrc,
        state: create_prelude_mount_dst_choice_state(src),
    });
    prelude
}

fn handle_prelude_modal_with_effects(
    prelude: &mut crate::tui::state::CreatePreludeState<'_>,
    key: crossterm::event::KeyEvent,
) {
    let outcome = handle_prelude_modal(prelude, key);
    if !matches!(outcome, PreludeModalOutcome::ReopenFileBrowserAtLastCwd) {
        return;
    }

    let Ok(mut file_browser) = crate::services::file_browser::state_from_home() else {
        prelude.modal = None;
        return;
    };
    if let Some(cwd) = prelude.last_browser_cwd.as_ref() {
        crate::services::file_browser::clamp_state_to_cwd(&mut file_browser, cwd);
    }
    prelude.modal = Some(Modal::FileBrowser {
        target: FileBrowserTarget::CreateFirstMountSrc,
        state: file_browser,
    });
}

fn handle_prelude_modal(
    prelude: &mut crate::tui::state::CreatePreludeState<'_>,
    key: crossterm::event::KeyEvent,
) -> PreludeModalOutcome {
    raw_handle_prelude_modal(prelude, key, Rect::new(0, 0, 120, 40))
}

#[test]
fn prelude_mount_same_path_chains_to_workdir_pick_with_dst_equal_src() {
    // Mount-at-same-path on the choice modal should: (a) set prelude.pending_mount_dst
    // to src, (b) advance the step to PickWorkdir, (c) open the
    // WorkdirPick modal pre-loaded with the staged mount.
    let mut prelude = prelude_with_browser_committed("/home/user/project");
    handle_prelude_modal(&mut prelude, key(KeyCode::Char('m')));

    assert!(
        matches!(prelude.modal, Some(Modal::WorkdirPick { .. })),
        "Mount at same path must chain to WorkdirPick; got {:?}",
        prelude.modal
    );
    assert_eq!(
        prelude.pending_mount_dst.as_deref(),
        Some("/home/user/project"),
        "Mount-at-same-path fast path stores dst = src on the prelude"
    );
    assert!(!prelude.pending_readonly);
    assert!(matches!(
        prelude.step,
        crate::tui::state::CreateStep::PickWorkdir
    ));
}

#[test]
fn prelude_edit_opens_textinput_preserving_chain_to_workdir_pick() {
    // Edit destination on the choice modal must open a TextInput
    // pre-filled with the src (today's flow). The TextInputDst
    // commit branch then advances to WorkdirPick — so this test pins
    // that the Edit-path does not short-circuit; the chain continues
    // through TextInput like before.
    let mut prelude = prelude_with_browser_committed("/home/user/project");
    handle_prelude_modal(&mut prelude, key(KeyCode::Char('e')));

    match &prelude.modal {
        Some(Modal::TextInput { target, .. }) => {
            assert_eq!(target, &crate::tui::state::TextInputTarget::MountDst);
        }
        other => panic!("expected TextInput(MountDst); got {other:?}"),
    }
    // Edit must not itself store a dst — the TextInput commit will.
    assert!(prelude.pending_mount_dst.is_none());
    // The prelude's internal step is still PickFirstMountDst (not
    // advanced yet) — TextInput commit is what calls accept_mount_dst.
    assert!(matches!(
        prelude.step,
        crate::tui::state::CreateStep::PickFirstMountDst
    ));
}

#[test]
fn prelude_cancel_on_mount_dst_choice_rewinds_to_file_browser() {
    // Esc on MountDstChoice must not close the wizard — it must
    // step back to FileBrowserSrc so the operator can pick a
    // different source folder without losing state.
    let mut prelude = prelude_with_browser_committed("/home/user/project");
    handle_prelude_modal_with_effects(&mut prelude, key(KeyCode::Esc));
    assert!(
        matches!(prelude.modal, Some(Modal::FileBrowser { .. })),
        "Esc on MountDstChoice must reopen FileBrowser; got {:?}",
        prelude.modal
    );
    assert!(
        prelude.pending_mount_dst.is_none(),
        "Cancel must not store a dst"
    );
}

#[test]
fn prelude_esc_at_mount_dst_choice_returns_to_file_browser_at_last_cwd() {
    // Step-back from MountDstChoice must reopen FileBrowser seeded at
    // the last cwd the browser was pointing at when src was committed.
    // The FileBrowser root is always `$HOME`, so the restored cwd has
    // to live inside `$HOME` — we use `$HOME` itself which is always
    // a valid target for `set_cwd` to honour.
    let home = directories::BaseDirs::new()
        .map(|b| b.home_dir().to_path_buf())
        .expect("resolve $HOME");

    let mut prelude = crate::tui::state::CreatePreludeState::new();
    prelude.accept_mount_src(home.clone());
    prelude.last_browser_cwd = Some(home.clone());
    prelude.modal = Some(Modal::MountDstChoice {
        target: FileBrowserTarget::CreateFirstMountSrc,
        state: create_prelude_mount_dst_choice_state(home.display().to_string()),
    });

    handle_prelude_modal_with_effects(&mut prelude, key(KeyCode::Esc));

    match &prelude.modal {
        Some(Modal::FileBrowser { state, .. }) => {
            let cwd = state.cwd().to_path_buf();
            assert!(
                cwd == home || cwd.starts_with(&home),
                "FileBrowser should restore a cwd inside $HOME (got {cwd:?})"
            );
        }
        other => panic!("expected FileBrowser, got {other:?}"),
    }
}

#[test]
fn prelude_esc_at_text_input_dst_returns_to_mount_dst_choice() {
    // Tapping "Edit destination" opens TextInputDst; Esc inside that
    // TextInput must rewind to the MountDstChoice modal — not close
    // the wizard.
    let mut prelude = prelude_with_browser_committed("/home/user/project");
    // Choose the Edit branch to open the TextInput.
    handle_prelude_modal(&mut prelude, key(KeyCode::Char('e')));
    assert!(matches!(prelude.modal, Some(Modal::TextInput { .. })));

    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    assert!(
        matches!(prelude.modal, Some(Modal::MountDstChoice { .. })),
        "Esc on TextInputDst must reopen MountDstChoice; got {:?}",
        prelude.modal
    );
}

#[test]
fn prelude_esc_at_workdir_pick_returns_to_mount_dst_choice_fast_path() {
    // When the operator took the mount-at-same-path fast path for dst, Esc on
    // WorkdirPick must step back to MountDstChoice.
    let mut prelude = prelude_with_browser_committed("/home/user/project");
    handle_prelude_modal(&mut prelude, key(KeyCode::Char('m'))); // same path → WorkdirPick
    assert!(matches!(prelude.modal, Some(Modal::WorkdirPick { .. })));

    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    assert!(
        matches!(prelude.modal, Some(Modal::MountDstChoice { .. })),
        "Esc on WorkdirPick (fast-path) must rewind to MountDstChoice; got {:?}",
        prelude.modal
    );
}

#[test]
fn prelude_esc_at_workdir_pick_returns_to_text_input_dst_when_edit_used() {
    // When the operator took the Edit branch, Esc on WorkdirPick must
    // rewind to the TextInputDst step so they can retry the typed dst.
    let mut prelude = prelude_with_browser_committed("/home/user/project");
    handle_prelude_modal(&mut prelude, key(KeyCode::Char('e'))); // open TextInputDst
    // Simulate commit of typed dst (Enter closes TextInput) by
    // advancing the modal directly to WorkdirPick — we only care
    // about `used_edit_dst` state at this point.
    prelude.used_edit_dst = true;
    prelude.accept_mount_dst("/home/user/project".into(), false);
    prelude.modal = Some(Modal::WorkdirPick {
        state: create_prelude_workdir_pick_state(&[jackin_config::MountConfig {
            src: "/home/user/project".into(),
            dst: "/home/user/project".into(),
            readonly: false,
            isolation: jackin_config::MountIsolation::Shared,
        }]),
    });

    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    match &prelude.modal {
        Some(Modal::TextInput { target, .. }) => {
            assert_eq!(target, &crate::tui::state::TextInputTarget::MountDst);
        }
        other => panic!("expected TextInput(MountDst); got {other:?}"),
    }
}

#[test]
fn prelude_esc_at_name_step_returns_to_workdir_pick() {
    // Name is the last step in the wizard — Esc on TextInputName
    // must rewind to WorkdirPick so the operator can change the
    // workdir without abandoning the partial workspace.
    let mut prelude = crate::tui::state::CreatePreludeState::new();
    prelude.accept_mount_src(std::path::PathBuf::from("/home/user/project"));
    prelude.accept_mount_dst("/home/user/project".into(), false);
    prelude.accept_workdir("/home/user/project".into());
    prelude.modal = Some(Modal::TextInput {
        target: crate::tui::state::TextInputTarget::Name,
        state: create_prelude_workspace_name_input_state("project"),
    });

    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    assert!(
        matches!(prelude.modal, Some(Modal::WorkdirPick { .. })),
        "Esc on TextInputName must reopen WorkdirPick; got {:?}",
        prelude.modal
    );
    assert!(prelude.pending_name.is_none(), "Esc must not commit a name");
}

#[test]
fn prelude_esc_at_file_browser_src_returns_to_list() {
    // Step 1 (FileBrowserSrc) has no prior state to restore — Esc
    // must close the modal so the outer dispatcher drops back to
    // the workspace list (today's "cancelled" contract).
    let mut prelude = crate::tui::state::CreatePreludeState::new();
    let fb = crate::tui::components::file_browser::FileBrowserState::from_listing(
        crate::services::file_browser::listing_from_home()
            .expect("file browser should build in test env"),
    );
    prelude.modal = Some(Modal::FileBrowser {
        target: FileBrowserTarget::CreateFirstMountSrc,
        state: fb,
    });

    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    assert!(
        prelude.modal.is_none(),
        "Esc on FileBrowserSrc must close the modal; got {:?}",
        prelude.modal
    );
    assert!(prelude.pending_name.is_none());
}

// ---------------------------------------------------------------------------
// Golden wizard step-walk sequences (plan 012 step 4)
//
// Characterization pins for the boolean-priority step resolver's observable
// behavior, recorded before the FormWizard re-host. Every expected value
// below is a hand-written literal derived from the current arms in
// `input/prelude.rs` (SamePath chain :108-116, Edit :117-127, rewind rules
// :128-134/:152-155/:165-189/:205-209, cancel :79-85) — never recomputed
// through the code under test.
// ---------------------------------------------------------------------------

const GOLDEN_SRC: &str = "/home/user/project";

/// Observable step after a key: which `CreatePreludeModalStep` the open
/// modal maps to, `Other` once the modal is closed.
fn observed_step(prelude: &crate::tui::state::CreatePreludeState<'_>) -> CreatePreludeModalStep {
    prelude
        .modal
        .as_ref()
        .map_or(CreatePreludeModalStep::Other, Modal::create_prelude_step)
}

fn observed_completion(
    prelude: &crate::tui::state::CreatePreludeState<'_>,
) -> CreatePreludeCompletionStatus {
    create_prelude_completion_status(prelude.modal.is_some(), prelude.completed().is_some())
}

fn file_browser_src_prelude() -> crate::tui::state::CreatePreludeState<'static> {
    let mut prelude = crate::tui::state::CreatePreludeState::new();
    let fb = crate::tui::components::file_browser::FileBrowserState::from_listing(
        crate::services::file_browser::listing_from_home()
            .expect("file browser should build in test env"),
    );
    prelude.modal = Some(Modal::FileBrowser {
        target: FileBrowserTarget::CreateFirstMountSrc,
        state: fb,
    });
    prelude
}

#[test]
fn golden_walk_1_same_path_forward_completes() {
    // FileBrowser commit (seeded) → SamePath → WorkdirPick commit →
    // TextInputName commit ⇒ Complete, dst = src, workdir = src,
    // name = dst basename.
    let mut prelude = prelude_with_browser_committed(GOLDEN_SRC);
    let mut steps = vec![observed_step(&prelude)];
    assert_eq!(
        observed_completion(&prelude),
        CreatePreludeCompletionStatus::InProgress
    );

    handle_prelude_modal(&mut prelude, key(KeyCode::Char('m')));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));

    assert_eq!(
        steps,
        [
            CreatePreludeModalStep::MountDstChoice,
            CreatePreludeModalStep::WorkdirPick,
            CreatePreludeModalStep::TextInputName,
            CreatePreludeModalStep::Other,
        ]
    );
    assert_eq!(prelude.pending_mount_dst.as_deref(), Some(GOLDEN_SRC));
    assert!(!prelude.pending_readonly);
    assert!(!prelude.used_edit_dst);
    assert_eq!(prelude.pending_workdir.as_deref(), Some(GOLDEN_SRC));
    assert_eq!(prelude.pending_name.as_deref(), Some("project"));
    assert_eq!(
        observed_completion(&prelude),
        CreatePreludeCompletionStatus::Complete
    );
}

#[test]
fn golden_walk_2_edit_dst_forward_completes() {
    // FileBrowser commit (seeded) → Edit → TextInputDst commit →
    // WorkdirPick commit → TextInputName commit ⇒ Complete.
    let mut prelude = prelude_with_browser_committed(GOLDEN_SRC);
    let mut steps = vec![observed_step(&prelude)];

    handle_prelude_modal(&mut prelude, key(KeyCode::Char('e')));
    steps.push(observed_step(&prelude));
    assert_eq!(
        observed_completion(&prelude),
        CreatePreludeCompletionStatus::InProgress
    );
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));

    assert_eq!(
        steps,
        [
            CreatePreludeModalStep::MountDstChoice,
            CreatePreludeModalStep::TextInputDst,
            CreatePreludeModalStep::WorkdirPick,
            CreatePreludeModalStep::TextInputName,
            CreatePreludeModalStep::Other,
        ]
    );
    assert_eq!(prelude.pending_mount_dst.as_deref(), Some(GOLDEN_SRC));
    assert!(!prelude.pending_readonly);
    assert!(prelude.used_edit_dst);
    assert_eq!(prelude.pending_workdir.as_deref(), Some(GOLDEN_SRC));
    assert_eq!(prelude.pending_name.as_deref(), Some("project"));
    assert_eq!(
        observed_completion(&prelude),
        CreatePreludeCompletionStatus::Complete
    );
}

#[test]
fn golden_walk_3_same_path_full_rewind_cancels() {
    // Walk 1 to TextInputName, then Esc at each step:
    // TextInputName → WorkdirPick → MountDstChoice → FileBrowser (at
    // last cwd) → Esc ⇒ Cancelled.
    let mut prelude = prelude_with_browser_committed(GOLDEN_SRC);
    handle_prelude_modal(&mut prelude, key(KeyCode::Char('m')));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    assert_eq!(
        observed_step(&prelude),
        CreatePreludeModalStep::TextInputName
    );

    let mut steps = Vec::new();
    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));
    handle_prelude_modal_with_effects(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));

    assert_eq!(
        steps,
        [
            CreatePreludeModalStep::WorkdirPick,
            CreatePreludeModalStep::MountDstChoice,
            CreatePreludeModalStep::FileBrowserSrc,
            CreatePreludeModalStep::Other,
        ]
    );
    assert!(
        prelude.pending_name.is_none(),
        "Esc rewinds never commit a name"
    );
    assert_eq!(
        observed_completion(&prelude),
        CreatePreludeCompletionStatus::Cancelled
    );
}

#[test]
fn golden_walk_4_edit_dst_full_rewind_cancels() {
    // Walk 2 to TextInputName, then Esc at each step:
    // TextInputName → WorkdirPick → TextInputDst (used_edit_dst rule) →
    // MountDstChoice → FileBrowser → Esc ⇒ Cancelled.
    let mut prelude = prelude_with_browser_committed(GOLDEN_SRC);
    handle_prelude_modal(&mut prelude, key(KeyCode::Char('e')));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    assert_eq!(
        observed_step(&prelude),
        CreatePreludeModalStep::TextInputName
    );

    let mut steps = Vec::new();
    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));
    handle_prelude_modal_with_effects(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));

    assert_eq!(
        steps,
        [
            CreatePreludeModalStep::WorkdirPick,
            CreatePreludeModalStep::TextInputDst,
            CreatePreludeModalStep::MountDstChoice,
            CreatePreludeModalStep::FileBrowserSrc,
            CreatePreludeModalStep::Other,
        ]
    );
    assert!(prelude.pending_name.is_none());
    assert_eq!(
        observed_completion(&prelude),
        CreatePreludeCompletionStatus::Cancelled
    );
}

#[test]
fn golden_walk_5a_direction_change_edit_branch_matches_uninterrupted() {
    // Forward 2 (Edit → TextInputDst commit), back 1 (Esc →
    // TextInputDst... forward again): the final pending fields are
    // identical to walk 2's.
    let mut prelude = prelude_with_browser_committed(GOLDEN_SRC);
    let mut steps = vec![observed_step(&prelude)];

    handle_prelude_modal(&mut prelude, key(KeyCode::Char('e')));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));
    // Back 1: used_edit_dst rewind lands on TextInputDst.
    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));
    // Forward again to completion.
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));

    assert_eq!(
        steps,
        [
            CreatePreludeModalStep::MountDstChoice,
            CreatePreludeModalStep::TextInputDst,
            CreatePreludeModalStep::WorkdirPick,
            CreatePreludeModalStep::TextInputDst,
            CreatePreludeModalStep::WorkdirPick,
            CreatePreludeModalStep::TextInputName,
            CreatePreludeModalStep::Other,
        ]
    );
    assert_eq!(prelude.pending_mount_dst.as_deref(), Some(GOLDEN_SRC));
    assert!(!prelude.pending_readonly);
    assert!(prelude.used_edit_dst);
    assert_eq!(prelude.pending_workdir.as_deref(), Some(GOLDEN_SRC));
    assert_eq!(prelude.pending_name.as_deref(), Some("project"));
    assert_eq!(
        observed_completion(&prelude),
        CreatePreludeCompletionStatus::Complete
    );
}

#[test]
fn golden_walk_5b_direction_change_same_path_branch_matches_uninterrupted() {
    // Forward 2 (SamePath → WorkdirPick commit), back 1 (Esc →
    // WorkdirPick), forward again: identical to walk 1.
    let mut prelude = prelude_with_browser_committed(GOLDEN_SRC);
    let mut steps = vec![observed_step(&prelude)];

    handle_prelude_modal(&mut prelude, key(KeyCode::Char('m')));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));
    // Back 1: Esc at TextInputName reopens WorkdirPick.
    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));
    steps.push(observed_step(&prelude));
    // Forward again to completion: WorkdirPick commit →
    // TextInputName commit.
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));
    handle_prelude_modal(&mut prelude, key(KeyCode::Enter));
    steps.push(observed_step(&prelude));

    assert_eq!(
        steps,
        [
            CreatePreludeModalStep::MountDstChoice,
            CreatePreludeModalStep::WorkdirPick,
            CreatePreludeModalStep::TextInputName,
            CreatePreludeModalStep::WorkdirPick,
            CreatePreludeModalStep::TextInputName,
            CreatePreludeModalStep::Other,
        ]
    );
    assert_eq!(prelude.pending_mount_dst.as_deref(), Some(GOLDEN_SRC));
    assert!(!prelude.pending_readonly);
    assert!(!prelude.used_edit_dst);
    assert_eq!(prelude.pending_workdir.as_deref(), Some(GOLDEN_SRC));
    assert_eq!(prelude.pending_name.as_deref(), Some("project"));
    assert_eq!(
        observed_completion(&prelude),
        CreatePreludeCompletionStatus::Complete
    );
}

#[test]
fn golden_walk_6_esc_at_file_browser_src_cancels() {
    // Esc at step 1 (FileBrowserSrc) cancels the whole prelude.
    let mut prelude = file_browser_src_prelude();
    assert_eq!(
        observed_step(&prelude),
        CreatePreludeModalStep::FileBrowserSrc
    );

    handle_prelude_modal(&mut prelude, key(KeyCode::Esc));

    assert_eq!(observed_step(&prelude), CreatePreludeModalStep::Other);
    assert!(prelude.pending_mount_src.is_none());
    assert_eq!(
        observed_completion(&prelude),
        CreatePreludeCompletionStatus::Cancelled
    );
}
