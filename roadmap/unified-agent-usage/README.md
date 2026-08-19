# Unified Agent Usage Experience

- **Status**: SHAPING
- **Slug**: unified-agent-usage
- **Created**: 2026-08-20 · **Updated**: 2026-08-20
- **Plan**: — (plans/unified-agent-usage/ once planned)

## Intent

Finalize one agent usage experience across jackin❯ desktop, `jackin console`, the `jackin usage` command, and `jackin-capsule`.

## Vocabulary

- **Initialized agent**: An agent for which at least one session has been started in the current Capsule. _Avoid_: using “initialized” to mean that a usage account or capability was resolved.
- **Capsule quota preview**: Subscription or quota limits shown by `jackin-capsule` before an agent's first session, using a resolved usage capability when one exists. _Avoid_: applying this lifecycle state to the console, CLI, or jackin❯ desktop; model context-window tokens; token prices; or historical token usage.

## Decisions

- 2026-08-20 — **Bare `jackin usage` opens the host-wide deduplicated overview, while `jackin usage <instance> …` remains available for inspecting a particular Capsule instance.** Because the normal operator path should show all host usage immediately without removing instance-scoped inspection.
- 2026-08-20 — **Capsule shows every agent allowed by its launch configuration before the first session as neutral `Not started`, with a quota preview when a usable capability exists; usage resolution and refresh failures remain errors.** Because an agent not yet started is not a failure, and its known limits are still useful.
- 2026-08-20 — **The host-wide `jackin usage` and `jackin console` views include all eight host usage surfaces: Claude, Codex, Amp, Grok, Kimi, OpenCode, Z.AI, and MiniMax; jackin❯ desktop retains the same catalog except OpenCode.** Because the host surfaces must cover every discovered agent and configuration while the desktop catalog remains a separate settled product boundary.
- 2026-08-20 — **`jackin usage` and the `jackin console` usage screen consume the same Rust-owned canonical inventory, deduplication, refresh, cache, and projection; only their presentation differs.** The CLI renders human-readable or JSON output, while the console renders the TUI, so both surfaces stay behaviorally consistent.
- 2026-08-20 — **One host broker owns provider refresh and durable canonical-account freshness.** Local processes and views may retain immutable projections for presentation, but they never probe providers, own retry deadlines, or queue duplicate refresh generations, because concurrent callers must share cached and in-flight work.
- 2026-08-20 — **Current read-only discovery across global, role, workspace, and workspace-role scopes owns host inventory membership; durable history only enriches current members, and unsupported or undiscovered providers do not appear as empty rows.** Because host-wide usage should reflect presently available configurations without resurrecting stale accounts or fabricating availability.
- 2026-08-20 — **Usage is a top-level route in `jackin console`, opening on Overview in the console's established left-list/right-detail structure.** Because usage is a primary host-wide operator surface and should reuse familiar console navigation rather than hide behind a workspace or modal.
- 2026-08-20 — **The console TUI orders provider groups by the settled eight-surface list and canonical accounts beneath them; it explicitly represents loading, refreshing, empty, stale last-good, partial-provider error, and global failure.** Selection drives detail, `r` refreshes, Back/Escape follows the shared navigation contract, and active keys appear in footer hints, because every state and action must remain visible and predictable.
- 2026-08-20 — **Human `jackin usage` output renders provider groups, one canonical row per account, then that account's limit windows, with explicit stale and error annotations; `--format json` exposes the same projection as a stable machine-readable envelope.** Because CLI and TUI must express the same truth without flattening canonical accounts back into duplicated window rows.
- 2026-08-20 — **Instance `accounts` and `verify` retain their Capsule inspection and verification intent; every host read is moved onto the canonical broker projection, and cache, `--no-refresh`, `--sync-host-cache`, or snapshot forms that preserve an independent freshness authority or misleading bypass are removed or redefined rather than kept as compatibility shims.** Because diagnostic value must survive without preserving the architecture that permits duplicate or stale authority.

## Capabilities

- Provide agent usage CLI output through `jackin usage`.
- Preserve explicit Capsule-instance account inspection and verification while eliminating host-side cache and refresh bypasses.
- Make agent usage available inside `jackin console`.
- Show subscription and quota usage limits only, including remaining or used percentage, reset countdowns, plan and status, and provider-supplied limit windows such as money caps when they are quota bounds, as required by [`AGENTS.md`](../../AGENTS.md).

## Screens

### Console usage

