# Plan 006: Keep credential values out of container-visible config and runtime argv

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If a STOP condition
> occurs, stop and report; do not improvise. Update this plan's row in
> `plans/README.md` when finished.
>
> **Drift check (run first)**:
> `git diff --stat 27d0d9b3..HEAD -- crates/jackin-env crates/jackin-protocol crates/jackin-runtime crates/jackin-capsule HOST_AND_CONTAINER.md`
> This plan runs before Plan 003 in the unified current-branch sequence. Plan 003 will
> later restructure `launch_runtime.rs`/`capsule_setup.rs`/`exec_host.rs` for the
> usage broker and must preserve the credential/env transport contracts below. Any
> other semantic mismatch is a STOP condition; a citation off by a few lines with
> the described code clearly present nearby is not drift.
>
> Command prefix note: `rtk` is an optional local output-compressor. The
> canonical command is everything after `rtk `; if `rtk` is not installed, drop
> the prefix.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: none; unified sequence runs it after Plan 002 and before Plan 003
- **Category**: security
- **Planned at**: commit `27d0d9b3`, 2026-08-13

## Why this matters

Two transport paths currently hand secret values to places the design says must
never see them. First, an on-demand env binding whose value is a plain literal is
serialized — value included — into the capsule's `agent.toml` at container start,
before any operator exec-approval, contradicting the documented "the container
only learns the names … never resolved values" contract. Second, every credential
forwarded to a Docker container rides `docker run -e KEY=VALUE` argv, which is
readable via host process listing while the launch runs. (Docker additionally
records env values in the container config where `docker inspect` shows them;
that exposure is inherent to env-based forwarding and is a recorded non-goal of
this plan — the fix here removes the argv/process-listing leg.)

## Current state

- `crates/jackin-env/src/resolve.rs:525-547` builds `ExecBinding`s for on-demand
  values. The mapping at `:531-543`:

  ```rust
  let (kind, source) = match value {
      EnvValue::OpRef(r) => (ExecKind::Op, r.op),
      EnvValue::Extended(e) => {
          if parse_host_ref(&e.value).is_some() {
              (ExecKind::Env, e.value)
          } else {
              (ExecKind::Literal, e.value)   // source = the raw secret value
          }
      }
      EnvValue::Plain(s) => (ExecKind::Literal, s),
  };
  ```

- `crates/jackin-protocol/src/lib.rs:163-168` documents the opposite intent for
  `exec_bindings`: "the container only learns the names … never resolved values"
  (fields at `:167-168`). This doc/code contradiction is itself part of the
  finding.
- The container-visible serialization happens at the two `toml::to_string` call
  sites — `launch_runtime.rs:879-880` (Docker) and `apple_container.rs:275-276`
  (Apple) — whose output `capsule_setup.rs:94-103` (which receives an
  already-serialized `&str`) writes into the per-container socket dir that is
  bind-mounted at `/jackin/run`; the capsule reads it
  (`crates/jackin-capsule/src/tui/daemon/input_dispatch.rs:335-339`).
- The **same** `ctx.capsule_config.exec_bindings` vector also feeds the host-side
  exec allowlist (`exec_host::start_for_container` at `launch_runtime.rs:976-981`
  and `apple_container.rs:324-328`), so there is currently no separate host-side
  copy: redacting at the producer (`resolve.rs:531-543`) would destroy the value
  everywhere. Redaction must therefore split the projection, not the producer.
- Value resolution at exec time uses the **request** ref, not the allowlist
  entry: `exec_host::resolve_one` maps `ExecKind::Literal => Ok(r.source.clone())`
  (`exec_host.rs:396-416`, literal arm at `:415`), and the capsule stores its
  bindings verbatim and sends them back (`crates/jackin-capsule/src/exec.rs:33-45`,
  `:85-91`, `:137-145`). With a naive redaction the exec flow would silently
  "succeed" handing the agent the placeholder string as the credential.
- The capsule picker already never renders `Literal` sources — it shows `b.name`
  only (`crates/jackin-capsule/src/exec.rs:59-75`, documented `:40-41`). The
  leak is the on-disk `agent.toml`, not the picker UI.
