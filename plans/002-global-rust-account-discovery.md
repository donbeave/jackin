# Plan 002: Discover every configured supported account in Rust

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If a STOP condition
> occurs, stop and report; do not improvise. Update this plan's row in
> `plans/README.md` when finished.
>
> **Drift check (run first)**:
> `git diff --stat 27d0d9b3..HEAD -- crates/jackin-config crates/jackin-env crates/jackin-core crates/jackin-usage crates/jackin-usage-ffi native/Sources/JackinUsageBridge native/Generated 'docs/content/roadmap/(operator-surface)/native-macos-usage-menu-bar.mdx'`
> Plan 001 is expected to have changed the usage/FFI excerpts. Confirm its canonical
> account/catalog types exist. Plan 007 runs first in the unified branch sequence
> and hardens `crates/jackin-config` validation/persistence/locking plus
> `crates/jackin-env` error variants. Preserve those changes, use its shared config
> read guard, and do not fork a second loader. Any other semantic mismatch is a STOP condition; a citation off
> by a few lines with the described code clearly present nearby is not drift.
>
> Command prefix note: `rtk` is an optional local output-compressor. The
> canonical command is everything after `rtk `; if `rtk` is not installed, drop
> the prefix.
>
> Architecture constraint (hard, gate-enforced): `jackin-env` and `jackin-usage`
> are both tier 3 in `crates/jackin-xtask/src/arch.rs:54,59`, and the arch gate
> (`arch.rs:368-370`, run by `cargo xtask ci --fast` via `lint --strict`) rejects
> any production dependency that does not point at a strictly lower tier.
> `jackin-usage` therefore may depend on `jackin-config` (tier 1) and
> `jackin-core` (tier 0) but MUST NOT depend on `jackin-env`. Env/1Password
> resolution reaches discovery through a port (Step 2/3), implemented in tier-4
> composition crates.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: HIGH
- **Depends on**: `plans/001-canonical-account-inventory.md`,
  `plans/007-config-validation-hardening.md`
- **Category**: direction, tech-debt, security, tests, docs
- **Planned at**: commit `27d0d9b3`, 2026-08-13

## Why this matters

jackin❯ desktop is intended to answer which unique supported accounts exist anywhere
in the operator's jackin❯ configuration and how much quota each has. Today it probes
only ambient process credential locations and merges old snapshots; it never scans
global, workspace, or role overrides. Swift must not learn configuration precedence
or receive secrets. This plan adds a read-only canonical config snapshot and a
Rust-owned discovery pipeline that resolves every effective scope, validates sources,
and deduplicates authenticated accounts.

## Current state

- `crates/jackin-usage-ffi/src/dto.rs:14-25` opens Desktop with only data directory,
  refresh floor, enabled surfaces, and a live-probe flag. It has no config root or
  discovery scope.
- `crates/jackin-usage/src/host.rs:1173-1187` creates one ambient refresh target per
  enabled surface.
- `crates/jackin-usage/Cargo.toml` has no `jackin-config` or `jackin-env`
  dependency.
- `crates/jackin-config/src/app_config/persist.rs:26-95` is not read-only:

  ```rust
  load_split_config(...)              // may split legacy embedded workspaces
  migrations::migrate_workspace_file_if_needed(&path)?; // writes the file
  ```

- `AppConfig::load_or_init` at
  `crates/jackin-config/src/app_config/persist.rs:278-335` creates directories,
  migrates files, synchronizes builtin roles, and may save. Desktop discovery must
  not call it.
- The pure migration building blocks already exist: `apply_migrations` at
  `crates/jackin-config/src/migrations.rs:415-450` transforms a `DocumentMut`
  purely in memory, and `doc_version` at `migrations.rs:470-480` reads a
  document's version without I/O. `migrate_file_if_needed` at
  `migrations.rs:382-412` is the writing wrapper — the read-only loader must not
  call it.
- `crates/jackin-config/src/app_config/roles.rs:135-156` (`resolve_sync_source_dir`)
  resolves with workspace×role -> workspace -> global precedence and returns
  `None` when unset — the **caller** falls back to
  `AgentRuntime::state_paths().credential_dir` (doc at `roles.rs:131-132`). The
  auth-mode resolver is `resolve_mode` at `roles.rs:39-46` (via
  `resolve_mode_with_trace` at `:53-80`, defaulting to `Sync`). There is no
  global-role layer for auth modes — that is a schema fact, not a bug.
