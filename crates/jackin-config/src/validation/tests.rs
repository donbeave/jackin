// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

use super::*;

fn worktree(src: impl Into<String>, dst: impl Into<String>) -> MountConfig {
    MountConfig {
        src: src.into(),
        dst: dst.into(),
        readonly: false,
        isolation: MountIsolation::Worktree,
    }
}

#[test]
fn ancestor_comparison_uses_normalized_path_components() {
    assert!(is_strict_ancestor("/workspace/a/", "/workspace/x/../a/b"));
    assert!(!is_strict_ancestor("/workspace/a", "/workspace/ab"));
    assert!(!is_strict_ancestor("/workspace/a", "/workspace/a/"));
}

#[test]
fn same_host_repo_normalizes_missing_paths() {
    assert!(same_host_repo("/missing/repo/", "/missing/x/../repo").unwrap());
}

#[test]
#[cfg(unix)]
fn same_host_repo_resolves_symlink_aliases() {
    let temp = tempfile::tempdir().unwrap();
    let repo = temp.path().join("repo");
    let alias = temp.path().join("alias");
    std::fs::create_dir(&repo).unwrap();
    std::os::unix::fs::symlink(&repo, &alias).unwrap();
    assert!(same_host_repo(&repo.to_string_lossy(), &alias.to_string_lossy()).unwrap());
}

#[test]
fn isolation_rejects_normalized_duplicate_repositories() {
    let mounts = [
        worktree("/missing/repo", "/workspace/a"),
        worktree("/missing/x/../repo", "/workspace/b"),
    ];
    assert!(validate_isolation_layout(&mounts).is_err());
}
