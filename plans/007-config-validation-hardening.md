# Plan 007: Harden config validation, sensitive-mount detection, and error redaction

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If a STOP condition
> occurs, stop and report; do not improvise. Update this plan's row in
> `plans/README.md` when finished.
>
> **Drift check (run first)**:
> `git diff --stat 27d0d9b3..HEAD -- crates/jackin-config crates/jackin-env crates/jackin/src/workspace/sensitive`
> This plan runs after Plan 001 and before Plans 002/006 in the unified branch
> sequence, so their config-discovery and exec-binding changes should not exist yet.
> This plan owns error-variant text, config locking, and validation. Any semantic
> mismatch with the excerpts below is a STOP condition; a citation off by a few
> lines with the described code clearly present nearby is not drift.
>
> Command prefix note: `rtk` is an optional local output-compressor. The
> canonical command is everything after `rtk `; if `rtk` is not installed, drop
> the prefix.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: none; unified sequence runs it after Plan 001 and before Plan 002
- **Category**: security, bug
- **Planned at**: commit `27d0d9b3`, 2026-08-13

## Why this matters

The sensitive-mount confirmation — the control that makes an operator explicitly
approve mounting a credential directory into an AI-agent container — can be
skipped by mounting a subpath, a symlink alias, or a path with `..` segments.
Separately, three env-resolution error variants echo the raw operator-supplied
value into stderr (a pasted literal credential lands verbatim in logs), the Grok
agent is missing from auth-mode validation, config saves can tear across files,
and repo-identity checks degrade to string comparison. Each is small; together
they are the validation layer's integrity.

## Current state

- `crates/jackin-config/src/sensitive.rs:34-49` — `find_sensitive_mounts` matches
  `mount.src.trim_end_matches('/')` with `ends_with(suffix)` against the fixed
  table at `:15-22` (`/.ssh`, `/.aws`, `/.gnupg`, `/.config/gcloud`, `/.kube`,
  `/.docker`). No normalization, no `..`/`.` handling, no symlink resolution. The
  doc at `:12-14` claims matching happens "(after tilde expansion)" — no
  expansion occurs in this function. Gate callers:
  `crates/jackin-runtime/src/runtime/launch/launch_pipeline.rs:459`,
  `crates/jackin-isolation/src/materialize.rs:439`,
  `crates/jackin/src/app/config_cmd.rs:98`,
  `crates/jackin-console/src/services/workspace.rs:59`.
- `crates/jackin-config/src/paths.rs:29-42` already provides a filesystem-free
  `normalize_path`, and `resolve_path` (`:47-57`) the full expand+normalize — the
  machinery exists and is unused here.
- `crates/jackin-env/src/resolve.rs:36-55` — `NotOpRef`, `ShellVarInRef`, and
  `MalformedRef` all interpolate `value` into their `#[error(...)]` text:

  ```rust
  #[error("not an op:// reference: {value}")]
  NotOpRef { value: String },
  ```

  Constructed in `resolve_op_uri_to_ref` at `:179`, `:184`, `:194`, `:203`. The
  `:179` site fires precisely when the input is NOT an `op://` reference — i.e.
  the echoed string is a plain (possibly secret) config value. Reached from
  `crates/jackin/src/app/config_cmd.rs:37` and `token_cmd.rs:26`. The rest of the
  crate deliberately avoids this (`classify_str` at `:836-842` collapses literals
  to `"literal"`).
- `crates/jackin-config/src/app_config.rs:98-103` — the `pairs` array checked for
  unsupported `OAuthToken` lists Codex/Amp/Kimi/Opencode only; same four-element
  arrays at `crates/jackin-config/src/schema.rs:415-420` and `:435-440`. Grok's
  `supported_modes()` is `[Sync, ApiKey, Ignore]`
  (`crates/jackin-core/src/agent/adapters/grok.rs:69-75`), so
  `[grok] auth_forward = "oauth_token"` validates clean and breaks at launch.
  By contrast `auth_forward_for` (`app_config.rs:126-135`) enumerates all six
  agents — the omission is an oversight.
