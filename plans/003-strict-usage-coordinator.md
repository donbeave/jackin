# Plan 003: Enforce one refresh generation per account through a host broker

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If a STOP condition
> occurs, stop and report; do not improvise. Update this plan's row in
> `plans/README.md` when finished.
>
> **Drift check (run first)**:
> `git diff --stat 27d0d9b3..HEAD -- crates/jackin-usage crates/jackin-protocol crates/jackin-runtime crates/jackin-capsule crates/jackin-usage-ffi crates/jackin native docs HOST_AND_CONTAINER.md TESTING.md`
> Plans 001–002 are expected to have changed canonical account/discovery code.
> Confirm those contracts exist. Plans 006 and 008 run earlier on this branch;
> their credential-transport, mount fail-closed, and notification hardening changes
> are expected. Merge on top and do not revert them.
> Any other semantic mismatch is a STOP condition; a citation off by a few lines
> with the described code clearly present nearby is not drift.
>
> Command prefix note: `rtk` is an optional local output-compressor. The
> canonical command is everything after `rtk `; if `rtk` is not installed, drop
> the prefix.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: HIGH
- **Depends on**: `plans/001-canonical-account-inventory.md`,
  `plans/002-global-rust-account-discovery.md`,
  `plans/006-capsule-credential-exposure.md`,
  `plans/008-backend-parity-fail-closed.md`
- **Category**: security, bug, perf, tech-debt, tests, docs, direction
- **Planned at**: commit `27d0d9b3`, 2026-08-13
- **Execution state**: BLOCKED — implementation and local gates pass, including
  the complete Docker E2E profile on macOS 26.5.2 with OrbStack 29.4.0. This host
  has no Docker Desktop installation, so the required real Docker Desktop run
  remains unavailable. Operator prerequisite: install/start Docker Desktop, select
  its Docker context, then run `cargo xtask ci --e2e` and retain the CI/PR result.

## Why this matters

The current cache is a best-effort optimization, not a single-flight guarantee.
Lock failure permits an unlocked provider call, a lock loser neither waits nor adopts
the winner, manual refresh can queue another call, and time-limited worker threads may
continue after ownership is released. Worse, every Capsule receives the entire
writable shared account tree; a compromised Capsule can enumerate unrelated accounts,
corrupt state, or plant symlinks followed by a later host write. This plan makes one
host-side Rust broker the authority for discovery, refresh generations, rate limits,
and atomic cached results. Desktop and Capsules become scoped clients.

## Current state

- `crates/jackin-usage/src/usage/refresh.rs:233-278` defines
  `RefreshLockOutcome::Unavailable` as permission to proceed without a lock. Any
  lock-directory/open failure returns that outcome.
- `crates/jackin-usage/src/usage.rs:458-499` reads shared state before locking;
  a held target is dropped and returned to the caller without waiting for or
  re-reading the winner's result.
- `crates/jackin-usage/src/usage/refresh.rs:32-97` spawns one OS thread per target,
  drops join handles, and returns timeout fallbacks while the worker may continue.
- `crates/jackin-usage/src/usage/refresh.rs:292-310` writes snapshots with direct
  `fs::write`. Cooldown is written separately; `usage.rs:813-818` can commit a
  success cooldown before its snapshot.
- `crates/jackin-usage/src/usage.rs:836-863` has canonical account identity only
  for some ambient OAuth cases; otherwise coordination collapses to one surface key.
  Plans 001–002 replace this with canonical account IDs.
- `native/Sources/JackinUsageBridge/PresentationStore.swift:655-688` cancels a
  Swift task before starting another synchronous refresh. Cancellation does not prove
  the provider work stopped, so clicks can become sequential force refreshes.
