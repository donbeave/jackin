# jackin❯ desktop refinement feedback

Status: feedback collection only. No implementation is authorized by this file.

## Batch 1 — provider identity, section priority, and update state

### Core problem

The selected provider and account are not clear enough at a glance. Important quota
limits appear too late in the popover, while the Details section repeats context that
the provider identity block already establishes. The refresh state also uses wording
that is ambiguous or duplicated.

### Menu-bar popover

Required information order:

1. Provider identity and selected account.
2. Account selector when multiple accounts are available.
3. Limits.
4. Details.

Requirements:

- Move **Limits** above **Details**. Limits are the primary popover information.
- Keep the provider identity block first.
- Always identify the currently displayed account in the first provider block. This
  must work even when only one account exists and no account picker is shown.
- Keep any multi-account selector near the top so the selected account can be changed
  before reading its limits.
- The exact visual composition of the account indicator is not selected yet. It may
  use the account label, username/email, or another existing Rust-owned account label,
  but it must make the active account immediately unambiguous without scrolling.

### Usage window

Required information order:

1. Provider identity and selected account.
2. Account selector when multiple accounts are available.
3. Details.
4. Limits.

Requirements:

- Keep the account information at the top.
- Keep **Limits** below **Details**. The Usage window is the deeper inspection surface,
  so its order intentionally differs from the popover.
- Apply the same duplicate-removal and update-state rules described below.
- Opening Usage from a provider popover must open the Usage window with that same
  provider selected.

### Remove duplicated Details rows

Apply this cleanup to both the popover and Usage window:

- Remove **Focused**. A value such as agent + provider + account repeats information
  already communicated by the selected provider and the account shown at the top.
- Remove **Header**. Repeating `Anthropic` below the Anthropic identity block adds no
  information.
- Remove **Provider**. Repeating `Anthropic` again adds no information.
- Do not repeat **Account** inside Details after the selected account is visible in the
  top identity/account region.
- Remove the ordinary **Fresh** status presentation. Its meaning is unclear and it
  duplicates the recency communicated by the update timestamp.
- Keep genuinely useful, non-duplicated metadata only. This feedback does not yet ask
  to remove plan, credential origin/authentication, username, errors, or quota limits.

### Updated and updating wording

Resting state:

- Show one natural recency phrase, such as `Updated now`, `Updated 2m ago`, or an
  equivalent Rust-owned string.
- Never repeat the label inside its value. Invalid examples include
  `Updated: Updated just now` and `Updated at: Updated at now`.
- The rendered phrase must contain the update concept only once.

Refresh in progress:

- While a background or manual refresh is actually running, show an active state such
  as `Updating…` instead of a completed update timestamp.
- Pressing **Refresh** must change the visible state to `Updating…` immediately and
  keep it visible until the refresh finishes.
- After success, replace `Updating…` with the new recency phrase.
- A completed timestamp must not imply that an in-flight refresh has already finished.

### Exceptional status interpretation

The request explicitly removes the ordinary `Fresh` label. It does not remove useful
exceptional states. `Updating…`, stale data, provider errors, permission problems, and
offline states may remain when they communicate distinct, actionable information.

### Acceptance scenarios

- Single-account Anthropic popover: the provider block identifies Anthropic and the
  active account without scrolling; Limits precede Details.
- Multi-account popover: the identity block reflects the selected account, changing
  the picker updates that identity, and the displayed limits belong to that account.
- Anthropic Details contains no Focused, Header, Provider, duplicated Account, or
  ordinary Fresh row.
- Usage opened from the Anthropic popover selects Anthropic and preserves the account
  context.
- Usage keeps account context at the top and Limits below Details.
- Idle data shows one update phrase with no repeated `Updated` wording.
- Manual and background refresh show `Updating…` only while work is in flight, then
  return to a completed recency phrase.
- Account, provider, and update state remain accessible to VoiceOver and keyboard
  users after the visual cleanup.

## Items awaiting later feedback or design selection

- Exact typography and placement of the selected-account indicator in the provider
  identity block.
- Whether the account indicator should prefer account label, username/email, or a
  combined label when both exist.
- Final copy choice between `Updated now`, `Updated just now`, and equivalent localized
  wording.

## Batch 2 — Overview provider grouping and account correctness

### Core problem

The Overview table combines provider and account into one column, repeats provider
names on every account row, and currently shows some accounts under providers they do
not belong to. Real multi-account data, historical data, and local-auth placeholders
are visually indistinguishable, so the operator cannot tell whether repeated rows are
valid accounts or data-association bugs.

### Overview organization

Requirements:

- Separate **Provider** and **Account** into distinct concepts and columns.
- Group account rows under their provider when the native table hierarchy can express
  this clearly.
- Show each provider identity once per group instead of repeating it in every account
  title.
- Preserve the canonical provider order used by the sidebar.
- Keep each account independently selectable. Selecting an account row must open that
  provider and that exact account.
- A provider with one account should remain easy to scan and should not require a
  special unrelated layout.
- Grouping must remain understandable with keyboard navigation, VoiceOver, narrow
  windows, long account labels, errors, and expanded/collapsed provider groups.
- Exact native table construction and the expanded-by-default behavior are not yet
  selected.

A candidate information model is:

| Provider | Account | Plan or status | Remaining | Reset |
|---|---|---|---|---|
| OpenAI | account A | Pro 20x | 98% | — |
|  | account B | Pro 20x | 96% | — |

This table illustrates hierarchy only. It is not final visual authority.

### Account correctness

Requirements:

- One account must belong to exactly one canonical provider surface.
- Deduplicate by the Rust-owned stable surface/account identity, not by display text.
- Distinct genuine accounts for one provider should remain distinct.
- Never copy OpenAI accounts into Z.AI, MiniMax, Amp, or another provider group.
- Never let an account selected for one provider become the selected account for a
  different provider.
