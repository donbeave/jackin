# Unified Agent Usage Experience

- **Status**: SHAPING
- **Slug**: unified-agent-usage
- **Created**: 2026-08-20 · **Updated**: 2026-08-20
- **Plan**: — (plans/unified-agent-usage/ once planned)

## Intent

Finalize one agent usage experience across jackin❯ desktop, `jackin console`, the `jackin usage` command, and `jackin-capsule`.

## Vocabulary

- **Initialized agent**: An agent for which at least one session has been started in the current Capsule. _Avoid_: using “initialized” to mean that a usage account or capability was resolved.
- **Agent-uninitialized error**: The typed Capsule-only lifecycle error
  `agent_uninitialized`, emitted when a fully resolved launch-config agent has no
  started session. A quota preview may accompany it, but must not downgrade it
  to success or turn it into a provider-refresh failure.
- **Capsule quota preview**: Subscription or quota limits shown by `jackin-capsule` before an agent's first session, using a resolved usage capability when one exists. _Avoid_: applying this lifecycle state to the console, CLI, or jackin❯ desktop; model context-window tokens; token prices; or historical token usage.

## Decisions

- 2026-08-20 — **Bare `jackin usage` opens the host-wide deduplicated overview, while `jackin usage <instance> …` remains available for inspecting a particular Capsule instance.** Because the normal operator path should show all host usage immediately without removing instance-scoped inspection.
- 2026-08-20 — **Capsule shows every agent in the current fully resolved instance launch configuration; an agent with no started session carries the typed `agent_uninitialized` lifecycle error, with a quota preview when a resolved usage capability exists.** The lifecycle error remains visible beside any preview, is distinct from usage resolution or refresh failure, and never blocks launch.
- 2026-08-20 — **The host-wide `jackin usage` and `jackin console` views include all eight host usage surfaces: Claude, Codex, Amp, Grok, Kimi, OpenCode, Z.AI, and MiniMax; jackin❯ desktop retains the same catalog except OpenCode.** Because the host surfaces must cover every discovered agent and configuration while the desktop catalog remains a separate settled product boundary.
- 2026-08-20 — **`jackin usage` and the `jackin console` usage screen consume the same Rust-owned canonical inventory, deduplication, refresh, cache, and projection; only their presentation differs.** The CLI renders human-readable or JSON output, while the console renders the TUI, so both surfaces stay behaviorally consistent.
- 2026-08-20 — **One host broker owns provider refresh and durable canonical-account freshness.** Local processes and views may retain immutable projections for presentation, but they never probe providers, own retry deadlines, or queue duplicate refresh generations, because concurrent callers must share cached and in-flight work.
- 2026-08-20 — **Current read-only discovery across global, role, workspace, and workspace-role scopes owns host inventory membership; durable history only enriches current members, and unsupported or undiscovered providers do not appear as empty rows.** Because host-wide usage should reflect presently available configurations without resurrecting stale accounts or fabricating availability.
- 2026-08-20 — **Usage is a top-level route in `jackin console`, opening on Overview in the console's established left-list/right-detail structure.** Because usage is a primary host-wide operator surface and should reuse familiar console navigation rather than hide behind a workspace or modal.
- 2026-08-20 — **The console TUI orders provider groups by the settled eight-surface list and canonical accounts beneath them; it explicitly represents loading, refreshing, empty, stale last-good, partial-provider error, and global failure.** Selection drives detail, `r` refreshes, Back/Escape follows the shared navigation contract, and active keys appear in footer hints, because every state and action must remain visible and predictable.
- 2026-08-20 — **Human `jackin usage` output renders provider groups, one canonical row per account, then that account's limit windows, with explicit stale and error annotations; `--format json` exposes the same projection as a stable machine-readable envelope.** Because CLI and TUI must express the same truth without flattening canonical accounts back into duplicated window rows.
- 2026-08-20 — **Instance `accounts` and `verify` retain their Capsule inspection and verification intent; every host read is moved onto the canonical broker projection, and cache, `--no-refresh`, `--sync-host-cache`, or snapshot forms that preserve an independent freshness authority or misleading bypass are removed or redefined rather than kept as compatibility shims.** Because diagnostic value must survive without preserving the architecture that permits duplicate or stale authority.
- 2026-08-20 — **When a Capsule receives multiple launch-forwarded accounts for one fully resolved launch-config agent, its quota preview shows every deduplicated canonical account and supports account detail or selection.** Because collapsing to a surface-only request is ambiguous and hiding accounts would make the preview incomplete.
- 2026-08-20 — **The Capsule quota preview orders rows by fully resolved launch-config agent then canonical account and distinguishes `agent_uninitialized`, loading, available limits, no-capability, stale last-good, usage resolution failure, and refresh failure.** Its single refresh action joins active broker work, and selection survives the transition to an initialized session, because lifecycle and data freshness are independent and should not disrupt operator context.
- 2026-08-20 — **Quota data is informational and never authorizes or blocks Capsule agent launch or session actions, including when limits are exhausted, unknown, stale, or failed.** Because usage observation and launch policy are separate responsibilities, while explicit state remains sufficient for informed operator choice.
- 2026-08-20 — **Every usage surface consumes Rust-owned remaining/used conventions, rounding, countdowns, stale markers, missing-plan fallbacks, and money-cap units verbatim, adapting layout only.** Because presentation code must not infer or reinterpret quota meaning and create cross-surface disagreement.
- 2026-08-20 — **jackin❯ desktop derives a filtered view from the same canonical host discovery and account graph, excluding OpenCode and applying its frozen Codex, Claude, Amp, Grok, Z.AI, Kimi, MiniMax order plus native presentation settings without a second identity or discovery pipeline.** Because one account graph preserves deduplication and broker authority while retaining the settled seven-provider desktop boundary and order.
- 2026-08-20 — **Bare `jackin usage` renders every usable row with explicit partial-provider stale or error state and exits successfully; it exits nonzero only for an invalid invocation or when no usable projection can be produced.** A valid completed membership evaluation is usable even when empty or unresolved-only; current or stale last-good rows make partial output usable. When every current member failed with no last-good row, human and JSON output still preserve structured failures but exit nonzero, because partial degradation is usable output while total provider failure is not.
- 2026-08-20 — **jackin❯ desktop retains Rust-ranked provider-focused status items with icon-only, worst-provider, pinned-provider, and bounded-strip modes.** Clicking an item focuses that provider and its selected canonical account, while the Usage window remains the all-provider overview, because glanceable urgency and complete exploration serve different operator moments.
- 2026-08-20 — **jackin❯ desktop preserves its native popover, retained two-pane Usage window, and Settings information architecture unless prototype evidence proves a specific structural defect.** Because the existing structure is native and coherent, while design work should target evidenced usability and craft gaps instead of decorative replacement.
- 2026-08-20 — **Finalizing jackin❯ desktop includes Developer ID signing, notarization, a public artifact, and Homebrew cask installation proof.** Because the native application is not complete until its release path satisfies the platform trust boundary and an operator can install the shipped artifact.
- 2026-08-20 — **The jackin❯ desktop Usage window keeps alternative A (Grouped Overview, Provider Detail) without the H popover remix, as selected by Alexey Zhokhov.** A is the structure the running incumbent prototype already proves buildable; every recorded baseline defect is a row/composition failure, not a structural one, so the fix is targeted rather than a re-architecture. B moves too many long account labels into navigation, G adds an urgency destination without baseline evidence that reaching depleted/stale rows is slow, and H removes complete quota-window detail from a popover whose baseline hierarchy already passed visual review. Full selection record: [`native/Design/UnifiedAgentUsage/Alternatives.md`](../../native/Design/UnifiedAgentUsage/Alternatives.md).