- `crates/jackin-runtime/src/runtime/launch/launch_runtime.rs:908-1014` creates
  `~/.jackin/data/usage-shared` (no restrictive mode; tree is 0755/0644), then
  bind-mounts the entire directory read-write at `/jackin/usage-shared` and sets
  `JACKIN_USAGE_{SNAPSHOTS,COOLDOWN,LOCK}_DIR` — **Docker launches only**. The
  apple-container backend mounts no usage tree and sets none of those env vars
  (`crates/jackin-runtime/src/runtime/apple_container.rs:253-284`), so capsules on
  that backend currently fall back to a container-local `~/.jackin` and have **no
  cross-instance coordination at all**. Step 4 therefore removes the mount from
  the Docker path and adds the scoped relay socket to **both** backends.
- The host adopts shared snapshots with no validation:
  `usage.rs:602-620` mtime-gates then `insert_adopted_shared_view` at
  `usage.rs:624-647` replaces the cached view whenever `fetched_at_epoch` is
  strictly newer. A capsule-forged snapshot with a far-future epoch pins itself
  permanently, forged cooldown markers suppress real host refreshes, and
  free-text label fields flow to the host status bar unsanitized.
- A probe that times out (or returns `Unavailable`/`Unsupported`/`NeedsSecret`)
  currently **publishes**: `preserve_cached_quota_on_failed_refresh` rescues only
  `Stale | NeedsLogin | Error` (`usage/view.rs:367-374`), and the non-rate-limited
  else-branch at `usage.rs:806-818` writes a full-interval `"ok"` cooldown plus
  the empty snapshot. One slow probe blanks the shared view for every instance
  for ~5 minutes.
- Every ambient host poll force-marks every target: `host.rs:537-539` calls
  `request_account_refresh` unconditionally; `mark_due` inserts into
  `force_refresh` (`usage.rs:706-710`); and the forced branch checks only the
  rate-limit cooldown, skipping the success cooldown entirely
  (`usage.rs:731-739`). The cross-process success cooldown is therefore bypassed
  on every tick past the floor.
- Shared snapshot payloads include quota data and errors
  (`crates/jackin-protocol/src/control.rs:391-418`, `FocusedUsageView`) plus
  account label/username/plan/credential origin one hop away in
  `FocusedAccountHeader` (`control.rs:492-508`).
- Shared file names are predictable and `OpenOptions`/`fs::write` follow symlinks.
  Containers run as the host UID, so a malicious shared-tree symlink can redirect a
  later host write.
- `crates/jackin-runtime/src/host_daemon.rs` already supplies a host-only Unix-socket
  lifecycle and framing foundation: run dir `0o700` + socket `0o600`
  (`host_daemon.rs:386-403`), newline-framed JSON with a 16 KiB request cap
  (`:21`, `:596-608`), and a protocol-version + build-ID handshake (`:746-763`).
  Its authorization is **filesystem permissions only** — there is no peer-cred
  check. `crates/jackin-runtime/src/exec_host.rs` demonstrates a per-container
  allowlisted socket relay, but its peer authentication is **PID/NSpid-based on
  Linux** (`exec_host.rs:312-344`: peer must be the container's init process) and
  an unconditional `Ok(())` on non-Linux (`:346-349`) — there is no "UID peer
  authentication" to reuse, and on the macOS host it is a no-op. The broker/relay
  must therefore define its own peer model: host-side sockets rely on `0o700`
  dir + `0o600` socket ownership (the host_daemon pattern); the per-container
  relay socket is authorized by being mounted only into that container plus the
  per-socket capability allowlist, mirroring exec_host's allowlist (not its peer
  check). Do not expose the global broker socket directly to a Capsule.

Architecture decision for this plan:

```text
Desktop FFI ───────────────┐
                           ├─ host-only usage broker ─ provider probes + atomic state
Capsule ─ scoped relay ────┘
          allowlist: only accounts forwarded to this Capsule
```

The state machine, canonical account policy, scheduling, probe dispatch, and cache
belong to `jackin-usage`. `jackin-protocol` owns sanitized wire records.
`jackin-runtime` owns host lifecycle and per-container relay/mount assembly. Swift is
only a client/renderer. Capsules do not perform provider usage network calls after
this plan; they request and join broker generations for accounts explicitly forwarded
at launch.