- Do not present a local credential-presence placeholder as if it were a second
  confirmed subscription account.
- Historical accounts must not look simultaneously active without an explicit product
  rule and visible provenance or recency. The retention/removal policy still needs a
  design decision.
- Provider-level status must not overwrite a different account's status. Every account
  row must use that account's own Rust-owned status.
- Overview must contain only the frozen, detected jackin❯ desktop provider catalog.
  OpenCode and undetected placeholder surfaces must not leak into it.

### Screenshot observations

The operator-supplied running-app screenshot from 2026-08-13 14:10 shows:

- two legitimate OpenAI identities in the first OpenAI area;
- the same OpenAI identities repeated again under the Z.AI surface, whose visible
  provider label has incorrectly become `OpenAI`;
- the same OpenAI identities repeated again in the MiniMax account inventory;
- Amp showing both an older email identity and `local Amp auth`;
- `local Amp auth` displayed as `fresh` even though current stored evidence describes
  it as an unsupported presence-only result;
- OpenCode in Overview even though it is intentionally outside the jackin❯ desktop
  provider contract.

The screenshot itself is not copied into the repository. These observations preserve
the actionable evidence without retaining progress imagery.

### Investigation findings

#### Confirmed cause 1 — OpenAI accounts leak into routed providers

Z.AI and MiniMax intentionally use `codex` as a routing agent slug while provider labels
distinguish their real surfaces. Account discovery also treats `agent_slug()` as a
provider-identity alias. Therefore a durable `OpenAI / Codex` account matches Z.AI and
MiniMax through their shared `codex` routing slug.

Evidence:

- `HostSurfaceId::Zai` and `HostSurfaceId::Minimax` both return `codex` from
  `agent_slug()` in `crates/jackin-usage/src/host.rs`.
- `surface_matches_provider` accepts `surface.agent_slug()` as an identity match in
  `crates/jackin-usage/src/host/accounts.rs`.
- The matching function accepts containment and OpenAI/Codex synonyms.
- The local durable store contains two real OpenAI account identities. Applying the
  production matcher classifies both into `codex`, `zai`, and `minimax`.
- The persisted Z.AI selection points at one of those OpenAI account keys, which is why
  the Z.AI glance/provider label can become `OpenAI`.

This is a structural identity-boundary bug. A routing agent slug is not a provider
ownership key.

#### Confirmed cause 2 — Amp merges historical and live identities

The older Amp email row and `local Amp auth` are different stored identities, not two
copies of one key:

- the durable database has a successful Amp email snapshot last fetched on
  2026-08-11;
- the current shared snapshot from 2026-08-13 identifies `local Amp auth` and reports
  an unsupported, presence-only result because no balance was returned;
- account discovery intentionally merges live, durable, and shared snapshots and has
  no expiration or visible provenance rule;
- the persisted Amp selection still points at the older email account.

The merge explains why both rows appear. The data may be historically valid, but the
current UI incorrectly presents both as equivalent current accounts.

#### Confirmed cause 3 — status is borrowed from the selected provider glance

The Overview inventory assigns `glance.statusLabel` to every account under a surface,
while `AccountRow.statusWord` is available but ignored. This lets an old selected Amp
account's `fresh` status appear on the separate `local Amp auth` row.

#### Confirmed cause 4 — non-desktop surfaces leak into Overview

The bridge asks Rust for accounts across every host surface. Swift then appends account
surfaces missing from the detected glance/sidebar list as `extraSurfaces`. This bypasses
the frozen Desktop catalog and explains the OpenCode row.

### Root-fix direction to validate before implementation

- Use canonical surface identity for account ownership. Routing slugs must never
  participate in account/provider association.
- Reject or clear any persisted selected-account key that does not belong to its
  canonical surface.
- Build Overview groups from detected Desktop surfaces only, then attach only accounts
  whose canonical `surfaceId` matches that group.
- Give every account row its own plan, status, remaining value, reset, error, and
  provenance/recency data as available from Rust. Do not borrow them from the selected
  provider glance.
- Decide a lifecycle for old durable accounts: omit when no longer discoverable,
  visibly mark as historical/stale, or provide an explicit removal action. Do not keep
  the current ambiguous presentation.
- Treat credential-presence placeholders as provider state unless a stable account
  identity exists.

### Acceptance scenarios

- Two real OpenAI accounts appear once, together under one OpenAI provider group.
- Z.AI and MiniMax contain no OpenAI accounts even though both route through the Codex
  agent implementation.
- An invalid persisted cross-provider account selection is rejected and cannot change
  the provider's visible identity.
- Amp does not show an old durable account and current local-auth placeholder as two
  equally current subscriptions.
- Each account row shows its own status; an unsupported local result cannot inherit
  `fresh` from another account.
- OpenCode never appears in the Overview or sidebar.
- Provider groups and child accounts remain selectable and accessible.
- Provider grouping removes repeated provider text while preserving all useful account,
  plan, limit, and reset information.

## Batch 2 items awaiting design selection

- Native grouping interaction: hierarchical Table rows, non-collapsible provider
  sections, or another standard macOS composition.
- Whether provider groups start expanded and whether expansion persists.
- Historical-account lifecycle and removal behavior.
- Whether a local-auth-only state belongs in the provider group header, an empty state,
  or an account row after stable identity becomes available.
- Whether Overview should show only detected providers or also a clearly separated
  unavailable-provider section. Current feedback requires that unavailable placeholders
  not mix with current accounts.

## Batch 3 — global jackin❯ account discovery

### Product purpose

