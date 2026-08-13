# Plan 008: Fail closed on unenforceable mount options and harden notify argv

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If a STOP condition
> occurs, stop and report; do not improvise. Update this plan's row in
> `plans/README.md` when finished.
>
> **Drift check (run first)**:
> `git diff --stat 27d0d9b3..HEAD -- crates/jackin-runtime/src/runtime/launch/mounts.rs crates/jackin-runtime/src/host_daemon.rs HOST_AND_CONTAINER.md`
> This plan runs before Plan 003 in the unified current-branch sequence. Plan 003 will
> later restructure `host_daemon.rs` broker paths and the apple-container launch
> call path and must preserve this plan's contracts. Only
> `build_workspace_mount_pairs`/`build_workspace_mount_strings` and
> `notification_command_for_host` must still match the excerpts below. Plan 009
> may have corrected `HOST_AND_CONTAINER.md` (layout list, cleanup command) —
> preserve those. Any other semantic mismatch is a STOP condition; a citation
> off by a few lines with the described code clearly present nearby is not drift.
>
> Command prefix note: `rtk` is an optional local output-compressor. The
> canonical command is everything after `rtk `; if `rtk` is not installed, drop
> the prefix.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none; unified sequence runs it before Plan 003, which must preserve
  its `host_daemon.rs` and apple-container guarantees
- **Category**: security, bug
- **Planned at**: commit `27d0d9b3`, 2026-08-13

## Why this matters

An operator who marks a mount `readonly = true` and selects the apple-container
backend gets that mount read-write with no warning — a security control the
config presents as enforced is silently dropped by a selectable backend. The same
translation drops the `:ro` worktree `.git` pointer overrides whose stated
purpose is preventing a misbehaving role from redirecting git operations at
another repo. Separately, container-controlled notification text reaches
`notify-send` argv without an end-of-options sentinel on Linux hosts.

## Current state

- `crates/jackin-runtime/src/runtime/launch/mounts.rs:158-176`
  (`build_workspace_mount_strings`, Docker) honors both controls:

  ```rust
  let suffix = if mount.readonly { ":ro" } else { "" };
  out.push(format!("{}:{}{}", mount.bind_src, mount.dst, suffix));
  // worktree aux entries pushed with explicit :ro
  ```

- `mounts.rs:218-225` (`build_workspace_mount_pairs`, apple-container) maps each
  mount to a bare `(src, dst)` pair — `mount.readonly` and the `worktree_aux`
  `:ro` overrides are discarded. The doc at `:212-217` acknowledges this as
  "apple-container Phase 0 work".
- `mounts.rs:193-210` (`resolve_backend`) demonstrates the intended posture for
  backend divergence: an unknown backend name fails closed with an error rather
  than silently launching a weaker configuration.
- `readonly` is an operator-facing config option
  (`crates/jackin-config/src/schema.rs:82`, `:491`; editor at
  `crates/jackin-config/src/editor.rs:243`) and is carried on the materialized
  mount (`crates/jackin-isolation/src/materialize.rs:41`).
- `crates/jackin-runtime/src/host_daemon.rs:239-247` builds a desktop
  notification title from `notification.agent` and body from `notification.label`
  (both originate in the in-container capsule snapshot, `:285-301`);
  `:1020-1024` passes `vec![title, body]` to `notify-send` with no `--`
  separator. The macOS branch (`:1008-1019`) escapes via `apple_script_string`
  (`:1030-1032`) and is safe. `jackin_diagnostics::scrub_secrets` already runs at
  `:249-250`. The repo already uses the `--` sentinel pattern at
  `crates/jackin-runtime/src/exec_host.rs:423`.

Repository constraints:

- Fail closed is the established backend-divergence posture (`resolve_backend`).
- Implementing real `:ro` support inside the apple/container VM is explicitly
  tracked Phase 0 work needing empirical validation — this plan does NOT
  implement it; it makes the gap loud instead of silent.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Tests | `rtk cargo nextest run -p jackin-runtime` | exit 0 |
| Lint | `rtk cargo clippy -p jackin-runtime --all-targets -- -D warnings` | exit 0 |
| Fast gate | `rtk cargo xtask ci --fast` | exit 0 |
| Docs | `rtk cargo xtask docs repo-links` | exit 0 |

## Scope

**In scope**:

- `crates/jackin-runtime/src/runtime/launch/mounts.rs` (+ tests)
- the apple-container launch call path only as far as surfacing the new error
- `crates/jackin-runtime/src/host_daemon.rs` (notification argv only, + tests)
- `HOST_AND_CONTAINER.md` (one note documenting the apple-container limitation)
- `plans/README.md` (status row only)

