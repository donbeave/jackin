# Plan 001: Make account identity and Desktop inventory canonical in Rust

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If a STOP condition
> occurs, stop and report; do not improvise. Update this plan's row in
> `plans/README.md` when finished.
>
> **Drift check (run first)**:
> `git diff --stat 27d0d9b3..HEAD -- crates/jackin-usage crates/jackin-usage-ffi crates/jackin-core/src/account_key.rs native/Sources/JackinUsageBridge native/Generated native/Tests native/Tools/DesktopParityMatrixHarness native/AGENTS.md`
> If an in-scope file changed, compare the excerpts below with live code. A
> **semantic** mismatch is a STOP condition; a citation that is off by a few
> lines with the described code clearly present nearby is not drift.
>
> Command prefix note: `rtk` is an optional local output-compressor. The
> canonical command is everything after `rtk `; if `rtk` is not installed, drop
> the prefix.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: none
- **Category**: bug, tech-debt, perf, tests
- **Planned at**: commit `27d0d9b3`, 2026-08-13

## Why this matters

The current account inventory treats routing aliases and fuzzy display labels as
provider ownership. Z.AI and MiniMax route through the Codex implementation, so real
OpenAI accounts can be copied into those providers. The same pipeline mixes live,
durable-history, and presence-only records, then lets Swift borrow the selected
provider's status for every account. This plan establishes one exact Rust-owned
identity/catalog boundary and one complete grouped Desktop projection before global
config discovery is added.

## Current state

- `crates/jackin-usage/src/host.rs:124-136` maps both Z.AI and MiniMax to the
  `codex` routing slug (`agent_slug()` returns `"codex"` at `host.rs:132`).
  Routing is valid; using it as account ownership is not.
- `crates/jackin-usage/src/host/accounts.rs:223-232` is `surface_matches_provider`;
  it accepts `surface.agent_slug()` as an identity match. `provider_matches` at
  `accounts.rs:138-155` additionally accepts substring containment
  (`accounts.rs:145-146`) and OpenAI/Codex synonym pairs (`accounts.rs:147-148`).
  `surface_for_view` at `accounts.rs:119-136` shares the same defect but is
  masked by first-match ordering over `HostSurfaceId::ALL`; the durable-store
  path at `accounts.rs:183` is where cross-provider binding actually happens.
  Fix all three sites, not only `surface_matches_provider`.
- `crates/jackin-usage/src/host/accounts.rs:166-221` (`collect_account_views`)
  merges the live view, durable database rows, and every shared snapshot. Those
  sources carry no visible lifecycle/provenance contract.
- `crates/jackin-usage/src/host.rs:691-703` already drops duplicate placeholder
  rows (condition at `:696`, when `account_map.len() > 1 && key != live_key`)
  and relabels the survivor `Current host login` (`:702-703`) — so the live
  placeholder always survives as a fake account even though duplicates are
  pruned.
- `crates/jackin-usage/src/host.rs:635-716` lists `HostSurfaceId::ALL` when no
  surface is supplied. That includes OpenCode, which `native/AGENTS.md` excludes
  from the frozen Desktop contract.
- `crates/jackin-usage/src/host.rs:718-739` persists any nonempty selected
  account key without proving that the key belongs to the supplied surface
  (surface validated at `host.rs:723-724`; key inserted unchecked at
  `host.rs:728-729`).
- `crates/jackin-usage/src/host.rs:69-77` already defines the correct Desktop
  provider membership/order through `DESKTOP_PROVIDER_ORDER` (OpenCode excluded
  per the comment at `host.rs:67-68`); reuse it. `provider_glance_rows` at
  `host.rs:1030-1065` merely iterates it.
- `crates/jackin-usage/src/host.rs:417-423` silently drops unknown
  `enabled_surface_ids` at open — a typo yields an `Ok` runtime with everything
  disabled and a blank UI with no diagnosable cause.
- `crates/jackin-usage/src/host.rs:677-696` picks the `selected` flag from the
  full key list (`:677-682`) before the placeholder display filter at `:696`
  runs, so the selected row can be filtered out and the returned list has no
  `selected == true` entry.
- `crates/jackin-usage/src/host.rs:401-441` (`open`) repoints store paths but
  never resets `self.cache`, `self.events`, or `self.next_seq`, so a re-open
  against a different `data_dir` serves the previous profile's snapshots
  (cache keys are surface labels, not data-dir-scoped).