Why broker, not another filesystem lock: no primary Docker source guarantees coherent
`flock` semantics across macOS host sharing and multiple Docker Desktop containers.
The existing whole-tree mount also cannot enforce account visibility. A host broker
gives one serialization authority and a capability boundary that can be tested.

Repository constraints:

- Container paths remain under `/jackin/`; use a scoped socket under `/jackin/run`.
- Global account inventory and credential sources remain host-only.
- Unsupported coordination fails closed: keep last-good/typed error, never probe
  unlocked.
- No secret value crosses FFI, broker protocol, relay protocol, cache, log, or
  telemetry. Broker resolves Plan 002's host source capabilities internally.
- Use registry-first telemetry and existing scrubbers.
- Current `feature/native-liquid-glass-redesign` branch and its new active PR (`#843`
  is already merged historical context); signed Conventional Commits, Codex co-author trailer,
  immediate normal pushes, no force-push.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Coordinator tests | `rtk cargo nextest run -p jackin-usage -p jackin-protocol -p jackin-runtime -p jackin-capsule -p jackin-usage-ffi` | exit 0 |
| Lint | `rtk cargo clippy -p jackin-usage -p jackin-protocol -p jackin-runtime -p jackin-capsule -p jackin-usage-ffi --all-targets -- -D warnings` | exit 0 |
| Runtime E2E | `rtk cargo xtask ci --e2e` | exit 0 with Docker running |
| Full gate | `rtk cargo xtask ci` | exit 0 |
| Docs | `rtk cargo xtask roadmap audit && rtk cargo xtask docs repo-links && rtk cargo xtask research check && rtk cargo xtask lint agents` | exit 0 |

## Scope

**In scope**:

- coordinator/state/cache/probe modules under `crates/jackin-usage/src/usage/` and
  host modules under `crates/jackin-usage/src/host/`
- `crates/jackin-usage/src/usage.rs`, `host.rs`, `lib.rs`, tests, Cargo.toml,
  `AGENTS.md`, README
- `crates/jackin-protocol/src/lib.rs`, `control.rs`, tests, README
- `crates/jackin-runtime/src/host_daemon.rs`, `host_daemon/`, `exec_host.rs`,
  runtime launch code/tests for Docker and Apple container backends, Cargo.toml,
  README
- `crates/jackin-capsule` usage-refresh client/daemon paths and tests
- `crates/jackin-usage-ffi` broker client/open/refresh/projection paths and tests
- generated native FFI binding outputs
- native `PresentationStore` refresh-task/state **code and** its tests (Step 5
  changes its coalescing/task model; no view/layout changes — rendering is
  Plan 005)
- `crates/jackin/tests/usage_broker_e2e.rs` (create) and `crates/jackin/Cargo.toml`
  if the e2e feature needs a dev-dependency
- `.config/nextest.toml` (both default-filters — see Step 3 verify)
- `crates/jackin-core/src/container_paths.rs` (`USAGE_SOCK` const)
- process/Docker integration fixtures under existing Rust E2E/xtask test surfaces
- `HOST_AND_CONTAINER.md`, `TESTING.md`
- `docs/content/reference/adrs/adr-011-native-macos-usage-menu-bar.mdx`
- `docs/content/roadmap/(reactive-daemon-program)/jackin-daemon.mdx`
- `docs/content/roadmap/(operator-surface)/native-macos-usage-menu-bar.mdx`

**Out of scope**:

- Exposing the global host broker socket or global state directory inside a Capsule.
- Continuing filesystem `flock` as a correctness fallback.
- Sending credentials from Capsule/Swift to broker.
- Monitoring credentials created only inside a Capsule and not forwarded by the
  jackin❯ launch configuration. That would need a separate secure enrollment design.
- Provider UI/layout work, token prices, history/trends, or unrelated host-daemon
  adapters.
- A best-effort lane. Coordination failure is a typed no-probe result.

