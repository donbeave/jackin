// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

//! Per-container allowlisted relay to the host-only usage broker.

use std::collections::BTreeSet;
use std::fs;
use std::os::unix::fs::{PermissionsExt as _, symlink};
use std::path::{Path, PathBuf};
use std::sync::Arc;

use anyhow::{Context as _, Result};
use jackin_config::AppConfig;
use jackin_core::{JackinPaths, UsageCredentialEnvName, WorkspaceName};
use jackin_protocol::usage_broker::{
    USAGE_BROKER_MAX_FRAME_BYTES, USAGE_BROKER_PROTOCOL_VERSION, UsageAccountCapability,
    UsageBrokerOperation, UsageBrokerRequest, UsageBrokerResponse, UsageCoordinationError,
    UsageCoordinationErrorKind,
};
use jackin_usage::coordinator::UsageCapabilitySet;
use jackin_usage::host::{
    CachedProviderCredentialResolver, ForwardedUsageSources, HostSurfaceId,
    ProviderCredentialSecretOutcome, ProviderCredentialSecretResolution,
    ProviderCredentialSecretSource, UsageBrokerClient, UsageBrokerConfig, discover_usage_sources,
    ensure_usage_broker, forwarded_usage_capabilities, validate_usage_sources,
};
use tokio::io::{AsyncBufReadExt as _, AsyncReadExt as _, AsyncWriteExt as _, BufReader};
use tokio::net::{UnixListener, UnixStream};

const RELAY_SOCKET: &str = "usage.sock";

pub(crate) fn docker_runtime_mount(socket_dir: &Path) -> Result<String> {
    let source = socket_dir.to_str().ok_or_else(|| {
        anyhow::anyhow!(
            "socket dir {} contains non-UTF-8 bytes; cannot pass to docker -v",
            socket_dir.display(),
        )
    })?;
    Ok(format!(
        "{source}:{}",
        jackin_core::container_paths::RUN_DIR
    ))
}

pub(crate) fn apple_runtime_mount(
    socket_dir: PathBuf,
) -> crate::apple_container_client::AppleContainerMount {
    crate::apple_container_client::AppleContainerMount::new(
        socket_dir,
        jackin_core::container_paths::RUN_DIR,
        false,
    )
}

#[derive(Default)]
struct RuntimeSecretSource;

impl ProviderCredentialSecretSource for RuntimeSecretSource {
    fn resolve_secret(
        &self,
        config: &AppConfig,
        workspace: Option<&WorkspaceName>,
        role: Option<&str>,
        entry: UsageCredentialEnvName,
    ) -> Option<ProviderCredentialSecretResolution> {
        let declaration =
            jackin_env::lookup_operator_env_declaration(config, role, workspace, entry.name)?;
        let resolved =
            jackin_env::resolve_operator_env_per_key_matching(config, role, workspace, |key| {
                key == entry.name
            })
            .into_iter()
            .next();
        let outcome = match resolved {
            Some(result)
                if result.status() == jackin_env::OperatorEnvKeyStatus::Resolved
                    && result.resolved_value().is_some() =>
            {
                ProviderCredentialSecretOutcome::Resolved(
                    result.resolved_value().unwrap_or_default().to_owned(),
                )
            }
            Some(result) => match result.status() {
                jackin_env::OperatorEnvKeyStatus::Resolved => {
                    ProviderCredentialSecretOutcome::Malformed
                }
                jackin_env::OperatorEnvKeyStatus::Missing => {
                    ProviderCredentialSecretOutcome::Missing
                }
                jackin_env::OperatorEnvKeyStatus::DeniedOrUnavailable => {
                    ProviderCredentialSecretOutcome::Denied
                }
                jackin_env::OperatorEnvKeyStatus::Malformed => {
                    ProviderCredentialSecretOutcome::Malformed
                }
                jackin_env::OperatorEnvKeyStatus::InteractionRequired => {
                    ProviderCredentialSecretOutcome::InteractionRequired
                }
            },
            None => return None,
        };
        Some(ProviderCredentialSecretResolution {
            declaration,
            outcome,
        })
    }
}

/// Host launch facts needed to construct one scoped usage relay.
#[derive(Debug)]
pub struct UsageRelayLaunch<'a> {
    /// Host paths for config, data, and private socket directories.
    pub paths: &'a JackinPaths,
    /// Effective workspace, if this is not an ad-hoc launch.
    pub workspace_name: Option<&'a str>,
    /// Effective role key.
    pub role_key: &'a str,
    /// Exact credential sources proven to enter this Capsule.
    pub forwarded_sources: ForwardedUsageSources,
    /// Per-container host socket directory already mounted at `/jackin/run`.
    pub socket_dir: PathBuf,
}