- Env layering lives in `crates/jackin-env/src/resolve.rs`:
  `build_attributed_layers` at `resolve.rs:383-421` walks
  Global -> Role -> Workspace -> WorkspaceRole (last layer wins), and the
  filtered engine is `resolve_operator_env_with_matching` at `resolve.rs:574-669`,
  including account-pinned 1Password references (`op_runner.rs:48-49`). Reuse it
  with a provider-credential key predicate; do not resolve unrelated environment
  values.
- Default credential paths live in the six **agent adapters**, not in
  `runtime.rs` (which only declares the `state_paths` trait method and the
  `AgentStatePaths` struct): Claude `~/.claude` plus home file `.claude.json`
  (`crates/jackin-core/src/agent/adapters/claude.rs:82-91`), Codex
  `~/.codex/auth.json` (`adapters/codex.rs:76-81`), Amp
  `~/.local/share/amp/secrets.json` (`adapters/amp.rs:74-79`), Kimi `~/.kimi-code`
  with `credential_file: None` (`adapters/kimi.rs:74-79` — presence validation
  must not demand an auth file that the adapter does not define), OpenCode
  `~/.local/share/opencode/auth.json` (`adapters/opencode.rs:74-79`), Grok
  `~/.grok/auth.json` (`adapters/grok.rs:77-82`). Dispatch is `Agent::runtime()`
  at `crates/jackin-core/src/agent.rs:132-142`.
- `auth_forward = "ignore"` is `AuthForwardMode::Ignore` in
  `crates/jackin-core/src/auth.rs:33-35` with semantics "revoke any forwarded
  auth and never copy — container starts with `{}`". For discovery the mapping
  is: that scope contributes no source.
- No config file lock exists anywhere (`ConfigEditor::open`/`save` is an
  unlocked read-modify-write), so a concurrent CLI edit can produce a torn
  multi-file view while the desktop loader reads. The loader must defend itself
  (Step 1).
- `native/DESIGN_FEEDBACK.md` records real configurations at current global
  `v1alpha9` and workspace `v1alpha8`, including repeated Codex/Amp source roots and
  distinct Claude roots. Tests must use synthetic equivalents, never operator data.

Repository constraints:

- All discovery, credential validation, identity resolution, deduplication, and
  source diagnostics live in Rust. Swift receives only sanitized immutable DTOs.
- Reads of host config/credentials are authorized; writes are not. Discovery must
  make zero changes under the operator home.
- Respect `auth_forward = "ignore"`. A usable source in another effective scope is
  still discoverable.
- Supported Desktop quota surfaces remain Claude, Codex/OpenAI, Amp, Grok, Z.AI,
  Kimi, and MiniMax. OpenCode is an agent config source but intentionally excluded
  from Desktop. GitHub auth is not a quota surface.
- Discovery runs at host-runtime open and is reconciled again before an explicit
  manual Refresh. Background quota polling uses the last completed catalog generation
  and does not continuously rescan config or retry interactive credential acquisition.
  Relaunch always rescans. This is the deterministic config-reload contract for this
  change; do not add a watcher or another refresh policy in Swift.
- Existing macOS Keychain and 1Password access controls remain the consent boundary.
  Initial discovery may invoke their existing system-managed authorization flow for a
  configured source. A denied, unavailable, or interaction-required source becomes a
  sanitized per-source diagnostic. Background polling must not repeatedly present
  authorization UI; an explicit manual Refresh may retry it.
- Do not expose token prices, usage history, raw secret values, source paths, vault
  item paths, or 1Password account IDs to Swift, logs, telemetry, or persisted usage
  state.
- Current branch is `feature/native-liquid-glass-redesign`; use its new active PR
  (`#843` is already merged historical context). Use signed Conventional Commits with the Codex
  co-author trailer and push each commit normally; never force-push.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Config tests | `rtk cargo nextest run -p jackin-config -p jackin-env` | exit 0 |
| Usage tests | `rtk cargo nextest run -p jackin-usage -p jackin-usage-ffi` | exit 0 |
| Lint | `rtk cargo clippy -p jackin-config -p jackin-env -p jackin-usage -p jackin-usage-ffi --all-targets -- -D warnings` | exit 0 |
| Bindings | `rtk mise run desktop-bindings` | exit 0 |
| Swift harnesses | `rtk mise run desktop-test` | exit 0 (nextest + 3 harnesses; does NOT run XCTest classes) |
| Swift XCTest | `cd native && rtk swift test -c release` | exit 0, incl. the new `PresentationStoreTests` |
| Agent/docs gates | `rtk cargo xtask lint agents && rtk cargo xtask roadmap audit && rtk cargo xtask docs repo-links` | exit 0 |
| Cross-crate gate | `rtk cargo xtask ci --fast` | exit 0 |