jackin❯ desktop is the global account-and-quota view for the operator's entire jackin❯
installation. It must not monitor only the account currently active in the host's
default CLI profile. It must discover every account configured through global,
workspace, and workspace-role jackin❯ settings, merge duplicate identities, and refresh
each unique account once.

The desired answer is: which unique provider accounts are available anywhere to
jackin❯, and what quota remains for each account?

### Configuration sources to scan

Discovery must read, without mutating:

1. The global jackin❯ config at `~/.config/jackin/config.toml`.
2. Every versioned workspace file under `~/.config/jackin/workspaces/*.toml`.
3. Global per-agent auth mode and `sync_source_dir` settings.
4. Workspace per-agent overrides.
5. Workspace-role per-agent overrides.
6. Global, role, workspace, and workspace-role environment layers that declare
   provider authentication.
7. Each agent's standard host credential location when the effective mode is `sync`
   and no source-folder override exists.
8. Provider-key references such as `ZAI_API_KEY`, `MINIMAX_API_KEY`, and
   `KIMI_CODE_API_KEY`, including structured 1Password references.

The scanner must use the repository's versioned config parser, auth-mode resolver,
source-folder resolver, environment-layer resolver, and credential validators. It must
not create a second TOML schema or hand-written precedence model inside Swift.

### Existing precedence to preserve

For file-backed agent auth, the repository already defines most-specific-wins:

1. workspace × role override;
2. workspace override;
3. global setting;
4. agent default when no `sync_source_dir` is set.

Environment values have their existing layered resolution and may use plain values,
host-environment references, or 1Password references. Account discovery must evaluate
the effective sources for every persisted scope rather than choosing one currently
active workspace.

`auth_forward = "ignore"` contributes no account source for that scope. Other scopes
that resolve to a usable source remain discoverable.

### Standard file-backed sources

Current repository-owned defaults are:

| Provider/agent | Default source |
|---|---|
| Claude | `~/.claude`, plus Claude account metadata and the matching macOS Keychain scope |
| Codex | `~/.codex/auth.json` |
| Amp | `~/.local/share/amp/secrets.json` |
| Kimi | `~/.kimi-code` |
| OpenCode | `~/.local/share/opencode/auth.json` |
| Grok | `~/.grok/auth.json` |

An explicit `sync_source_dir` is the credential/config directory itself. In particular,
an Amp override points to the `amp` data directory containing `secrets.json`, not to
the parent XDG data root.

### Evidence from the operator's current configuration

The global config is `v1alpha9`; the current workspace files are `v1alpha8`. Global
settings enable `sync` for Claude, Codex, Amp, Kimi, OpenCode, and Grok. The global env
layer also contains structured 1Password references for Kimi, MiniMax, and Z.AI.

Thirteen workspace files exist. Two contain source-folder overrides:

| Workspace | Claude | Codex | Amp |
|---|---|---|---|
| `scentbird` | `~/.claude-scentbird` | `~/.codex-scentbird` | `~/.amp-scentbird/data/amp` |
| `scentbird-ai` | `~/.claude-scentbird-ai` | `~/.codex-scentbird` | `~/.amp-scentbird/data/amp` |

This produces three unique Claude profile roots, two unique Codex roots, and two unique
Amp roots after adding each default and deduplicating the repeated workspace paths.

The two alternate Claude directories exist and carry profile metadata; their OAuth
secret may be in the source-directory-specific macOS Keychain item. The shared Codex
override currently lacks `auth.json`, and the shared Amp override currently lacks
`secrets.json`. Discovery must validate these shapes and must not invent accounts from
directories that contain no usable credential.

No credential values were read or copied during this investigation.

### Current implementation gap

jackin❯ desktop does not currently read jackin❯ configuration:

- Swift opens the usage bridge with only `data_dir`, refresh floor, enabled surface
  IDs, and an allow-live-probes flag.
- `jackin-usage-ffi` depends on `jackin-usage`, not `jackin-config` or `jackin-env`.
- The host usage runtime can hold provider keys internally, but the desktop FFI does
  not provide profile discovery or provider-key configuration.
- File-backed probes resolve one ambient process profile from `HOME`,
  `CLAUDE_CONFIG_DIR`, `CODEX_HOME`, or similar defaults. They do not enumerate every
  configured profile root.
- The current multi-account list merges the active profile, durable history, and shared
  snapshots. It can discover accounts used previously, but it cannot proactively scan
  every configured workspace source.
- Structured 1Password references in jackin❯ config are not resolved for desktop
  provider probes. This explains why a configured Z.AI or MiniMax key can still appear
  as missing in the app unless the key also exists in the desktop process environment.

This is an ownership gap, not a missing Swift view. Rust needs a config-derived account
discovery model, and Swift should render its results.

### Required discovery pipeline

1. Load global and all workspace configs read-only using the canonical versioned
   parser.
2. Enumerate every effective auth scope relevant to provider usage: global, workspace,
   and workspace × role.
3. Resolve `auth_forward`, `sync_source_dir`, and provider credential env declarations
   through existing repository resolvers.
4. Convert each resolved setting into a typed credential-source candidate containing
   canonical provider surface, source kind, scope provenance, and source location or
   opaque secret reference.
5. Validate source structure before probing. Missing or malformed sources produce a
   source diagnostic, not a fake account.
6. Resolve credentials and account identity in Rust. Swift must never receive raw
   tokens, API keys, credential files, or 1Password values.
7. Merge source candidates that authenticate the same provider account.
8. Refresh quota once per unique account and fan the result out to all source
   provenance records that refer to it.
9. Publish one stable account descriptor per unique account to popover and Usage
   surfaces.
10. Reconcile removed or changed config sources so obsolete accounts do not remain
    indefinitely as apparently current.

### Unique-account identity

The credential path is not the account identity. Two workspaces can point at different
folders that contain credentials for the same provider account.