- `crates/jackin-usage/src/usage_snapshot_store.rs:930-946`
  (`load_account_usage_view`) loads the full table per account (N+1; see also
  `host/accounts.rs:181-196`) and, after filtering to the latest `fetched_at`,
  keeps rows from **all** sources — a multi-source account renders duplicate
  same-label buckets and a header whose source/confidence may belong to a
  different probe than the numbers shown.
- `crates/jackin-usage-ffi/src/dto.rs:198-206` (`AccountDescriptorDto`) exports
  exactly `surface_id, account_key, account_label, plan_label, selected,
  remaining_percent, status_word` — no reset, exact reset, error, update
  recency, or lifecycle/provenance.
- `native/Sources/JackinUsageBridge/OverviewInventory.swift:107-158` appends
  account-only `extraSurfaces`, composes provider/account/percent/reset strings,
  and assigns one glance status/error to all accounts.
- `native/Sources/JackinUsageBridge/PresentationHelpers.swift:146-155` declares a
  second Swift `frozenHostSurfaceIds` catalog with eight entries, including OpenCode;
  `DesktopParityMatrixHarness` (asserts 8 surfaces at
  `native/Tools/DesktopParityMatrixHarness/main.swift:47`) and architecture tests
  require it. It is not the only Swift provider catalog: `statusItemSystemImage`
  (`PresentationHelpers.swift:161-173`, 8 ids), `desktopProviderIconKeys`
  (`:177-179`), `desktopProviderOverviewRole` (`:184-195`, provider display copy),
  `statusItemFallbackGlyph` (`:248-265`), `ProviderMarks.swift:32-43` (7 ids; the
  unused `desktopProviderBrandChrome` RGB table at `:11-22`), and
  `ProviderUsageLinks.swift:20-47` (7 ids + URLs + a duplicate order array) all
  encode provider membership or provider display knowledge in Swift. Provider-
  specific icon/asset lookup may remain Swift presentation, but catalog
  membership/order/display-copy must come only from Rust.
- `native/AGENTS.md` currently mandates that `DesktopParityMatrixHarness` proves
  "full frozen catalog displayability". That mandate must be amended in the same
  change to require the harness to consume the Rust/FFI Desktop catalog fixture,
  or deleting the Swift catalog will violate the AGENTS rule as written.
- `crates/jackin-usage/src/host/tests.rs:13-19` (`open_runtime`) sets only a
  tempdir data dir and never overrides `JACKIN_USAGE_{SNAPSHOTS,COOLDOWN,LOCK}_DIR`,
  so host tests read the developer's real `~/.jackin/data/usage-shared`; the
  loose `listed.len() >= 2` assertion at `host/tests.rs:840-845` exists to
  tolerate that leak.
- `jackin_core::account_key_hash` in
  `crates/jackin-core/src/account_key.rs:14-17` is the existing opaque SHA-256
  `(provider, account_label)` key. Keep the wire format where provider and label
  are trustworthy, but canonicalize provider ownership before hashing.

Repository constraints:

- `crates/jackin-usage` owns account materialization, view shaping, and all domain
  strings. Swift renders immutable DTOs.
- Desktop provider membership is Claude, Codex/OpenAI, Amp, Grok, Z.AI, Kimi,
  and MiniMax only, in `DESKTOP_PROVIDER_ORDER`. OpenCode and GitHub must not be
  added.
- Product output is quota limits only. Do not add token prices, costs, or trends.
- This changes no versioned `config.toml` or workspace schema and therefore must
  not bump those schema versions.
- Use the current `feature/native-liquid-glass-redesign` branch and its new active PR
  (`#843` is already merged historical context). Commits are Conventional
  Commits, use `git commit -s`, include
  `Co-authored-by: Codex <codex@openai.com>`, and push immediately. Never force-push.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Rust tests | `rtk cargo nextest run -p jackin-usage -p jackin-usage-ffi` | exit 0; all tests pass |
