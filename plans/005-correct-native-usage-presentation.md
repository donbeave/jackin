# Plan 005: Render correct account-first quota presentation from one Rust projection

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If a STOP condition
> occurs, stop and report; do not improvise. Update this plan's row in
> `plans/README.md` when finished.
>
> **Drift check (run first)**:
> `git diff --stat 27d0d9b3..HEAD -- crates/jackin-protocol crates/jackin-usage crates/jackin-usage-ffi crates/jackin-capsule native/Sources native/Generated native/Tests native/UITests native/Tools native/README.md docs/content/reference/adrs/adr-011-native-macos-usage-menu-bar.mdx 'docs/content/roadmap/(operator-surface)/native-macos-usage-menu-bar.mdx'`
> Plans 001–004 are expected to change these paths. Confirm the canonical grouped
> inventory, broker phase, and pane ownership exist. Most Current-state excerpts
> below describe HEAD `27d0d9b3` **before** plans 001–004 ran — they are the
> rationale record, not a drift oracle. Expected transformations:
> `OverviewInventory`/`PresentationHelpers` catalogs and grouped DTO (001),
> `PresentationStore` refresh/coalescing model (003), toolbar/guard shape (004),
> `bridge/tests.rs` row-id ordering (unchanged until this plan). Treat as a STOP
> condition only: a missing prerequisite contract (grouped DTO, broker phase,
> pane ownership), or drift in paths **no earlier plan claims**. A citation off
> by a few lines with the described code clearly present nearby is never drift.
>
> Command prefix note: `rtk` is an optional local output-compressor. The
> canonical command is everything after `rtk `; if `rtk` is not installed, drop
> the prefix.
>
> Guard note: after Plan 004, the material/chrome guard covers **all** of
> `native/Sources/` (both targets) and rejects `.background(.bar)`/Material
> variants — new views written in this plan are subject to it.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: `plans/001-canonical-account-inventory.md`,
  `plans/002-global-rust-account-discovery.md`,
  `plans/003-strict-usage-coordinator.md`,
  `plans/004-native-full-height-sidebar.md`,
  `plans/006-capsule-credential-exposure.md`,
  `plans/007-config-validation-hardening.md`,
  `plans/008-backend-parity-fail-closed.md`,
  `plans/009-ci-testing-docs-hygiene.md`
- **Category**: bug, tech-debt, tests, docs
- **Planned at**: commit `27d0d9b3`, 2026-08-13
- **Execution state**: DONE — the branch-head Rust/FFI, native contract, real-host
  UI, full workspace, documentation, OrbStack broker, and final visual/accessibility
  gates pass. The canonical production app is rebuilt and verified.

## Why this matters

The data currently shown in the popover and Usage window is both repetitive and, in
Overview, sometimes wrong. Rust emits Focused/Header/Provider/Account/Fresh rows that
repeat the identity header, while the popover hides a single active account and puts
Details above the quota Limits. Overview flattens provider/account into one Swift-made
title, borrows one account's status for others, and can erase the entire UI when one
FFI call fails. This plan makes Rust publish one atomic, complete presentation and
keeps Swift to native grouping, selection, accessibility, and layout.

## Current state

- `crates/jackin-usage/src/usage/format.rs:724-805` documents and emits the fixed
  detail order `focused`, `header`, `provider`, `account`, `status`, `updated`, then
  username/plan/auth/buckets/detail.
- `crates/jackin-usage/src/usage/view.rs:155-163` sets the Fresh value to
  `Updated just now`; the detail row labels it `Updated`, creating duplicated
  wording. The stutter is universal, not Fresh-only:
  `refresh_cached_updated_label` at `usage.rs:1708-1716` overwrites
  `updated_label` for every Fresh/Stale cached read with the output of the pure
  `relative_updated_label` (`usage.rs:1697-1706`), which always begins
  `Updated …`.
- `crates/jackin-usage/src/usage/format.rs:236-238` renders any sub-minute
  duration as `0m` (`Cl resets 0m` in the chip, `Resets in 0m (…)` in detail);
  the `Resets now` case fires only at `reset_at <= now`, so the 1–59s window is
  misleading.
- `native/Sources/JackinDesktop/StatusItemLabel.swift:101-127`
  (`compactResetCountdown`) lowercases and string-parses the Rust reset label,
  stripping an English `"resets in "` prefix that the code deliberately builds
  from fragments (`"re" + "sets"`, lines 107-110) so the architecture scanner
  cannot see the banned token — a knowing evasion of the display-only guard.
  `DesktopAppDelegate.swift:124-128` likewise concatenates tooltip and
  accessibility strings in Swift.