Canonical uniqueness should be:

- provider surface ID plus provider-issued stable account/organization ID when
  available;
- provider surface ID plus an authenticated account label only when the provider has
  no stronger stable identifier;
- never display text alone across providers;
- never source path, workspace name, role name, auth mode, or routing agent slug.

One account descriptor may retain multiple provenance entries, such as default host
profile, `scentbird`, and `scentbird-ai`. These entries explain where the account was
found but do not create multiple quota refreshes.

When the same raw credential is referenced more than once, exact-secret duplicates
must coalesce before network work without persisting or exposing the secret. When
different credentials resolve to the same provider account, they must coalesce after
provider identity is known. At steady state, at most one refresh may be in flight for
one canonical provider account.

### API-key and secret-reference behavior

- Recognize only the repository-governed provider credential names; unrelated global
  env values such as `CONTEXT7_API_KEY` are not usage accounts.
- Use the existing environment/1Password resolution boundary. Do not parse `op://`
  values or invoke 1Password from Swift.
- Never log, display, persist, hash without a scoped one-way construction, or include
  raw secret values in account descriptors.
- A secret-resolution failure belongs to its source candidate and must not erase
  working accounts discovered from other sources.
- API-key providers may not expose a human email before a successful provider call.
  Their stable identity and deduplication rule must come from provider evidence, not an
  invented label.

### Refresh and lifecycle behavior

- Monitor every unique discovered account, not every path or workspace reference.
- Manual Refresh refreshes all unique accounts once; provider/account refresh targets
  only that canonical account.
- Background scheduling, cooldown, retry, and shared snapshot coordination key by
  canonical provider account.
- Preserve last-known quota through transient failures, but label it stale and retain
  source/account identity.
- A source removed from all configs must stop producing refresh work. Whether its last
  account remains as explicit history or disappears is part of the Batch 2 lifecycle
  decision.
- Config reload behavior may be restart-based or live-watched, but it must be explicit
  and deterministic.

### Security and host-integrity requirements

- Config and workspace discovery is read-only. The desktop app must not migrate,
  restamp, rewrite, or normalize host config while scanning.
- Do not change the host's active CLI login, process-global profile variables, Keychain
  contents, 1Password items, or credential files.
- Resolve and probe credentials in Rust at the narrowest existing security boundary.
- Expose only non-secret account identity, plan/status, quota, reset, provenance label,
  and typed errors to Swift.
- Keep per-source failures isolated; one denied Keychain item or unavailable
  1Password account must not block all other accounts.

### Provider-scope conflict to resolve

The operator request says to scan every account available to jackin❯, and the supplied
global config includes OpenCode and GitHub auth. Current binding desktop rules exclude
OpenCode from the frozen desktop provider catalog, and GitHub is not a quota provider.

Before implementation, define one of these boundaries explicitly:

- scan all configured auth sources but display only providers with supported quota
  semantics in jackin❯ desktop;
- expand the desktop provider contract through the required Rust/catalog/schema/docs
  changes;
- or keep OpenCode/GitHub excluded and state why they are not usage accounts.

No implementation may silently contradict either the operator's “all accounts” goal or
the current frozen provider contract.

### Acceptance scenarios

- Default Claude, Codex, Amp, Kimi, and Grok sources are considered according to their
  effective auth modes.
- Both alternate Claude source directories are scanned independently from the default
  profile without falling back to default Claude credentials.
- The repeated `~/.codex-scentbird` reference is scanned once, not once per workspace.
- The repeated `~/.amp-scentbird/data/amp` reference is scanned once and validated as
  the direct Amp data directory.
- Missing `auth.json` or `secrets.json` produces a source diagnostic and no fake
  account.
- Kimi, MiniMax, and Z.AI 1Password-backed config values can drive provider discovery
  without being copied to Swift or logs.
- Two folders containing the same provider account produce one account row and one
  refresh stream.
- Two genuine accounts for one provider produce two child rows under that provider.
- The same email on different providers remains separate because provider surface is
  part of identity.
- Removing a workspace override removes its provenance and unnecessary refresh work
  after deterministic reconciliation.
- A broken source or unavailable secret does not hide accounts discovered successfully
  elsewhere.

## Batch 3 items awaiting design or contract selection

- OpenCode and GitHub scope under the “all jackin❯ accounts” requirement.
- Stable identity fallback for providers that expose quotas but no account ID/email.
- Historical-account retention after all config provenance disappears.
- Whether config changes apply live or after relaunch.
- How source diagnostics are exposed without cluttering the account-focused Overview.
- Consent and interaction policy when background discovery needs Keychain or 1Password
  access.

## Batch 4 — Rust ownership, container isolation, and single-flight refresh

### Product invariant

Account discovery, credential-source resolution, provider/account identity,
deduplication, refresh scheduling, shared-cache coordination, quota probing, error
classification, and presentation data shaping are Rust business logic owned by
`jackin-usage`.

jackin❯ desktop remains a thin native display and interaction layer:

- Swift renders immutable Rust-owned DTOs and sends coarse operator intents such as
  select account, select provider, and Refresh.
- Swift must not scan config files, walk credential directories, resolve environment
  layers, contact providers, deduplicate accounts, calculate freshness, coordinate
  locks, or infer account state.
- `jackin-usage-ffi` remains a coarse synchronous facade. It may expose discovery
  results, refresh state, and typed diagnostics, but it must not become a second
  business-logic owner.
- Capsule and desktop consume the same Rust coordination rules even though they use
  different discovery scopes.

### Existing ownership rule verification

The requested rule already exists strongly for the native boundary:

- `native/AGENTS.md` calls the app a display-only Swift shell and says Rust owns
  probes, cache, severity, and every usage number.
