// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

use super::*;

fn mount(src: &str, dst: &str) -> MountConfig {
    MountConfig {
        src: src.to_owned(),
        dst: dst.to_owned(),
        readonly: false,
        isolation: MountIsolation::Shared,
    }
}

#[test]
fn mount_spec_rejects_dot_and_parent_components() {
    for candidate in [
        mount("/host/./repo", "/workspace/repo"),
        mount("/host/../repo", "/workspace/repo"),
        mount("/host/repo", "/workspace/./repo"),
        mount("/host/repo", "/workspace/../repo"),
    ] {
        let err = validate_mount_specs(&[candidate]).unwrap_err();
        assert!(err.to_string().contains("must not contain"), "{err}");
    }
}

#[test]
fn mount_spec_accepts_component_names_containing_dots() {
    validate_mount_specs(&[mount("/host/.../repo", "/workspace/repo..backup")]).unwrap();
}