- `native/Sources/JackinUsageBridge/PresentationStore.swift:955-999`
  (`applyStatusItemText`) is a dead pipeline: its outputs `statusItemText`/
  `statusItemChips` have no consumers (the menu bar renders
  `statusBarGlanceRows` via `DesktopAppDelegate.swift:112-129`), yet it runs
  extra bridge calls after every snapshot apply and on failure sets `lastError`
  (`:996`) immediately after `applySnapshots` cleared it (`:904`) — a failure in
  unused code can blank the whole UI.
- `PresentationStore.swift:657-689`: `refreshAll` cancels the previous task and
  starts another with no `Task.isCancelled` check, so a cancelled task still
  clears `refreshInProgress` (`:670`) while the replacement runs;
  `refresh(surfaceId:)` (`:676-689`) toggles the same flag independently and
  skips `applySnapshots` on error while `refreshAll` always applies — two
  divergent contracts for the same button. `applySnapshots` itself is re-entrant
  across its `await` (`:754-796`): an older projection resuming after a newer
  one silently reverts the visible state.
- `PresentationStore` assigns `String(describing: error)` to `lastError` at 11
  sites (e.g. `:494`, `:667`, `:793`) and the views render it verbatim
  (`PopoverRoot.swift:79`, `UsageWindowRoot.swift:166`) — Swift enum reflection
  is the user-facing error copy.
- `~500` lines of Swift business-string composition in `PresentationHelpers.swift`
  (`bucketPrimaryPercentLabel`, `accountPillLabel`, `formatMoneyDto`,
  `statusItemDisplayPercent` = Swift computing `100 - remaining`, …) have zero
  production call sites — referenced only by `ArchitectureTests` and the
  `Tools/` harnesses, which therefore "prove" a parallel presentation layer the
  shipped UI never uses. Caveat: `buildStatusItemChips` (`:632`) **is**
  production-called from `PresentationStore` and reaches
  `statusItemDisplayPercent` via `statusItemChipDisplayLines` -> 
  `statusItemPercentToken`, so the deletion set must be computed as "every
  symbol unreachable from production call sites after the dead status pipeline
  is removed", not from a name list. `formatMoneyDto` additionally drops the
  sign on negative amounts (`:793-810`). `isMachineStatusSlot`
  (`PresentationHelpers.swift:427-440`) is genuinely inert (both switch arms
  return true). Do **not** treat `:648-655` as inert: `positive` feeds the
  return at `:658` and changes chip filtering when `remainings` is empty with
  preview data absent — only its first disjunct is redundant.
- `native/Sources/JackinDesktop/SettingsView.swift:99-141`: the refresh-floor
  slider is bounded 1…30 and `onChange` fires on the `.onAppear` hydration
  assignment, so `UInt64(newValue) * 60` writes a truncated floor back to Rust
  merely from opening Settings (a 90s floor becomes 60s).
- `DesktopAppDelegate.swift:59-66` subscribes the status-item chip updates via
  `.receive(on: RunLoop.main)`, which defers delivery during menu tracking and
  live resize — including the screen-sharing privacy collapse driven by
  `statusBarShowsValues`.
- `DesktopAppDelegate.swift:294-317` (`showAutomationPopover`) leaks one
  always-on-top `NSPanel` per invocation on the visual-QA path.
- `native/Sources/JackinDesktop/VisualQALaunchOptions.swift:36-38` accepts the
  fixture id from the `JACKIN_DESKTOP_FIXTURE` environment variable with no
  debug gate, and `applyQIFixture` (`PresentationStore.swift:604-616`) puts the
  shipped binary into a permanent fabricated-data mode with no visible
  indicator.
- `crates/jackin-protocol/src/control.rs:451-487` models active refresh as an exact
  string-based `Unavailable` placeholder. `UsageSnapshotStatus` has no explicit
  refreshing phase. Plan 003 replaces this with a generation/phase contract.
- `native/Sources/JackinDesktop/PopoverRoot.swift:107-177` renders provider identity,
  optional picker, Details, then Limits. The picker exists only when account count is
  greater than one.
- `PopoverRoot.swift:180-205` shows provider name and status; it omits the selected
  account even though the Rust glance carries it.
- `native/Sources/JackinDesktop/UsageWindow/ProviderDetailView.swift:28-109` has the
  correct deep-window section order (identity, picker, Details, Limits), but
  `accountSubtitle` at lines 147-150 composes account + plan in Swift.