- `crates/jackin-usage-ffi/AGENTS.md` requires reuse of `HostUsageRuntime`, forbids
  probes in Swift/FFI, and says core truth stays in `jackin-usage`.
- ADR-011 assigns credential resolution, account selection, host-wide snapshot
  coordination, cooldowns, refresh policy, quota semantics, provider ordering, and
  displayed domain strings to Rust.

The rule is less explicit in `crates/jackin-usage/AGENTS.md`. It describes the crate as
owning probes, host runtime, snapshot store, and Capsule/Desktop shaping, but does not
explicitly name account discovery, config resolution, canonical account identity,
deduplication, or cross-process single-flight coordination. The implementation change
must strengthen that crate rule so future work cannot move these responsibilities into
Swift or the FFI adapter.

No AGENTS file is changed during feedback collection.

### Two execution contexts must remain separate

The Rust API needs an explicit discovery/visibility context. Ambient `HOME` or access
to a shared directory must never silently decide scope.

#### Host desktop context

- May read the global config and every persisted workspace/role scope described in
  Batch 3.
- Builds the operator-wide catalog of all supported unique accounts available to
  jackin❯.
- May monitor every unique discovered account.
- Keeps the global catalog and source provenance host-only.

#### Capsule context

- Knows only authentication sources actually forwarded into that Capsule.
- Builds refresh targets only from its launch config, active sessions, and forwarded
  credential capabilities.
- Must not scan the host's global jackin❯ config, workspace catalog, desktop durable
  account history, or snapshots for unrelated accounts.
- Must not learn that another host account exists through filenames, account labels,
  plans, quota snapshots, errors, or refresh metadata.

Suggested Rust modeling is an explicit type such as `UsageDiscoveryScope::HostDesktop`
versus `UsageDiscoveryScope::Capsule { forwarded_accounts }`. Exact names are not
selected, but the type boundary is required. A boolean is too weak because Capsule
scope must carry a concrete allowlist/capability set.

### Current coordination behavior — confirmed findings

The repository already has a useful partial design:

- every launch bind-mounts host `~/.jackin/data/usage-shared` at
  `/jackin/usage-shared`;
- `jackin-usage` hashes an account key into snapshot, cooldown, and lock filenames;
- `fs4::FileExt::try_lock` takes a non-blocking exclusive `flock`;
- the winner holds its file handle across provider fetch and shared-snapshot write;
- a successful refresh writes a host-shared cooldown and snapshot;
- other processes can adopt a newer shared snapshot on a later polling tick;
- the lock releases when its file handle/process exits;
- tests prove two local file descriptions cannot hold the same exclusive lock.

This is not yet the requested guarantee.

#### Gap 1 — a lock loser does not wait for the result

`RefreshLockOutcome::Held` drops the target immediately. It does not wait for the
winner, observe a refresh generation, re-read after the winner writes, or deliver the
winner's result to the manual Refresh caller. The loser can continue displaying an old
snapshot until a later poll.

#### Gap 2 — lock failure permits an unlocked provider request

`RefreshLockOutcome::Unavailable` explicitly continues without a lock. Therefore
directory creation, file opening, permission, filesystem, or lock-support failures can
re-enable parallel provider requests. A best-effort lock cannot prove “one process per
account.”

#### Gap 3 — no post-lock double check

A process decides that a target is due before lock acquisition. If it waits or later
wins after another process completed a refresh, it must re-read the shared state under
the lock before deciding to probe. Current non-blocking flow has no acquire-then-recheck
path.

#### Gap 4 — shared writes can be observed partially

Snapshots and cooldown files use direct `fs::write`. Readers do not take the writer's
lock. A reader can therefore observe an empty or partially replaced JSON/text file.
The mtime optimization can then remember an unreadable generation until another write
changes the file again. Shared state needs same-filesystem temporary write, flush as
required by the durability contract, and atomic rename/replacement.

#### Gap 5 — the whole host account tree is exposed read-write

Every Capsule receives the same root bind mount without `:ro`. Official Docker
documentation states that a bind mount exposes the mounted host directory to the
container and is read-write by default. Consequently every Capsule can enumerate,
read, modify, or delete every account snapshot, cooldown, and lock in the root, not
only data for credentials forwarded to that Capsule.

The current host tree verifies the practical exposure: the root/subdirectories are
mode `0755`, files are mode `0644`, and snapshot JSON contains non-secret but private
account identity, plan, quota, reset, and error data. This conflicts with the Capsule
visibility invariant even though raw credentials are not stored there.

#### Gap 6 — current shared identity is incomplete for multi-account discovery

Claude and Codex attempt to use resolved OAuth identity. Other providers fall back to
the provider surface key. Multiple API-key accounts for one provider would therefore
collide. Conversely, unknown candidates that use different credentials for the same
provider account cannot be deduplicated until Rust obtains trustworthy provider
identity.

The account filename hash is unkeyed 64-bit FNV-1a. It is a deterministic filename
helper, not a security boundary or collision-resistant account capability.

#### Gap 7 — force refresh is local intent, not a shared operation

`force_refresh` is an in-memory per-process set. Two manual Refresh actions from
different processes can both bypass the success cooldown. The lock prevents overlap
only while available and held; it does not represent a shared request generation that
all callers can join.

#### Gap 8 — lock behavior on Docker Desktop lacks a product proof

The installed `fs4` 1.1.0 source confirms that Unix `try_lock` calls non-blocking
exclusive `flock`. Linux and macOS document exclusive advisory-lock semantics and
automatic release on close/process exit. Docker documents that bind mounts share host
paths and that Docker Desktop bridges them through its VM, but its public bind-mount
contract does not explicitly guarantee `flock` coherence for this macOS-to-VM path.