## Steps

### Step 1: Specify the coordinator protocol and state machine

Add versioned sanitized protocol types for:

- account capability (opaque ID plus canonical surface; no display label required for
  authorization);
- request current snapshot;
- request refresh with observed generation and `force` intent;
- join/wait for a named generation;
- terminal success/failure response carrying sanitized usage projection;
- refresh phase: idle, queued, updating, completed, failed;
- typed coordination errors (unavailable, unauthorized, owner lost, wait timeout,
  corrupt state), never raw IO paths/errors.

Implement the coordinator state machine in `jackin-usage`. Per canonical account:

1. If a generation is active, every request—including manual force refresh—joins it.
   It never queues a second post-completion force refresh from requests that
   arrived during the in-flight window. A **later** explicit operator Refresh
   after a terminal generation starts a new generation, subject to the shared
   provider rate-limit deadline (Batch 4 explicitly allows this; without it,
   Refresh would be a permanent no-op after first completion).
   Force semantics are reserved for explicit operator Refresh: an ambient timer
   tick must never set force and must honor the shared success cooldown (this
   replaces the current behavior where every host poll force-marks every target
   and bypasses the success cooldown — see Current state). Refresh All creates
   exactly one request per unique canonical account — never per workspace,
   credential path, session, or process.
   The typed discovery scope from Plan 002 is completed here: implement
   `UsageDiscoveryScope::Capsule { forwarded_accounts }` in `jackin-usage` (Plan
   002 shipped only `HostDesktop`) and unit-test that a Capsule scope rejects any
   target absent from its forwarded allowlist before credential or provider
   access.
2. The winner rechecks terminal generation/rate-limit state after acquiring ownership.
3. One bounded worker executes the provider probe. Ownership remains active until the
   provider worker has actually terminated; returning a timeout while its thread still
   runs is forbidden.
4. All waiters receive the same terminal generation and result.
5. Owner death/worker failure produces a typed terminal generation and preserves
   last-good quota. Recovery grants exactly one later generation after the bounded
   lease/recovery rule.
6. Coordination unavailability/corruption yields typed stale/error output and zero
   provider calls.
7. Distinct proven accounts may refresh concurrently through a bounded executor;
   unknown bootstrap identities serialize per provider until Plan 002 resolves them.

A terminal result publishes to the shared/last-good state only when it actually
carries data or is a typed failure: a timed-out, unavailable, unsupported, or
needs-secret probe must never overwrite a data-bearing snapshot and must never
stamp a success cooldown (see Current state — today one slow probe blanks every
instance for the full interval). Failures write typed failure state with an
appropriate retry deadline while preserving last-good quota.

Use a configurable provider executor trait so tests count calls without network or
credentials. Remove the one-OS-thread-per-target fan-out and enforce a small bounded
concurrency value in Rust. (The old `in_flight` boolean and its
panic-leaves-it-stuck-forever hazard at `usage.rs:450-570` disappear with this
rewrite; the replacement must clear in-flight state via RAII/scope, not
straight-line assignments.)

**Verify**:
`rtk cargo nextest run -p jackin-usage -E 'test(/coordinator/)'`
-> new state-machine tests (name them `coordinator_*`) pass for winner, joiner,
force join, post-terminal manual Refresh creating a new generation, ambient-tick
honoring success cooldown, Refresh All fan-out (N unique accounts -> exactly N
requests), alias set sharing one scheduler/lock entry, no-publish-on-empty-result,
coordination-unavailable -> zero provider calls, corrupt/torn state -> zero
provider calls, Capsule scope rejecting a non-forwarded target, failure, owner
loss, timeout, unknown bootstrap, and distinct-account concurrency.

### Step 2: Persist one atomic host-only account envelope

Replace independent snapshot/cooldown/lock files with one versioned per-account state
envelope containing:

- canonical account/capability ID and schema version;
- monotonic generation and refresh phase;
- terminal sanitized result plus last-good result;
- started/completed timestamps;
- rate-limit deadline and consecutive failure count;
- provider response retry deadline when supplied.