- `native/Sources/JackinUsageBridge/OverviewInventory.swift:102-184` creates flat rows,
  appends extra surfaces, joins provider/account strings, formats percentage/reset,
  and assigns glance status/error to every account. Plan 001 provides a complete
  grouped Rust DTO; remove this reshaping.
- `native/Sources/JackinDesktop/UsageWindow/OverviewListView.swift:40-74` renders a
  flat native Table with a combined `Provider and account` column.
- `native/Sources/JackinUsageBridge/PresentationStore.swift:754-790` obtains one UI
  state through many bridge calls. Snapshot/account/glance failures are swallowed
  with `try?` and converted to nil/empty; lines 903-904 then reconcile selection and
  clear the error.
- Existing tests require the wrong contract:
  `crates/jackin-usage-ffi/src/bridge/tests.rs:332-338` pins the exact-order
  9-element row-id list (`"focused", "header", "provider", "account", "status",
  "updated", "bucket:0", …`) — the ids are distinct (duplicate *labels* keep
  distinct ids by design); the brittleness is the frozen ordering that includes
  the rows this plan deletes. `OverviewInventoryTests.swift:78` requires combined
  titles; fixture Refresh is a no-op, so current UI tests cannot prove a real
  transition.

Required visible contracts:

| Surface | Order |
|---|---|
| Popover | provider + selected account; account picker if multiple; Limits; Details |
| Usage provider | provider + selected account; account picker if multiple; Details; Limits |
| Overview | provider groups; selectable account children; Plan/status; Remaining; Reset |

Detail cleanup on both surfaces:

- remove Focused, Header, Provider, duplicated Account, and ordinary Fresh;
- keep useful nonduplicated username, plan, credential origin/auth, errors, and limits;
- show exactly one Rust-owned recency/activity phrase;
- show `Updating…` only while the broker generation is in flight;
- keep actionable exceptional stale/offline/permission/error state.

Repository constraints:

- Every provider/account/status/recency/quota/reset/error string is Rust-owned.
  Swift may use machine IDs, enum/layout kinds, severity, and meter geometry.
- Limits only: no token price, session cost, historical trend, chart, or spend history.
- Provider order/membership and account dedup come only from Plans 001–002.
- Refresh phase/generation comes only from Plan 003; no Swift-local semantic copy.
- Keep Plan 004's pane-owned toolbar/sidebar and zero custom material.
- Keep exact `jackin❯ desktop` branding in window and popover.
- Temporary visual QA outputs are ignored and deleted. No committed screenshots,
  plans-of-progress, logs, or prototypes.
- Current `feature/native-liquid-glass-redesign` branch and its new active PR (`#843`
  is already merged historical context); signed Conventional Commits with Codex co-author,
  immediate normal push, no force-push.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Rust/FFI | `rtk cargo nextest run -p jackin-protocol -p jackin-usage -p jackin-usage-ffi -p jackin-capsule` | exit 0 |
| Rust lint | `rtk cargo clippy -p jackin-protocol -p jackin-usage -p jackin-usage-ffi -p jackin-capsule --all-targets -- -D warnings` | exit 0 |
| Bindings | `rtk mise run desktop-bindings` | exit 0 |
| Native format/lint | `rtk mise run desktop-format-check && rtk mise run desktop-lint && rtk mise run desktop-deadcode` | exit 0 |
| Native harnesses | `rtk mise run desktop-test` | exit 0 (nextest + 3 `swift run` harnesses only — does **not** run XCTest classes) |
| Native XCTest | `cd native && rtk swift test -c release` | exit 0; all `JackinUsageBridgeTests` suites pass |
| Native UI | `rtk mise run desktop-test-ui` | exit 0 |
| Full CI | `rtk cargo xtask ci` | exit 0 |

## Scope

**In scope**:

- `crates/jackin-protocol/src/control.rs` and tests
- `crates/jackin-usage/src/usage/format.rs`, `view.rs`, coordinator/host projection
  modules, tests, README
- Capsule usage-detail rendering/tests only where the shared Rust row contract changes
- `crates/jackin-usage-ffi/src/dto.rs`, `bridge.rs`, tests, README
- generated binding outputs in `native/Generated/` and
  `native/Sources/JackinUsageBridge/jackin_usage_ffi.swift`