The mechanism is reasonable, but the release gate needs a real Docker Desktop
multi-container integration test. A source comment and same-process unit test are not
proof of host + two-Capsule behavior.

### Required Rust architecture

Use one Rust-owned coordinator implementation in `jackin-usage`, shared by Capsule,
host CLI, FFI, and jackin❯ desktop.

```text
host config/workspaces ──> HostDesktop discovery scope ─┐
                                                        ├─> canonical account targets
Capsule launch/auth ─────> Capsule forwarded scope ─────┘
                                                               │
                                      per-account coordinator <─┘
                                      lock → recheck → probe → atomic publish
                                                               │
                         Capsule view / host DTO / Swift display only
```

The coordinator owns one account state machine, not three loosely related files. A
versioned per-account state envelope should contain at least:

- opaque coordination ID and canonical provider surface;
- latest completed refresh generation;
- in-flight/requested generation or equivalent join token;
- fetched timestamp and next allowed refresh time;
- last-good non-secret quota snapshot;
- typed last attempt result/error and rate-limit deadline;
- schema version sufficient for fail-closed parsing.

Raw tokens, API keys, 1Password references, source paths, workspace names, and the
global provenance list do not belong in the shared account state.

### Mandatory per-account single-flight algorithm

For timer refresh and manual Refresh:

1. Resolve the caller's typed account target within its allowed discovery scope.
2. Map it to an opaque coordination ID shared by processes that hold the same account
   capability.
3. Acquire the exclusive per-account lock before making any provider/network/CLI
   request.
4. After acquiring, re-read and validate the latest atomic account state.
5. If another process already satisfied the due/manual generation, publish that shared
   result locally and release without probing.
6. If refresh is still required, mark the shared generation in flight and keep the
   lock for the entire probe and publish transaction.
7. Atomically publish success or typed failure, advance the completed generation, then
   release the lock.
8. A caller that finds the lock held joins the existing generation: wait with a
   bounded timeout, observe state-generation change, adopt the result, and never probe
   in parallel.
9. If lock infrastructure is unavailable or shared state is corrupt, fail closed to
   last-good/stale data plus a typed coordination error. Never silently probe unlocked.

The wait happens on a blocking worker or Rust async task, never the Swift main actor or
Capsule render loop. Swift receives `Updating…` and a later immutable result/event.

### Manual Refresh semantics

- Refresh from a Capsule and Refresh from desktop are the same Rust operation for the
  same canonical account.
- If a refresh is already in flight, a new manual action joins it instead of scheduling
  a second request immediately after it.
- Multiple callers requesting Refresh during the same in-flight window receive the
  same completed generation.
- A later explicit Refresh after completion may create a new generation, subject to
  hard provider rate-limit policy.
- Provider Refresh targets one canonical account. Refresh All creates one request per
  unique account, not per workspace, credential path, session, or process.
- Waiting callers surface the winner's success/failure and new timestamp; they must not
  report success merely because their own process skipped network work.

### Identity bootstrap and deduplication

Coordination identity has two phases:

1. Before provider identity is proven, deduplicate exact credential reuse with a
   domain-separated keyed one-way fingerprint. Do not persist a raw-secret hash or use
   display text/path as identity.
2. After authenticated provider evidence yields a stable account/organization ID,
   alias the credential fingerprint to canonical provider + account identity and use
   that account for steady-state coordination.

Different credentials can represent the same provider account. That equivalence is
not always knowable locally. Unknown candidates for one provider must therefore be
identity-resolved serially, not in parallel, until aliases are known. This prevents
parallel requests to an as-yet-unrecognized same account. Once canonical identity is
known, all aliases join one refresh stream.

When a credential contains a verifiable stable account claim, Rust may use that claim
without a network identity request according to provider-specific validation. It must
not decode arbitrary text and trust an unverified claim.

### Container-safe storage and mount topology

Split host-only catalog data from shared per-account coordination data.

- Host-only catalog: discovered accounts, config provenance, account aliases, and
  desktop selection/history. Never mounted wholesale into Capsules.
- Per-account coordination directory: only the state and lock for one opaque account
  capability.
- At launch, mount into a Capsule only the per-account coordination directories for
  credentials actually forwarded to that Capsule.
- Capsules sharing the same account mount the same host account directory and therefore
  contend on the same lock/state.
- A Capsule with account A receives no path from which account B can be enumerated.
- Pass opaque coordination IDs through typed launch configuration. Do not make the
  Capsule reconstruct global identity from host paths or secrets.
- Create directories with owner-only permissions and files with owner read/write
  permissions (`0700`/`0600` or stricter equivalent), while preserving access for the
  mapped host UID used inside the Capsule.
- Do not mount a host-global read-write usage root into every Capsule.

A single host daemon/broker is not required for correctness if per-account bind mounts,
mandatory locks, atomic state, and integration proof work. If Docker Desktop cannot
prove coherent locking, move coordination behind the existing per-Capsule host socket
or another Rust host broker. Do not retain a best-effort filesystem claim.

### Failure and recovery requirements

- Process/container crash releases the advisory lock. The next winner re-reads state,
  recognizes an incomplete generation, and safely resumes or reports failure.
- Provider timeout, 429, authentication failure, and network failure publish a typed
  attempt result while preserving last-good quota according to existing policy.
- Rate-limit backoff is shared per canonical account. Twenty processes must observe one
  backoff deadline, not maintain twenty retry loops.
- Atomic publish prevents torn JSON and makes generation changes observable.
- An unsupported filesystem/lock operation is a coordination failure, never permission
  to bypass single-flight.
- Wait has a bounded deadline greater than the provider probe deadline plus publish
  allowance. Timeout returns stale/typed error; it does not launch a parallel probe.
- A malicious or broken Capsule can affect only accounts whose coordination capability
  it was given. It cannot corrupt unrelated host accounts.

