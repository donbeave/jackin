// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

use super::*;
use std::sync::mpsc;

#[test]
fn config_lock_two_writers_serialize() {
    let temp = tempfile::tempdir().unwrap();
    let config = temp.path().join("config.toml");
    let first = acquire_lock(&config, LockMode::Exclusive, Duration::ZERO, Duration::ZERO).unwrap();
    let (acquired_tx, acquired_rx) = mpsc::channel();
    let config_for_thread = config.clone();
    let waiter = std::thread::spawn(move || {
        let second = acquire_lock(
            &config_for_thread,
            LockMode::Exclusive,
            Duration::from_secs(1),
            Duration::from_millis(1),
        )
        .unwrap();
        acquired_tx.send(()).unwrap();
        second
    });
    assert!(acquired_rx.recv_timeout(Duration::from_millis(20)).is_err());
    drop(first);
    acquired_rx.recv_timeout(Duration::from_secs(1)).unwrap();
    drop(waiter.join().unwrap());
}

#[test]
fn config_lock_shared_reader_excludes_writer() {
    let temp = tempfile::tempdir().unwrap();
    let config = temp.path().join("config.toml");
    let reader = acquire_lock(&config, LockMode::Shared, Duration::ZERO, Duration::ZERO).unwrap();
    let err =
        acquire_lock(&config, LockMode::Exclusive, Duration::ZERO, Duration::ZERO).unwrap_err();
    assert!(matches!(err, crate::ConfigError::ConfigLockTimeout { .. }));
    drop(reader);
    drop(acquire_lock(&config, LockMode::Exclusive, Duration::ZERO, Duration::ZERO).unwrap());
}

#[test]
fn config_lock_timeout_is_typed_and_reports_recorded_pid() {
    let temp = tempfile::tempdir().unwrap();
    let config = temp.path().join("config.toml");
    let writer = acquire_config_write_lock(&config).unwrap();
    let err = acquire_lock(&config, LockMode::Shared, Duration::ZERO, Duration::ZERO).unwrap_err();
    assert!(matches!(err, crate::ConfigError::ConfigLockTimeout { .. }));
    assert!(err.to_string().contains(&std::process::id().to_string()));
    drop(writer);
}

#[test]
fn config_lock_timeout_uses_injected_clock_without_sleeping() {
    let temp = tempfile::tempdir().unwrap();
    let config = temp.path().join("config.toml");
    let writer = acquire_config_write_lock(&config).unwrap();
    let mut ticks = [Duration::ZERO, Duration::from_millis(2)].into_iter();
    let mut waits = Vec::new();
    let err = acquire_lock_with_timing(
        &config,
        LockMode::Shared,
        Duration::from_millis(1),
        Duration::from_millis(1),
        || ticks.next().unwrap_or(Duration::from_millis(2)),
        |duration| waits.push(duration),
    )
    .unwrap_err();
    assert!(matches!(err, crate::ConfigError::ConfigLockTimeout { .. }));
    assert_eq!(waits, [Duration::from_millis(1)]);
    drop(writer);
}

#[test]
#[cfg(unix)]
// Re-spawns the test binary as a lock-holding child that must die with a
// real OS signal; process spawning and kernel flock semantics are outside
// what Miri models (posix spawn attributes are unsupported), so skip under
// Miri.
#[cfg_attr(miri, ignore)]
fn config_lock_process_death_releases_ownership() {
    const CHILD_PATH: &str = "JACKIN_CONFIG_LOCK_TEST_CHILD";
    if let Some(path) = std::env::var_os(CHILD_PATH) {
        let config = PathBuf::from(path);
        let _writer = acquire_config_write_lock(&config).unwrap();
        std::fs::write(config.with_extension("ready"), b"ready").unwrap();
        loop {
            std::thread::sleep(Duration::from_mins(1));
        }
    }

    let temp = tempfile::tempdir().unwrap();
    let config = temp.path().join("config.toml");
    let ready = config.with_extension("ready");
    let mut child = std::process::Command::new(std::env::current_exe().unwrap())
        .arg("--exact")
        .arg("persist::tests::config_lock_process_death_releases_ownership")
        .arg("--nocapture")
        .env(CHILD_PATH, &config)
        .spawn()
        .unwrap();
    let deadline = Instant::now() + Duration::from_secs(5);
    while !ready.exists() && Instant::now() < deadline {
        std::thread::sleep(Duration::from_millis(5));
    }
    assert!(ready.exists(), "child did not acquire config lock");
    child.kill().unwrap();
    child.wait().unwrap();

    let lock_path = config.with_file_name("config.lock");
    assert!(lock_path.exists(), "persistent lock file must remain");
    drop(
        acquire_lock(
            &config,
            LockMode::Exclusive,
            Duration::from_secs(1),
            Duration::from_millis(1),
        )
        .unwrap(),
    );
}