- `crates/jackin-config/src/editor.rs:130-145` — `save` order: global
  `atomic_write` (`:130`), `create_dir_all` (`:131`), workspace-stem validation
  loop (`:132-134`), per-workspace writes (`:135-137`), delete loop (`:138-145`).
  Every step after `:130` can fail with the global file already replaced.
  `workspace_doc_mut` (`:665-670`) only `debug_assert!`s the stem (the assert is
  at `:667`).
- `crates/jackin-config/src/validation.rs:106-113` — `same_host_repo` falls back
  to raw string equality when `canonicalize` fails (including the common
  "path does not exist yet" case); `is_strict_ancestor` (`:115-125`) compares raw
  strings; `validate_mount_specs` (`schema.rs:616-632`) accepts `..` segments.
- `crates/jackin-config/src/persist.rs:29-86` — `atomic_write` (`:29-61`) with
  `stage_write` (`:63-86`) staging `.mode(0o600)` (`:76`) + `sync_all` (`:79`)
  on unix, but never fsyncing the parent directory after the rename at `:52`;
  the `#[cfg(not(unix))]` branch (`:82-83`) is a bare `std::fs::write` with no
  mode and no sync.
- No advisory lock exists anywhere in `jackin-config`/`jackin-env`:
  `ConfigEditor::open` (`editor.rs:76-97`) → `save` (`:111-149`) is an unlocked
  whole-document read-modify-write; `load_workspace_files`
  (`app_config/persist.rs:80-91`) migrates (writes) then re-reads each entry.

Repository constraints:

- Schema changes are versioned (5-artifact rule) — none of these fixes may bump
  the config/workspace schema; they change validation and I/O behavior only.
- Resolution/validation stay pure transforms; persistence is the only I/O and
  stays narrow (`crates/jackin-config` AGENTS rule).
- Never echo secret values; use `jackin-diagnostics` redaction helpers where a
  value could transit an error path.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Tests | `rtk cargo nextest run -p jackin-config -p jackin-env` | exit 0 |
| Dependents | `rtk cargo nextest run -p jackin-runtime -p jackin-isolation -p jackin-console -p jackin` | exit 0 |
| Lint | `rtk cargo clippy -p jackin-config -p jackin-env --all-targets -- -D warnings` | exit 0 |
| Fast gate | `rtk cargo xtask ci --fast` | exit 0 |

## Scope

**In scope**:

- `crates/jackin-config/src/sensitive.rs` (+ tests)
- `crates/jackin/src/workspace/sensitive/` incl. `tests.rs` (caller-side
  normalization helper and the existing sensitive test suite)
- the four confirm call sites, normalization-call only:
  `crates/jackin-runtime/src/runtime/launch/launch_pipeline.rs:459`,
  `crates/jackin-isolation/src/materialize.rs:439`,
  `crates/jackin/src/app/config_cmd.rs:98`,
  `crates/jackin-console/src/services/workspace.rs:59`
- `crates/jackin-config/src/app_config.rs`, `schema.rs` (validation arrays and
  mount-spec validation only), `editor.rs`, `validation.rs`,
  `crates/jackin-config/src/persist.rs` (the crate has two `persist.rs` files —
  this is the root one with `atomic_write`, not `app_config/persist.rs`)
  (+ their tests)
- `crates/jackin-config/Cargo.toml` (`fs4.workspace = true` for Step 7; the
  workspace and lockfile already contain the pinned crate)
- `plans/README.md` (status row only)
- `crates/jackin-env/src/resolve.rs` (error variants + construction sites,
  + tests)
- `crates/jackin-config/README.md` (behavior notes)

**Out of scope**:

- The read-only snapshot loader (Plan 002) beyond merge coordination.
- Any schema/version bump, migration artifact, or persisted-format change.
- Changing which mounts are allowed — only whether the confirm fires.
- Prompt/UX changes at the four confirm call sites beyond what stricter matching
  forces.

## Git workflow

Stay on the existing `feature/native-liquid-glass-redesign` branch and its new active
PR (`#843` is already merged historical context);
the operator explicitly selected this plan into that branch. Do not create or switch
branches. Use Conventional Commits, `git commit -s`, add
`Co-authored-by: Codex <codex@openai.com>`, and push after every commit. Never
force-push.

## Steps

### Step 1: Make sensitive-mount detection normalization- and symlink-aware