### Required verification

#### Rust unit/state-machine tests

- lock winner rechecks and skips when another generation already completed;
- held caller waits and adopts the winner's success;
- held caller adopts the winner's typed failure and last-good data;
- unavailable lock produces no provider call;
- corrupt/torn state produces no unlocked provider call;
- direct and background Refresh coalesce by generation;
- exact duplicate credentials resolve once without persisting secret material;
- aliases for one canonical account share one scheduler/lock;
- separate genuine accounts refresh independently;
- Capsule scope rejects a target absent from its forwarded allowlist;
- host discovery scope can enumerate all configured supported accounts;
- atomic replacement readers see old-complete or new-complete state, never partial
  content.

#### Real process and Docker Desktop integration tests

- two host processes requesting one account concurrently cause exactly one fake probe;
- host process + two Capsules requesting one account cause exactly one fake probe;
- twenty Capsules + jackin❯ desktop requesting one account cause exactly one fake probe;
- killing the winner releases ownership and one waiter recovers without a herd;
- manual Refresh in a Capsule shows `Updating…` in desktop and both receive the same
  generation;
- manual Refresh in desktop is adopted by every relevant Capsule without extra probes;
- account A Capsule cannot enumerate/read/modify account B coordination data;
- Capsules with different accounts can refresh concurrently;
- tests run on the supported macOS 26 + Docker Desktop release path, not only a Linux
  temp directory or same-process unit test.

Use an instrumented fake provider/counter so the “exactly one request” assertion is
observable and independent of real provider credentials or rate limits.

### Documentation and architecture updates required with implementation

- Strengthen `crates/jackin-usage/AGENTS.md` with explicit ownership of discovery,
  config/auth resolution, canonical identity, deduplication, scheduler, shared cache,
  and single-flight coordination.
- Keep and extend the display-only rules in `native/AGENTS.md` and
  `crates/jackin-usage-ffi/AGENTS.md`.
- Amend ADR-011: replace the current globally mounted shared-tree claim with the
  verified account-scoped coordination contract.
- Update host/container security documentation to state that global account inventory
  is host-only and Capsules receive least-visibility account capabilities.
- Document the exact crash, timeout, manual-refresh join, backoff, and lock-unavailable
  semantics.

### Authoritative research notes