## Capabilities

- Provide agent usage CLI output through `jackin usage`.
- Preserve explicit Capsule-instance account inspection and verification while eliminating host-side cache and refresh bypasses.
- Make agent usage available inside `jackin console`.
- Show subscription and quota usage limits only, including remaining or used percentage, reset countdowns, plan and status, and provider-supplied limit windows such as money caps when they are quota bounds, as required by [`AGENTS.md`](../../AGENTS.md).
- Ship jackin❯ desktop with Developer ID signing, notarization, a public artifact, and verified Homebrew cask installation.

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
- **Design**: Swift and system-owned native Liquid Glass; Rust-ranked provider-focused status items support icon-only, worst-provider, pinned-provider, and bounded-strip modes; the Usage window remains the all-provider overview.
- **Glance behavior**: Clicking a provider status item focuses that provider and its selected canonical account in the popover before deeper navigation.
- **Structure rule**: Human selection 2026-08-20 (Alexey Zhokhov): alternative A — Grouped Overview, Provider Detail — without the H popover remix; the native popover, two-pane Usage window, and Settings architecture are retained.

### CLI usage output

- **Purpose**: Render the shared host-wide usage projection through bare `jackin usage`.
- **States**: Current, refreshing, stale last-good, partial-provider error, empty, and global failure.
- **Key interactions**: Use human output by default or `--format json` for the stable envelope; pass an instance for Capsule-scoped inspection.
- **Design**: Provider groups contain one canonical row per account followed by that account's limit windows.
- **Exit contract**: Empty or unresolved-only inventory exits zero when membership evaluation completed; partial stale or failed providers with current or last-good rows exit zero; all current members failed with no last-good row, invalid invocation, or failure to construct a schema-valid envelope exits nonzero. JSON retains structured failures whenever an envelope can be constructed.

