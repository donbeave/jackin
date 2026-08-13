// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

//! Host-only usage broker lifecycle and bounded Unix-socket transport.

use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Read, Write};
use std::os::unix::fs::{MetadataExt as _, PermissionsExt as _};
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::{Duration, Instant};

use jackin_protocol::control::UsageSnapshotStatus;
use jackin_protocol::usage_broker::{
    USAGE_BROKER_MAX_FRAME_BYTES, USAGE_BROKER_PROTOCOL_VERSION, UsageAccountCapability,
    UsageBrokerOperation, UsageBrokerRequest, UsageBrokerResponse, UsageCoordinationError,
    UsageCoordinationErrorKind, UsageGenerationView,
};
use nix::fcntl::{OFlag, open, openat};
use nix::sys::signal::kill;
use nix::sys::stat::{Mode, fchmod, mkdirat};
use nix::unistd::{Pid, geteuid};

use crate::coordinator::{
    FileAccountStateStore, ProviderProbeOutcome, UsageCoordinator, UsageCoordinatorConfig,
    UsageProviderExecutor,
};

use super::ValidatedUsageDiscovery;
use super::discovery::{
    ProviderCredentialEnvResolver, ProviderCredentialRefreshOutcome, ValidatedCredentialBinding,
    refresh_credential_binding,
};

const BROKER_DIR: &str = "usage-broker";
const BROKER_RUN_DIR: &str = "run";
const BROKER_SOCKET: &str = "usage-broker.sock";
const BROKER_LEADER: &str = "leader.pid";
const CONNECT_RETRY: Duration = Duration::from_secs(2);
const CONNECT_RETRY_STEP: Duration = Duration::from_millis(20);

/// Host broker filesystem and handshake configuration.
#[derive(Debug, Clone)]
pub struct UsageBrokerConfig {
    /// Host-only jackin data directory. Never mounted into a Capsule.
    pub data_dir: PathBuf,
    /// Exact caller build identifier.
    pub build_id: String,
    /// Bounded refresh scheduling policy.
    pub coordinator: UsageCoordinatorConfig,
}

impl UsageBrokerConfig {
    /// Build production defaults for one host data directory.
    #[must_use]
    pub fn for_data_dir(data_dir: PathBuf) -> Self {
        Self {
            data_dir,
            build_id: env!("CARGO_PKG_VERSION").to_owned(),
            coordinator: UsageCoordinatorConfig::default(),
        }
    }

    fn socket_path(&self) -> PathBuf {
        self.data_dir
            .join(BROKER_DIR)
            .join(BROKER_RUN_DIR)
            .join(BROKER_SOCKET)
    }
}

/// Attached broker plus every host-discovered canonical capability.
#[derive(Debug, Clone)]
pub struct UsageBrokerHandle {
    /// Host-only transport client.
    pub client: UsageBrokerClient,
    /// Canonical accounts known to this discovery generation.
    pub capabilities: Vec<UsageAccountCapability>,
}

/// Small synchronous client. Each operation uses one bounded frame/connection.
#[derive(Debug, Clone)]
pub struct UsageBrokerClient {
    socket_path: PathBuf,
    build_id: String,
}

impl UsageBrokerClient {
    /// Attach to an already-running broker socket.
    #[must_use]
    pub fn at(socket_path: PathBuf, build_id: String) -> Self {
        Self {
            socket_path,
            build_id,
        }
    }

    /// Read one account generation without provider work.
    pub fn current(
        &self,
        capability: UsageAccountCapability,
    ) -> Result<UsageGenerationView, UsageCoordinationError> {
        self.request(UsageBrokerOperation::Current { capability })
    }

    /// Request or join one account generation.
    pub fn refresh(
        &self,
        capability: UsageAccountCapability,
        observed_generation: u64,
        force: bool,
    ) -> Result<UsageGenerationView, UsageCoordinationError> {
        self.request(UsageBrokerOperation::Refresh {
            capability,
            observed_generation,
            force,
        })
    }

    /// Wait for one named generation. This does not release broker ownership on timeout.
    pub fn join(
        &self,
        capability: UsageAccountCapability,
        generation: u64,
        timeout: Duration,
    ) -> Result<UsageGenerationView, UsageCoordinationError> {
        let timeout_ms = u64::try_from(timeout.as_millis()).unwrap_or(u64::MAX);
        self.request(UsageBrokerOperation::Join {
            capability,
            generation,
            timeout_ms,
        })
    }