- **Purpose**: Show a basic usage overview plus detailed views per provider and account across all available agents and configurations.
- **States**: Loading; refreshing; empty; Overview; provider detail; account detail; stale last-good; partial-provider error; global failure.
- **Key interactions**: Enter the top-level Usage route; select provider/account rows in the left list; inspect right-side detail; press `r` to refresh; use the shared Back/Escape behavior; follow active footer hints.
- **Design**: An intuitive TUI similar to the existing `jackin-capsule` usage experience.

### Desktop usage

- **Purpose**: Provide the agent usage experience as a native macOS app.
- **States**: Current baseline includes loading, global unavailable with Retry, Overview, provider detail, provider failure with Retry, and empty inventory.
- **Key interactions**: Current baseline includes provider and account selection, Refresh, opening the retained Usage window from the popover, toggling its sidebar, and opening Settings through the application menu.
- **Design**: Swift and system-owned native Liquid Glass; the current baseline uses status items, a native popover, a retained two-pane Usage window, and a standard Settings window.

### CLI usage output

- **Purpose**: Render the shared host-wide usage projection through bare `jackin usage`.
- **States**: Current, refreshing, stale last-good, partial-provider error, empty, and global failure.
- **Key interactions**: Use human output by default or `--format json` for the stable envelope; pass an instance for Capsule-scoped inspection.
- **Design**: Provider groups contain one canonical row per account followed by that account's limit windows.

## Flows

1. The operator runs bare `jackin usage` or enters Usage in `jackin console`; both request the same host projection, join an active canonical-account refresh when one exists, and render the result as CLI output or TUI respectively.
2. From the console Overview, the operator moves into provider and account detail without triggering a second discovery, deduplication, or provider-fetch path.
3. The operator runs `jackin usage <instance> …` to inspect one Capsule instance's current usage projection without losing the host-wide default path.
4. In `jackin-capsule`, every launch-allowed agent appears before its first session as `Not started`; a known quota preview is available, and the row transitions after the first session starts.
5. In jackin❯ desktop, the operator glances from the status item and popover, then opens the retained Usage window for Overview or provider/account detail.

## Data & integrations

- Rust owns the shared host provider/account projection consumed by both `jackin usage` and `jackin console`; their output adapters do not rediscover, rededuplicate, or refresh accounts independently.
- The host projection covers all eight usage surfaces. The separate jackin❯ desktop projection remains limited to its fixed seven-provider catalog.
- Rust owns desktop discovery, account identity, deduplication, broker coordination, quota shaping, and immutable projections; the UniFFI boundary exports sanitized display data, and Swift remains display-only.
- Current read-only configuration discovery owns host inventory membership; history may enrich but never create membership.

## References

- [`crates/jackin-capsule/`](../../crates/jackin-capsule/) — existing capsule usage experience named as the console TUI reference.
- [`native/`](../../native/) — native macOS application surface.

## Research