### Capsule usage

- **Purpose**: Show quota limits for every agent in the current fully resolved instance launch configuration and its canonical accounts, including an optional preview before the first session starts.
- **States**: `agent_uninitialized`; loading; available limits; no-capability explanation; stale last-good; usage resolution failure; refresh failure; initialized session.
- **Key interactions**: Select an agent and canonical account; inspect its windows; use one refresh action that joins active broker work; retain selection when the agent becomes initialized.
- **Design**: Derive membership only from the fully resolved instance launch configuration, order by resolved agent then canonical account, and keep lifecycle error separate from quota availability or freshness. Never render fixed global tabs or unresolved/global agent rows.

## Flows

1. The operator runs bare `jackin usage` or enters Usage in `jackin console`; both request the same host projection, join an active canonical-account refresh when one exists, and render the result as CLI output or TUI respectively.
2. From the console Overview, the operator moves into provider and account detail without triggering a second discovery, deduplication, or provider-fetch path.
3. The operator runs `jackin usage <instance> …` to inspect one Capsule instance's current usage projection without losing the host-wide default path.
4. In `jackin-capsule`, every agent in the fully resolved instance launch configuration appears before its first session with `agent_uninitialized`; a known quota preview accompanies that error when possible, and the lifecycle error clears after the first session starts.
   When an agent has multiple launch-forwarded accounts, each canonical account remains visible and selectable.
5. In jackin❯ desktop, the operator glances from the status item and popover, then opens the retained Usage window for Overview or provider/account detail.

## Data & integrations

- Rust owns the shared host provider/account projection consumed by both `jackin usage` and `jackin console`; their output adapters do not rediscover, rededuplicate, or refresh accounts independently.
- The host projection covers all eight usage surfaces. A derived filtered jackin❯ desktop projection remains limited to its fixed seven-provider catalog by excluding OpenCode.
- Rust owns desktop discovery, account identity, deduplication, broker coordination, quota shaping, and immutable projections; the UniFFI boundary exports sanitized display data, and Swift remains display-only.
- Current read-only configuration discovery owns host inventory membership; history may enrich but never create membership.
- Capsule inventory membership is a separate instance-scoped filter derived only
  from the current fully resolved launch configuration. A resolved usage
  capability enriches an eligible agent with preview rows but never creates an
  agent row by itself.
- Rust owns all quota labels and formatting semantics; CLI, TUI, Capsule, FFI, and Swift adapt only layout and never infer usage meaning.

## References

- [`crates/jackin-capsule/`](../../crates/jackin-capsule/) — existing capsule usage experience named as the console TUI reference.
- [`native/`](../../native/) — native macOS application surface.

## Native design preparation

- [Experience brief](../../native/Design/UnifiedAgentUsage/ExperienceBrief.md) —
  archetype, jobs, hierarchy, actions, window model, accessibility, and release
  acceptance contract.
