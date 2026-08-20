use super::{
    MIN_OS, minos_matches_target, normalize_generated_text, tree_differences, validate_build,
    validate_version,
};

#[test]
fn version_accepts_dotted_numeric() {
    validate_version("0.6.0").unwrap();
    validate_version("1").unwrap();
    validate_version("10.20.30").unwrap();
}

#[test]
fn version_rejects_semver_prerelease_and_empty() {
    assert!(validate_version("").is_err());
    assert!(validate_version("0.6.0-dev").is_err());
    assert!(validate_version("v0.6.0").is_err());
    assert!(validate_version("0..1").is_err());
}

#[test]
fn build_accepts_numeric_only() {
    validate_build("1").unwrap();
    validate_build("42").unwrap();
    assert!(validate_build("").is_err());
    assert!(validate_build("1a").is_err());
}

#[test]
fn minos_must_match_current_baseline() {
    assert!(minos_matches_target("26.0", MIN_OS));
    assert!(minos_matches_target("26.0.0", MIN_OS));
    assert!(!minos_matches_target("25.0", MIN_OS));
    assert!(!minos_matches_target("26.1", MIN_OS));
    assert!(!minos_matches_target("27.0", MIN_OS));
}

#[test]
fn generated_bindings_have_stable_whitespace() {
    assert_eq!(
        normalize_generated_text("one  \n  two\t\n\n"),
        "one\n  two\n"
    );
    assert_eq!(normalize_generated_text("one"), "one\n");
    assert_eq!(normalize_generated_text(" \t\n"), "");
}

fn write_tree(root: &std::path::Path, files: &[(&str, &[u8])]) {
    for (relative, bytes) in files {
        let path = root.join(relative);
        std::fs::create_dir_all(path.parent().unwrap()).unwrap();
        std::fs::write(path, bytes).unwrap();
    }
}

#[test]
fn tree_differences_clean_when_identical() {
    let temp = std::env::temp_dir().join(format!("jackin-bindings-clean-{}", std::process::id()));
    let expected = temp.join("expected");
    let actual = temp.join("actual");
    drop(std::fs::remove_dir_all(&temp));
    write_tree(&expected, &[("a.bin", b"one"), ("nested/b.bin", b"two")]);
    write_tree(&actual, &[("a.bin", b"one"), ("nested/b.bin", b"two")]);
    assert!(tree_differences(&expected, &actual, "label").unwrap().is_empty());
    std::fs::remove_dir_all(&temp).unwrap();
}

#[test]
fn tree_differences_flags_stale_missing_and_extra() {
    let temp = std::env::temp_dir().join(format!("jackin-bindings-drift-{}", std::process::id()));
    let expected = temp.join("expected");
    let actual = temp.join("actual");
    drop(std::fs::remove_dir_all(&temp));
    write_tree(&expected, &[("stale.bin", b"old"), ("missing.bin", b"gone")]);
    write_tree(&actual, &[("stale.bin", b"new"), ("extra.bin", b"added")]);
    let differences = tree_differences(&expected, &actual, "label").unwrap();
    assert_eq!(
        differences,
        vec![
            "label/missing.bin: missing after regeneration".to_owned(),
            "label/extra.bin: not committed".to_owned(),
            "label/stale.bin: content drift".to_owned(),
        ]
    );
    std::fs::remove_dir_all(&temp).unwrap();
}