    fn request(
        &self,
        operation: UsageBrokerOperation,
    ) -> Result<UsageGenerationView, UsageCoordinationError> {
        let request = UsageBrokerRequest {
            protocol_version: USAGE_BROKER_PROTOCOL_VERSION.to_owned(),
            build_id: self.build_id.clone(),
            operation,
        };
        let mut bytes = serde_json::to_vec(&request).map_err(|_| unavailable())?;
        if bytes.len() >= USAGE_BROKER_MAX_FRAME_BYTES {
            return Err(protocol_error());
        }
        bytes.push(b'\n');
        let mut stream = UnixStream::connect(&self.socket_path).map_err(|_| unavailable())?;
        stream
            .set_read_timeout(Some(Duration::from_secs(30)))
            .map_err(|_| unavailable())?;
        stream.write_all(&bytes).map_err(|_| unavailable())?;
        stream
            .shutdown(std::net::Shutdown::Write)
            .map_err(|_| unavailable())?;
        let response = read_frame::<UsageBrokerResponse>(&mut stream)?;
        match response {
            UsageBrokerResponse::State { state } => Ok(*state),
            UsageBrokerResponse::Error { error } => Err(error),
        }
    }
}

struct DiscoveryProviderExecutor {
    bindings: BTreeMap<UsageAccountCapability, ValidatedCredentialBinding>,
    resolver: Arc<dyn ProviderCredentialEnvResolver>,
}

impl UsageProviderExecutor for DiscoveryProviderExecutor {
    fn probe(&self, capability: &UsageAccountCapability, _generation: u64) -> ProviderProbeOutcome {
        let Some(binding) = self.bindings.get(capability) else {
            return ProviderProbeOutcome::Failure {
                kind: UsageCoordinationErrorKind::Unauthorized,
                message: "usage account capability is not authorized".to_owned(),
                retry_at_epoch: None,
            };
        };
        match refresh_credential_binding(binding, self.resolver.as_ref()) {
            ProviderCredentialRefreshOutcome::Snapshot(view) => match view.status {
                UsageSnapshotStatus::NeedsSecret | UsageSnapshotStatus::NeedsLogin => {
                    ProviderProbeOutcome::Failure {
                        kind: UsageCoordinationErrorKind::NeedsSecret,
                        message: "usage provider credentials require operator action".to_owned(),
                        retry_at_epoch: None,
                    }
                }
                UsageSnapshotStatus::Unavailable | UsageSnapshotStatus::Unsupported => {
                    ProviderProbeOutcome::Failure {
                        kind: UsageCoordinationErrorKind::ProviderUnavailable,
                        message: "usage provider quota is unavailable".to_owned(),
                        retry_at_epoch: None,
                    }
                }
                _ => ProviderProbeOutcome::success(*view),
            },
            ProviderCredentialRefreshOutcome::Missing
            | ProviderCredentialRefreshOutcome::Denied
            | ProviderCredentialRefreshOutcome::InteractionRequired => {
                ProviderProbeOutcome::Failure {
                    kind: UsageCoordinationErrorKind::NeedsSecret,
                    message: "usage provider credentials require operator action".to_owned(),
                    retry_at_epoch: None,
                }
            }
            ProviderCredentialRefreshOutcome::Malformed => ProviderProbeOutcome::Failure {
                kind: UsageCoordinationErrorKind::ProviderUnavailable,
                message: "usage provider response is unavailable".to_owned(),
                retry_at_epoch: None,
            },
        }
    }
}

/// Ensure one host broker backed by the validated Rust discovery generation.
pub fn ensure_usage_broker(
    config: UsageBrokerConfig,
    discovery: ValidatedUsageDiscovery,
    resolver: Arc<dyn ProviderCredentialEnvResolver>,
) -> Result<UsageBrokerHandle, UsageCoordinationError> {
    let mut bindings = BTreeMap::new();
    for binding in discovery.bindings {
        let capability = capability_for_binding(&binding);
        bindings.entry(capability).or_insert(binding);
    }
    let capabilities = bindings.keys().cloned().collect();
    let executor = Arc::new(DiscoveryProviderExecutor { bindings, resolver });
    let client = ensure_usage_broker_with_executor(config, executor)?;
    Ok(UsageBrokerHandle {
        client,
        capabilities,
    })
}