- A static code-path trace found that Capsule provider work is correctly restricted to launch-forwarded capabilities derived from the resolved workspace, role, profiles, and credential environment ([relay capability construction](../../crates/jackin-runtime/src/usage_relay.rs#L189-L215), [exact scope filtering](../../crates/jackin-runtime/src/usage_relay.rs#L385-L419)). Confidence: HIGH.
- The same trace found that the Capsule usage dialog still displays all seven provider tabs rather than filtering its display by those capabilities ([fixed provider tabs](../../crates/jackin-usage/src/usage/view.rs#L470-L489)); unavailable tabs fail closed at the relay instead of disappearing. Confidence: HIGH.
- The host runtime already exposes a canonical deduplicated account inventory and atomic grouped provider/account projection ([canonical identity](../../crates/jackin-usage/src/host/accounts.rs#L19-L57), [inventory and projection](../../crates/jackin-usage/src/host.rs#L1163-L1303)); the current CLI instead renders raw account-window rows and can duplicate one account across sources or windows ([cache identity](../../crates/jackin/src/cli/usage/store.rs#L75-L93), [flat rendering](../../crates/jackin/src/cli/usage.rs#L403-L424)). Confidence: HIGH.
- Host usage has eight surfaces, including OpenCode, while jackin❯ desktop has a frozen seven-provider catalog that excludes OpenCode ([host and desktop surface sets](../../crates/jackin-usage/src/host.rs#L54-L98)). Confidence: HIGH.
- `jackin console` currently has no usage route, state, component, or effect, but its workspace screen already establishes a left-list/right-detail navigation pattern ([current routes](../../crates/jackin-console/src/tui/model/stage.rs#L11-L36), [workspace split layout](../../crates/jackin-console/src/tui/screens/workspaces/view.rs#L105-L175)). Confidence: HIGH.
- jackin❯ desktop already ships native status items and a popover, a retained two-pane Usage window with Overview and provider/account detail, and Settings; system AppKit and SwiftUI controls own Liquid Glass rather than explicit glass effects ([window host](../../native/Sources/JackinDesktop/UsageWindowController.swift#L41-L80), [overview table](../../native/Sources/JackinDesktop/UsageWindow/OverviewListView.swift#L33-L108), [Liquid Glass enforcement](../../native/Tests/JackinUsageBridgeTests/ArchitectureTests.swift#L81-L104)). Confidence: HIGH.
- Desktop, `jackin usage host snapshot`, and the Capsule relay converge on one broker generation for the same data directory and canonical account capability; even forced callers join active work rather than starting a parallel provider call ([active-generation join](../../crates/jackin-usage/src/coordinator.rs#L281-L303), [CLI broker path](../../crates/jackin/src/cli/usage.rs#L228-L255), [Capsule relay path](../../crates/jackin-runtime/src/usage_relay.rs#L497-L563)). Confidence: HIGH.
- The single-authority invariant is not complete: `jackin usage host snapshot --no-refresh` bypasses broker state, Capsule can queue a forced manual refresh behind active work, anonymous ordinal identities can fragment one real account into parallel capabilities, broker leadership dies with its first owning process, and `jackin-capsule usage claude-cli` probes directly ([no-refresh path](../../crates/jackin/src/cli/usage.rs#L223-L260), [queued Capsule refresh](../../crates/jackin-capsule/src/daemon/multiplexer_utils.rs#L243-L281), [anonymous capability identity](../../crates/jackin-usage/src/host/discovery.rs#L811-L842), [broker process ownership](../../crates/jackin-usage/src/host/broker.rs#L507-L576), [direct diagnostic probe](../../crates/jackin-usage/src/usage.rs#L1148-L1169)). Confidence: HIGH for the mechanisms; runtime occurrence of duplicate anonymous sources remains MEDIUM.
- Instance-scoped `accounts` and `verify` read the Capsule daemon's current local projection and do not themselves start provider work; `--sync-host-cache` copies those rows into a separate SQLite projection rather than the broker's durable account state ([instance read path](../../crates/jackin/src/cli/usage.rs#L335-L400), [projection store](../../crates/jackin/src/cli/usage/store.rs#L15-L42)). Confidence: HIGH.

## Must not

- MUST NOT display duplicated accounts in the console usage interface — each account should appear once across available agent configurations.
- MUST NOT show token unit prices, session cost estimates, spend-over-time history, usage trends, aggregate-spend charts, or cost rankings — [`AGENTS.md`](../../AGENTS.md) restricts usage surfaces to subscription and quota limits.
- MUST NOT let a CLI, console, desktop, Capsule, diagnostic, or presentation-cache path call a provider directly, queue a refresh behind active canonical-account work, or become an independent freshness/retry authority — one broker owns provider work.
- MUST NOT use unstable source ordinals as durable canonical account identity when they can fragment one account or alias persisted broker state.

## Quality bar

- The console TUI satisfies the repository's TUI decisions for non-blocking rendering, visible loading/refresh state, keyboard navigation, footer hints, focus and scroll behavior, modal geometry, and shared component reuse, with render-conformance fixtures for its major states.
- The desktop app uses system-owned native components and Liquid Glass, answers “Where am I?”, “What can I do?”, and “Where can I go from here?” in every state, passes the macOS design rubric with zero hard failures, and has running-app visual evidence plus accessibility audits across required appearance and Reduce-settings states.
- Concurrent usage reads and refreshes for one canonical account reuse shared cached data and join one in-flight refresh generation instead of issuing parallel duplicate provider requests; every usage surface must be verified against this invariant and any bypass fixed before shipping.

## Open questions

- ~~Which configuration sources make an account part of the host-wide inventory, and should supported but undiscovered providers appear?~~ **Resolved 2026-08-20**: current read-only discovery owns membership; history only enriches current members.
- ~~Where should Usage live in `jackin console`, and what is its navigation model?~~ **Resolved 2026-08-20**: top-level Usage route, Overview first, left-list/right-detail navigation.
- ~~What exact hierarchy, ordering, filtering, states, and refresh interactions should the console TUI use?~~ **Resolved 2026-08-20**: settled provider order, canonical accounts, explicit lifecycle/error states, selection-driven detail, `r`, shared Back/Escape, and footer hints.
- ~~What exact hierarchy should the human `jackin usage` output render from the shared projection?~~ **Resolved 2026-08-20**: provider groups, canonical account rows, limit windows, stale/error annotations, and stable JSON for the same projection.
- ~~What roles should the existing `host snapshot`, instance `accounts`/`verify`, cache, `--no-refresh`, and `--sync-host-cache` forms retain after the bare overview is added?~~ **Resolved 2026-08-20**: keep instance inspection/verification intent, move host reads to the canonical broker projection, and remove or redefine bypassing forms without compatibility shims.
- When `jackin-capsule` receives multiple launch-forwarded accounts for one allowed agent, should the quota preview show every canonical account or one selected account? **Recommendation**: show every deduplicated account and allow account detail/selection instead of failing surface-only requests as ambiguous.
- What are the full Capsule quota-preview presentation rules? **Recommendation**: order by allowed agent then canonical account; show `Not started`, loading, available limits, no-capability explanation, stale last-good, and recoverable error distinctly; expose one refresh action that joins active work and preserve the transition into initialized state without losing selection.
- May exhausted, unknown, stale, or failed quota data block or disable Capsule agent launch and session actions? **Recommendation**: no; usage is informational, states remain explicit, and quota observation never becomes launch authorization or enforcement.
- Which remaining/used convention, rounding, countdown form, stale marker, missing-plan fallback, and money-cap units should all output surfaces use? **Recommendation**: consume the existing Rust-owned formatting preferences and labels verbatim, with only layout adaptation per surface and no presentation-side quota inference.
- Is jackin❯ desktop a filtered view of the same canonical host inventory or a separate discovery/inventory pipeline sharing only broker work? **Recommendation**: use one canonical host discovery and account graph, then derive the fixed seven-provider desktop projection by filtering OpenCode and applying native presentation settings; do not maintain a second identity or discovery pipeline.
- How should bare `jackin usage` exit when some providers are stale or failed but last-good rows remain usable? **Recommendation**: render usable rows with explicit per-provider stale/error state and exit successfully; return nonzero only when no usable projection can be produced or the invocation itself is invalid, while JSON preserves structured partial failures.
- Should the jackin❯ desktop menu bar use one aggregate status item or retain provider-focused status items, and which account/window should each glance prioritize? **Recommendation**: retain the current Rust-ranked provider-focused model and its icon-only, worst-provider, pinned-provider, and bounded-strip modes; clicking an item focuses that provider and its selected canonical account, while the Usage window remains the all-provider overview.
- Should jackin❯ desktop retain its current native popover, two-pane Usage window, and Settings information architecture while design work focuses on evidence-led refinement, or permit a structural replacement? **Recommendation**: preserve the current native structure unless prototype evidence proves a specific structural defect; avoid a decorative rewrite.
- Does “finalize jackin❯ desktop” include the first Developer ID signing, notarization, public artifact, and Homebrew cask proof? **Recommendation**: include them, because the existing desktop roadmap identifies them as the remaining release boundary.

## Open research questions

- Which durable broker ownership model preserves one refresh authority when short-lived CLI, desktop, and Capsule-relay processes start and exit?
- How should anonymous credential sources receive stable canonical identity before provider authentication without leaking secret material or merging distinct accounts?
- What are the canonical projection's schema/versioning, identity precedence, collision behavior, merge precedence, sorting, window grouping, partial-provider failure, and JSON evolution contracts?
- What TTL, invalidation, retry/backoff, cancellation, locking, persistence, crash-recovery, force, and no-refresh semantics make the broker's single-authority guarantee executable and testable?
- Which current Apple macOS 26 Liquid Glass patterns, native component choices, accessibility behaviors, and exemplar applications should refine the existing jackin❯ desktop surfaces without custom-painted glass?
- What exact dependency order, repository gates, and independently verifiable vertical slices let implementation preserve a green build while unifying the broker, CLI, console, Capsule, FFI, and Swift surfaces?

## Deferred

## Log

- 2026-08-20 — tailrocks-idea — created (DRAFT).
- 2026-08-20 — tailrocks-brainstorm — moved to SHAPING after settling the default CLI overview behavior.
- 2026-08-20 — tailrocks-brainstorm — closed shaping session after settling shared CLI/TUI behavior and Capsule pre-session usage; remaining decisions recorded with recommendations.