## Scope

**In scope**:

- `crates/jackin-config/src/app_config/persist.rs`
- `crates/jackin-config/src/app_config/persist/tests.rs`
- `crates/jackin-config/src/lib.rs`
- `crates/jackin-config/README.md`
- `crates/jackin-env/src/resolve.rs` and its tests (the per-key outcome API of
  Step 2 — it does not exist at the planned-at commit; preserve Plan 007's
  redacted error variants in the same file)
- `crates/jackin-usage/src/host/accounts.rs` (or Plan 001's successor catalog
  module — Step 4's membership-authority rule changes it)
- `crates/jackin-core/src/agent.rs`, agent adapters/runtime tests only if discovery
  needs an existing credential-shape descriptor exposed
- `crates/jackin-usage/Cargo.toml`
- new discovery modules/tests under `crates/jackin-usage/src/host/`
- `crates/jackin-usage/src/host.rs`, `lib.rs`, `AGENTS.md`, and `README.md`
- `crates/jackin-usage-ffi/src/dto.rs`, `bridge.rs`, tests, and README
- generated binding outputs under `native/Generated/` and
  `native/Sources/JackinUsageBridge/jackin_usage_ffi.swift`
- `native/Sources/JackinUsageBridge/PresentationStore.swift` only to render
  sanitized discovery errors; production passes no paths (Step 5's Rust-owned
  default-path constructor); no discovery logic
- `native/Tests/JackinUsageBridgeTests/PresentationStoreTests.swift` (create —
  no such suite exists yet; `PresentationStore` currently has no dedicated tests)
- `docs/content/roadmap/(operator-surface)/native-macos-usage-menu-bar.mdx`

**Out of scope**:

- Editing any operator config, credential, Keychain item, 1Password item, or host
  environment.
- Adding a second config schema/parser, Swift-side path scanning, or shelling out from
  Swift.
- OpenCode/GitHub Desktop quota support.
- Cross-process single-flight/container capability transport: Plan 003.
- Visual Overview/provider layout: Plan 005.
- Changing the versioned config/workspace schema. A pure read-only loader is an API
  addition, not a persisted schema change.

## Steps

### Step 1: Add a canonical zero-write config snapshot loader

Add a clearly named read-only API in `jackin-config` that accepts explicit
`JackinPaths` and returns the global `AppConfig`, every split workspace, and typed
source diagnostics without mutating disk. It must:

1. read `config.toml` if present; missing means an empty/default in-memory snapshot,
   not initialization;
2. parse `DocumentMut`, reject newer versions, and run `apply_migrations` in memory;
3. handle legacy embedded workspaces in memory by extracting them into the returned
   map without creating split files;
4. read each `workspaces/*.toml`, validate the filename, run workspace migrations in
   memory, and parse it;
5. apply the same reserved-env, auth-mode, and workspace validation as normal load;
6. never call `ensure_base_dirs`, `migrate_*_file_if_needed`, `atomic_write`,
   `ConfigEditor`, `sync_builtin_agents`, or `load_or_init`.

Refactor the existing legacy transform only enough to share a pure transformation
body between mutating and read-only callers. Keep telemetry registry-first and never
emit config values or full paths.

Because no config lock exists, defend against torn multi-file reads: record the
`(path, mtime, len)` (or content-hash) set of every admitted file before parsing
and re-check it after; on a mismatch, retry the whole snapshot a bounded number
of times, then return a typed transient-conflict diagnostic. Do not add a lock
file in this plan.

Add a sentinel test tree with read-only file permissions and capture file bytes,
metadata, directory entries, and mtimes before/after. Test current global/current
workspace versions, current global/older supported workspace version, embedded legacy
workspaces, missing config, malformed file, and newer unsupported version.

**Verify**:
`rtk cargo nextest run -p jackin-config -E 'test(/disc_read_only/)'`
-> new `disc_read_only_*` tests all pass and byte/mtime/directory snapshots are
identical before and after.

### Step 2: Enumerate every effective auth scope

In `jackin-usage`, create an explicit `UsageDiscoveryScope` with at least:

- `HostDesktop { config_root, operator_home }` — may enumerate all persisted global,
  workspace, and workspace-role scopes;
- `Capsule { forwarded_accounts }` — may inspect only its explicit capabilities.

This plan implements HostDesktop enumeration; Plan 003 wires Capsule capabilities.
For HostDesktop, enumerate:

- one global scope;
- every workspace;
- every role that can be effective in each workspace, including global roles allowed
  there and workspace role overrides.

For every supported agent/provider candidate, call existing
`resolve_mode`/`resolve_sync_source_dir` and existing layered environment resolution.
Do not duplicate precedence. `Ignore` contributes no source. `Sync` with no override
uses `AgentRuntime::state_paths`; explicit Amp roots mean the directory containing
`secrets.json`, not its parent. Filter env resolution to known provider credential
keys so unrelated refs never trigger a prompt/read.

The current filtered resolver aggregates errors and discards its successful map when
any included key fails (`crates/jackin-env/src/resolve.rs:656-669`). Extract a
reusable attributed per-key outcome API **inside `jackin-env`**. Preserve launch's
existing fail-fast/aggregate adapter, while discovery consumes successful provider
sources plus isolated typed failures.

Because `jackin-usage` cannot depend on `jackin-env` (see the architecture
constraint in the preamble), discovery consumes env/1Password resolution through a
port: define in `jackin-usage` a small trait (e.g.
`ProviderCredentialEnvResolver`) whose methods accept the typed scope and the
governed provider key names and return non-secret typed per-key outcomes
(resolved-source handle, missing, denied, malformed — the secret value itself
stays behind the implementation). Implement the trait over `jackin-env`'s new
per-key API in the tier-4 composition crates that already see both sides:
`jackin-usage-ffi` for jackin❯ desktop (and the host CLI/broker wiring reuses the
same adapter type from there or its own copy in a ≥T4 crate). Config parsing,
scope enumeration, and `resolve_mode`/`resolve_sync_source_dir` reuse need no
port — `jackin-config` is tier 1 and may be a direct dependency.

"Known provider credential keys" is a closed, repository-governed set. Locate the
existing provider key-name constants (search the workspace for `ZAI_API_KEY`,
`MINIMAX_API_KEY`, `KIMI_CODE_API_KEY` — launch env assembly already consumes
them). If they are already centralized in one lower-tier crate, re-export and
reuse that registry; if they are scattered, consolidate them into `jackin-core`
in this step and point both launch and discovery at the one list. Do not
hand-write a second list inside discovery. If any pure credential-shape
validation needed here currently lives above `jackin-usage` in the crate graph
(e.g. in `jackin-instance` or launch code), move that pure logic down into
`jackin-core` (auth module) or `jackin-env` so both launch and usage can depend
on it; do not make `jackin-usage` depend upward. If the move would drag
non-pure launch behavior along, STOP and report the entangled function list.
If any step appears to require `jackin-usage` to depend on `jackin-env` or any
same-or-higher-tier crate, STOP — the port boundary above is the design; do not
re-tier crates in `arch.rs`.

Model a source candidate with canonical surface, credential kind, opaque internal
source identity, and non-secret scope provenance. Keep raw paths and resolved secret
values inside the resolver only. Provenance labels are Rust-composed and may name
the scope including its workspace/role name — `global`, `workspace scentbird`,
`workspace scentbird-ai role reviewer` — because the feedback explicitly expects
provenance entries like "default host profile, `scentbird`, `scentbird-ai`"
(Batch 3) to explain where an account was found. What stays banned in DTOs,
diagnostics, logs, and telemetry: absolute/home paths, credential file names,
`op://` URIs, vault/item coordinates, and 1Password account IDs. Diagnostics
additionally say `missing/malformed/denied` per source.

Name every new test in this plan with the prefix `disc_` so verify filters are
anchored to new work rather than pre-existing tests.

**Verify**:
`rtk cargo nextest run -p jackin-usage -E 'test(/disc_scope/)'`
-> new `disc_scope_*` tests: synthetic global/workspace/role matrices produce the
exact effective candidate set; ignored scopes contribute nothing. Zero matching
tests means the step is not done.

### Step 3: Validate each source with existing provider readers

Reuse the repository's credential definitions/readers rather than adding parallel
path knowledge:

- Claude: effective config root, account metadata, and matching macOS Keychain scope;
- Codex: effective root containing `auth.json`;
- Amp: effective data root containing `secrets.json`;
- Kimi: effective Kimi root and relevant resolved key declarations;
- Grok: effective Grok root and supported key declarations;
- Z.AI and MiniMax: filtered environment/1Password declarations.

If existing probes only read ambient `HOME`/environment, parameterize their Rust
credential resolution and snapshot construction to accept an explicit typed source.
Do not mutate process-wide environment variables to switch profiles. Missing or
malformed paths yield a typed source diagnostic, not `Current host login`, `local
auth`, a fake account, or a provider call.

Resolve structured 1Password refs through `jackin-env`'s account-pinned `OpRunner`
path with bounded execution — reached only via the Step 2 port implementation in
the tier-4 adapter, never as a direct `jackin-usage` dependency. Do not persist
resolved values. Tests must inject fake port implementations (and, in the adapter
crate, fake runners) and fake Keychain/credential readers; no real `op`,
Keychain, or network.

**Verify**:
`rtk cargo nextest run -p jackin-usage -E 'test(/disc_source/)'`
-> new `disc_source_*` tests: valid synthetic sources resolve; missing/malformed/
denied sources return sanitized diagnostics and zero probe invocations.

### Step 4: Deduplicate before and after account resolution

Deduplicate identical source locations/references before credential reads so repeated
workspace overrides are loaded once. Resolve authenticated provider identity in Rust,
then merge candidates by Plan 001's canonical account ID (ordered rule:
provider-issued stable account/organization ID first, authenticated label only as
fallback — see Plan 001 Step 1). The same account reached
through several folders/scopes becomes one account row with a provenance set; two
genuine accounts remain separate.