/// Test/runtime seam that preserves the same process election and transport.
#[doc(hidden)]
pub fn ensure_usage_broker_with_executor(
    config: UsageBrokerConfig,
    executor: Arc<dyn UsageProviderExecutor>,
) -> Result<UsageBrokerClient, UsageCoordinationError> {
    let socket_path = config.socket_path();
    let client = UsageBrokerClient::at(socket_path.clone(), config.build_id.clone());
    if connect_probe(&client) {
        return Ok(client);
    }

    let run_dir = secure_run_directory(&config.data_dir)?;
    let leader_path = run_dir.join(BROKER_LEADER);
    if !claim_leader(&leader_path)? {
        wait_for_leader(&client)?;
        return Ok(client);
    }

    if socket_path.exists() {
        fs::remove_file(&socket_path).map_err(|_| unavailable())?;
    }
    let listener = UnixListener::bind(&socket_path).map_err(|_| unavailable())?;
    fs::set_permissions(&socket_path, fs::Permissions::from_mode(0o600))
        .map_err(|_| unavailable())?;
    validate_owned_mode(&socket_path, 0o600)?;
    let store = Arc::new(FileAccountStateStore::under_data_dir(&config.data_dir));
    let coordinator = Arc::new(UsageCoordinator::new(executor, store, config.coordinator));
    let build_id = config.build_id.clone();
    jackin_telemetry::spawn::thread_joined_named("usage-broker".to_owned(), move || {
        serve(listener, coordinator, &build_id);
    })
    .map_err(|_| unavailable())?;
    wait_for_leader(&client)?;
    Ok(client)
}

fn serve(listener: UnixListener, coordinator: Arc<UsageCoordinator>, build_id: &str) {
    for incoming in listener.incoming() {
        let Ok(mut stream) = incoming else {
            continue;
        };
        let response = match read_frame::<UsageBrokerRequest>(&mut stream) {
            Ok(request) => dispatch(&coordinator, request, build_id),
            Err(error) => UsageBrokerResponse::Error { error },
        };
        if let Ok(mut bytes) = serde_json::to_vec(&response)
            && bytes.len() < USAGE_BROKER_MAX_FRAME_BYTES
        {
            bytes.push(b'\n');
            let _write_result = stream.write_all(&bytes);
        }
    }
}

fn dispatch(
    coordinator: &UsageCoordinator,
    request: UsageBrokerRequest,
    build_id: &str,
) -> UsageBrokerResponse {
    if request.protocol_version != USAGE_BROKER_PROTOCOL_VERSION || request.build_id != build_id {
        return UsageBrokerResponse::Error {
            error: protocol_error(),
        };
    }
    let now = chrono::Utc::now().timestamp();
    let result = match request.operation {
        UsageBrokerOperation::Current { capability } => coordinator.current(&capability, now),
        UsageBrokerOperation::Refresh {
            capability,
            observed_generation,
            force,
        } => coordinator.request_refresh(&capability, observed_generation, force, now),
        UsageBrokerOperation::Join {
            capability,
            generation,
            timeout_ms,
        } => coordinator.join_generation(
            &capability,
            generation,
            Duration::from_millis(timeout_ms.min(30_000)),
            now,
        ),
    };
    match result {
        Ok(state) => UsageBrokerResponse::State {
            state: Box::new(state),
        },
        Err(error) => UsageBrokerResponse::Error { error },
    }
}

fn read_frame<T: serde::de::DeserializeOwned>(
    stream: &mut UnixStream,
) -> Result<T, UsageCoordinationError> {
    let mut reader = BufReader::new(stream);
    let mut bytes = Vec::new();
    let read = reader
        .by_ref()
        .take(u64::try_from(USAGE_BROKER_MAX_FRAME_BYTES).unwrap_or(u64::MAX) + 1)
        .read_until(b'\n', &mut bytes)
        .map_err(|_| unavailable())?;
    if read == 0 || read > USAGE_BROKER_MAX_FRAME_BYTES || bytes.last() != Some(&b'\n') {
        return Err(protocol_error());
    }
    bytes.pop();
    serde_json::from_slice(&bytes).map_err(|_| protocol_error())
}

fn secure_run_directory(data_dir: &Path) -> Result<PathBuf, UsageCoordinationError> {
    fs::create_dir_all(data_dir).map_err(|_| unavailable())?;
    let data_fd = open(
        data_dir,
        OFlag::O_RDONLY | OFlag::O_DIRECTORY | OFlag::O_NOFOLLOW,
        Mode::empty(),
    )
    .map_err(|_| unavailable())?;
    let data = File::from(data_fd);
    validate_owned_base_directory(&data)?;
    let broker = private_child_directory(&data, BROKER_DIR)?;
    let run = private_child_directory(&broker, BROKER_RUN_DIR)?;
    drop(run);
    Ok(data_dir.join(BROKER_DIR).join(BROKER_RUN_DIR))
}

