// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

#![cfg(feature = "e2e")]

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::Arc;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use jackin_protocol::control::{
    FocusedUsageView, QuotaBucketView, UsageConfidence, UsageSeverity, UsageSnapshotStatus,
    UsageSource,
};
use jackin_protocol::usage_broker::UsageCoordinationErrorKind;
use jackin_protocol::usage_broker::{UsageAccountCapability, UsageRefreshPhase};
use jackin_usage::coordinator::{ProviderProbeOutcome, UsageProviderExecutor};
use jackin_usage::host::{UsageBrokerConfig, ensure_usage_broker_with_executor};

const CHILD_ENV: &str = "JACKIN_USAGE_BROKER_E2E_CHILD";
const ROOT_ENV: &str = "JACKIN_USAGE_BROKER_E2E_ROOT";
const CLIENTS: usize = 20;
static PROCESS_CALLS: AtomicUsize = AtomicUsize::new(0);

struct FileCountingProvider {
    root: PathBuf,
}

impl UsageProviderExecutor for FileCountingProvider {
    fn probe(
        &self,
        _capability: &UsageAccountCapability,
        _generation: u64,
    ) -> ProviderProbeOutcome {
        let call = PROCESS_CALLS.fetch_add(1, Ordering::SeqCst);
        if fs::write(
            self.root
                .join(format!("provider-call-{}-{call}", std::process::id())),
            b"called\n",
        )
        .is_err()
        {
            return ProviderProbeOutcome::Failure {
                kind: UsageCoordinationErrorKind::ProviderUnavailable,
                message: "fake provider counter is unavailable".to_owned(),
                retry_at_epoch: None,
            };
        }
        std::thread::park_timeout(Duration::from_millis(100));
        ProviderProbeOutcome::success(quota_view())
    }
}

fn capability() -> UsageAccountCapability {
    UsageAccountCapability {
        account_id: "shared-account".to_owned(),
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
    view.account.account_label = "shared@example.test".to_owned();
    view.buckets = vec![QuotaBucketView {
        label: "Weekly".to_owned(),
        used_label: None,
        limit_label: None,
        remaining_percent: Some(64),
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

#[test]
fn usage_broker_child() {
    let Ok(child) = std::env::var(CHILD_ENV) else {
        return;
    };
    let root = PathBuf::from(std::env::var_os(ROOT_ENV).unwrap());
    fs::write(root.join(format!("ready-{child}")), b"ready\n").unwrap();
    wait_until(Duration::from_secs(10), || root.join("go").exists());

    let executor: Arc<dyn UsageProviderExecutor> =
        Arc::new(FileCountingProvider { root: root.clone() });
    let client = ensure_usage_broker_with_executor(
        UsageBrokerConfig::for_data_dir(root.join("data")),
        executor,
    )
    .unwrap();
    let state = client.refresh(capability(), 0, true).unwrap();
    let terminal = client
        .join(capability(), state.generation, Duration::from_secs(5))
        .unwrap();
    assert_eq!(terminal.generation, 1);
    assert_eq!(terminal.phase, UsageRefreshPhase::Completed);
    fs::write(root.join(format!("done-{child}")), b"done\n").unwrap();
    wait_until(Duration::from_secs(10), || {
        entries_with_prefix(&root, "done-") == CLIENTS
    });
}

#[test]
fn usage_broker_twenty_host_processes_make_one_provider_call() {
    let temp = tempfile::tempdir().unwrap();
    let root = temp.path();
    let executable = std::env::current_exe().unwrap();
    let mut children = Vec::new();
    for child in 0..CLIENTS {
        children.push(
            Command::new(&executable)
                .arg("--exact")
                .arg("usage_broker_child")
                .arg("--nocapture")
                .env(CHILD_ENV, child.to_string())
                .env(ROOT_ENV, root)
                .spawn()
                .unwrap(),
        );
    }
    wait_until(Duration::from_secs(10), || {
        entries_with_prefix(root, "ready-") == CLIENTS
    });
    fs::write(root.join("go"), b"go\n").unwrap();
    for mut child in children {
        assert!(child.wait().unwrap().success());
    }
    assert_eq!(entries_with_prefix(root, "provider-call-"), 1);
}

fn wait_until(timeout: Duration, condition: impl Fn() -> bool) {
    let started = Instant::now();
    while !condition() {
        assert!(started.elapsed() < timeout, "timed out waiting for barrier");
        std::thread::park_timeout(Duration::from_millis(10));
    }
}

fn entries_with_prefix(root: &Path, prefix: &str) -> usize {
    let Ok(entries) = fs::read_dir(root) else {
        return 0;
    };
    entries
        .filter_map(Result::ok)
        .filter(|entry| entry.file_name().to_string_lossy().starts_with(prefix))
        .count()
}