For credentials whose provider does not expose identity before a quota request, use a
non-secret opaque bootstrap identity suitable for Plan 003's broker. It must be stable
across processes without writing secret-derived unsalted hashes into DTOs or logs.
Prefer broker-issued capabilities/keyed fingerprints; if that cannot be implemented
without Plan 003, keep the credential value and process-local equality comparison
internal and serialize bootstrap requests per provider until the canonical account ID
is learned. Do not weaken security to gain parallelism.

Apply the lifecycle rule from Plan 001: current config discovery is membership
authority. Durable/shared history may enrich a discovered account, but it cannot
create an active account absent from discovery. A previously known but no longer
discoverable account may remain in storage; it does not appear as current Desktop
inventory.

**Verify**:
`rtk cargo nextest run -p jackin-usage -E 'test(/disc_dedup/)'`
-> new `disc_dedup_*` tests: repeated roots/refs are read once, same account
merges once, distinct accounts remain distinct, and undiscoverable history does
not create an active row.

### Step 5: Wire Desktop to the global Rust discovery scope

Selected FFI contract (do not offer alternatives): the bridge gains a Rust-owned
default-path constructor — Swift passes **no** paths for production use; Rust
derives the config root and operator home from the process environment exactly as
the CLI does. The open configuration additionally accepts an optional explicit
config-root override used only by tests/fixtures. Swift never parses config or
credentials. Opening the host runtime runs discovery off the main actor, exposes
typed progress/failure through the coarse bridge, and merges the result into
Plan 001's grouped inventory.