| Rust lint | `rtk cargo clippy -p jackin-usage -p jackin-usage-ffi --all-targets -- -D warnings` | exit 0; no diagnostics |
| Bindings | `rtk mise run desktop-bindings` | exit 0; generated Swift/C artifacts match Rust DTOs |
| Swift harnesses | `rtk mise run desktop-test` | exit 0; Rust/FFI nextest + the 3 release harnesses pass |
| Swift XCTest suites | `cd native && rtk swift test -c release` | exit 0; all `JackinUsageBridgeTests` classes pass |
| Cross-crate gate | `rtk cargo xtask ci --fast` | exit 0 |

Note: `mise run desktop-test` (= `cargo xtask desktop test`,
`crates/jackin-xtask/src/desktop.rs:180-197`) runs nextest for the usage crates
plus three `swift run` harnesses only — it does **not** run the XCTest classes.
Any step touching `OverviewInventoryTests`/`ArchitectureTests` fixtures must
verify with `swift test`.

## Scope

**In scope**:

- `crates/jackin-usage/src/host.rs`
- `crates/jackin-usage/src/host/accounts.rs`
- `crates/jackin-usage/src/host/tests.rs`
- `crates/jackin-usage/src/usage_snapshot_store.rs`
- `crates/jackin-usage/src/usage_snapshot_store/tests.rs`
- `crates/jackin-usage/src/lib.rs`
- `crates/jackin-usage/AGENTS.md`
- `crates/jackin-usage/README.md`
- `crates/jackin-usage-ffi/src/bridge.rs`
- `crates/jackin-usage-ffi/src/bridge/tests.rs`
- `crates/jackin-usage-ffi/src/dto.rs`
- `crates/jackin-usage-ffi/README.md`
- generated binding outputs under `native/Generated/` and
  `native/Sources/JackinUsageBridge/jackin_usage_ffi.swift`
- `native/Tests/JackinUsageBridgeTests/OverviewInventoryTests.swift` only for
  DTO decoding/contract fixtures; visual grouping belongs to Plan 005
- `native/Sources/JackinUsageBridge/PresentationHelpers.swift` (delete
  `frozenHostSurfaceIds` + membership assertions; deprecation comments on the
  other tables — their deletion is Plan 005)
- deprecation comments only in `native/Sources/JackinDesktop/ProviderMarks.swift`
  and `native/Sources/JackinUsageBridge/ProviderUsageLinks.swift` (note the
  second file lives in `JackinUsageBridge`, not `JackinDesktop`)
- `native/AGENTS.md` (parity-harness mandate wording only)
- `native/Tools/DesktopParityMatrixHarness/main.swift`
- relevant catalog assertions in
  `native/Tests/JackinUsageBridgeTests/ArchitectureTests.swift`

**Out of scope**:

- Reading jackin❯ config/workspace files or resolving 1Password: Plan 002.
- Shared refresh locking, broker transport, or container mounts: Plan 003.
- Popover, Usage window, or sidebar visual composition: Plans 004–005.
- A config schema/version change, database migration, OpenCode Desktop support,
  GitHub quota support, account-removal UI, or historical usage trends.

## Steps

### Step 1: Introduce exact canonical surface identity

Create a typed canonical provider/surface identity in `jackin-usage` and make
`HostSurfaceId` map to it explicitly. One identity value must represent each frozen
provider; the routing agent slug remains a separate field used only to dispatch a
probe.

Replace `provider_matches`, containment matching, and `agent_slug()` account matching
with a closed alias parser. Allowed aliases must be enumerated and tested (for example,
OpenAI/Codex -> Codex; Anthropic/Claude -> Claude; xAI/Grok -> Grok). Z.AI and MiniMax
must never map through the Codex alias merely because their probe implementation uses
the Codex agent. Unknown provider strings return a typed unowned result; they do not
fall back to substring matching.

Canonicalize the provider before calling `account_key_hash`. Preserve existing keys
for aliases that already represent the same provider where possible. If an existing
stored provider cannot be mapped exactly, classify it as unowned history and exclude
it from active Desktop membership rather than guessing.

Make account identity optional until real identity evidence exists. Do not test a
hashed key for emptiness: `account_key_hash` returns a nonempty digest even for an
empty label. Validate the typed provider subject/account label first, then hash it.

Canonical uniqueness is ordered (this is the Batch 3 identity rule and is
binding):

1. canonical surface ID plus a provider-issued stable account/organization ID
   when the provider supplies one;
2. canonical surface ID plus the authenticated account label only when no
   stronger stable identifier exists;
3. never display text alone across providers (the same email on two providers is
   two accounts, because surface is part of identity);