- `capsule_setup.rs:90-93` documents that the socket dir is created under the
  default umask and tightened to `0o700` only when `exec_host` binds. Two
  consequences: the tightening runs in a detached task
  (`launch_runtime.rs:976-981`, `apple_container.rs:324-328`) so the config file
  can be world-readable for a window after launch — and for workspaces with
  **zero** on-demand bindings, `start_for_container` never runs and the dir is
  **never** tightened at all. The Docker path does not even call
  `prepare_socket_dir`: it inlines `create_dir_all` + `fs::write`
  (`launch_runtime.rs:925-932`); only `apple_container.rs:277` uses
  `prepare_socket_dir`.
- `crates/jackin-runtime/src/exec_host.rs:238-257` authorizes exec requests
  against an allowlist matching the exact `(name, kind, source)` triple
  (`:241`) — a redacted `source` sent to the capsule will not round-trip through
  this check unchanged.
- `crates/jackin-runtime/src/runtime/launch/launch_runtime.rs:826-829` pushes
  every assembled env entry as literal argv:

  ```rust
  for env_str in &env_strings {
      run_args.push("-e");
      run_args.push(env_str);
  }
  ```

  Entries include the GitHub token under two names (`GH_TOKEN` at `:700-701`,
  `GITHUB_TOKEN` at `:806-810`), the enterprise token (`:818-824`), a Grok
  deployment key derived from the API key (pushed at `:677` inside `:670-678`),
  operator/manifest env vars (`:652-661`), and `OTEL_EXPORTER_OTLP_HEADERS`
  (`:1391-1393`). Executed via `runner.run("docker", &run_args, …)` at `:1048`.
- The Apple backend has its **own** argv assembly with the identical exposure:
  `apple_container.rs:254-270` builds the env vector and
  `apple_container_client.rs:131-137` formats `-e K=V` argv. It does not share
  `launch_runtime`'s code, so it needs its own explicit fix (Step 3).
- Contrast: `exec_host.rs:423` already inserts a `--` end-of-options sentinel,
  and `crates/jackin-capsule/src/exec.rs:236-256` scrubs secrets from exec
  output — the repo's stated posture is that secret transport is guarded.

Repository constraints:

- Forwarding the operator's configured credentials INTO a capsule that was
  explicitly configured to receive them is by design. The finding is the
  transport, not the forwarding.
- Telemetry stays registry-first; use `jackin-diagnostics` redaction helpers for
  anything that could carry a value.
- `jackin-runtime` convention (its AGENTS.md): characterization tests first
  around observable launch behavior; the launch phases have snapshot-style
  tests — update them deliberately, never loosen them to "contains".

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Tests | `rtk cargo nextest run -p jackin-env -p jackin-protocol -p jackin-runtime -p jackin-capsule` | exit 0 |
| Lint | `rtk cargo clippy -p jackin-env -p jackin-protocol -p jackin-runtime -p jackin-capsule --all-targets -- -D warnings` | exit 0 |
| E2E lane | `rtk cargo xtask ci --e2e` | exit 0 with Docker running |
| Fast gate | `rtk cargo xtask ci --fast` | exit 0 |

## Scope

**In scope**:

- `crates/jackin-protocol/src/lib.rs` (`ExecBinding`/`CapsuleConfig` docs/types,
  capsule-facing redacted projection)
- `crates/jackin-runtime/src/runtime/launch/capsule_setup.rs`
- `crates/jackin-runtime/src/runtime/launch/launch_runtime.rs` (socket-dir
  create, capsule-config serialization, env assembly and `docker run` argument
  construction)
- `crates/jackin-runtime/src/runtime/apple_container.rs` and
  `crates/jackin-runtime/src/apple_container_client.rs` (same serialization/env
  split for the Apple backend)