**Out of scope**:

- Implementing `:ro` semantics inside the apple-container backend (Phase 0 work;
  separate effort with empirical VM validation).
- Any other host_daemon adapter, socket, or protocol behavior.
- Docker launch behavior (already correct).

## Git workflow

Stay on the existing `feature/native-liquid-glass-redesign` branch and its new active
PR (`#843` is already merged historical context);
the operator explicitly selected this plan into that branch. Do not create or switch
branches. Use Conventional Commits, `git commit -s`, add
`Co-authored-by: Codex <codex@openai.com>`, and push after every commit. Never
force-push.

## Steps

### Step 1: Fail closed on unenforceable mount options

In the apple-container translation path, return an error before launch when any
materialized mount carries `readonly = true` or a `worktree_aux` override. The
message must name the offending mount(s) and the remedy, e.g.:
`mount <dst> requires read-only enforcement, which the apple-container backend
does not support yet; use the docker backend or remove readonly from this mount`.
Wire the error through `build_workspace_mount_pairs`'s caller so it surfaces as a
normal launch failure (match how `resolve_backend` errors surface).

Add tests: (a) a readonly mount + apple backend → the typed error naming the
mount; (b) a worktree-isolation workspace + apple backend → same; (c) plain
read-write mounts + apple backend → unchanged success shape; (d) Docker path
unchanged (existing snapshot tests still pass).

**Verify**:
`rtk cargo nextest run -p jackin-runtime -E 'test(/mount/)'` -> (a)–(d) pass.

### Step 2: Sentinel and clamp for notify-send

In the Linux notification branch (`host_daemon.rs:1020-1024`), insert `--` before
the positional title/body, strip control characters from both, and clamp each to
a bounded length (follow the clamp style used elsewhere in the daemon; 200 chars
is fine if no precedent exists). Do not modify the macOS branch.

Testability: `notification_command_for_host` selects the branch via
`cfg!(target_os = "linux")`, so a test asserting `notify-send` argv cannot run
on the macOS dev host. Extract the Linux argument construction into a pure
`fn linux_notify_args(title: &str, body: &str) -> Vec<String>` (compiled on all
platforms, invoked only from the Linux branch) and unit-test **it**
unconditionally: a title beginning with `-` lands after `--`; control characters
are removed; lengths are clamped.

**Verify**:
`rtk cargo nextest run -p jackin-runtime -E 'test(/linux_notify/)'` -> the new
platform-independent argv tests pass on the macOS host.

### Step 3: Document the limitation

Add one short paragraph to `HOST_AND_CONTAINER.md` where backends are discussed:
the apple-container backend rejects launches that require read-only mounts until
`:ro` support ships; the docker backend enforces them. Keep this paragraph isolated
so Plan 009 can correct adjacent layout and cleanup documentation later.

**Verify**:
`rtk rg -n 'read-only mounts' HOST_AND_CONTAINER.md` -> ≥1 hit in the new
paragraph (`docs repo-links` walks only `docs/content` and cannot check this
file); `rtk cargo xtask ci --fast` -> exit 0.

## Test plan

- Mount-translation tests per Step 1, modeled on the existing mount tests beside
  `mounts.rs`.
- Notification argv unit test with hostile fixture strings (no real
  notifications sent — assert on the built command vector).

## Done criteria

- [ ] A readonly or worktree-override mount on the apple-container backend fails
  the launch with a mount-naming error; Docker behavior is byte-identical.
- [ ] Linux notify argv contains `--` before positionals; title/body are clamped
  and control-char-free.
- [ ] `HOST_AND_CONTAINER.md` documents the backend limitation.
- [ ] Tests, clippy, fast gate, docs gate pass; only in-scope files and
  `plans/README.md` changed.

## STOP conditions

- The apple-container CLI turns out to support read-only mounts after all
  (check `container` CLI help during implementation) — report it; implementing
  `:ro` is then preferable to failing closed, but it is a different change with
  VM validation requirements.
- The error cannot surface without restructuring launch phases.

## Maintenance notes

When apple-container `:ro` support lands (Phase 0 roadmap), Step 1's rejection
turns into real enforcement — keep the tests, flip the expectation. Reviewers of
future backends: `resolve_backend`'s fail-closed posture plus this plan's rule
("an unenforceable operator security option rejects the launch") is the template.