/// Session-lifetime relay ownership. Drop revokes the socket task.
pub struct UsageRelayGuard {
    task: tokio::task::JoinHandle<()>,
    socket_path: PathBuf,
    _short_path_root: tempfile::TempDir,
}

impl std::fmt::Debug for UsageRelayGuard {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter
            .debug_struct("UsageRelayGuard")
            .finish_non_exhaustive()
    }
}

impl Drop for UsageRelayGuard {
    fn drop(&mut self) {
        self.task.abort();
        drop(fs::remove_file(&self.socket_path));
    }
}

/// Derive source proof from credentials actually provisioned for this launch.
#[must_use]
pub fn forwarded_sources_from_launch(
    state: &crate::instance::RoleState,
    resolved_env: &jackin_env::ResolvedEnv,
) -> ForwardedUsageSources {
    let profile_surface_ids = state
        .auth_outcomes
        .iter()
        .filter(|(_, outcome)| **outcome == crate::instance::AuthProvisionOutcome::Synced)
        .map(|(agent, _)| HostSurfaceId::from_agent(*agent).id().to_owned())
        .collect();
    let env_names = resolved_env
        .vars
        .iter()
        .map(|(name, _)| name.as_str())
        .collect::<BTreeSet<_>>();
    let env_keys = jackin_core::USAGE_CREDENTIAL_ENV_REGISTRY
        .iter()
        .filter(|entry| env_names.contains(entry.name))
        .map(|entry| entry.name.to_owned())
        .collect();
    ForwardedUsageSources {
        profile_surface_ids,
        env_keys,
    }
}

/// Resolve global discovery, ensure the host broker, then start one scoped relay.
/// Broker startup failure remains fail-closed through an unavailable client.
pub async fn prepare_for_container(launch: UsageRelayLaunch<'_>) -> Result<UsageRelayGuard> {
    let paths = launch.paths.clone();
    let workspace_name = launch.workspace_name.map(str::to_owned);
    let role_key = launch.role_key.to_owned();
    let forwarded_sources = launch.forwarded_sources;
    let socket_dir = launch.socket_dir;
    let prepared = jackin_telemetry::spawn::joined_blocking(move || {
        prepare_broker_client(
            &paths,
            workspace_name.as_deref(),
            &role_key,
            &forwarded_sources,
        )
    })
    .await
    .context("usage broker preparation task panicked")?;
    let (client, capabilities) = prepared;
    let short_path_root = tempfile::Builder::new()
        .prefix("jackin-usage-")
        .tempdir_in("/tmp")
        .context("creating short private usage relay path")?;
    let short_socket_dir = short_path_root.path().join("r");
    symlink(&socket_dir, &short_socket_dir)
        .with_context(|| format!("linking short usage relay path to {}", socket_dir.display()))?;
    let socket_path = short_socket_dir.join(RELAY_SOCKET);
    let task = start(socket_path.clone(), client, capabilities)?;
    Ok(UsageRelayGuard {
        task,
        socket_path,
        _short_path_root: short_path_root,
    })
}

fn prepare_broker_client(
    paths: &JackinPaths,
    workspace_name: Option<&str>,
    role_key: &str,
    forwarded_sources: &ForwardedUsageSources,
) -> (UsageBrokerClient, Vec<UsageAccountCapability>) {
    let resolver = Arc::new(CachedProviderCredentialResolver::new(RuntimeSecretSource));
    let scope = jackin_usage::host::UsageDiscoveryScope::HostDesktop {
        config_root: paths.config_dir.clone(),
        operator_home: paths.home_dir.clone(),
    };
    let broker_config = UsageBrokerConfig::for_data_dir(paths.data_dir.clone());
    let fallback = broker_config.client();
    let Ok(catalog) = discover_usage_sources(&scope, resolver.as_ref()) else {
        return (fallback, Vec::new());
    };
    let discovery = validate_usage_sources(catalog, resolver.as_ref());
    let scope_label = workspace_name.map_or_else(
        || format!("role {role_key}"),
        |workspace| format!("workspace {workspace} role {role_key}"),
    );
    let capabilities = forwarded_usage_capabilities(&discovery, &scope_label, forwarded_sources);
    let broker_resolver = Arc::clone(&resolver);
    let broker_resolver: Arc<dyn jackin_usage::host::ProviderCredentialEnvResolver> =
        broker_resolver;
    let client = ensure_usage_broker(broker_config, discovery, broker_resolver)
        .map_or(fallback, |handle| handle.client);
    (client, capabilities)
}