Purity constraint (this crate's AGENTS rule, quoted above, and the module doc at
`sensitive.rs:6-8` both forbid filesystem access in `jackin-config` validation):
keep `find_sensitive_mounts` a pure transform and put the I/O at the callers.

1. In `jackin-config`, change `find_sensitive_mounts` to accept
   already-normalized source paths (or a caller-supplied resolver): matching
   operates on path **components**, not `str::ends_with`. A path is sensitive
   when its components **end with** a table entry's components (`~/.ssh` ↔
   entry `/.ssh`) **or contain them as a contiguous run** (so
   `~/.ssh/known_hosts`, a file inside, matches; `/foo/bar.ssh` does not).
2. At the four confirm call sites — which already perform I/O — normalize each
   `mount.src` before calling: `paths::resolve_path` (tilde + `.`/`..`, no
   filesystem), then `std::fs::canonicalize` when the path exists (fall back to
   the normalized form when it does not). Provide one shared helper so the four
   sites cannot drift; put it beside the existing sensitive-check plumbing in
   `crates/jackin/src/workspace/sensitive/` (already impure territory).
3. Extend the table with `/.config/gh`, `/.netrc`, `/.npmrc`,
   `/.git-credentials`, and `/.config/op` (reasons one line each).
4. Fix the module doc (`sensitive.rs:12-14` claims tilde expansion happens
   inside — it must describe the new caller contract).

Audit the four confirm call sites for non-interactive contexts: if any caller
auto-answers or cannot prompt, surface that as a report in the PR description —
do not silently change its behavior.

**Verify**:
`rtk cargo nextest run -p jackin-config -p jackin -E 'test(/sensitive/)'`
-> table-driven tests pass for: exact dir, trailing slash, file inside a listed
dir, `..` segments, tilde form, symlink alias (tempdir, in the `jackin`-side
tests where I/O is allowed), and a non-matching `.sshx` sibling. Note: the
existing sensitive tests live in package `jackin`
(`crates/jackin/src/workspace/sensitive/tests.rs:19-92`) — extend them there;
`-p jackin-config` alone matches nothing today.

### Step 2: Redact env-resolution error values

- `NotOpRef`: remove `value` from the `Display` text entirely (the type of
  failure is self-describing). Keep the field if a caller needs it
  programmatically; mark it doc(hidden) from display.
- `ShellVarInRef` / `MalformedRef`: render a redacted shape (segment count or
  vault/item with the field elided), never the full URI.
- Check `crates/jackin/src/app/config_cmd.rs` and `token_cmd.rs` (and any picker
  tests) for assertions on the old text; update them.
- Add a note to the error rustdoc: any credential that transited the old message
  format should be rotated.

**Verify**:
`rtk cargo nextest run -p jackin-env -E 'test(/op_ref|resolve_error/)'`
-> a fixture literal passed where a ref was expected produces an error whose
`Display` output does not contain the fixture string.

### Step 3: Close the Grok validation hole structurally

Replace the three hand-maintained four-element arrays
(`app_config.rs:98-103`, `schema.rs:415-420`, `schema.rs:435-440`) with iteration
over `Agent::ALL` driving the per-agent accessor, so every current and future
agent is covered. Add a test asserting each `Agent` variant with an unsupported
mode is rejected at every scope (global, workspace, workspace-role).

**Verify**:
`rtk cargo nextest run -p jackin-config -E 'test(/auth_mode/)'`
-> `[grok] auth_forward = "oauth_token"` is rejected at all three scopes; all
previously valid configs still validate.

### Step 4: Make `ConfigEditor::save` tear-proof

Reorder and stage:

1. Validate all workspace stems **before** any write (promote the
   `debug_assert!` at `editor.rs:667` to a returned error).
2. Stage every file (global + workspaces) to `.tmp` siblings first; only after
   all stages succeed, rename each into place; then process deletions.
3. On any staging failure, remove the `.tmp` files and return with the previous
   config fully intact.

**Verify**:
`rtk cargo nextest run -p jackin-config -E 'test(/editor_save|save_atomic/)'`
-> an injected failure between stages leaves every original file byte-identical.

### Step 5: Normalize repo-identity and mount-spec validation

- `same_host_repo`: normalize both sides with `paths::resolve_path` first; use
  `canonicalize` when both exist; on `NotFound` compare normalized forms; on
  other errors propagate instead of returning "different".
