use std::collections::BTreeMap;

use super::*;
use jackin_config::{EnvValue, WorkspaceConfig};
use jackin_core::UsageCredentialOwner;
use jackin_usage::host::{ProviderCredentialEnvOutcome, ProviderCredentialEnvResolver};

fn entry(name: &'static str, owner: UsageCredentialOwner) -> UsageCredentialEnvName {
    UsageCredentialEnvName { name, owner }
}

#[test]
fn disc_source_adapter_caches_identical_declaration_before_second_read() {
    let resolver = DesktopCredentialResolver::default();
    let mut config = AppConfig::default();
    config.env.insert(
        "ZAI_API_KEY".to_owned(),
        EnvValue::Plain("fixture-secret".to_owned()),
    );
    config.workspaces.insert(
        "alpha".to_owned(),
        WorkspaceConfig {
            workdir: "/workspace".to_owned(),
            env: BTreeMap::from([(
                "ZAI_API_KEY".to_owned(),
                EnvValue::Plain("fixture-secret".to_owned()),
            )]),
            ..WorkspaceConfig::default()
        },
    );
    let key = entry("ZAI_API_KEY", UsageCredentialOwner::Zai);
    let global = resolver.resolve_provider_credentials(&config, None, None, &[key]);
    let workspace = WorkspaceName::parse("alpha").unwrap();
    let scoped = resolver.resolve_provider_credentials(&config, Some(&workspace), None, &[key]);

    assert_eq!(global, scoped);
    assert_eq!(resolver.cached_resolution_count(), 1);
    let debug = format!("{:?}", global);
    assert!(!debug.contains("fixture-secret"));
}

#[test]
fn disc_dedup_adapter_reuses_handle_for_same_provider_secret() {
    let resolver = DesktopCredentialResolver::default();
    let mut config = AppConfig::default();
    config.env.insert(
        "KIMI_CODE_API_KEY".to_owned(),
        EnvValue::Plain("same-secret".to_owned()),
    );
    config.env.insert(
        "KIMI_API_KEY".to_owned(),
        EnvValue::Plain("same-secret".to_owned()),
    );
    let results = resolver.resolve_provider_credentials(
        &config,
        None,
        None,
        &[
            entry("KIMI_CODE_API_KEY", UsageCredentialOwner::Kimi),
            entry("KIMI_API_KEY", UsageCredentialOwner::Kimi),
        ],
    );

    let handles = results
        .iter()
        .filter_map(|result| match &result.outcome {
            ProviderCredentialEnvOutcome::Resolved(handle) => Some(handle),
            _ => None,
        })
        .collect::<Vec<_>>();
    assert_eq!(handles.len(), 2);
    assert_eq!(handles[0], handles[1]);
}

#[test]
fn disc_source_manual_retry_evicts_only_failed_resolution() {
    let resolver = DesktopCredentialResolver::default();
    let mut config = AppConfig::default();
    config.env.insert(
        "ZAI_API_KEY".to_owned(),
        EnvValue::Plain("$JACKIN_TEST_INTENTIONALLY_MISSING".to_owned()),
    );
    config.env.insert(
        "MINIMAX_API_KEY".to_owned(),
        EnvValue::Plain("resolved-secret".to_owned()),
    );
    let keys = [
        entry("ZAI_API_KEY", UsageCredentialOwner::Zai),
        entry("MINIMAX_API_KEY", UsageCredentialOwner::Minimax),
    ];
    let results = resolver.resolve_provider_credentials(&config, None, None, &keys);
    assert_eq!(results.len(), 2);
    assert_eq!(resolver.cached_resolution_count(), 2);

    resolver.begin_manual_retry();

    assert_eq!(resolver.cached_resolution_count(), 1);
}