Before a manual Refresh creates account refresh requests, compute a non-secret config
generation from the files already admitted by the read-only loader and reconcile the
catalog if that generation changed. The generation is defined as: SHA-256 over the
sorted sequence of `(config-root-relative path, file byte content)` for every
admitted file — content-based, so `touch` does not force a rescan and an edit
always does. Equality of the hex digest means "unchanged". Removed sources stop future refresh work; added or
changed sources are validated before entering the catalog. A background quota tick
must neither rescan config nor retry a source that requires interactive authorization.
Relaunch creates a new discovery generation unconditionally. Manual Refresh
retries an interaction-required (Keychain/1Password) source exactly once per
manual action; background polling never retries it. This is normative — the test
plan asserts it.

Failures must be per-source/per-provider where possible. One malformed workspace or
denied credential must not erase last-good rows from unrelated accounts. No FFI
record may contain secrets, credential file contents, source paths, `op://` URIs, or
1Password account IDs. Export only a Rust-composed provider-level diagnostic summary
and sanitized provider-detail diagnostics; never create an account row for a source
failure. Diagnostics and provenance labels may name the scope (workspace/role
name) per Step 2's provenance contract, but never credential locations.
Regenerate bindings.

Update the native roadmap page and crate docs to state: global + all workspace/role
discovery is Rust-owned; config loading is read-only; historical snapshots are not
membership; OpenCode/GitHub remain outside Desktop quota scope.

