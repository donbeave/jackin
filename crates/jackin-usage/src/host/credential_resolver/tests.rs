// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

use std::sync::atomic::{AtomicUsize, Ordering};

use super::*;

#[derive(Default)]
struct CountingSecretSource {
    resolutions: AtomicUsize,
}

impl ProviderCredentialSecretSource for CountingSecretSource {
    fn lookup_declaration(
        &self,
        config: &AppConfig,
        _workspace: Option<&WorkspaceName>,
        _role: Option<&str>,
        entry: UsageCredentialEnvName,
    ) -> Option<EnvValue> {
        config.env.get(entry.name).cloned()
    }

    fn resolve_secret(
        &self,
        config: &AppConfig,
        _workspace: Option<&WorkspaceName>,
        _role: Option<&str>,
        entry: UsageCredentialEnvName,
    ) -> Option<ProviderCredentialSecretResolution> {
        self.resolutions.fetch_add(1, Ordering::Relaxed);
        Some(ProviderCredentialSecretResolution {
            declaration: config.env.get(entry.name)?.clone(),
            outcome: ProviderCredentialSecretOutcome::Resolved("fixture-secret".to_owned()),
        })
    }
}

#[test]
fn disc_source_cache_skips_duplicate_protected_resolution() {
    let mut config = AppConfig::default();
    config.env.insert(
        "ZAI_API_KEY".to_owned(),
        EnvValue::Plain("fixture-declaration".to_owned()),
    );
    let resolver = CachedProviderCredentialResolver::new(CountingSecretSource::default());
    let entry = UsageCredentialEnvName {
        name: "ZAI_API_KEY",
        owner: UsageCredentialOwner::Zai,
    };

    let first = resolver.resolve_provider_credentials(&config, None, None, &[entry]);
    let second = resolver.resolve_provider_credentials(&config, None, None, &[entry]);

    assert_eq!(first, second);
    assert_eq!(resolver.source.resolutions.load(Ordering::Relaxed), 1);
}
