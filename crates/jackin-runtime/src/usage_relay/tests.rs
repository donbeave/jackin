// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

use std::os::unix::fs::MetadataExt as _;
use std::path::Path;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use jackin_protocol::control::{
    FocusedUsageView, QuotaBucketView, UsageConfidence, UsageSeverity, UsageSnapshotStatus,
    UsageSource,
};
use jackin_protocol::usage_broker::UsageRefreshPhase;
use jackin_usage::coordinator::{ProviderProbeOutcome, UsageProviderExecutor};
use jackin_usage::host::ensure_usage_broker_with_executor;
use tokio::io::{AsyncBufReadExt as _, AsyncWriteExt as _};

use super::*;

#[test]
fn usage_mount_uses_only_existing_runtime_directory_for_both_backends() {
    let socket_dir = PathBuf::from("/host/jackin/sockets/fixture");

    let docker = docker_runtime_mount(&socket_dir).unwrap();
    assert_eq!(docker, "/host/jackin/sockets/fixture:/jackin/run");
    assert!(!docker.contains("usage-shared"));

    let apple = apple_runtime_mount(socket_dir.clone());
    assert_eq!(apple.source, socket_dir);
    assert_eq!(apple.target, PathBuf::from("/jackin/run"));
    assert!(!apple.readonly);
    assert!(!apple.source.to_string_lossy().contains("usage-shared"));
}

#[test]
fn forwarded_sources_include_only_provisioned_profiles_and_governed_env() {
    use crate::instance::{
        AgentRuntimeState, AuthProvisionOutcome, GithubProvisionOutcome, ProvisionedAuth, RoleState,
    };
    use jackin_core::Agent;

    let temp = tempfile::tempdir().unwrap();
    let state = RoleState {
        root: temp.path().join("role"),
        gh_config_dir: temp.path().join("role/.config/gh"),
        gh_provision_outcome: GithubProvisionOutcome::Skipped,
        agent_runtime: AgentRuntimeState {
            agent: Agent::Claude,
            model: None,
        },
        auth: ProvisionedAuth::default(),
        auth_outcomes: std::collections::BTreeMap::from([
            (Agent::Claude, AuthProvisionOutcome::Synced),
            (Agent::Codex, AuthProvisionOutcome::HostMissing),
            (Agent::Amp, AuthProvisionOutcome::TokenMode),
        ]),
    };
    let resolved_env = jackin_env::ResolvedEnv {
        vars: vec![
            ("OPENAI_API_KEY".to_owned(), "secret".to_owned()),
            ("UNRELATED".to_owned(), "value".to_owned()),
        ],
    };

    let sources = forwarded_sources_from_launch(&state, &resolved_env);
    assert_eq!(
        sources.profile_surface_ids,
        BTreeSet::from(["claude".to_owned()])
    );
    assert_eq!(
        sources.env_keys,
        BTreeSet::from(["OPENAI_API_KEY".to_owned()])
    );
}

struct CountingExecutor {
    calls: AtomicUsize,
}

impl UsageProviderExecutor for CountingExecutor {
    fn probe(
        &self,
        _capability: &UsageAccountCapability,
        _generation: u64,
    ) -> ProviderProbeOutcome {
        self.calls.fetch_add(1, Ordering::SeqCst);
        ProviderProbeOutcome::success(quota_view())
    }
}

fn capability(account_id: &str) -> UsageAccountCapability {
    UsageAccountCapability {
        account_id: account_id.to_owned(),
        surface_id: "claude".to_owned(),
    }
}

fn quota_view() -> FocusedUsageView {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let mut view = FocusedUsageView::unavailable("claude", i64::try_from(now).unwrap_or(i64::MAX));
    view.status = UsageSnapshotStatus::Fresh;
    view.source = UsageSource::ProviderApi;
    view.confidence = UsageConfidence::Authoritative;
    view.account.provider_label = "Claude".to_owned();
    view.account.account_label = "allowed@example.test".to_owned();
    view.buckets = vec![QuotaBucketView {
        label: "Weekly".to_owned(),
        used_label: None,
        limit_label: None,
        remaining_percent: Some(55),
        reset_label: None,
        resets_at: None,
        status_slot: None,
        pace_label: None,
        status: UsageSnapshotStatus::Fresh,
        used_money: None,
        limit_money: None,
        severity: UsageSeverity::Normal,
    }];
    view
}