- [Native component map](../../native/Design/UnifiedAgentUsage/NativeComponentMap.md)
  — system-owned component choices, region classifications, interaction
  contracts, and explicit custom-component absence.
- [Structural alternatives](../../native/Design/UnifiedAgentUsage/Alternatives.md)
  — eligible A, B, and G Usage-window directions, optional H popover remix,
  rejected counter-directions, and the recorded human selection of A without H
  (2026-08-20).
- [Anti-reference corpus](../../native/Design/UnifiedAgentUsage/AntiReferences.md)
  — explicit rejected states, failure reasons, corrections, and learned rules;
  pending eligible directions remain human-owned.
- [Canonical fixture matrix](../../native/Design/UnifiedAgentUsage/Fixtures.md) —
  deterministic F00–F24 scenario/task definitions, future prototype subscenario
  IDs and launch contract, status-item projections, and live/post-signoff
  coverage.
- [Prototype handoff](../../native/Design/UnifiedAgentUsage/PrototypeHandoff.md)
  — exact selection preconditions, skill invocation, revision ledger, package,
  live blessing, `SIGNOFF.md`, `Regions.md`, and post-signoff QA gates.
- [Legacy baseline visual QA](../../native/Design/UnifiedAgentUsage/BaselineVisualQA.md)
  — running-app evidence, Increased Contrast hard failure, missing automation,
  restoration proof, and states still requiring final QA.
- [Swift project readiness audit](../../native/Design/UnifiedAgentUsage/SwiftProjectReadiness.md)
  — generation, toolchain, CI, test, signing, binding, and Rust-core remediation
  inputs.
- [Swift best-practices review](../../native/Design/UnifiedAgentUsage/SwiftBestPracticesReview.md)
  — concurrency, ownership, typed boundary, adaptive sizing, accessibility,
  AppKit, localization, and failure-path remediation inputs.

Human structural selection is recorded: alternative A without H (Alexey
Zhokhov, 2026-08-20). The prototype handoff preconditions are met; the runnable
prototype package, `SIGNOFF.md` live blessing, post-signoff baseline, design
approval, READY transition, and plan remain unclaimed.

## Research

- [Agent usage platform research](../../research/agent-usage-platform/README.md) — vetted architecture, Apple-native, reference-implementation, cache-authority, identity, projection, and delivery evidence.
- [Research verification ledger](../../research/agent-usage-platform/05-verification-ledger.md)
  — exact source searches, test commands/results, expected assertions, and
  explicit zero-test/unavailable proof gaps.