4. never source path, workspace name, role name, auth mode, or routing agent slug.

Model the identity type so a stable provider ID, when later learned, supersedes a
label-derived key for the same account without producing two rows.

Name every new test in this plan with the prefix `canon_` (e.g.
`canon_openai_never_matches_zai`) so verify filters are anchored to work this
plan actually adds, not to pre-existing tests that happen to match.

**Verify**:
`rtk cargo nextest run -p jackin-usage -E 'test(/canon_/)'`
-> at least the alias-table tests run and pass, including one proving OpenAI maps
only to Codex and never Z.AI or MiniMax; zero `canon_` tests running means the
step is not done.

### Step 2: Define account lifecycle and membership separately from snapshots

Replace the untyped `HashMap<String, FocusedUsageView>` merge with catalog entries
that contain:

- canonical surface ID and stable account key;
- account label and optional username/plan;
- source provenance set (live host, current shared result, durable history);
- lifecycle: current, historical, or provider-presence-only;
- the account's own latest view plus fetched-at time.

Use the existing fresh/stale policy to distinguish a current shared result from old
history; do not introduce a second arbitrary timeout. Durable-only rows are
historical. A provider-presence result without a stable account identity is provider
state, not an account row. Keep last-good data for a known account, but never let an
old snapshot silently assert that it is the current login.

Materialize the durable database and shared snapshot directory once per catalog
generation, then index by `(canonical_surface, account_key)`. Do not rescan the same
database/files once per provider, and do not keep the current N+1 shape where
`load_account_usage_view` re-runs the unfiltered table load per identity
(`usage_snapshot_store.rs:930-934` called per identity from
`host/accounts.rs:181-196`): load rows once per generation and group in memory,
or add a keyed `WHERE account_key_hash = ?` query. Add invalidation when a
refresh publishes a new view, selection changes, or the poll observes a newer
shared generation.

When reconstructing an account view from durable rows, pin one `source` after
selecting the latest `fetched_at` (prefer `provider_api` over `cli` over local
evidence) so multi-source rows cannot produce duplicate same-label buckets or a
header whose source/confidence belongs to a different probe
(`usage_snapshot_store.rs:938-946`).

The account descriptor keeps a provenance **set** (live host, current shared
result, durable history — later extended by Plan 002 with config scopes), not a
single collapsed label: one account found in several places is one row with
several provenance entries.

No raw credential, token, API key, credential path, or 1Password reference may enter
the descriptor, database, logs, telemetry, or FFI.

**Verify**:
`rtk cargo nextest run -p jackin-usage -E 'test(/canon_/)'`
-> the new catalog tests prove one scan per generation, historical
classification, single-source pinning, and that a presence-only Amp result is
not emitted as a subscription account.

### Step 3: Validate selected-account ownership

Change `set_selected_account(surface_id, account_key)` so it succeeds only when the
canonical catalog contains that key under that exact surface. An empty key may still
clear selection. On load, clear persisted selections that are unknown or belong to a
different canonical surface; persist the cleaned map atomically using the
in-crate helper `atomic_write_usage_json`
(`crates/jackin-usage/src/usage/refresh.rs:488`) rather than direct `fs::write`
(do not add a `jackin-config` dependency for this).

Selection fallback must prefer a current discovered account, then a current live
account. Historical rows cannot become selected implicitly. The selected account must
not be able to replace the provider's canonical display identity.

Compute the `selected` flag from the **visible** row set, not the raw key list:
today `host.rs:676-694` chooses `selected` before the placeholder filter runs, so
the marked row can be dropped and the emitted list carries no selection while
`snapshot()` still resolves the hidden key. When the persisted selection is not
visible, fall back to the live/current account and clear the stale persisted
entry. Invariant: a nonempty account list always contains exactly one
`selected == true` row.

**Verify**:
`rtk cargo nextest run -p jackin-usage -E 'test(/canon_sel/)'`
-> new `canon_sel_*` tests prove cross-provider and unknown keys are
rejected/cleared, valid same-provider keys remain selected across reopen, and a
nonempty list always carries exactly one selected row.

### Step 4: Export one complete Rust-owned grouped Desktop inventory