#[tokio::test]
async fn usage_relay_authorizes_only_exact_forwarded_account() {
    let temp = tempfile::tempdir().unwrap();
    let executor = Arc::new(CountingExecutor {
        calls: AtomicUsize::new(0),
    });
    let concrete = Arc::clone(&executor);
    let broker_executor: Arc<dyn UsageProviderExecutor> = concrete;
    let broker = ensure_usage_broker_with_executor(
        UsageBrokerConfig::for_data_dir(temp.path().join("data")),
        broker_executor,
    )
    .unwrap();
    let socket = temp.path().join("usage.sock");
    let allowed = capability("allowed");
    let denied = capability("denied");
    let relay = start(socket.clone(), broker, vec![allowed.clone()]).unwrap();

    let denied_response = send(
        &socket,
        UsageBrokerOperation::Refresh {
            capability: denied,
            observed_generation: 0,
            force: true,
        },
    )
    .await;
    let UsageBrokerResponse::Error { error } = denied_response else {
        panic!("denied capability returned state");
    };
    assert_eq!(error.kind, UsageCoordinationErrorKind::Unauthorized);
    assert_eq!(executor.calls.load(Ordering::SeqCst), 0);

    let refresh = send(
        &socket,
        UsageBrokerOperation::Refresh {
            capability: allowed.clone(),
            observed_generation: 0,
            force: true,
        },
    )
    .await;
    let UsageBrokerResponse::State { state } = refresh else {
        panic!("allowed capability returned error");
    };
    let terminal = send(
        &socket,
        UsageBrokerOperation::Join {
            capability: allowed,
            generation: state.generation,
            timeout_ms: 2_000,
        },
    )
    .await;
    let UsageBrokerResponse::State { state } = terminal else {
        panic!("allowed generation join returned error");
    };
    assert_eq!(state.phase, UsageRefreshPhase::Completed);
    assert_eq!(executor.calls.load(Ordering::SeqCst), 1);
    let metadata = fs::metadata(&socket).unwrap();
    assert_eq!(metadata.mode() & 0o777, 0o600);
    relay.abort();
}

#[tokio::test]
async fn usage_relay_binds_through_short_private_symlink() {
    let temp = tempfile::tempdir().unwrap();
    let long_dir = temp.path().join("long-component-".repeat(8));
    fs::create_dir_all(&long_dir).unwrap();
    let short = tempfile::Builder::new()
        .prefix("jackin-usage-test-")
        .tempdir_in("/tmp")
        .unwrap();
    let link = short.path().join("r");
    symlink(&long_dir, &link).unwrap();
    let socket = link.join("usage.sock");
    assert!(long_dir.join("usage.sock").as_os_str().len() >= 104);

    let executor: Arc<dyn UsageProviderExecutor> = Arc::new(CountingExecutor {
        calls: AtomicUsize::new(0),
    });
    let broker = ensure_usage_broker_with_executor(
        UsageBrokerConfig::for_data_dir(temp.path().join("data")),
        executor,
    )
    .unwrap();
    let relay = start(socket, broker, Vec::new()).unwrap();

    assert!(long_dir.join("usage.sock").exists());
    relay.abort();
}

async fn send(socket: &Path, operation: UsageBrokerOperation) -> UsageBrokerResponse {
    let mut stream = UnixStream::connect(socket).await.unwrap();
    let request = UsageBrokerRequest {
        protocol_version: USAGE_BROKER_PROTOCOL_VERSION.to_owned(),
        build_id: env!("CARGO_PKG_VERSION").to_owned(),
        operation,
    };
    let mut bytes = serde_json::to_vec(&request).unwrap();
    bytes.push(b'\n');
    stream.write_all(&bytes).await.unwrap();
    let mut response = Vec::new();
    BufReader::new(stream)
        .read_until(b'\n', &mut response)
        .await
        .unwrap();
    response.pop();
    serde_json::from_slice(&response).unwrap()
}