The broker is the only writer. Store state beneath a host-only jackin❯ data/runtime
directory with directories `0700` and files `0600`. Use directory-relative no-follow
opens/owner checks so a symlink cannot redirect reads/writes. Commit via same-directory
temporary file, file `fsync`, atomic rename, then directory `fsync`. Readers see the
old complete envelope or new complete envelope, never partial JSON. A corrupt or
unsupported envelope fails closed and preserves any separately verified last-good
state; it never authorizes a probe.

Preserve actual provider `Retry-After`/rate-limit deadlines and failure count in the
envelope. Do not cap a provider-mandated deadline to a shorter local value. A manual
refresh joins active work and respects an active provider-mandated backoff.

Because the current shared tree taught the host to trust container-written JSON
(see Current state), broker-side ingestion of any externally sourced state is a
validated boundary: cap body size, reject `fetched_at_epoch` beyond now plus a
small skew allowance, validate the schema version fail-closed, and clamp/strip
control characters and length on every display string before a value can enter
the cache, the SQLite store, or a DTO. Identity-bearing fields (account label/
email, username, plan, credential origin) live in host-only state and are never
written where a container can read them.

Delete the usage crate's `fs4` dependency if no usage code still uses it. Do not remove
workspace-level `fs4`; other crates use it.

**Verify**:
`rtk cargo nextest run -p jackin-usage -E 'test(/atomic_state|symlink|rate_limit/)'`
-> tests prove permissions, no-follow behavior, crash points, old-or-new reads, and
shared retry state.

### Step 3: Run/attach one host broker from every host client

Provide an idempotent `ensure_usage_broker` used by:

- the installed host daemon when present;
- `jackin-runtime` before launching a Capsule;
- `jackin-usage-ffi` when jackin❯ desktop opens.

Exactly one host process wins the broker socket/leader guard. Other host processes
connect. A stale PID/socket is recovered without two simultaneous servers. The broker
loads Plan 002's read-only discovery catalog and is the only component allowed to
resolve configured credential capabilities and dispatch provider probes.

Use the host daemon's existing framed Unix-socket, permission, coredump, build-ID, and
version-handshake patterns (`host_daemon.rs:386-403`, `:596-608`, `:746-763`).
Leader election reuses the same lifecycle shape: atomically bind the socket in a
`0o700` run dir with a PID guard file; a connect-probe distinguishes a live
leader from a stale socket, and stale socket+PID are removed before rebinding.
If extending the existing daemon introduces a dependency
cycle, keep a dedicated `usage-broker.sock` transport in `jackin-usage` and have
runtime/FFI adapt to it; do not move the business state machine out of usage. The
broker socket and persisted envelope directory must never be mounted into containers.

**Verify**:
add the multi-process integration test as a new integration-test target
`crates/jackin/tests/usage_broker_e2e.rs` (the same surface that hosts
`dind_e2e.rs`), guarded with `#![cfg(feature = "e2e")]`. Registration requires
editing `.config/nextest.toml` — both filters, or the new binary is silently
excluded from the e2e profile and wrongly included in the default one:
`[profile.docker-e2e] default-filter = 'binary(/dind_e2e|usage_broker_e2e/)'`
and `[profile.default] default-filter = 'not binary(/dind_e2e|usage_broker_e2e/)'`.
Then ->
`rtk cargo nextest run -p jackin --features e2e --profile docker-e2e -E 'test(/usage_broker/)'`
runs the new tests (zero tests executed = registration failed) and shows 20 host
clients concurrently force-refreshing one fake account produce exactly one
fake-provider invocation and one terminal generation.

### Step 4: Replace the global Capsule mount with scoped relay capabilities

