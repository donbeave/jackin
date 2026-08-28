//! End-to-end smoke for the programmatic (`LoadOptions`) launch surface.
//!
//! Drives `jackin_runtime::runtime::load_role` directly — no CLI, no PTY, no
//! `script(1)` — with every launch decision pre-supplied: role selector, agent,
//! account source folder, model, effort, env, pre-approved on-demand bindings,
//! mounts, and force. The launch must run to a started container without
//! opening a single dialog and hand back the instance identity, which the test
//! prints for the host verifier to feed to `jackin status <instance id>`.
//!
//! Unlike `dind_e2e`, this test does not attach: a non-TTY launch has no
//! terminal for the capsule multiplexer, so it leaves the instance running for
//! `jackin hardline` (and for the host part's `jackin status`) to find.

// Expects only apply when the e2e feature compiles the body; without it the
// crate is empty and unfulfilled-expect would fail `cargo clippy -p jackin`.
#![cfg_attr(
    feature = "e2e",
    expect(
        clippy::unwrap_used,
        clippy::panic,
        clippy::disallowed_methods,
        reason = "integration tests: fail-fast fixtures and host-side blocking helpers"
    )
)]
#![cfg(feature = "e2e")]

use std::path::PathBuf;
use std::process::Command;

use jackin_config::{AppConfig, MountConfig, ResolvedWorkspace};
use jackin_core::{Agent, JackinPaths, MountIsolation, ReasoningEffort, RoleSelector};
use jackin_docker::ShellRunner;
use jackin_docker::docker_client::BollardDockerClient;
use jackin_runtime::runtime::{self, LoadOptions};

/// Marker the host verifier greps out of `launch.txt`.
const INSTANCE_ID_MARKER: &str = "LOAD_OPTIONS_INSTANCE_ID";
const ROLE: &str = "the-architect";

fn docker_available() -> bool {
    Command::new("docker")
        .arg("info")
        .output()
        .is_ok_and(|output| output.status.success())
}

/// The account (auth sync source) folder a Claude launch stages from.
fn claude_account_dir() -> Option<PathBuf> {
    let home = std::env::var_os("HOME").map(PathBuf::from)?;
    let dir = home.join(".claude");
    dir.is_dir().then_some(dir)
}

#[tokio::test(flavor = "multi_thread")]
async fn load_options_launch() {
    assert!(
        docker_available(),
        "e2e tests require a running Docker daemon (`docker info` failed)"
    );

    // The operator's real jackin home: the role's trust grant and staged agent
    // auth live there, and it is the same store `jackin status` reads.
    let paths = JackinPaths::detect().expect("jackin paths must resolve");
    paths.ensure_base_dirs().expect("jackin base dirs");
    let mut config = AppConfig::load_or_init(&paths).expect("jackin config must load");
    let selector = RoleSelector::parse(ROLE).expect("role selector must parse");

    // A workspace that is not one of the operator's projects: an empty scratch
    // directory bind-mounted at /workspace.
    let workdir = tempfile::tempdir().expect("workspace tempdir");
    let host_src = workdir
        .path()
        .canonicalize()
        .expect("workspace path must canonicalize");
    let workspace = ResolvedWorkspace {
        name: host_src.display().to_string(),
        label: host_src.display().to_string(),
        workdir: "/workspace".to_owned(),
        mounts: vec![MountConfig {
            src: host_src.display().to_string(),
            dst: "/workspace".to_owned(),
            readonly: false,
            isolation: MountIsolation::Shared,
        }],
        keep_awake_enabled: false,
        default_agent: None,
        git_pull_on_entry: false,
    };

    // Every decision pre-supplied; nothing here may open a dialog.
    let mut opts = LoadOptions::programmatic(Agent::Claude);
    opts.force = true;
    opts.account = claude_account_dir();
    opts.model = Some("claude-opus-5".to_owned());
    opts.effort = Some(ReasoningEffort::Medium);
    opts.env
        .insert("JACKIN_E2E_LOAD_OPTIONS".to_owned(), "1".to_owned());
    opts.extra_mounts = Vec::new();
    opts.on_demand_bindings = Vec::new();

    let docker = BollardDockerClient::connect().expect("docker client must connect");
    let mut runner = ShellRunner { debug: false };

    runtime::load_role(
        &paths,
        &mut config,
        &selector,
        &workspace,
        &docker,
        &mut runner,
        &opts,
    )
    .await
    .expect("programmatic launch of the-architect must succeed without a TTY");

    let launched = opts
        .launched_instance()
        .expect("a programmatic launch must report its instance identity");
    assert!(
        !launched.instance_id.is_empty(),
        "the launch must report a non-empty instance id"
    );
    // Printed, not asserted against a fixture: the host verifier reads this
    // line out of launch.txt and feeds the id to `jackin status`.
    println!("{INSTANCE_ID_MARKER}={}", launched.instance_id);
    println!("LOAD_OPTIONS_CONTAINER_BASE={}", launched.container_base);
}