Add a coarse `HostUsageRuntime` projection containing Rust-ordered provider groups and
self-contained account rows. Build groups only from detected, enabled entries in
`DESKTOP_PROVIDER_ORDER`. Each account row must carry finished Rust-owned display
strings and machine identity/geometry:

- surface ID, provider display label, icon key, account key, account display label;
- selected flag and lifecycle/provenance label;
- plan-or-status display string;
- remaining label/geometry, reset phrase, exact reset, severity;
- account-specific exceptional status, last error, and update recency.

Do not borrow reset/status/error from the selected provider glance. Do not emit
OpenCode, undetected placeholder surfaces, or account-only extra surfaces. Emit an
empty provider state separately when a detected provider has no stable account.

Delete `frozenHostSurfaceIds` and every Swift test/harness assertion that establishes
provider **membership or count**, and drive status-strip/parity test rows from the
Rust/FFI Desktop catalog fixture or explicit synthetic row arrays that test layout
without claiming product membership. Add the new Rust-owned display fields to the
glance/inventory DTOs now: icon key, fallback glyph text, provider display copy,
and the provider usage-page URL.

Division of labor with Plan 005 (deliberate — do not exceed it here): the other
Swift provider tables (`statusItemSystemImage`'s id switch,
`desktopProviderIconKeys`, `desktopProviderOverviewRole`,
`statusItemFallbackGlyph`, `ProviderMarks`, `ProviderUsageLinks`) have live
production and harness consumers (`PopoverRoot`, `StatusItemLabel`,
`ProviderDetailView`, `UsageWindowRoot`, `PresentationStore`,
`StatusItemChipHarness`, `ProviderMarksHarness`, `DesktopSoTParityHarness`,
`ProviderUsageLinksTests`); rewiring those views/harnesses onto the new DTO
fields and deleting the tables is **Plan 005's** job. In this plan: leave those
tables in place, mark each with a `// Deprecated: replaced by Rust DTO fields —
removed in Plan 005` comment, and delete only assertions that use them to prove
membership/count (e.g. the `frozenHostSurfaceIds.allSatisfy` coverage check at
`PresentationHelpers.swift:244` moves to the Rust catalog fixture). A Swift icon
resolver mapping an incoming Rust icon key to an asset/system symbol
(`ProviderMarks.resourceName(forIconKey:)` at `ProviderMarks.swift:32-43` is
exactly that) is legitimate presentation and stays. Amend the
`native/AGENTS.md` parity-harness mandate in the same change so the rule requires
proving displayability of the Rust-supplied catalog fixture rather than a Swift
constant.

Two host-runtime hardening items ride this step because they change the same
`open`/projection surface:

- `open` must reject unknown `enabled_surface_ids` with a typed error (or at
  minimum emit a config-warning event naming the dropped ids) instead of the
  silent drop at `host.rs:417-423`.
- `open` must reset `self.cache`, `self.events`, and `self.next_seq` when the
  incoming `data_dir` differs from the current one, so a re-open cannot serve the
  previous profile's snapshots (`host.rs:401-441`).

Mirror this as one UniFFI record graph and one coarse bridge method. Regenerate the
bindings. Keep old methods temporarily only if another non-Desktop consumer still
uses them; otherwise remove them in the same change. Swift must not need to join
provider/account titles, format percentages, compose reset strings, or derive
severity.

**Verify**:
`rtk mise run desktop-bindings && rtk cargo nextest run -p jackin-usage-ffi && rtk mise run desktop-test && (cd native && rtk swift test -c release)`
-> bindings generate, FFI round-trip tests preserve group order, exact identity,
and every per-account field, and the Swift package (harnesses + XCTest) still
compiles and passes after the membership-assertion removals.

### Step 5: Strengthen ownership docs and contract tests

Update `crates/jackin-usage/AGENTS.md` to explicitly assign Rust ownership of account
discovery, canonical provider/account identity, deduplication, lifecycle, scheduling,
shared cache, and single-flight coordination. Keep the limits-only rule. Update both
crate READMEs with the grouped inventory endpoint and exact provider-membership rule.

Replace tests that encode fuzzy matching or unscoped `ALL` inventory. Add regressions
for:

- two OpenAI accounts appear once under Codex/OpenAI;
- Z.AI and MiniMax receive no OpenAI account;
- two real accounts for one provider stay distinct;
- the same account label/email on two different providers stays two separate
  accounts (surface is part of identity);
