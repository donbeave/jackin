// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

//! Materialized-account writes and provider error classification.

use super::{AtomicU64, FocusedUsageView, Ordering, Path, Serialize, Write, fs};
#[cfg(test)]
use serde::Deserialize;

pub(crate) static MATERIALIZED_TMP_COUNTER: AtomicU64 = AtomicU64::new(0);

pub(crate) fn usage_error_is_rate_limited(error: &str) -> bool {
    let lower = error.to_ascii_lowercase();
    lower.contains("429")
        || lower.contains("rate limit")
        || lower.contains("retry-after")
        || lower.contains("retry after")
}

/// True when a provider fetch failed because the token was rejected (expired or
/// revoked), as opposed to a transient/network error. Drives the honest
/// `NeedsLogin` status so a stale on-disk token reads as "login", not "stale".
pub(crate) fn usage_error_is_unauthorized(error: &str) -> bool {
    let lower = error.to_ascii_lowercase();
    lower.contains("http 401") || lower.contains("http 403") || lower.contains("unauthorized")
}

pub(crate) fn parse_retry_after_seconds(error: &str) -> Option<u64> {
    for marker in ["retry-after", "retry after"] {
        let Some((_, tail)) = error.split_once(marker) else {
            continue;
        };
        let digits = tail
            .chars()
            .skip_while(|ch| !ch.is_ascii_digit())
            .take_while(char::is_ascii_digit)
            .collect::<String>();
        if let Ok(seconds) = digits.parse::<u64>() {
            return Some(seconds);
        }
    }
    None
}

/// Owned document shape for reading materialized accounts JSON (tests + any
/// future consumers). Write path serializes via `MaterializedUsageAccountsRef`.
#[derive(Debug, Serialize, Deserialize)]
#[cfg(test)]
pub(crate) struct MaterializedUsageAccounts {
    pub(crate) generated_at_epoch: i64,
    pub(crate) snapshots: Vec<FocusedUsageView>,
}

#[derive(Serialize)]
struct MaterializedUsageAccountsRef<'a> {
    generated_at_epoch: i64,
    snapshots: &'a [&'a FocusedUsageView],
}

pub(crate) fn write_materialized_usage_accounts(
    path: &Path,
    generated_at_epoch: i64,
    snapshots: &[&FocusedUsageView],
) -> Result<(), String> {
    let document = MaterializedUsageAccountsRef {
        generated_at_epoch,
        snapshots,
    };
    let contents = serde_json::to_string_pretty(&document)
        .map_err(|err| format!("usage accounts encode failed: {err}"))?;
    atomic_write_usage_json(path, &contents)
}

#[expect(
    clippy::disallowed_methods,
    reason = "documented residual allow; prefer expect when site is lint-true"
)]
pub(crate) fn atomic_write_usage_json(path: &Path, contents: &str) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|err| format!("create usage materialization dir failed: {err}"))?;
    }
    let counter = MATERIALIZED_TMP_COUNTER.fetch_add(1, Ordering::Relaxed);
    let mut staged_name = path
        .file_name()
        .map(std::ffi::OsStr::to_os_string)
        .unwrap_or_default();
    staged_name.push(format!(".tmp.{}.{counter}", std::process::id()));
    let tmp = path.with_file_name(staged_name);
    let staged = (|| -> Result<(), String> {
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            let mut file = fs::OpenOptions::new()
                .write(true)
                .create(true)
                .truncate(true)
                .mode(0o644)
                .open(&tmp)
                .map_err(|err| format!("open staged usage accounts failed: {err}"))?;
            file.write_all(contents.as_bytes())
                .map_err(|err| format!("write staged usage accounts failed: {err}"))?;
            file.sync_all()
                .map_err(|err| format!("sync staged usage accounts failed: {err}"))?;
        }

        #[cfg(not(unix))]
        fs::write(&tmp, contents)
            .map_err(|err| format!("write staged usage accounts failed: {err}"))?;

        Ok(())
    })();
    if let Err(error) = staged {
        drop(fs::remove_file(&tmp));
        return Err(error);
    }
    if let Err(error) = fs::rename(&tmp, path) {
        drop(fs::remove_file(&tmp));
        return Err(format!("rename usage accounts into place failed: {error}"));
    }
    Ok(())
}