- `native/Sources/JackinUsageBridge/OverviewInventory.swift`
- `native/Sources/JackinUsageBridge/PresentationStore.swift`
- `native/Sources/JackinUsageBridge/UsageWindowModel.swift`
- `native/Sources/JackinDesktop/PopoverRoot.swift`
- `native/Sources/JackinDesktop/UsageWindow/OverviewListView.swift`
- `native/Sources/JackinDesktop/UsageWindow/ProviderDetailView.swift`
- `native/Sources/JackinDesktop/StatusItemLabel.swift`
- `native/Sources/JackinDesktop/DesktopAppDelegate.swift` (subscription delivery,
  tooltip/AX composition removal, automation-panel reuse)
- `native/Sources/JackinDesktop/SettingsView.swift` (hydration guard only)
- `native/Sources/JackinDesktop/VisualQALaunchOptions.swift` and
  `native/Sources/JackinDesktop/VisualQAFixtures.swift` (fixture gating and the
  fixture surface's use of deleted store outputs)
- `native/Sources/JackinUsageBridge/PresentationHelpers.swift` (dead-layer +
  deprecated provider-table deletion; membership authority moved to Rust in 001)
- `native/Sources/JackinDesktop/ProviderMarks.swift`,
  `native/Sources/JackinUsageBridge/ProviderUsageLinks.swift` (delete the
  001-deprecated tables as views move to DTO fields)
- `native/Tools/DesktopParityMatrixHarness/main.swift`,
  `native/Tools/StatusItemChipHarness/main.swift`,
  `native/Tools/ProviderMarksHarness/main.swift`,
  `native/Tools/DesktopSoTParityHarness/main.swift` (repoint at DTO projection)
- `native/Tests/JackinUsageBridgeTests/ProviderUsageLinksTests.swift` (retire or
  repoint at the DTO URL field)
- `plans/README.md` (status row only)
- `native/Sources/JackinDesktop/UsageWindow/UsageWindowRoot.swift` only to consume
  Plan 004 toolbar and Plan 003 refresh projection
- related native unit, architecture, fixture, and UI tests
- `native/README.md`, ADR-011, native roadmap page

**Out of scope**:

- Account discovery/identity/broker redesign beyond consuming Plans 001–003.
- Sidebar/material redesign beyond preserving Plan 004.
- Provider additions, OpenCode/GitHub Desktop support, settings redesign, account
  deletion UI, or historical trend presentation.
- Swift string formatting, provider matrices, business-state inference, or silent
  fallback to empty data.

## Steps

### Step 1: Replace duplicate rows with Rust-owned identity/activity presentation

Add a Rust presentation record for the provider identity region, mirrored through
FFI, with finished strings and machine state:

- canonical provider title/icon key;
- selected account label, or an honest non-account provider state such as
  `No authenticated account` when identity is absent;
- activity phrase and activity kind;
- plan stays in Details; identity shows the account label only (selected
  contract — do not duplicate plan into the identity block).

The status-item glance DTO additionally gains Rust-owned `compact_reset_label`
(the short chip form, e.g. `2h 14m`) and a full accessibility label, so
`compactResetCountdown` and the Swift tooltip/AX concatenations in
`DesktopAppDelegate` are deleted along with their scanner-evasion comment. While
in `format.rs`, fix the sub-minute duration form: `compact_duration_label`
returns `<1m` (chip) and the long form says `Resets in under a minute` for the
1–59s window instead of `0m`.

Activity wording rules:

- idle/fresh: one phrase such as `Updated now` or `Updated 2m ago`;
- active broker generation: `Updating…`;
- stale/error/offline/permission: one Rust-composed actionable exceptional phrase that
  may preserve last-good recency, for example `Update failed · Updated 2m ago`;
- never render ordinary `Fresh` and never combine a label/value into
  `Updated: Updated ...`.

Change `usage_detail_presentation` to emit only nonduplicated Details metadata:
username when distinct, plan, credential origin/auth, the account's Rust-owned
provenance/lifecycle label when present (from Plans 001–002), and an actionable
detail/error.
Remove row IDs `focused`, `header`, `provider`, `account`, and ordinary Fresh status.
If a non-Fresh exceptional state is already fully represented in identity activity,
do not duplicate it in Details. Bucket rows remain the Rust-owned Limits projection.

Update protocol rustdocs and Capsule rendering/tests. Do not let Desktop-only feedback
cause Capsule to synthesize replacement strings.

**Verify**:
`rtk cargo nextest run -p jackin-usage -p jackin-protocol -p jackin-capsule -E 'test(/detail|presentation|refresh/)'`
-> no duplicate row IDs, one activity phrase, and Capsule parity tests pass.

### Step 2: Publish one atomic Desktop projection through FFI

Expose a single coarse bridge call returning the complete immutable Desktop state for
one broker generation:

- global phase/error and generation;
- detected Rust-ordered provider groups with self-contained account children from
  Plan 001;
- selected provider/account identity and detail/limit presentation;
- status-item/popover rows;
- Rust-owned identity/activity strings.

Build it under one Rust runtime lock/snapshot boundary. Required subprojection failure
must make the call return a typed error or a marked stale last-good projection; it
must not become an empty array. Keep one last-good projection in Rust or
`PresentationStore` and replace it only after full successful decode.

Rewrite `PresentationStore.applySnapshots` to call this endpoint once. Remove `try?`
for required snapshot/accounts/glance calls and remove Swift account severity/
percentage/reset/title composition. On transient projection failure:

- retain previous providers, accounts, limits, selection, and destination;
- expose the typed global error/stale state;
- do not reconcile to Overview or `No providers detected`;
- clear the error only after a later complete success.

Store-hardening items that ride this rewrite (all confirmed defects in the
current store):

- **Stale-resume guard**: applies are serialized by generation — a projection
  that resumes after a newer one applied is dropped, never written over it
  (today `applySnapshots` is re-entrant across its `await`).
- **One refresh contract**: Plan 003 owns the task/coalescing model — this plan
  only consumes it. Assert that both entry points (`refreshAll`,
  `refresh(surfaceId:)`) render the identical Rust phase/generation and apply
  the projection identically; do not reintroduce a Swift-local
  `refreshInProgress` semantic (that would violate this plan's own "refresh
  phase comes only from Plan 003" constraint).
- **Delete the dead status-item pipeline**: `applyStatusItemText`,
  `statusItemText`, `statusItemChips`, and their bridge calls; also delete the
  unconsumed published outputs (`mergedBarLabel`, `compactBarLabel`,
  `overviewRows` mapping, `allEnabledSurfacesDegraded`) and the unused
  `UsageWindowModel.Action`/`selection(after:)` pair. Deletion is the selected
  branch — do not instead wire views through them. Keep `nextRefreshLabel`: it
  is consumed by `VisualQAFixtures`/`applyQIFixture` (5 fixture call sites) and
  goes away only if the fixture surface stops using it.
- **Typed user-facing errors**: `lastError` becomes a Rust-supplied user-facing
  message (or a small fixed set of product strings); `String(describing:)`
  output is logged, never rendered.
- **Delete the unused Swift business-string layer** in `PresentationHelpers.swift`:
  compute the set as every symbol unreachable from production call sites once
  the dead status pipeline is gone (this includes the percent/pill/money/pace
  label builders, `statusItemDisplayPercent`, `formatMoneyDto`,
  `buildStatusItemChips` and its private helpers, and the inert
  `isMachineStatusSlot` at `:427-440`; it does **not** include `:648-655` —
  see Current state). `desktopProviderBrandChrome` was already deleted by
  Plan 001; the remaining provider tables (`statusItemSystemImage`,
  `desktopProviderIconKeys`, `desktopProviderOverviewRole`,
  `statusItemFallbackGlyph`, `ProviderMarks` id list, `ProviderUsageLinks`
  tables — all carrying 001's deprecation comments) are deleted **here** as
  views/harnesses move onto the Rust DTO fields 001 added. The parity harnesses
  are already Rust-catalog-driven for membership after 001; this plan repoints
  their remaining string assertions at the DTO projection so parity proofs
  exercise what production renders.
- **Main-queue delivery**: switch the `DesktopAppDelegate.swift:59-66`
  subscriptions from `.receive(on: RunLoop.main)` to main-queue/actor delivery so
  chip updates (including the privacy collapse) are not deferred during menu
  tracking or live resize.
- **Settings hydration guard**: `SettingsView` must not write the refresh floor
  back during `.onAppear` hydration, and out-of-range/non-integer floors render
  clamped without being persisted until the operator moves the slider.
- **Visual-QA hygiene**: `showAutomationPopover` reuses/orders-out its anchor
  panel instead of leaking one per call. Fixture gating, selected contract (no
  branches): (1) delete the `JACKIN_DESKTOP_FIXTURE` env fallback so `--fixture`
  argv is the only entry (`VisualQALaunchOptions.swift:36-38` is the sole reader
  repo-wide; `XCUIApplication.launchArguments` injects argv, so the UITest host
  permits this); (2) add a persistent visible fixture badge to the status
  item/window while `fixtureMode` is true; (3) `#if DEBUG`/target extraction of
  `VisualQAFixtures` is explicitly deferred — record it in Maintenance notes,
  do not attempt it here. Verify (1) with
  `rg -n 'JACKIN_DESKTOP_FIXTURE' native/Sources` -> no matches.

Regenerate bindings.

**Verify**:
`rtk mise run desktop-bindings && rtk cargo nextest run -p jackin-usage-ffi && rtk mise run desktop-test && (cd native && rtk swift test -c release --filter PresentationStoreTests)`
-> atomic projection round-trips; the `PresentationStoreTests` XCTest suite
(created by Plan 002, extended here) proves injected component failure preserves
the exact last-good UI model and selection (`desktop-test` alone cannot — it
runs no XCTest classes).

### Step 3: Correct popover identity, order, and focus handoff

In `PopoverRoot`:

1. render the Rust provider identity and selected account at the top for one or many
   accounts;
2. render Limits before Details;
3. render useful Details only;
4. move the native account picker out of the content form to the trailing edge of the
   fixed footer, only when multiple stable accounts exist;
5. render Refresh and Open Usage as adjacent native leading icon-only SF Symbol
   buttons, preserving independent action semantics, labels, shortcuts, hover help,
   and system-owned sizing/material.

The identity account text must update immediately after selection and displayed
limits must belong to that account. During a manual or background generation, render
the Rust `Updating…` activity; after terminal success/failure, render the new Rust
activity phrase.

Change Open Usage intent to carry both canonical surface ID and selected account key.
The Usage window must open on that provider/account even if another poll arrives
between click and window presentation. Do not depend on an incidental global selection.

Keep centered popover `jackin❯ desktop` branding and Plan 004's system-owned popover
background.

**Verify**:
create XCTest class `PopoverPresentationTests` in
`native/Tests/JackinUsageBridgeTests/` (no popover suite exists; `--filter
PopoverRoot` would match nothing), then
`(cd native && rtk swift test -c release --filter PopoverPresentationTests)`
plus the popover cases in `rtk mise run desktop-test-ui` -> single-account
identity is visible without picker; multi-account selection updates
identity/limits; Limits precede Details; Open Usage preserves exact
provider/account; footer actions remain accessible icon-only buttons and the account
picker remains trailing and reachable while content scrolls.

### Step 4: Keep Usage provider detail deep and account-first

In `ProviderDetailView`, render the same Rust identity/account/activity projection at
top, then the native multi-account picker, then Details, then Limits. Delete
`accountSubtitle` and any other Swift string composition. Use the account key carried
by the selected grouped projection.

Plan 003's broker phase drives the same `Updating…` shown in the popover. The toolbar
button may expose a native busy indicator/accessibility value, but its visible semantic
copy comes from Rust and must agree with the provider identity state.

Preserve provider usage link, Retry, scrolling, native `List`/`Section`/
`LabeledContent`/`ProgressView`, and Plan 004 detail-toolbar ownership.

**Verify**:
`cd native && rtk swift test --filter UsageWindowModelTests`
-> account identity and detail order are exact, with no Swift-composed subtitle.

### Step 5: Render Overview as a native provider hierarchy

Replace the flat combined-title model with the grouped DTO from Plan 001. Use the
SwiftUI hierarchical `Table` API: the `Table(_:children:)`/`DisclosureTableRow`
family that renders expandable parent rows (available since macOS 14; verify the
exact initializer against the macOS 26 SDK in Xcode's local documentation — no
network lookup is required). Provider rows are parents, account rows are
children. If that API family is absent from the SDK, that is a STOP condition,
not a license to improvise a flat layout. Columns are:

- Provider
- Account
- Plan or status
- Remaining
- Reset

Show provider identity once at the group level; do not repeat it in every account
title. Start detected groups expanded on first display and keep expansion while the
retained Usage window lives. Persistence across app relaunch is not required. A
single-account provider uses the same group/child layout.

Account children are independently selectable. Selecting one sends exact surface ID
and account key, opens that provider, and selects that exact account. Re-selecting
the same row after returning to Overview must navigate again — drive navigation
from the store selection rather than a local `@State` that only fires on change
(today `OverviewListView.swift:13,77-81` makes same-row re-clicks dead), and no
row may be silently inert (the `extraSurfaces` dead-click class disappears with
the grouped DTO). Selecting a
provider parent may open its currently selected account, but must never fabricate a
key. Preserve Rust provider order. Use Rust strings verbatim for every cell. Empty
cells, one rule: every display-cell DTO field is **non-optional** — Rust fills an
absent value with the literal `—` — and Swift renders the string verbatim. No
nil display fields exist, so no Swift placeholder logic can exist.
Accessibility shape, selected contract: each account row is one combined
element (`.accessibilityElement(children: .combine)`) carrying a Rust-supplied
row summary ("provider context, account, plan/status, remaining, reset" in one
label) and a stable identifier; the provider parent row separately announces
provider + expanded/collapsed state. Traversal-order and content assertions in
Step 6 target these combined labels — do not additionally require per-cell
child elements (a combined element hides its children from traversal by
design).

Accessibility/keyboard requirements:

- parent announces provider and expanded/collapsed state;
- child announces provider context, account, plan/status, remaining, reset;
- disclosure, arrow navigation, row selection, long labels, narrow window, error and
  Retry remain usable;
- OpenCode/undetected placeholders cannot appear because no extra surface fallback
  exists.

Delete `OverviewInventory.rows` reshaping and tests for combined titles. Keep a thin
verbatim DTO adapter only if generated records cannot conform directly to SwiftUI
identity protocols.

**Verify**:
`(cd native && rtk swift test -c release) && rtk mise run desktop-test-ui`
(`mise run desktop-test` does not run the XCTest suites — see the command-table
note) -> two OpenAI accounts appear once under one group; Z.AI/MiniMax contain
none; each child navigates to the exact account, and re-selecting the same row
navigates again; hierarchy is keyboard/AX usable.

### Step 6: Replace broad accessibility suppressions with exact assertions

In `JackinDesktopUITests`, remove the blanket Overview suppression of all
`.contrast` and `.sufficientElementDescription` issues
(`JackinDesktopUITests.swift:395-403`), the blanket popover `.parentChild`
suppression (`:405-408`), and the blanket popover `.contrast` suppression
(`:470-473`). Suppress only a documented Xcode 26 false positive identified by
specific element type, identifier/role, and host condition. Any anonymous broad
predicate is a failure. Accessibility assertions target the combined row labels
selected in Step 5 (one element per account row), not per-cell children.

Add explicit assertions for:

- provider group and account child labels/roles;
- selected account in both identity blocks;
- `Updating…` transition and terminal recency;
- section order through accessibility traversal;
- grouped keyboard navigation and exact account selection;
- stale/error/presence-only provider state;
- provider-level discovery summary and sanitized source diagnostics without fake
  account children or exposed workspace/credential locations;
- Plan 004 native sidebar toggle order.

Fixture Refresh must drive a deterministic Rust/bridge phase transition rather than
remain a no-op. Keep fixture data isolated and secret/network-free.

**Verify**:
`rtk mise run desktop-test-ui`
-> accessibility audits pass with only exact documented suppressions.

### Step 7: Verify full scenarios and update source-of-truth docs

Add end-to-end synthetic cases:

- single-account Anthropic: account visible at top, no picker, Limits first in popover;
- multi-account OpenAI: two children one group; trailing footer picker changes
  identity/limits;
- Z.AI/MiniMax: no OpenAI accounts;
- Amp: old history is absent from current catalog; presence-only source is provider
  state, not a Fresh account;
- OpenCode: absent everywhere in Desktop;
- manual and background refresh: immediate `Updating…`, then one terminal phrase;
- projection failure: last-good UI/selection retained;
- popover Open Usage: exact provider/account preserved;
- Details: no Focused/Header/Provider/Account/Fresh or repeated Updated wording;
- narrow/long/error/VoiceOver/keyboard cases remain usable.

Update native README, ADR-011, and roadmap page with the final atomic projection,
grouped Overview, account-first orders, recency/refresh state, and Rust/Swift boundary.
Document only the final production design, not feedback iterations. Preserve Plan
004's constraint when rewriting the same paragraphs: describe only the retained
sidebar/toolbar implementation path (no AppKit-fallback prose if the shipped path
is pure SwiftUI, and vice versa).

Run final visual QA against the canonical built app in Clear and Tinted system styles,
light/dark, contrast/transparency, popover and Usage window. Keep captures in ignored
`native/.build/visual-qa/final/`, inspect, then delete. Do not commit screenshots or
logs.

**Verify**:
all commands in Final gate pass; `rtk git status --short` shows no generated captures,
logs, prototypes, or sketches.

## Test plan

- Rust contract: identity/activity strings, exceptional state, no duplicate rows,
  complete grouped account fields, generation coherence.
- FFI: one atomic projection, typed failure, generated bindings, no secret fields.
- Swift unit: verbatim DTO mapping, section order, hierarchy/selection, last-good
  retention, exact provider/account handoff.
- Real UI: single/multi account, grouped table, active/terminal refresh, partial
  failure, sidebar coexistence, keyboard/VoiceOver.
- Visual: system Clear/Tinted and accessibility appearances; temporary captures
  removed.

Final gate:

```bash
rtk cargo nextest run -p jackin-protocol -p jackin-usage -p jackin-usage-ffi -p jackin-capsule
rtk cargo clippy -p jackin-protocol -p jackin-usage -p jackin-usage-ffi -p jackin-capsule --all-targets -- -D warnings
rtk mise run desktop-bindings
rtk mise run desktop-format-check
rtk mise run desktop-lint
rtk mise run desktop-deadcode
rtk mise run desktop-test
rtk mise run desktop-test-ui
(cd native && rtk swift test -c release)
rtk cargo xtask ci
rtk cargo xtask roadmap audit
rtk cargo xtask docs repo-links
rtk cargo xtask research check
```

All commands exit 0.

## Done criteria

- [ ] Provider and selected account are always visible at the top of both surfaces.
- [ ] Popover content order is identity, Limits, Details; the optional account picker
  is fixed at the trailing footer edge beside separate leading semantic
  icon-only Refresh/Open Usage controls.
- [ ] Usage order is identity, picker, Details, Limits.
- [ ] Focused/Header/Provider/duplicate Account/ordinary Fresh rows are absent.
- [ ] Exactly one Rust-owned activity phrase is visible; real in-flight work says
  `Updating…` and terminal work says `Updated now`/`Updated Xm ago`/an
  exceptional phrase (selected copy — `Updated just now` is retired).
- [ ] `format.rs` emits `<1m` (compact) and `Resets in under a minute` (long) for
  the 1–59s window; Rust tests assert both, and the glance DTO carries
  `compact_reset_label` plus the full accessibility label.
- [ ] No Swift code parses, trims, or re-composes a Rust display string; the
  `compactResetCountdown` scanner evasion is gone and the status-item chip/AX
  strings come from the DTO.
- [ ] The dead status-item pipeline, unconsumed published properties, and unused
  Swift business-string helper layer are deleted; harnesses exercise the DTO
  projection production renders.
- [ ] Store applies are stale-resume-safe; both refresh entry points share one
  coalesced contract; opening Settings never rewrites the persisted floor.
- [ ] Fixture mode requires the argv flag; no env-var path into fabricated data
  remains.
- [ ] Overview uses provider parent groups and selectable account children with five
  distinct columns.
- [ ] Provider/account/status/reset/error values are account-specific and Rust-owned.
- [ ] OpenAI never leaks into Z.AI/MiniMax; Amp placeholders/history are honest;
  OpenCode never appears.
- [ ] Open Usage preserves exact provider/account context.
- [ ] Projection failure preserves last-good rows/selection and surfaces an error.
- [ ] Accessibility audits are strict except exact documented platform false positives.
- [ ] All Rust/FFI/Swift/UI/full-CI/docs gates pass.
- [ ] No temporary screenshot, plan-of-progress, log, prototype, or sketch remains.

## STOP conditions

- Plans 001–003 do not provide exact account membership, grouped rows, or a real
  refresh phase/generation.
- A visible domain string must be composed/formatted/guessed in Swift.
- Hierarchical native Table cannot preserve exact account selection or accessibility
  on macOS 26. Report the API limitation and measured behavior before choosing another
  standard native composition; do not flatten silently.
- A projection error can only be represented by clearing current UI state.
- Updating shared detail semantics would break Capsule and no parity-preserving Rust
  contract can be defined.
- UI acceptance requires custom material/glass or committed screenshot artifacts.

## Maintenance notes

The atomic Desktop projection is the only Swift data boundary after this plan. New
account fields must be complete in Rust before UI use; never borrow provider glance
state or format missing values in Swift. Provider groups are catalog structure, not a
visual heuristic. When the entire feedback program is implemented and verified,
perform the final cleanup described in `plans/README.md`: preserve the app/source,
remove feedback/advisor plans and temporary evidence in one explicit cleanup commit.
