# Plan 008: Enforce Apple read-only mount parity and harden notify argv

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
- The repository requires Apple `container` v0.11.0 or newer.

Implementation discovery: current official command documentation and the pinned
v0.11.0 parser support `-v host:guest:ro` for directory mounts. This triggered
the original STOP condition. The pinned, latest-stable, and current parsers all
reject single-file bind sources, however, so worktree isolation cannot represent
its two protected pointer-file overlays. Step 1 therefore implements real
read-only translation for shared directory mounts and fails closed on worktree
isolation before cleanup or launch. Command-vector tests validate the exact
supported syntax; live VM conformance remains part of the existing
Apple-container Phase 0 environment validation.

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
- `crates/jackin-runtime/src/apple_container_client.rs` (+ tests)
- the apple-container launch call path and session-contract mount rendering
- `crates/jackin-runtime/src/host_daemon.rs` (notification argv only, + tests)
- `HOST_AND_CONTAINER.md` (one note documenting the apple-container limitation)
- `plans/README.md` (status row only)

**Out of scope**:

- Live Apple VM conformance on a host without the `container` CLI.
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

### Step 1: Preserve read-only semantics on Apple container mounts

Replace bare Apple `(host, guest)` pairs with a typed mount carrying its
read-only bit. Shared directory mounts use their configured permission and Apple
CLI argv `-v host:guest[:ro]`, the syntax supported by the pinned v0.11.0
parser. Reject worktree-isolated mounts with a typed, destination-naming error
before cleanup or launch because Apple rejects the required file overlays.

Add tests: (a) a readonly mount preserves its read-only bit; (b) a
worktree-isolation workspace returns a typed error naming its destination and
Docker remedy; (c) plain read-write mounts retain the unchanged shape; (d)
generated Apple CLI argv includes `:ro` only for read-only mounts; (e) existing
Docker snapshot tests still pass.

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
both backends enforce read-only directory mounts, Apple uses the supported `:ro`
option, Apple worktree isolation rejects unsupported file overlays, and future
backends must reject rather than silently weaken the restriction.
Keep this paragraph isolated so Plan 009 can correct adjacent layout and cleanup
documentation later.

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

- [x] A readonly shared mount on the apple-container backend emits `:ro`; a
  worktree-override mount fails before cleanup/launch with a destination-naming
  error; plain read-write and Docker behavior remain unchanged.
- [x] Linux notify argv contains `--` before positionals; title/body are clamped
  and control-char-free.
- [x] `HOST_AND_CONTAINER.md` documents backend parity and the fail-closed rule.
- [x] Tests, clippy, fast gate, docs gate pass; only in-scope files and
  `plans/README.md` changed.

## STOP conditions

- [x] The apple-container CLI supports read-only directory mounts. Reported
  during implementation; the plan was updated to real `:ro` enforcement for
  supported mounts plus fail-closed worktree handling after checking official
  current docs and pinned/current parser source.
- The error cannot surface without restructuring launch phases.

## Maintenance notes

Reviewers of future backends: `resolve_backend`'s fail-closed posture plus this plan's rule
("an unenforceable operator security option rejects the launch") is the template.