- A static code-path trace found that Capsule provider work is correctly restricted to launch-forwarded capabilities derived from the resolved workspace, role, profiles, and credential environment ([relay capability construction](../../crates/jackin-runtime/src/usage_relay.rs#L189-L215), [exact scope filtering](../../crates/jackin-runtime/src/usage_relay.rs#L385-L419)). Confidence: HIGH.
- The same trace found that the Capsule usage dialog still displays all seven provider tabs rather than filtering its display by those capabilities ([fixed provider tabs](../../crates/jackin-usage/src/usage/view.rs#L470-L489)); unavailable tabs fail closed at the relay instead of disappearing. Confidence: HIGH.
- The target contract removes those fixed tabs: Capsule presentation membership
  must equal the current fully resolved instance launch configuration, with no
  global, unresolved, or capability-only rows.
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
- MUST NOT disable or block Capsule launch or session actions based on exhausted, unknown, stale, or failed quota observations.
- MUST NOT downgrade `agent_uninitialized` to a neutral/success state merely
  because a quota preview is available, or confuse that lifecycle error with a
  provider usage failure.
- MUST NOT populate Capsule presentation from the fixed provider catalog, global
  host discovery, unresolved configuration, or usage capability alone; the
  fully resolved instance launch configuration owns membership.

## Quality bar

- The console TUI satisfies the repository's TUI decisions for non-blocking rendering, visible loading/refresh state, keyboard navigation, footer hints, focus and scroll behavior, modal geometry, and shared component reuse, with render-conformance fixtures for its major states.
- The desktop app uses system-owned native components and Liquid Glass, answers “Where am I?”, “What can I do?”, and “Where can I go from here?” in every state, passes the macOS design rubric with zero hard failures, and has running-app visual evidence plus accessibility audits across required appearance and Reduce-settings states.
- Concurrent usage reads and refreshes for one canonical account reuse shared cached data and join one in-flight refresh generation instead of issuing parallel duplicate provider requests; every usage surface must be verified against this invariant and any bypass fixed before shipping.
- CLI, console, Capsule, and desktop fixtures prove identical Rust-owned labels and values for the same projection, with only surface-appropriate layout differences.
- Release evidence proves Developer ID signing, notarization, public artifact publication, and installation through the Homebrew cask.

## Open questions

- ~~Which configuration sources make an account part of the host-wide inventory, and should supported but undiscovered providers appear?~~ **Resolved 2026-08-20**: current read-only discovery owns membership; history only enriches current members.
- ~~Where should Usage live in `jackin console`, and what is its navigation model?~~ **Resolved 2026-08-20**: top-level Usage route, Overview first, left-list/right-detail navigation.
- ~~What exact hierarchy, ordering, filtering, states, and refresh interactions should the console TUI use?~~ **Resolved 2026-08-20**: settled provider order, canonical accounts, explicit lifecycle/error states, selection-driven detail, `r`, shared Back/Escape, and footer hints.
- ~~What exact hierarchy should the human `jackin usage` output render from the shared projection?~~ **Resolved 2026-08-20**: provider groups, canonical account rows, limit windows, stale/error annotations, and stable JSON for the same projection.
- ~~What roles should the existing `host snapshot`, instance `accounts`/`verify`, cache, `--no-refresh`, and `--sync-host-cache` forms retain after the bare overview is added?~~ **Resolved 2026-08-20**: keep instance inspection/verification intent, move host reads to the canonical broker projection, and remove or redefine bypassing forms without compatibility shims.
- ~~When `jackin-capsule` receives multiple launch-forwarded accounts for one resolved launch-config agent, should the quota preview show every canonical account or one selected account?~~ **Resolved 2026-08-20**: show every deduplicated canonical account and support account detail or selection.
- ~~What are the full Capsule quota-preview presentation rules?~~ **Resolved 2026-08-20**: membership comes only from the fully resolved instance launch configuration; order by resolved agent then canonical account; show typed `agent_uninitialized` until a session starts, optionally accompanied by limits; distinguish loading, limits, no-capability, stale, usage-resolution, and refresh states; join active work on refresh; preserve selection through initialization.
- ~~May exhausted, unknown, stale, or failed quota data block or disable Capsule agent launch and session actions?~~ **Resolved 2026-08-20**: no; usage remains informational and explicit states never become launch authorization or enforcement.
- ~~Which remaining/used convention, rounding, countdown form, stale marker, missing-plan fallback, and money-cap units should all output surfaces use?~~ **Resolved 2026-08-20**: consume Rust-owned labels and formatting semantics verbatim, adapt layout only, and perform no presentation-side quota inference.
- ~~Is jackin❯ desktop a filtered view of the same canonical host inventory or a separate discovery/inventory pipeline sharing only broker work?~~ **Resolved 2026-08-20**: derive the fixed seven-provider desktop projection from the canonical host account graph, excluding OpenCode and applying native presentation settings without a second discovery pipeline.
- ~~How should bare `jackin usage` exit when some providers are stale or failed but last-good rows remain usable?~~ **Resolved 2026-08-20**: empty or unresolved-only completed inventory exits zero; partial current or stale last-good rows exit zero; total current-member failure with no last-good, invalid invocation, or no schema-valid envelope exits nonzero; preserve structured failures in human and JSON output whenever possible.
- ~~Should the jackin❯ desktop menu bar use one aggregate status item or retain provider-focused status items, and which account/window should each glance prioritize?~~ **Resolved 2026-08-20**: retain Rust-ranked provider-focused status items and existing display modes; focus the clicked provider and selected canonical account; keep the Usage window as all-provider overview.
- ~~Should jackin❯ desktop retain its current native popover, two-pane Usage window, and Settings information architecture while design work focuses on evidence-led refinement, or permit a structural replacement?~~ **Resolved 2026-08-20**: preserve the current native structure unless prototype evidence proves a specific structural defect; avoid decorative replacement.
- ~~Does “finalize jackin❯ desktop” include the first Developer ID signing, notarization, public artifact, and Homebrew cask proof?~~ **Resolved 2026-08-20**: include Developer ID signing, notarization, public artifact publication, and Homebrew cask installation proof.

## Open research questions

- ~~Which durable broker ownership model preserves one refresh authority when short-lived CLI, desktop, and Capsule-relay processes start and exit?~~ **Dispositioned 2026-08-20**: both resident and demand-activated directions require an independent per-user broker service that survives its activating client. A bounded concurrent-start and owner-exit spike must select the activation/lifetime policy by proof; available reference evidence cannot choose it.
- ~~How should anonymous credential sources receive stable canonical identity before provider authentication without leaking secret material or merging distinct accounts?~~ **Dispositioned 2026-08-20**: never mint canonical identity from source ordinals, labels, or token material. Keep unresolved configuration capability state outside canonical account rows, then alias or merge only from provider-stable non-secret evidence. Planning must freeze exact normalization in the provider-by-scope identity matrix and implementation must prove every transition.
- ~~What are the canonical projection's schema/versioning, identity precedence, collision behavior, merge precedence, sorting, window grouping, partial-provider failure, and JSON evolution contracts?~~ **Dispositioned 2026-08-20**: the research contract matrix enumerates every V1 field and normative choice. Planning must freeze each row plus fixtures before implementation; no existing desktop or CLI projection is canonical enough to inherit.
- ~~What TTL, invalidation, retry/backoff, cancellation, locking, persistence, crash-recovery, force, and no-refresh semantics make the broker's single-authority guarantee executable and testable?~~ **Dispositioned 2026-08-20**: the research policy matrix defines every outcome, candidate mechanism, transition, and value that planning must freeze. Forced callers join one generation; no-refresh cannot bypass broker authority; current catalog/bindings must replace first-owner state; provider work cannot block indefinitely; and lease/recovery semantics remain broker-owned. Exact update, cancellation, storage, and lease mechanisms remain explicit planning choices.
- ~~Which current Apple macOS 26 Liquid Glass patterns, native component choices, accessibility behaviors, and exemplar applications should refine the existing jackin❯ desktop surfaces without custom-painted glass?~~ **Answered 2026-08-20**: preserve the system status item, native popover, retained split Usage window, and Settings structure; refine with standard AppKit and SwiftUI controls and verify appearance, contrast, transparency, focus, keyboard, VoiceOver, localization, display, and release matrices.
- ~~What exact dependency order, repository gates, and independently verifiable vertical slices let implementation preserve a green build while unifying the broker, CLI, console, Capsule, FFI, and Swift surfaces?~~ **Answered 2026-08-20**: identity/protocol, broker/projection, CLI/diagnostics, console/Capsule, FFI/Swift, native QA, then signed distribution, with green consumer-specific fixtures and no-direct-fetch architecture gates after each slice.

## Deferred

## Log

- 2026-08-20 — tailrocks-idea — created (DRAFT).
- 2026-08-20 — tailrocks-brainstorm — moved to SHAPING after settling the default CLI overview behavior.
- 2026-08-20 — tailrocks-brainstorm — closed shaping session after settling shared CLI/TUI behavior and Capsule pre-session usage; remaining decisions recorded with recommendations.
- 2026-08-20 — tailrocks-research — completed and linked vetted architecture, Apple-native, reference-implementation, and delivery research.
- 2026-08-20 — tailrocks-swift-project-setup — completed the read-only native project-readiness audit.
- 2026-08-20 — tailrocks-swift-best-practices — completed the read-only Swift architecture and implementation-practices review.
- 2026-08-20 — tailrocks-macos-visual-qa — recorded the failed incumbent running-app baseline and honest missing-state matrix.
- 2026-08-20 — tailrocks-macos-design — completed the preselection brief, component map, alternatives, and deterministic fixture contract; human selection remains mandatory.
- 2026-08-20 — tailrocks-record-decision — recorded the human structural selection of Usage-window alternative A without H (Alexey Zhokhov); propagated the selection record, anti-reference rejections, brief approval, and prototype-handoff preconditions; status stays SHAPING pending prototype blessing.