/// Start a relay at an explicit per-container socket path.
pub fn start(
    socket_path: PathBuf,
    broker: UsageBrokerClient,
    capabilities: Vec<UsageAccountCapability>,
) -> Result<tokio::task::JoinHandle<()>> {
    let allowlist = UsageCapabilitySet::new(capabilities);
    drop(fs::remove_file(&socket_path));
    let listener = UnixListener::bind(&socket_path)
        .with_context(|| format!("binding scoped usage relay at {}", socket_path.display()))?;
    fs::set_permissions(&socket_path, fs::Permissions::from_mode(0o600))?;
    Ok(jackin_telemetry::spawn::spawn_stream(
        "usage_relay.connection",
        async move {
            if let Err(_error) = run_listener(listener, broker, allowlist).await {
                let _recorded = jackin_telemetry::record_error(
                    jackin_telemetry::schema::enums::ErrorType::RpcError,
                );
            }
        },
    ))
}

async fn run_listener(
    listener: UnixListener,
    broker: UsageBrokerClient,
    allowlist: UsageCapabilitySet,
) -> Result<()> {
    loop {
        let (stream, _) = listener.accept().await?;
        let broker = broker.clone();
        let allowlist = allowlist.clone();
        drop(jackin_telemetry::spawn::spawn_stream(
            "usage_relay.request",
            async move {
                drop(handle_connection(stream, broker, allowlist).await);
            },
        ));
    }
}

async fn handle_connection(
    stream: UnixStream,
    broker: UsageBrokerClient,
    allowlist: UsageCapabilitySet,
) -> Result<()> {
    let (reader, mut writer) = stream.into_split();
    let mut bytes = Vec::new();
    let mut reader = BufReader::new(reader)
        .take(u64::try_from(USAGE_BROKER_MAX_FRAME_BYTES).unwrap_or(u64::MAX) + 1);
    let read = reader.read_until(b'\n', &mut bytes).await?;
    let response =
        if read == 0 || read > USAGE_BROKER_MAX_FRAME_BYTES || bytes.last() != Some(&b'\n') {
            error_response(UsageCoordinationErrorKind::ProtocolMismatch)
        } else {
            bytes.pop();
            match serde_json::from_slice::<UsageBrokerRequest>(&bytes) {
                Ok(request)
                    if request.protocol_version == USAGE_BROKER_PROTOCOL_VERSION
                        && request.build_id == env!("CARGO_PKG_VERSION") =>
                {
                    dispatch(request.operation, broker, allowlist).await
                }
                _ => error_response(UsageCoordinationErrorKind::ProtocolMismatch),
            }
        };
    let mut response = serde_json::to_vec(&response)?;
    anyhow::ensure!(
        response.len() < USAGE_BROKER_MAX_FRAME_BYTES,
        "response too large"
    );
    response.push(b'\n');
    writer.write_all(&response).await?;
    Ok(())
}

async fn dispatch(
    operation: UsageBrokerOperation,
    broker: UsageBrokerClient,
    allowlist: UsageCapabilitySet,
) -> UsageBrokerResponse {
    let capability = match &operation {
        UsageBrokerOperation::Current { capability }
        | UsageBrokerOperation::Refresh { capability, .. }
        | UsageBrokerOperation::Join { capability, .. } => capability,
    };
    if let Err(error) = allowlist.authorize(capability) {
        return UsageBrokerResponse::Error { error };
    }
    match jackin_telemetry::spawn::joined_blocking(move || broker.execute(operation)).await {
        Ok(Ok(state)) => UsageBrokerResponse::State {
            state: Box::new(state),
        },
        Ok(Err(error)) => UsageBrokerResponse::Error { error },
        Err(_) => error_response(UsageCoordinationErrorKind::Unavailable),
    }
}

fn error_response(kind: UsageCoordinationErrorKind) -> UsageBrokerResponse {
    let message = match kind {
        UsageCoordinationErrorKind::Unauthorized => "usage account capability is not authorized",
        UsageCoordinationErrorKind::ProtocolMismatch => "usage relay protocol mismatch",
        _ => "usage broker is unavailable",
    };
    UsageBrokerResponse::Error {
        error: UsageCoordinationError {
            kind,
            message: message.to_owned(),
        },
    }
}

#[cfg(test)]
mod tests;