fn private_child_directory(parent: &File, name: &str) -> Result<File, UsageCoordinationError> {
    match mkdirat(parent, name, Mode::from_bits_truncate(0o700)) {
        Ok(()) | Err(nix::errno::Errno::EEXIST) => {}
        Err(_) => return Err(unavailable()),
    }
    let fd = openat(
        parent,
        name,
        OFlag::O_RDONLY | OFlag::O_DIRECTORY | OFlag::O_NOFOLLOW,
        Mode::empty(),
    )
    .map_err(|_| unavailable())?;
    let directory = File::from(fd);
    fchmod(&directory, Mode::from_bits_truncate(0o700)).map_err(|_| unavailable())?;
    validate_owned_directory(&directory)?;
    Ok(directory)
}

fn validate_owned_directory(directory: &File) -> Result<(), UsageCoordinationError> {
    let metadata = directory.metadata().map_err(|_| unavailable())?;
    if !metadata.is_dir()
        || metadata.uid() != geteuid().as_raw()
        || metadata.mode() & 0o777 != 0o700
    {
        return Err(unavailable());
    }
    Ok(())
}

fn validate_owned_base_directory(directory: &File) -> Result<(), UsageCoordinationError> {
    let metadata = directory.metadata().map_err(|_| unavailable())?;
    if !metadata.is_dir() || metadata.uid() != geteuid().as_raw() || metadata.mode() & 0o022 != 0 {
        return Err(unavailable());
    }
    Ok(())
}

fn validate_owned_mode(path: &Path, mode: u32) -> Result<(), UsageCoordinationError> {
    let metadata = fs::symlink_metadata(path).map_err(|_| unavailable())?;
    if metadata.file_type().is_symlink()
        || metadata.uid() != geteuid().as_raw()
        || metadata.mode() & 0o777 != mode
    {
        return Err(unavailable());
    }
    Ok(())
}

fn claim_leader(path: &Path) -> Result<bool, UsageCoordinationError> {
    match open(
        path,
        OFlag::O_WRONLY | OFlag::O_CREAT | OFlag::O_EXCL | OFlag::O_NOFOLLOW,
        Mode::from_bits_truncate(0o600),
    ) {
        Ok(fd) => {
            let mut file = File::from(fd);
            writeln!(file, "{}", std::process::id()).map_err(|_| unavailable())?;
            file.sync_all().map_err(|_| unavailable())?;
            Ok(true)
        }
        Err(nix::errno::Errno::EEXIST) => {
            validate_owned_mode(path, 0o600)?;
            let pid = fs::read_to_string(path)
                .ok()
                .and_then(|value| value.trim().parse::<i32>().ok());
            if pid.is_some_and(|pid| kill(Pid::from_raw(pid), None).is_ok()) {
                return Ok(false);
            }
            fs::remove_file(path).map_err(|_| unavailable())?;
            claim_leader(path)
        }
        Err(_) => Err(unavailable()),
    }
}

fn wait_for_leader(client: &UsageBrokerClient) -> Result<(), UsageCoordinationError> {
    let started = Instant::now();
    while started.elapsed() < CONNECT_RETRY {
        if connect_probe(client) {
            return Ok(());
        }
        std::thread::park_timeout(CONNECT_RETRY_STEP);
    }
    Err(unavailable())
}

fn connect_probe(client: &UsageBrokerClient) -> bool {
    UnixStream::connect(&client.socket_path).is_ok()
}

fn capability_for_binding(binding: &ValidatedCredentialBinding) -> UsageAccountCapability {
    let subject = if let Some(identity) = &binding.identity {
        identity.account_key()
    } else {
        format!("bootstrap:{}", binding.source_id)
    };
    let hashed = jackin_core::account_key_hash(binding.surface.id(), &subject);
    let account_id = hashed.strip_prefix("sha256:").unwrap_or(&hashed).to_owned();
    UsageAccountCapability {
        account_id,
        surface_id: binding.surface.id().to_owned(),
    }
}

fn unavailable() -> UsageCoordinationError {
    UsageCoordinationError {
        kind: UsageCoordinationErrorKind::Unavailable,
        message: "usage broker is unavailable".to_owned(),
    }
}

fn protocol_error() -> UsageCoordinationError {
    UsageCoordinationError {
        kind: UsageCoordinationErrorKind::ProtocolMismatch,
        message: "usage broker protocol mismatch".to_owned(),
    }
}

#[cfg(test)]
mod tests;
