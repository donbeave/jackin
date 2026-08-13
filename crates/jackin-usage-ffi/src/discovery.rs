// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

//! Tier-4 adapter joining config attribution, env/1Password resolution, and
//! the tier-3 usage discovery port. Secrets remain process-local here.

use std::sync::Mutex;

use jackin_config::AppConfig;
use jackin_core::{EnvValue, UsageCredentialEnvName, UsageCredentialOwner, WorkspaceName};
use jackin_usage::host::{
    HostSurfaceId, OpaqueCredentialHandle, ProviderCredentialEnvOutcome,
    ProviderCredentialEnvResolution, ProviderCredentialEnvResolver,
    ProviderCredentialRefreshOutcome,
};

struct CachedResolution {
    key: String,
    owner: UsageCredentialOwner,
    declaration: EnvValue,
    handle: Option<OpaqueCredentialHandle>,
    secret: Option<String>,
    outcome: ProviderCredentialEnvOutcome,
}

#[derive(Default)]
struct ResolverState {
    next_handle: u64,
    cache: Vec<CachedResolution>,
}

/// Process-scoped protected-source resolver used by the Desktop bridge.
#[derive(Default)]
pub(crate) struct DesktopCredentialResolver {
    state: Mutex<ResolverState>,
}

impl DesktopCredentialResolver {
    fn resolve_one(
        &self,
        config: &AppConfig,
        workspace: Option<&WorkspaceName>,
        role: Option<&str>,
        entry: UsageCredentialEnvName,
    ) -> Option<ProviderCredentialEnvResolution> {
        let declaration =
            jackin_env::lookup_operator_env_declaration(config, role, workspace, entry.name)?;
        let mut state = self
            .state
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner);
        if let Some(cached) = state
            .cache
            .iter()
            .find(|cached| cached.key == entry.name && cached.declaration == declaration)
        {
            return Some(ProviderCredentialEnvResolution {
                key: entry.name.to_owned(),
                outcome: cached.outcome.clone(),
            });
        }

        let resolved =
            jackin_env::resolve_operator_env_per_key_matching(config, role, workspace, |key| {
                key == entry.name
            })
            .into_iter()
            .next();
        let (outcome, secret, handle) = match resolved {
            Some(result)
                if result.status() == jackin_env::OperatorEnvKeyStatus::Resolved
                    && result.resolved_value().is_some() =>
            {
                let secret = result.resolved_value().unwrap_or_default().to_owned();
                let reused = state.cache.iter().find_map(|cached| {
                    (cached.owner == entry.owner && cached.secret.as_deref() == Some(&secret))
                        .then(|| cached.handle.clone())
                        .flatten()
                });
                let handle = reused.unwrap_or_else(|| {
                    state.next_handle = state.next_handle.saturating_add(1);
                    OpaqueCredentialHandle::new(format!("credential-{}", state.next_handle))
                });
                (
                    ProviderCredentialEnvOutcome::Resolved(handle.clone()),
                    Some(secret),
                    Some(handle),
                )
            }
            Some(result) => {
                let outcome = match result.status() {
                    jackin_env::OperatorEnvKeyStatus::Resolved => {
                        ProviderCredentialEnvOutcome::Malformed
                    }
                    jackin_env::OperatorEnvKeyStatus::Missing => {
                        ProviderCredentialEnvOutcome::Missing
                    }
                    jackin_env::OperatorEnvKeyStatus::DeniedOrUnavailable => {
                        ProviderCredentialEnvOutcome::Denied
                    }
                    jackin_env::OperatorEnvKeyStatus::Malformed => {
                        ProviderCredentialEnvOutcome::Malformed
                    }
                    jackin_env::OperatorEnvKeyStatus::InteractionRequired => {
                        ProviderCredentialEnvOutcome::InteractionRequired
                    }
                };
                (outcome, None, None)
            }
            None => return None,
        };
        state.cache.push(CachedResolution {
            key: entry.name.to_owned(),
            owner: entry.owner,
            declaration,
            handle,
            secret,
            outcome: outcome.clone(),
        });
        Some(ProviderCredentialEnvResolution {
            key: entry.name.to_owned(),
            outcome,
        })
    }
}

impl ProviderCredentialEnvResolver for DesktopCredentialResolver {
    fn begin_manual_retry(&self) {
        let mut state = self
            .state
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner);
        state
            .cache
            .retain(|cached| matches!(cached.outcome, ProviderCredentialEnvOutcome::Resolved(_)));
    }

    fn resolve_provider_credentials(
        &self,
        config: &AppConfig,
        workspace: Option<&WorkspaceName>,
        role: Option<&str>,
        keys: &[UsageCredentialEnvName],
    ) -> Vec<ProviderCredentialEnvResolution> {
        keys.iter()
            .filter_map(|entry| self.resolve_one(config, workspace, role, *entry))
            .collect()
    }

    fn identify_provider_credential(
        &self,
        _surface: HostSurfaceId,
        _handle: &OpaqueCredentialHandle,
    ) -> jackin_usage::host::ProviderCredentialIdentityOutcome {
        // API-key surfaces generally reveal identity only in their quota
        // response. The opaque handle still deduplicates reads/refresh work.
        jackin_usage::host::ProviderCredentialIdentityOutcome::Anonymous
    }

    fn refresh_provider_credential(
        &self,
        surface: HostSurfaceId,
        key: &str,
        handle: &OpaqueCredentialHandle,
    ) -> ProviderCredentialRefreshOutcome {
        let secret = {
            let state = self
                .state
                .lock()
                .unwrap_or_else(std::sync::PoisonError::into_inner);
            state.cache.iter().find_map(|cached| {
                (cached.key == key && cached.handle.as_ref() == Some(handle))
                    .then(|| cached.secret.clone())
                    .flatten()
            })
        };
        let Some(secret) = secret else {
            return ProviderCredentialRefreshOutcome::Missing;
        };
        ProviderCredentialRefreshOutcome::Snapshot(Box::new(
            jackin_usage::usage::provider_credential_snapshot(surface.id(), key, &secret),
        ))
    }
}

#[cfg(test)]
mod tests;