- [Docker bind-mount documentation](https://docs.docker.com/engine/storage/bind-mounts/)
  confirms that a mounted host directory is visible inside the container and is
  read-write by default. It also notes that Docker Desktop mediates host paths through
  its Linux VM.
- [Linux `flock(2)` documentation](https://man7.org/linux/man-pages/man2/flock.2.html)
  defines exclusive, blocking/non-blocking, advisory, and close-release behavior used
  by Unix `fs4` inside Capsules.
- [Apple `flock(2)` documentation](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/flock.2.html)
  defines the corresponding host-process advisory/exclusive behavior.
- Installed `fs4` 1.1.0 source and `Cargo.lock` were inspected locally; its Unix
  `FileExt::try_lock` delegates to non-blocking exclusive `rustix::fs::flock`.
- No official Docker source found during this investigation states that `flock`
  coherence across macOS host sharing and multiple Docker Desktop containers is a
  guaranteed API contract. That missing guarantee is why the real release-path test is
  mandatory and why a Rust host broker is the fallback.

### Batch 4 acceptance scenarios

- Rust owns the whole account lifecycle; Swift remains renderer + intent sender.
- Desktop discovers the operator-wide configured catalog; a Capsule sees only accounts
  actually forwarded to it.
- Twenty Capsules plus desktop produce one concurrent provider request per canonical
  account, never twenty-one.
- Every waiter receives the same refresh generation and visible result.
- A manual Refresh from any surface coalesces with work already in flight.
- Lock/state failure cannot cause an unlocked provider call.
- Shared snapshots are atomically published and last-good data survives transient
  failures.
- Different sources for one provider account merge into one account row and refresh
  stream.
- Different accounts remain isolated and may refresh independently.
- No Capsule can enumerate or modify unrelated host account state.
- macOS Docker Desktop integration tests prove the claim before the feature is called
  complete.

## Batch 5 — full-height Usage sidebar and pane-owned toggle

### Core problem

The Usage window currently reads as one full-width header placed above two content
columns. That header consumes the top of the leading column, so the sidebar begins
below it instead of owning the full leading structural region of the window. The
show/hide control consequently looks like an external toolbar action rather than part
of the sidebar navigation system.

The expanded sidebar must use the full available leading side of the window. “Full”
means the sidebar owns the leading layout region from the top window structure to the
bottom while the system applies macOS 26's inset/floating Liquid Glass shape and safe
areas. It does not mean drawing a custom edge-to-edge rectangular material.

### Confirmed current cause

This is a hierarchy problem, not a color, tint, opacity, or glass-effect problem:

- `UsageWindowRoot` creates a system `NavigationSplitView`, but explicitly removes its
  automatic `.sidebarToggle`.
- It then adds a custom `usage.sidebar-toggle` as a root `.navigation` toolbar item.
- The centered `jackin❯ desktop` brand is a root `.principal` toolbar item in the same
  window-wide toolbar.
- The Refresh action is also attached to that root toolbar.
- The resulting toolbar spans both columns, and the `List`/brand sidebar stack starts
  below it.
- ADR-011 currently codifies removal of the automatic sidebar item and replacement with
  the custom navigation item. This newly collected feedback supersedes that decision.

The existing `NavigationSplitView` and `.listStyle(.sidebar)` are the correct system
foundation. Their ownership/toolbar composition needs adjustment; custom glass is not
the fix.

### Required expanded layout

- The sidebar is the full-height leading navigation plane.
- The macOS traffic-light area remains system-owned and respects its safe area.
- The sidebar show/hide control belongs to the sidebar's top structural/control region,
  adjacent to the standard leading window controls according to system metrics.
- Overview, Providers, provider rows, and the quiet sidebar wordmark remain inside the
  same sidebar plane.
- No global header strip may run across or reserve content space above the sidebar.
- The detail/content pane begins at the sidebar divider and owns its own top toolbar
  region.
- `jackin❯ desktop` remains centered in the detail/content toolbar region, not centered
  across the combined sidebar + detail width.
- Refresh remains a detail/window action at the trailing side of the content toolbar.
- The system decides Liquid Glass shape, inset, shadow, overlap, scroll-edge behavior,
  and accessibility adaptations. Do not add explicit `glassEffect`, custom material,
  blur, background capsule, or hand-drawn sidebar chrome.

Conceptual ownership only:

```text
┌─ system window ──────────────────────────────────────────────────────┐
│ traffic lights  [sidebar toggle] │     jackin❯ desktop     [Refresh] │
│                                  │                                   │
│ full-height system sidebar       │ detail/content pane               │
│ Overview                         │                                   │
│ Providers                        │                                   │
│ …                                │                                   │
│ jackin❯ signature                │                                   │
└──────────────────────────────────┴───────────────────────────────────┘
```

The drawing describes layout ownership, not custom borders or a final pixel design.
macOS may visually inset and float the Liquid Glass sidebar within that owned region.

### Required collapsed layout

- Hiding the sidebar removes the sidebar plane and lets the detail pane consume the
  newly available width.
- The reveal control remains visible at the same stable far-leading window location.
  It must not jump into the centered brand group, move to the trailing controls, or
  disappear with the sidebar.
- “Inside the sidebar” therefore means that, while expanded, the control is visually
  and structurally part of the sidebar's top region. While collapsed, it occupies the
  same sidebar-origin reveal position so the hidden navigation can always be restored.
- The control uses the standard sidebar symbol, native tooltip/accessibility label, and
  native Show/Hide Sidebar command behavior.
- Control-Command-S and the View menu continue to invoke the same single toggle
  authority as the visible control.
- Collapse/expand animation, divider movement, focus preservation, and window resizing
  use the native split-view behavior.

### Apple Liquid Glass alignment

Apple's current guidance supports this hierarchy:

- [Sidebars — Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sidebars)
  describes the sidebar as leading navigation that floats above content in the Liquid
  Glass layer, recommends extending content beneath it, and recommends familiar native
  hide/show interactions.
- [Toolbars — Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/toolbars)
  places the sidebar show/hide control at the far leading edge and separates leading
  navigation controls, centered content, and trailing actions into familiar regions.
- [Build an AppKit app with the new design — WWDC25](https://developer.apple.com/videos/play/wwdc2025/310/)
  explains that system sidebar split items receive the appropriate floating glass
  automatically and that pane-specific split-item accessories can occupy only one
  split instead of spanning the full window.
- [Build a SwiftUI app with the new design — WWDC25](https://developer.apple.com/videos/play/wwdc2025/323/)
  confirms that `NavigationSplitView` supplies the floating Liquid Glass sidebar and
  edge-to-edge content behavior when the standard structure is preserved.

Implementation should prefer the standard SwiftUI sidebar toggle/toolbar ownership if
it meets the required stable geometry. If SwiftUI cannot express a pane-specific top
region correctly on macOS 26, use the native split-item accessory mechanism described
by Apple. Do not simulate it with an app-owned full-width header or custom glass.

### Branding relationship

- The sidebar and detail toolbar remain one coherent jackin❯ desktop window, but they
  have separate structural ownership.
- The centered `jackin❯ desktop` title remains the primary window identity without
  pushing the sidebar downward.
- The quiet `jackin❯ by tailrocks` signature remains non-interactive sidebar identity;
  it must not become a toolbar action or substitute for navigation.
- Existing jackin❯ phosphor color rules remain restrained. The system glass and native
  monochrome toolbar/navigation treatments remain primary.

### Architecture and documentation changes required with implementation

- Replace the current custom `UsageWindowNavigationState`/toolbar composition only as
  far as necessary to give native split-view state one authoritative toggle path.
- Remove the architecture test that requires the custom root
  `usage.sidebar-toggle`; replace it with tests for standard pane ownership and one
  stable toggle authority.
- Amend ADR-011's statement that the automatic sidebar item must be removed and a
  custom `.navigation` item installed.
- Preserve the native View menu command and keyboard shortcut even if the visible
  control returns to the system-provided toggle.
- Keep the existing prohibition on custom glass/material.

### Batch 5 acceptance scenarios

- Expanded window: the sidebar occupies the full leading structural height; no global
  header strip sits above it.
- Expanded window: the sidebar toggle appears in the sidebar's top region and the
  centered product title belongs to the detail region.
- Collapsed window: detail expands into the released width and the reveal button stays
  visible at the same far-leading location.
- Repeated hide/show does not move the toggle, lose the selected provider/account, or
  shift the product title into the sidebar.
- Resizing from wide to minimum supported width preserves native sidebar behavior and
  never clips the toggle behind traffic lights.
- The View menu, Control-Command-S, toolbar control, and accessibility action all
  report and mutate one real sidebar visibility state.
- VoiceOver identifies the button as Show Sidebar or Hide Sidebar according to actual
  state.
- Full Keyboard Access reaches the toggle in native order.
- Increased Contrast, Reduce Transparency, light/dark appearance, and Clear/Tinted
  system styles remain system-correct without an app-specific fallback renderer.
- Visual QA verifies both expanded and collapsed states at normal and minimum window
  sizes.
- Production code still contains zero custom sidebar material, explicit glass effect,
  or app-owned header background.