**Verify**:
`rtk mise run desktop-bindings && rtk cargo nextest run -p jackin-usage-ffi && rtk mise run desktop-test`
-> all pass with synthetic config roots and no host writes.

## Test plan

- Use temporary `JackinPaths`, fake credential readers, fake Keychain readers, and a
  fake `OpRunner`.
- Build a synthetic equivalent of the feedback matrix: one default plus two workspace
  overrides where Codex/Amp roots repeat and Claude roots differ. Assert three unique
  Claude roots, two Codex roots, and two Amp roots before authentication; then assert
  post-auth account dedup.
- Add global, workspace, role, and workspace-role env precedence tests for Z.AI,
  MiniMax, and Kimi.
- Assert `Ignore` removes only that effective scope.
- Assert an unrelated global env key (fixture equivalent of `CONTEXT7_API_KEY`)
  produces no source candidate, triggers no Keychain/1Password read, and appears
  in no diagnostic.
- Assert one account discovered through several scopes keeps a provenance set
  naming each scope (e.g. default profile + two workspaces) while refreshing once.
- Assert the same account label on two different providers yields two accounts.
- Assert the loader's torn-read defense: a file mutated between admit and parse
  causes a bounded retry and then a typed transient-conflict diagnostic, never a
  half-merged snapshot.
- Assert a missing `auth.json`/`secrets.json` does not invent an account, and
  that Kimi presence validation does not require a credential file (the adapter
  defines none).
- Assert no serialized DTO/error/debug line contains fixture secret values, absolute
  credential paths, `op://`, vault names, or account IDs.
- Assert the read-only loader leaves bytes, mtimes, permissions, and directory entries
  unchanged.
- Assert background polling neither rereads config nor invokes Keychain/1Password
  after the discovery generation completes. Assert manual Refresh reconciles a
  changed synthetic config before scheduling quota work and retries an
  interaction-required source once.
- Assert source failures appear only as sanitized provider diagnostics, never as
  account children, and that one failing source does not erase another account.

Final gate:

```bash
rtk cargo nextest run -p jackin-config -p jackin-env -p jackin-usage -p jackin-usage-ffi
rtk cargo clippy -p jackin-config -p jackin-env -p jackin-usage -p jackin-usage-ffi --all-targets -- -D warnings
rtk mise run desktop-test
(cd native && rtk swift test -c release)
rtk cargo xtask lint agents
rtk cargo xtask roadmap audit
rtk cargo xtask docs repo-links
rtk cargo xtask ci --fast
```

All commands exit 0.

## Done criteria

- [x] Config/workspace discovery performs zero filesystem writes.
- [x] Every global/workspace/role effective auth scope is enumerated with existing
  precedence resolvers.
- [x] Default and overridden credential roots use existing agent definitions.
- [x] Provider env refs, including account-pinned 1Password refs, resolve only in Rust.
- [x] Invalid/missing sources produce diagnostics, never fake accounts.
- [x] Same source is read once; same authenticated account refreshes once; distinct
  accounts stay distinct.
- [x] Current config discovery—not historical snapshots—defines active membership.
- [x] Relaunch and manual Refresh deterministically reconcile config; background quota
  polling neither rescans config nor causes repeated credential authorization UI.
- [x] Source failures are provider-scoped sanitized diagnostics, never fake accounts.
- [x] Swift receives only sanitized immutable discovery/account projections.
- [x] OpenCode and GitHub remain outside Desktop inventory.
- [x] All tests, lints, docs gates, and fast CI pass.

## STOP conditions

- The only proposed loader calls `load_or_init`, a file migration, editor, directory
  initializer, or any other write path.
- Implementation needs to copy config precedence, credential paths, or provider
  matrices into Swift.
- A source can be deduplicated only by persisting an unkeyed secret hash or raw secret.
- A test requires real operator config, credentials, Keychain, 1Password, or network.
- Supporting current persisted versions requires a version bump or migration artifact;
  report why before changing schema.
- Plan 001 canonical identity/catalog is absent or still permits routing-slug ownership.

## Maintenance notes

Reviewers should scrutinize zero-write proof and secret-boundary tests, not only happy
path discovery counts. Plan 003 must reuse `UsageDiscoveryScope` and canonical account
IDs; it may add broker-issued opaque capabilities but must not make Capsules global
discoverers. When new agents or credential modes are added, extend the canonical Rust
agent/auth registries first, then add discovery fixtures—never add a Desktop-only path
table.