During launch, derive the Capsule's allowed account capabilities only from the
credentials actually forwarded for its effective workspace/role. Add those opaque
capabilities to the host-side relay configuration, not to a globally enumerable
Capsule config list. Start a per-container usage relay whose socket lives inside the existing
per-container socket directory — that directory is already bind-mounted
wholesale at `/jackin/run` (`launch_runtime.rs:986-993`;
`apple_container.rs:277-279`), so the relay appears at `/jackin/run/usage.sock`
with **no new mount argument**. Add the container path as a `USAGE_SOCK` const in
`crates/jackin-core/src/container_paths.rs` — a raw `"/jackin/run/usage.sock"`
literal elsewhere fails `cargo xtask lint container-paths` (the gate allowlists
only `container_paths.rs`/`derived_image.rs` as `/jackin` string sources).

The relay must:

- authorize every request against that container's exact capability allowlist;
- reject list/global-discovery operations;
- forward sanitized request/result frames to the host broker;
- never return another account's metadata or state;
- authorize by construction: the relay socket is mounted only into its own
  container, its capability allowlist is fixed at launch (the exec_host
  allowlist pattern, `exec_host.rs:238-257`), and host-side socket files stay
  `0o600` in `0o700` dirs. Do not claim UID peer authentication — exec_host's
  peer check is Linux-PID-based and a no-op on macOS (`exec_host.rs:346-349`);
  if a stronger in-container peer check is feasible, it is optional hardening,
  not the boundary;
- close/revoke capabilities when the container session ends.

Remove the `usage-shared` directory creation, read-write bind mount, and
`JACKIN_USAGE_{SNAPSHOTS,COOLDOWN,LOCK}_DIR` container environment from the Docker
launch path (the Apple-container path never had them — see Current state). Add the
relay socket mount to **both** Docker and Apple-container launches so the Apple
backend gains usage coordination for the first time. Add negative launch-argument
tests for both backends proving no `usage-shared` mount/env remains and the only
usage surface is `/jackin/run/usage.sock`.

**Verify**:
`rtk cargo nextest run -p jackin-runtime -p jackin-protocol -E 'test(/usage_relay|usage_mount/)'`
-> account A can read/refresh A; A cannot enumerate/read/modify B; launch args for
both backends contain no `usage-shared` mount, no `JACKIN_USAGE_*_DIR` env, and
no additional usage-specific mount (the relay rides the existing `/jackin/run`
dir mount). Also `rtk cargo xtask lint container-paths` -> exit 0 with the new
`USAGE_SOCK` const.

### Step 5: Make Capsule and Desktop pure coordinator clients

Change Capsule refresh paths to request/join through `/jackin/run/usage.sock` and
adopt broker snapshots. Remove direct provider refresh execution from Capsule runtime
paths. Out-of-scope capability requests fail before credential or provider access.

Change host runtime/FFI refresh to request/join the broker. The FFI contract is
non-blocking for waiters: a refresh/join bridge call returns immediately with the
current phase/generation; the bounded generation wait happens on Rust worker
threads (deadline greater than probe deadline plus publish allowance), and Swift
observes completion through the existing poll/event path. No bridge call may
block the Swift main actor for the duration of a provider probe. Eliminate Swift
task cancellation as coalescing authority: `PresentationStore` sends intent once,
renders the Rust phase/generation, and accepts the terminal projection.
Background poll and manual Refresh use the same broker operation, and the
background poll never sets force. Plan 005 will render `Updating…`; this
step must expose the phase immediately.

On broker unavailable, both clients show last-good/typed coordination failure and
make zero provider calls. Never fall back to the old filesystem path.

**Verify**:
`rtk cargo nextest run -p jackin-capsule -p jackin-usage-ffi -E 'test(/broker_client/)' && rtk mise run desktop-test`
-> new `broker_client_*` tests (zero running = step not done) prove clients join
one generation, preserve last-good on failure, and never invoke provider code
locally.

### Step 6: Prove the real process and Docker Desktop contract

Add an instrumented fake provider/counter and deterministic barriers, extending
the Step 3 target `crates/jackin/tests/usage_broker_e2e.rs`, covering:

- two host processes -> exactly one call;
- Desktop host + two Capsules -> exactly one call;
- 20 Capsules + Desktop -> exactly one call;
- winner process killed -> one recovery owner, no herd;
- provider timeout -> ownership held until worker ends;
- manual Refresh from Capsule is visible as the same updating generation in Desktop;
- manual Refresh from Desktop is adopted by Capsules without another call;
- typed failure/last-good result is identical for all waiters;
- account A Capsule cannot enumerate/read/modify B;
- distinct accounts refresh concurrently within the bound;
- rate-limit deadline/failure count are shared;
- broker/state unavailable -> zero calls;
- no global usage tree is mounted.

Run these on supported macOS 26 with Docker Desktop, not only a Linux temp directory.
If normal hosted CI cannot provide Docker Desktop, document the gate as a named
mandatory lane in `TESTING.md` (command, expected machine-readable output =
nextest JUnit under `target/nextest/docker-e2e/`, and the rule that the active PR
completion waits for it); the durable evidence is the PR check/comment recording
that run, never a committed file. Documenting the lane is required **in
addition to** running it, never instead: until a real macOS 26 + Docker Desktop
run is recorded in the PR, this plan's status is BLOCKED, not DONE. Temporary
counters/logs live in ignored `.build`/`target` directories and are deleted
after the run. When touching `TESTING.md`/`HOST_AND_CONTAINER.md`, keep the broker
topology self-contained so Plan 009 can correct the final layout list and cleanup
command without undoing this contract.

**Verify**:
`rtk cargo xtask ci --e2e`
-> all fake-provider and isolation assertions pass on Docker Desktop; counter is 1 for
the 20+Desktop case.

### Step 7: Correct normative docs

Update `crates/jackin-usage/AGENTS.md`, `native/AGENTS.md`,
`crates/jackin-usage-ffi/AGENTS.md` (the feedback's Batch 4 documentation list
requires keeping **and extending** the display-only rules in both of the latter),
ADR-011, `HOST_AND_CONTAINER.md`, `TESTING.md`,
crate/runtime READMEs, and both roadmap pages. State explicitly:

- host Desktop discovers globally; Capsule sees only forwarded account capabilities;
- Rust (`jackin-usage`) explicitly owns account discovery, config/auth
  resolution, canonical account identity, deduplication, scheduling, shared
  cache, and single-flight coordination (the seven Batch 4 ownership terms — all
  of them go into `crates/jackin-usage/AGENTS.md`);
- one Rust broker owns refresh generation, cache, and rate limits;
- all active callers join; force does not queue a second generation;
- coordination failure is fail-closed;
- timeout ownership lasts until provider work terminates;
- atomic state/crash recovery semantics;
- rate-limit backoff deadlines and failure counts are shared per canonical
  account — N processes observe one deadline, not N retry loops;
- no global account tree is mounted into a container;
- Capsule refresh targets come only from launch-forwarded credential
  capabilities; credentials created inside a Capsule and never forwarded are
  explicitly out of scope pending a secure enrollment design (record this
  Batch 4 scope reduction in `plans/README.md` and the roadmap page);
- Docker Desktop E2E is required evidence.

Remove claims that shared `flock`/cooldown files guarantee one call.

**Verify**:
`rtk cargo xtask lint agents && rtk cargo xtask roadmap audit && rtk cargo xtask docs repo-links && rtk cargo xtask research check`
-> all exit 0. These gates cannot detect missing statements (`docs repo-links`
walks only `docs/content`; `lint agents` checks symlinks), so additionally:
`rtk rg -n 'single-flight' crates/jackin-usage/AGENTS.md` -> ≥1 hit;
`rtk rg -n 'usage-shared' HOST_AND_CONTAINER.md` -> hits describe the removed
mount only in past-tense/socket terms;
`rtk rg -n 'at most one probe' docs/content/reference/adrs/adr-011-native-macos-usage-menu-bar.mdx`
-> the claim is either gone or restated as the broker guarantee.