- `crates/jackin-runtime/src/exec_host.rs` (allowlist matching **and**
  `resolve_one`'s Literal arm)
- `crates/jackin-capsule` exec/picker regression tests (no behavior change
  expected — the picker already hides literal sources)
- `crates/jackin-env/src/resolve.rs` only if the projection is cleanest at the
  producer type level (coordinate with Plan 007, which edits the same file's
  error variants)
- `HOST_AND_CONTAINER.md` (Step 4 section)
- `plans/README.md` (status row only)
- tests beside each of the above

**Out of scope**:

- The usage-shared mount and usage broker (Plan 003).
- Changing which credentials are forwarded, auth modes, or the config schema.
- Config-time rejection of on-demand literal values (config-validation surface;
  raise with Plan 007 if wanted).
- 1Password/Keychain resolution behavior.
- `docker inspect` env exposure (inherent to env forwarding; recorded non-goal).

## Git workflow

Stay on the existing `feature/native-liquid-glass-redesign` branch and its new active
PR (`#843` is already merged historical context);
the operator explicitly selected this plan into that branch. Do not create or switch
branches. Use Conventional Commits, `git commit -s`, add
`Co-authored-by: Codex <codex@openai.com>`, and push immediately after every commit.
Never force-push.

## Steps

### Step 1: Split host and capsule projections so `Literal` values never leave the host

Do **not** redact at the producer (`resolve.rs:531-543`) — the same vector feeds
the host allowlist, and redacting there destroys the only copy (see Current
state). Instead:

1. Keep the full `ExecBinding` triples on the host: `start_for_container`
   (`launch_runtime.rs:976-981`, `apple_container.rs:324-328`) continues to
   receive the unredacted vector.
2. Introduce a capsule-facing redaction applied exactly at the two
   `toml::to_string(&capsule_config)` sites (`launch_runtime.rs:879-880`,
   `apple_container.rs:275-276`): serialize a projection in which
   `ExecKind::Literal` sources are replaced by the fixed placeholder string
   `literal` (matching `classify_str`, `resolve.rs:836-842`). `Op` and `Env`
   sources stay as-is — the capsule needs the reference text for display, and
   they are references, not secret values.
3. Fix authorization **and resolution** in `exec_host.rs` together:
   - allowlist matching for `Literal` bindings matches on `(name, kind)` and
     ignores the request's `source` (`exec_host.rs:238-257`); `Op`/`Env` keep
     exact triple matching;
   - `resolve_one` (`exec_host.rs:396-416`) must resolve `Literal` from the
     **matched allowlist entry's** source, never from the request ref — with the
     redacted capsule copy, resolving from the request would hand the agent the
     literal string `literal` as its credential. Add a regression test for
     exactly that.
4. The capsule picker already hides literal sources (`exec.rs:59-75`); add a
   regression test asserting it renders `b.name` only, and confirm no other
   capsule surface prints `binding.source` for `Literal`.
5. Fix the `crates/jackin-protocol/src/lib.rs:163-168` doc so it states the now
   actually-true contract, and note on the type that the capsule-facing copy is
   redacted.

Do not add config-time rejection of on-demand literals in this plan — that is
config-validation surface (Plan 007's territory) and would need an operator
decision about existing configs. If, while implementing, redaction turns out to
be impossible without a protocol/wire version change, STOP and report.

**Verify**:
`rtk cargo nextest run -p jackin-env -p jackin-protocol -p jackin-runtime -p jackin-capsule -E 'test(/exec_binding|capsule_config|allowlist|resolve_literal/)'`
-> serialized capsule-facing `CapsuleConfig` fixtures contain no literal source
values; exec authorization round-trips for all three kinds; the
resolve-from-allowlist regression proves a redacted request still yields the
true value; the picker regression passes.

### Step 2: Close the socket-dir permission window on both backends

Create the per-container socket directory `0o700` synchronously **before any
file is written into it**, on both launch paths:

- Docker: the inline `create_dir_all` + `fs::write` at
  `launch_runtime.rs:925-932` does not go through `prepare_socket_dir` at all —
  either route it through `prepare_socket_dir` or set the mode right there.
- Apple: `prepare_socket_dir` (`capsule_setup.rs`, called from
  `apple_container.rs:277`) gains the `0o700` create.

This must hold for workspaces with zero on-demand bindings too — today
`start_for_container` (the only chmod) never runs for them and the dir stays
umask-default forever. Keep the later `exec_host` chmod as no-op hardening. Add
tests asserting the directory mode immediately after each backend's setup
returns, including the zero-bindings case.

**Verify**:
`rtk cargo nextest run -p jackin-runtime -E 'test(/socket_dir/)'` -> mode tests
pass for Docker path, Apple path, and the zero-bindings case.

### Step 3: Move secret env values out of container-runtime argv (both backends)

Write secret-bearing env entries to an `--env-file` created `0o600` in a
**host-only** directory that is never mounted into any container — e.g. a
per-container file under the host runtime dir beside (not inside) the mounted
socket dir. Never place it in the socket/run directory: that dir is bind-mounted
at `/jackin/run`, which would hand the container a persistent secrets file and
undo Step 2. Unlink the file as soon as the `docker run` invocation returns
(`launch_runtime.rs:1048`), and also on the error path.

Pass only non-sensitive `JACKIN_*` metadata as inline `-e` args. "Secret-bearing"
is a closed list assembled where the entries are built: both GitHub tokens, the
enterprise token, the Grok API/deployment keys, every operator/manifest env var
whose value came from the env-resolution layer, and
`OTEL_EXPORTER_OTLP_HEADERS`.

The Apple backend does **not** share this assembly — apply the same split
explicitly in `apple_container.rs:254-270` / `apple_container_client.rs:131-137`.
If the `container` CLI has no env-file equivalent, keep that backend on argv,
record it as a named residual risk in `HOST_AND_CONTAINER.md`, and say so in the
PR description — do not silently skip it.

Add a test that assembles launch args for a fixture with a fake GitHub token and
asserts: (a) no `-e` argument value contains the fake token, (b) the env file
exists with mode `0o600` and contains it, (c) the env file's path is not under
any mounted directory, (d) existing snapshot tests are updated to the new shape
(never loosened).

**Verify**:
`rtk cargo nextest run -p jackin-runtime -E 'test(/launch_args|env_file/)'`
-> assertions (a)–(d) pass; then `rtk cargo xtask ci --e2e` -> capsules still
receive their env end-to-end.

### Step 4: Rotation guidance and docs

Add a short section to `HOST_AND_CONTAINER.md` (heading: `## Credential
transport`) stating the transport contract (secrets ride the 0600 host-only env
file and host-side allowlist; never argv, never container-visible config), and
note that any credential previously configured as an on-demand literal should be
rotated because it was exposed to the container filesystem. Do not list or echo
any value. Keep this section isolated so Plan 009 can correct adjacent layout and
cleanup documentation later without rewriting the credential contract.

**Verify**:
`rtk rg -n '## Credential transport' HOST_AND_CONTAINER.md` -> 1 hit (the
`docs repo-links` gate walks only `docs/content` and cannot check this file);
`rtk cargo xtask ci --fast` -> exit 0.

## Test plan

- Unit: binding projection per kind; allowlist matching per kind; socket-dir
  mode; argv/env-file split with fake secrets (never real values).
- E2E: `cargo xtask ci --e2e` proves a capsule still resolves an on-demand
  binding through the picker and receives its forwarded env.
- Negative: serialized `CapsuleConfig` and assembled argv snapshots contain no
  fixture secret string.

## Done criteria

- [x] No raw literal binding value appears in any container-visible file or DTO;
  exec resolution still yields the true value (resolve-from-allowlist test).
- [x] `ExecBinding` docs match behavior.
- [x] Socket dir is `0o700` from creation on both backends, including
  zero-binding workspaces.
- [x] No secret value appears in `docker run` argv; the env file is `0o600`,
  host-only (never under a mounted path), and removed after launch. The Apple
  backend has the same split or a documented named residual.
- [x] All tests, clippy, `--fast` and `--e2e` gates pass.
- [x] Only in-scope files and `plans/README.md` changed.

## STOP conditions

- The exec protocol cannot distinguish `Literal` matching without a wire-format
  version change — report the protocol impact first.
- The container runtime in use does not support `--env-file` semantics for some
  launch path (report which).
- Any test would require a real credential.
- An in-scope excerpt above no longer matches the code.

## Maintenance notes

Reviewers: check the closed "secret-bearing" list whenever a new env var is added
to launch assembly — the failure mode is a new secret silently going argv-inline.
The redacted-literal contract must survive any future `ExecKind` addition; add an
exhaustive-match test so a new kind fails compilation until classified.