- `is_strict_ancestor`: compare by path components after the same normalization,
  not `starts_with` on strings.
- `validate_mount_specs`: reject `..` and `.` components in `src` and `dst`.

**Verify**:
`rtk cargo nextest run -p jackin-config -E 'test(/same_host_repo|ancestor|mount_spec/)'`
-> trailing-slash/`..`/symlink spellings of one repo are detected as the same;
`..` mounts are rejected.

### Step 6: Durability and non-unix mode in `atomic_write`

After the rename at `persist.rs:52`, open the parent directory and `sync_all()`
it. For the `#[cfg(not(unix))]` branch, the default is: set restrictive
permissions explicitly after write and add the missing sync. (Gating the crate to
unix-only instead would need an operator decision — if you believe that is the
right call, it is a STOP-and-report, not a choice you make.) Record what was done.

**Verify**:
`rtk cargo nextest run -p jackin-config -E 'test(/atomic_write/)'` -> passes;
`rtk cargo clippy -p jackin-config --all-targets -- -D warnings` -> clean.

### Step 7: Serialize config editors and whole-tree readers

The operator selected the lock policy for this unified execution; do not stop for a
second policy decision:

1. Add the already workspace-pinned `fs4` dependency to `jackin-config`.
2. Use a sibling `config.lock` file. Hold an exclusive OS advisory lock from
   `ConfigEditor::open` until its save/abort lifecycle ends. Expose a shared read
   guard for whole-tree readers; Plan 002's read-only discovery loader must hold it
   for its complete snapshot.
3. Acquisition uses `try_lock`/`try_lock_shared` with a 25 ms poll and a 5 second
   production deadline. Make the clock/deadline injectable so contention tests use a
   short deterministic deadline rather than sleeping five seconds.
4. On timeout, return a typed error saying another jackin❯ process is editing the
   config. The lock file may contain the exclusive holder PID for diagnosis, but its
   content never grants ownership.
5. The OS lock is authoritative. A dead process releases it automatically; a leftover
   lock file is harmless and reused. Never delete/reclaim a file merely because a PID
   appears dead—PID reuse makes that unsafe.
6. The guard is synchronous and must be acquired on the existing blocking/config I/O
   path, never the Swift main actor or an async render loop.

**Verify**:
`rtk cargo nextest run -p jackin-config -E 'test(/config_lock/)'`
-> two competing editors serialize; a shared reader excludes a writer for the whole
snapshot; process death releases ownership despite a persistent lock file; a held
lock times out with the typed error.

## Test plan

- Table-driven sensitive-mount cases (Step 1 list) modeled after existing
  `sensitive`-module tests if present, else after `validation.rs` tests.
- Error-display redaction with fixture strings, asserted via `to_string()`.
- Exhaustive agent/mode validation matrix.
- Injected-failure save teardown; byte-snapshot comparison.
- All fixtures synthetic; never operator config or real credentials.

## Done criteria

- [ ] A mount of, into, or through a listed credential directory always triggers
  the confirmation, regardless of spelling or symlinks.
- [ ] No env-resolution error `Display` output can contain an operator-supplied
  value.
- [ ] Unsupported auth modes are rejected for every agent at every scope.
- [ ] A failed save never leaves a torn multi-file config.
- [ ] Repo-identity and mount-spec validation are normalization-aware.
- [ ] `atomic_write` is rename-durable; non-unix behavior is explicit.
- [ ] Step 7's selected advisory-lock policy is implemented and tested; Plan 002 can
  consume the shared read guard.
- [ ] All listed gates pass; only in-scope files and `plans/README.md` changed.

## STOP conditions

- Any fix appears to require a config/workspace schema version bump.
- Stricter mount matching would block a launch path that cannot prompt
  (non-interactive) — report the call site instead of weakening the matcher.
- A test can pass only against real operator credentials/config.
- Dropping non-unix support looks preferable to fixing the non-unix branch
  (platform policy is the operator's call).

## Maintenance notes

The `Agent::ALL`-driven validation (Step 3) is the pattern for every future
per-agent table — reviewers should reject new hand-enumerated agent arrays.
When Plan 002's read-only loader lands, its torn-read retry and Step 7's lock interact:
the loader's shared lock acquisition must never block the UI thread.