## Test plan

- Unit: pure coordinator transition table with fake clock/executor/store.
- State IO: permissions, symlink rejection, owner mismatch, torn temp, crash between
  file sync/rename/directory sync, corrupt/unknown version.
- Process: independent clients and broker leader recovery.
- Runtime: Docker/Apple launch args and scoped relay authorization.
- Capsule/FFI: same generation/phase/result, last-good preservation, fail-closed.
- Docker Desktop: 2, 20, killed owner, different accounts, account isolation.
- Security assertions: no snapshot/account metadata or credential source crosses an
  unauthorized relay; no raw IO path/secret enters telemetry/errors.

Final gate:

```bash
rtk cargo nextest run -p jackin-usage -p jackin-protocol -p jackin-runtime -p jackin-capsule -p jackin-usage-ffi
rtk cargo clippy -p jackin-usage -p jackin-protocol -p jackin-runtime -p jackin-capsule -p jackin-usage-ffi --all-targets -- -D warnings
rtk mise run desktop-test
rtk cargo xtask ci --e2e
rtk cargo xtask ci
rtk cargo xtask lint agents
rtk cargo xtask roadmap audit
rtk cargo xtask docs repo-links
rtk cargo xtask research check
```

All commands exit 0; Docker Desktop evidence is retained only in the PR/check result,
not as committed logs/screenshots.

## Done criteria

- [x] Exactly one active refresh generation exists per canonical account.
- [x] Manual/background requests join active work and receive one terminal result.
- [x] Timeout never releases ownership while provider work continues.
- [x] Broker/rate-limit/state failure produces zero unlocked provider calls.
- [x] One atomic envelope owns snapshot, generation, failure, and cooldown.
- [x] State files are host-only, no-follow, `0600`; directories are `0700`.
- [x] No Capsule receives the global broker socket or global account state tree.
- [x] Capsule relay authorizes only explicitly forwarded accounts.
- [x] Desktop (via FFI/`PresentationStore` state, fixture-proof) and Capsule
  expose the same Rust generation/phase/result; final Desktop visual rendering
  of that phase is Plan 005's gate, not this one.
- [x] Ambient ticks never bypass the success cooldown; Refresh All issues exactly
  one request per unique canonical account.
- [x] A timed-out/unavailable/unsupported probe never overwrites a data-bearing
  snapshot and never writes a success cooldown.
- [x] Broker ingestion validates size/epoch/schema and sanitizes display strings;
  identity-bearing fields never reach container-readable state.
- [x] 20 Capsules + Desktop make exactly one fake-provider request for one account.
- [x] Different accounts can refresh concurrently within a bounded executor.
- [ ] macOS 26 Docker Desktop test proves process/container behavior.
- [x] All unit, integration, lint, docs, and full CI gates pass.

## STOP conditions

- The proposed design still depends on cross-Docker `flock` correctness.
- A Capsule must receive the global broker socket/tree or another account's metadata.
- A coordination error path performs a provider call.
- Provider timeout cannot cancel/join the worker while keeping ownership. Report the
  provider adapter that lacks a bounded/cancellable operation.
- Canonical account/source capabilities from Plans 001–002 are missing.
- Real Docker Desktop verification cannot run. Do not claim completion; report the
  unavailable gate and exact command/operator prerequisite.
- No workable peer/authorization model exists for the relay on the target
  platform (e.g. per-container socket-dir isolation turns out insufficient).
  Report the measured gap; do not ship an unauthorized socket.
- Implementation requires credentials to cross Swift, relay, cache, logs, or telemetry.

## Maintenance notes

Treat the broker protocol as a security boundary. Review authorization before
functionality, then generation transitions, then crash durability. New providers must
join through the same coordinator; no provider may add a direct Capsule/Desktop probe
lane. If local-only Capsule authentication is desired later, design explicit secure
capability enrollment rather than remounting global state or accepting caller-chosen
account IDs.