- invalid persisted selection cannot cross surfaces;
- a nonempty account list always contains exactly one `selected == true` row,
  including when the persisted selection was filtered out;
- old Amp history is marked historical, while presence-only local auth is provider
  state;
- every account retains its own status/error/reset;
- a multi-source durable account reconstructs from one pinned source with no
  duplicate same-label buckets;
- an unknown surface id passed to `open` is rejected (typed error or warning
  event), and re-open with a different `data_dir` serves no stale cached view;
- OpenCode never appears in the Desktop projection;
- catalog materialization scans durable/shared sources once per generation.

**Verify**:
`rtk cargo nextest run -p jackin-usage -p jackin-usage-ffi && rtk cargo clippy -p jackin-usage -p jackin-usage-ffi --all-targets -- -D warnings`
-> all tests and lints pass.

## Test plan

- Model new matcher/catalog tests after `crates/jackin-usage/src/host/tests.rs`.
- Model store-history fixtures after
  `crates/jackin-usage/src/usage_snapshot_store/tests.rs` and use temporary roots;
  never inspect real operator credentials or home directories.
- Fix the existing host-test isolation leak: `open_runtime` in
  `crates/jackin-usage/src/host/tests.rs:13-19` must point
  `JACKIN_USAGE_SNAPSHOTS_DIR`, `JACKIN_USAGE_COOLDOWN_DIR`, and
  `JACKIN_USAGE_LOCK_DIR` at per-test temp dirs (serialize tests that set them —
  env is process-global), then tighten the `listed.len() >= 2` assertion at
  `host/tests.rs:840-845` to an exact expected account set.
- Model UniFFI DTO tests after `crates/jackin-usage-ffi/src/bridge/tests.rs`.
- Add a fixture with the exact structural collision: Codex, Z.AI, and MiniMax all
  route through `codex`, but only Codex owns an OpenAI record.
- Add a transient store/read error fixture. Projection failure must be typed; it must
  not silently become an empty catalog.

Final gate:

```bash
rtk cargo nextest run -p jackin-usage -p jackin-usage-ffi
rtk cargo clippy -p jackin-usage -p jackin-usage-ffi --all-targets -- -D warnings
rtk mise run desktop-test
(cd native && rtk swift test -c release)
rtk cargo xtask ci --fast
```

All commands exit 0.

## Done criteria

- [ ] Routing slug and display text never decide account ownership.
- [ ] Empty or fabricated account labels are rejected before account-key hashing.
- [ ] Persisted selection is validated against exact surface membership.
- [ ] Historical and presence-only state cannot masquerade as a current account.
- [ ] Desktop inventory uses only detected `DESKTOP_PROVIDER_ORDER` groups.
- [ ] Every account row carries its own Rust-owned status/limit/reset/error data.
- [ ] OpenCode and account-only extra surfaces cannot enter Desktop inventory.
- [ ] No Swift constant/test/harness defines provider membership, order, provider
  display copy, or provider URLs; `native/AGENTS.md`'s parity mandate references
  the Rust catalog fixture.
- [ ] `open` rejects unknown surface ids and resets cached state on data-dir
  change; a nonempty account list has exactly one selected row.
- [ ] Host tests are isolated from the real `~/.jackin` shared tree.
- [ ] Durable/shared inputs are materialized once per generation (no per-identity
  full-table reloads).
- [ ] Generated bindings are current; Rust, FFI, Swift harness, lint, and fast CI pass.
- [ ] Only in-scope files and `plans/README.md` changed.

## STOP conditions

- Exact canonical provider ownership requires changing provider probe routing; routing
  and ownership must remain separate.
- A versioned config/workspace schema or durable database migration appears necessary.
  Report the proposed schema/version artifacts before proceeding.
- A test can pass only by reading real home credentials, snapshots, or 1Password data.
- A new Swift-side provider matrix, formatter, or account deduplicator seems necessary.
- An unknown stored provider would have to be guessed via substring matching.
- An in-scope file drifted semantically from the excerpts above.

## Maintenance notes

Plan 002 will replace historical/live source membership with the complete config-derived
catalog; preserve the lifecycle/provenance types for that extension. Plan 003 will use
the same canonical identity as the refresh coordination key. Reviewers should reject
any later reintroduction of routing slugs, fuzzy display matching, or snapshot history
as membership authority.
