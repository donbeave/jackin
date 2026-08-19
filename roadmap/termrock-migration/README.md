# TermRock migration

- **Status**: IN EXECUTION
- **Slug**: termrock-migration
- **Created**: 2026-08-19 · **Updated**: 2026-08-19
- **Plan**: [plans/termrock-migration/](../../plans/termrock-migration/README.md)

## Intent

Migrate jackin❯ to use the latest and greatest TermRock (https://github.com/tailrocks/termrock), which is located locally at `/Users/donbeave/Projects/tailrocks/termrock`.

Destination: all six consuming crates build against the TermRock head rev `e1d61f4d`, every surface runs on the new component set, brand compositions keep their look on new primitives, and PNG baselines prove each modernized surface's rendering.

## Vocabulary

- **Surface**: the TUI area of one consuming crate — console (`jackin-console`), capsule (`jackin-capsule`), launch (`jackin-launch`), adapter (`jackin`), facade (`jackin-tui`), oppicker (`jackin-oppicker`). The host-console adapter code in `crates/jackin/src/console/` belongs to the adapter surface, not console. _Avoid_: screen, app.
- **Bump phase**: the first PR — rev bump + mechanical API migration + the minimum compiler-forced redesigns (focus/modal, diff scrolling), each behaviorally parity-tested; no other judgement changes (decision 2026-08-19). _Avoid_: upgrade PR, port.
- **Modernization phase**: a per-surface PR that re-platforms that surface's hand-rolled machinery on the new TermRock component set. _Avoid_: refactor, redesign.
- **Brand compositions**: BrandHeader, digital rain, the launch animation (= the warp intro/outro), the launch progress rail, and the capsule brand pill (block + word + chevron) — jackin❯-owned visuals upstream declined to absorb (rail and pill: jackin❯'s own designations, decisions 2026-08-19). The rest of capsule row 0 (tabs, underline, menu, fills) is product chrome. _Avoid_: brand widgets, chrome.
- **Surface finalization**: the follow-up closing session on this item scoped to one surface (a `tailrocks-finalize`/`tailrocks-record-decision` round), run before `tailrocks-plan` produces that surface's modernization plan; it fixes that surface's adoption map, key-screen list, and brand proof mechanism. _Avoid_: sign-off, review.
- **Key screens**: the subset of a surface's existing screens selected for zero-tolerance PNG baselines; the list is fixed at that surface's finalization (Deferred). _Avoid_: main screens, critical screens.

## Decisions

- 2026-08-19 — **Migration target is the upstream GitHub head rev (`e1d61f4d`, 2026-08-17), pinned in the current style: exact version + git rev in `Cargo.toml`.** Because tags lag far behind main (newest tag ~v0.9.0 while head `Cargo.toml` says 0.11.0), the local checkout is byte-identical to origin/main today (verified: clean tree, 0 ahead / 0 behind), and a path dependency would not build in CI. Upstream's version string is unchanged at head, so the pin after the bump reads `=0.11.0` at rev `e1d61f4d` — only the rev moves; the version string is not a compatibility signal (see References).
- 2026-08-19 — **One-off catch-up bump; no recurring freshness policy in this item.** Because the research watchlist already tracks the pinned rev, and future bumps are routine dependency work rather than roadmap items.
- 2026-08-19 — **Scope is full modernization, not a minimal port.** Re-platform all six consuming crates on the new TermRock component set (patterns, overlays, virtualization, animation, experience layer), not just the mechanical compile-fix. Chosen over the recommended minimal-port option: the point of the migration is the latest-and-greatest experience, not merely a fresh pin.
- 2026-08-19 — **Brand compositions: rebuild allowed, look preserved.** BrandHeader, digital rain, and the launch animation stay jackin❯-owned and keep their current visual identity, but may be re-implemented on new TermRock primitives (`Spring`/`FrameClock` instead of hand-rolled timers). Because ownership and look are the invariants, not the implementation.
- 2026-08-19 — **Phasing: bump first, then modernize surface-by-surface.** PR 1 is the rev bump + mechanical migration (compiles everywhere, snapshots re-baselined, upstream visuals accepted); each subsequent PR modernizes one surface (console, capsule, launch, …). Because the mechanical layer must never mix with judgement changes — bisectable, and each surface gets its own TUI-design-decision review.
- 2026-08-19 — **Visual proof: adopt the upstream `termrock-raster` PNG baseline pipeline in jackin❯ during modernization phases, in addition to re-baselined text snapshots.** Because zero-tolerance pixel baselines are the strongest visual-regression proof for a look-changing migration, and upstream built that pipeline specifically for jackin❯ parity.
- 2026-08-19 — **Modernization order: console → capsule → launch → small surfaces (jackin adapter, jackin-tui facade, oppicker).** Because console is the largest surface (636 refs, most component variety) and modernizing it first sets the patterns every other surface copies, with the cheapest host-side smoke path.
- 2026-08-19 — **Brand-look invariant binds from the bump PR onward.** The bump PR compensates in consumer code (pin affected brand spans to jackin-brand constants or explicit styles) so brand compositions render identically despite the theme swap. Because research proved the swap recolors BrandHeader, the launch header, and capsule row-0 chrome with jackin❯ code untouched, and no text snapshot catches color shifts.
- 2026-08-19 — **Bump PR = mechanical migration plus the minimum forced redesigns, each behaviorally parity-tested.** The three redesigns the compiler forces (`SurfaceFocus`/`ModalFlow` onto `InteractionScene`/`FocusGraph`/`OverlayStack`; `DiffViewState` scrolling) land inside the bump PR with named parity tests for Esc cascade, focus restore, and diff scrolling. Because the bump cannot compile without them, so they cannot be deferred past it — and untested redesigns inside a "mechanical" PR are how regressions hide.
- 2026-08-19 — **Surface background treatment is decided at bump-PR review from a side-by-side render** of the upstream obsidian surface ladder vs `RolePalette::terminal_native()`. Because a look decision should be made seeing both variants; research chapter 03 supplies the exact value tables. (Deferred entry records the trigger.)
- 2026-08-19 — **The launch progress rail is brand: look preserved.** The rail joins the protected brand set alongside BrandHeader, digital rain, and the launch animation — rebuild on new primitives allowed, current look preserved. Chosen over the recommended product-UI option: the rail is part of the launch brand experience.
- 2026-08-19 — **Adoption rule: swap wherever an upstream equivalent exists.** The concrete per-surface pairing map and each surface's key-screen list for PNG baselines are settled at that surface's finalization, console first, from research chapter 04's pairing tables. Because pairing decisions are best made next to the code with the vetted tables in hand.
- 2026-08-19 — **Capsule status-bar row 0: the brand pill is brand, the rest is product chrome.** The pill (block + word + chevron) gets bump-PR color compensation and stays frozen; tabs, underline, menu, and fills adopt the accepted upstream look. Because the protected set is compositions, not whole bars, and the capsule should stay visually coherent with modernized surfaces.
- 2026-08-19 — **Screen-set and flow preserving.** This item adds no new operator-visible screens or overlays and changes no operator journeys — existing screens change substrate and (accepted) look only; upstream new-UI candidates (e.g. `keyboard_help`, `notification_center`) become separate roadmap ideas. Because the migration must stay finishable and reviewable against a fixed screen inventory, and journey parity is exactly what the decided parity tests protect.
- 2026-08-19 — **TermRock is ours to change: when a TermRock API does not fit jackin❯, the preferred move is to extend or refactor TermRock itself** — making the API flexible enough to serve both jackin❯ and TermRock's role as a general reusable TUI component library — rather than working around it on the jackin❯ side. Breaking TermRock changes are acceptable at any time. Because TermRock is fully under our control and fully focused on our projects; it was designed as code exported from jackin❯ to become reusable, and jackin❯ is today its only consumer. This rule applies across every phase of this item.
- 2026-08-19 — **jackin-tui facade end-state deferred to console-phase finalization.** Until then the facade keeps its product runtime traits (`Component`/`View`/`Subscription`). Because the first modernized surface supplies the evidence the choice needs. (Deferred entry records the trigger.)

## Capabilities

- The workspace pin moves from rev `5ff94ee` (2026-07-17) to upstream head `e1d61f4d` (2026-08-17), same exact-version + git-rev style.
- Every surface is re-platformed on the new TermRock component set (overlays, virtualization, patterns, runtime animation, experience layer) wherever an upstream equivalent replaces hand-rolled machinery.
- Brand compositions are re-implemented on new TermRock primitives with their visual identity unchanged.
- Key screens of each modernized surface gain zero-tolerance PNG baselines via the `termrock-raster` pipeline.

## Screens

No new screens — explicit declaration (decision 2026-08-19). This item is screen-set preserving: every existing screen keeps its purpose, information architecture, states, interactions, and navigation; only the rendering substrate (TermRock head components) and the accepted upstream visuals change. The complete existing-screen inventory per surface (console stages + 19 modals, capsule multiplexer + 15 dialogs, launch cockpit + overlays + standalone prompts, small surfaces) is cited with `file:line` in [`research/termrock-head-adoption/04-component-adoption-candidates.md`](../../research/termrock-head-adoption/04-component-adoption-candidates.md). Visual truth per screen is owned by the quality bar's snapshot/PNG-baseline gates, not by mockups here. Upstream components that would introduce new operator-visible UI are out of scope and become separate roadmap ideas.

## Flows

No new or changed flows — explicit declaration (decision 2026-08-19). Every operator journey (workspace create/edit/save, launch, capsule dialog chains, exit paths) keeps its steps, screens, and failure points. The three compiler-forced redesigns touch flow-adjacent behavior (Esc cascade, focus restore, diff scrolling); the bump PR's named behavioral parity tests are the gate proving those journeys unchanged (decision 2026-08-19, Quality bar).

## Data & integrations

None — dependency migration; no product data owned. External touchpoints are the TermRock git source only (`Cargo.toml:118` pin, `deny.toml:204` allowlist).

## References

- https://github.com/tailrocks/termrock — upstream TermRock repository named in the request.
- `/Users/donbeave/Projects/tailrocks/termrock` — local TermRock checkout named in the request; head `e1d61f4d` ("feat: achieve Jackin-TermRock parity (#34)", 2026-08-17), 56 commits ahead of the rev the workspace pins.
- `Cargo.toml:118` — the workspace pins `termrock = "=0.11.0"` at git rev `5ff94ee117fd4a1b72fdd0d1b1847815055a93ac` (2026-07-17) with features `crossterm`, `serde`.
- Six workspace crates consume termrock via `termrock = { workspace = true }`: `crates/jackin-console` (636 refs — largest surface), `crates/jackin-capsule` (287), `crates/jackin-launch` (205), `crates/jackin` (27), `crates/jackin-tui` (20 — product-side facade), `crates/jackin-oppicker` (3). Grep survey 2026-08-19.
- Note: the AGENTS.md TUI table's `src/console/tui/` path does not exist; the real host-console surface is `crates/jackin-console/src/tui/` plus `crates/jackin/src/console/`. The fix belongs to whichever PR next touches AGENTS.md under the repository docs gate — this shaping session writes only the item and index.
- `deny.toml:204` — allowlists the termrock git source; a rev/URL change touches it.
- `crates/jackin-xtask/src/arch.rs:253-275` — arch gate forbids termrock in `jackin-core`/`jackin-runtime` and forbids re-vendoring `theme.rs`/`terminal.rs`/`run.rs` into `jackin-tui` — a standing constraint on how far the facade surface's modernization can reach.
- 18 `.snap` snapshot fixtures render through termrock (`crates/jackin-console/src/tui/view/snapshots/` ×6, `crates/jackin-capsule/src/tui/components/dialog/snapshots/` ×10, `crates/jackin-capsule/src/tui/components/branch_context_bar/snapshots/` ×2); ~25 unit test modules import termrock directly.
- `docs/content/reference/tui/` — 7 pages mention termrock; 3 pin soon-dead names and enter the bump PR's docs gate: `visual-design.mdx:10,24,64,76` (`Theme::default().style(role)`, `PanelEmphasis`), `dialogs.mdx:174` (`FocusRing` + `ModalStack` lifecycle), `navigation.mdx:24,26,142,249,359` (rg survey 2026-08-19). Repository law requires same-PR docs updates for TUI changes.
- `docs/content/research/watchlist.mdx:63-65` — explicitly tracks the pinned termrock revision, render fixtures, and compatibility matrix.
- API breadth in use (grep survey): `style` (281 refs, incl. `Role::*`), `scroll` (203), `widgets` (184, incl. `Panel`, `StatusBarState`, `DetailTable`, `ListState`, `TextInputState`, `HintSpan`), `text` (45), `osc` (40), `layout` (33), `input` (23), `keymap` (18), `interaction` (18, incl. `FocusRing`, `ModalStack`), `termrock::Theme::default` (314).
- `crates/jackin-capsule/src/tui/components/dialog/hint.rs:25` — comment-level mirror of `termrock::keymap::chord_glyph` convention; drift-prone on a bump.

Delta survey `5ff94ee..e1d61f4d` (method: git log/diff + upstream `migrations/` docs, 2026-08-19):

- Version string is not a compatibility signal: workspace `version = "0.11.0"` unchanged at both ends, no tags in range, while 304 numbered migration docs (`migrations/0028…0331`) target v0.12.0–v0.14.0; upstream CHANGELOG stale relative to `migrations/`.
- Breaking renames that hit jackin❯ directly (numbers superseded 2026-08-19 by the compiler-measured inventory in `research/termrock-head-adoption/`): crate-root re-exports purged (`termrock::Theme` — 351 matching lines, 305 measured errors — now `style::RolePalette`/`DesignSystem`); `widgets::PanelEmphasis` → `PanelChrome` (24 errors); `interaction::FocusRing`/`ModalStack` made crate-private (→ `InteractionScene`/`FocusGraph`/`OverlayStack` — redesign, not rename); `style::Role` tab-underline variants removed (~30 new variants added). (`runtime::RunOptions.synchronized_output` earlier listed here is not a jackin❯-used termrock API — jackin's `RunOptions` comes from `jackin_core`.)
- `2856f718 feat(design)!: complete premium TUI overhaul` (explicit BREAKING CHANGE trailer, migrations 0278–0326) changes visual output — the 18 jackin❯ snapshots will not survive unchanged.
- Parity commit `e1d61f4d` (#34): adds `termrock-raster` Ratatui→PNG baseline pipeline (107 phosphor PNG baselines, zero-tolerance pixel compare, `mise run png-baselines`/`bless-pngs`); promotes `widgets::TerminalCellGrid`+`TerminalCellSource` and `runtime::ReadySubscription` to public; explicitly declines to absorb jackin❯ brand/domain compositions (BrandHeader, digital rain, launch animation stay consumer-owned).
- Upstream migration directive (data point, matches repository latest-only law): migrate imports directly, no compatibility facades.
- New capabilities available post-bump (128 new widget files; highlights): virtualization (`virtual_list`, `virtual_grid`, `tree_table`, `data_table`), overlays/nav (`command_palette`, `drawer`, `popover`, `quick_open`, `notification_center`, `sidebar`), form controls (`select`, `combobox`, `form_wizard`, `date_time_picker`), runtime animation (`Spring`/`Tween`/`FrameClock`), style capability handling (`quantize` xterm256, `contrast_floor`, `density`), new modules `capability`, `context`, `patterns`, `perf`, `registry`.
- Feature flags identical at both revs (`crossterm`, `serde` still valid); new hard dep `web-time`; `ratatui` now `default-features = false`; MSRV 1.97 → 1.97.1.

## Research

- [`research/termrock-head-adoption/`](../../research/termrock-head-adoption/README.md) — the full evidence base: compiler-measured break inventory (384 errors, 15 classes), the 40 applicable upstream migration docs, theme/brand recolor facts, per-surface adoption pairing tables with trade-offs, and the PNG-baseline pipeline adoption contract.

## Must not

- MUST NOT move brand/domain compositions (BrandHeader, digital rain, launch animation, launch progress rail) into TermRock or change their visual identity — upstream explicitly declined to absorb the first three (migration doc 0331); the rail is jackin❯-designated brand (decision 2026-08-19); ownership and look are invariants, implementation is not.
- MUST NOT introduce compatibility facades or shim layers over renamed TermRock APIs — repository latest-only law; upstream migration docs direct the same. When an API misfits, the sanctioned route is changing TermRock itself (decision 2026-08-19), never a jackin❯-side shim.

## Quality bar

- Bump phase: all six crates compile against rev `e1d61f4d`, full test suite green, the 18 existing text snapshots deliberately re-baselined (upstream visuals accepted — wholesale, in bump-PR review under TESTING.md's snapshot gate), TUI docs under `docs/content/reference/tui/` updated in the same PR; named behavioral parity tests pass for the three forced redesigns (Esc cascade, focus restore, diff scrolling); brand compositions render identically via consumer-code compensation (decisions 2026-08-19).
- Bump phase additionally owns the forced side-tasks: `Cargo.lock` bump (serde 1.0.229 wave), the two cargo-deny skip entries (`base64@0.22.1`, `syn@2.0.119`), the three docs pages pinning dead names plus the stale AGENTS.md TUI-table path (same-PR docs gate), and the `hint.rs:25` chord_glyph-mirror drift check. Toolchain/dependency ripples (MSRV 1.97.1, `web-time`, `ratatui default-features = false`) carry no separate gate — the compile + suite-green gate covers them. The background variant chosen at bump-PR review lands inside the bump PR before merge (snapshots re-baselined on the chosen variant).
- Modernization phases: each surface additionally adopts the `termrock-raster` PNG baseline pipeline for its key screens — zero-tolerance pixel compare with a bless workflow, per the pipeline upstream built for jackin❯ parity (decision 2026-08-19). The pipeline's CI wiring lands with the first modernization phase (console); the gate binds on CI's runner platform, and cross-OS identity stays a parked research question, not a merge blocker. Text snapshots remain the standing suite; PNG baselines are additive.
- Brand surfaces: the brand compositions' own rendering stays identical before/after re-implementation; surrounding chrome may change with its surface's modernization. Each brand composition is rebuilt in its owning surface's modernization phase (BrandHeader: console + launch copies; rain, warp, rail: launch); the bump PR only compensates colors. The exact proof mechanism (text snapshot vs PNG-baseline crop) is settled at that surface's finalization.
- Usage-limits-only hard rule wins over adoption: if the `context_meter`/`metric_tile` render-path read fails it, those widgets are not adopted and the hand-rolled meter stays.
- Deliberately plan-owned (not specified here): PR granularity and internal sequencing for the small surfaces, concrete parity-test names/harness/locations, and the per-span brand compensation mechanism (jackin-brand constants vs explicit styles) — the affected-span inventory itself is research-supplied ([ch03](../../research/termrock-head-adoption/03-theme-brand-impact.md), Brand composition color sources).

## Open questions

All six 2026-08-19 open questions are settled — see Decisions (2026-08-19): brand invariant binds from bump PR; bump PR carries the three forced redesigns with parity tests; background treatment decided at bump-PR review (Deferred); progress rail designated brand; adoption rule settled with per-surface maps at finalization (Deferred); facade end-state deferred to console finalization (Deferred).

## Open research questions

- ~~Full per-crate compile-break inventory~~ — answered 2026-08-19 by [`research/termrock-head-adoption/`](../../research/termrock-head-adoption/01-compile-break-inventory.md): 384 measured errors across 15 classes, each mapped to its migration doc; plus a cargo-deny bans failure needing two skip entries.
- Mouse-subsystem behavioral parity: side-by-side interaction matrix of upstream `ScrollArea`/`UiContext` vs the pixel rules in `input/mouse/*` tests (console phase planning).
- `TerminalCell` metadata coverage vs capsule `HyperlinkRegion`/`SgrRegion` compositor caches (capsule phase planning).
- `context_meter`/`metric_tile` full render-path read against the usage-limits-only hard rule, before any Usage-dialog wiring.
- macOS↔Linux PNG baseline identity for `termrock-raster` (upstream measured per-arch only; measure once when wiring the jackin❯ CI lane).

## Deferred

- Surface background variant: obsidian ladder vs `RolePalette::terminal_native()` — revisit at bump-PR review with a side-by-side render (decision 2026-08-19 fixed the method; research ch03 has the value tables).
- Per-surface component adoption map + key-screen list — revisit at each surface's finalization, console first (rule settled 2026-08-19: swap wherever an upstream equivalent exists; research ch04 holds the pairing tables).
- jackin-tui facade end-state (product traits vs upstream `event_result`/`runtime` contracts) — revisit at console-phase finalization, once the first surface has exercised the upstream contracts.

## Log

- 2026-08-19 — execution — plan 002 resumed (BLOCKED → IN PROGRESS): operator authorized the misfit route ("allowed to change anything in termrock by creating a PR there") — executor lands the upstream knobs itself as stacked termrock PRs, re-pins, and continues step 12 until only the 13 sanctioned insta snapshot failures remain.

- 2026-08-19 — execution — plan 002 BLOCKED (termrock API misfit). Steps 1–11 landed green on `feature/termrock-head-bump` (pin now 9bd01be via stacked upstream PRs tailrocks/termrock#35 scroll_mut, #36 show_cursor, #37 status-bar separator budget, #38 classic-toast width; host adaptations: Panel-padding margins, host-owned Tab/BackTab cycling, dialog rhythm-row budgets, Backdrop::reset under modals). Step 12 full-suite census at 9bd01be: 31 failures, of which 13 are the sanctioned insta snapshot assertions in the three named modules (plan 003's worklist), but 18 are NON-snapshot behavior assertions the break inventory missed — (a) selection marker `▸`→`▌` gutter redesign (daemon::tests ×2, capsule dialog::tests::exit_dirty_selection_marker_moves_on_down_arrow, console role_picker/workspaces-list/file_browser column shifts ×8), (b) hover chrome redesign (branch_context_bar hover color, usage tab hover underline), (c) DetailTable click-region geometry (github_context clickable_at ×2), (d) status-slot style change (debug chip DANGER_RED bg). Classes (a)/(b)/(d) have no host override at head (GlyphSet is a profile enum). Recommended upstream change: host-configurable selection/hover glyphs on GlyphSet plus a status-slot explicit-style precedence fix — or re-plan sanctioning assertion updates where the head chrome is the wanted end state. Executor stopped per step 12's STOP rule; routing is the operator's.

- 2026-08-19 — execution — bump phase started (PLANNED → IN EXECUTION): plan 001 (parity characterization tests at the old pin) IN PROGRESS on `feature/termrock-head-bump` (cut off `roadmap/termrock-migration`; docs PR #896 still open — fallback branch-origin path per the hub).

- 2026-08-19 — tailrocks-idea — created (DRAFT).
- 2026-08-19 — tailrocks-brainstorm — shaped (DRAFT → SHAPING): settled target rev, one-off cadence, full-modernization scope, bump-first phasing, brand invariants, PNG-baseline quality bar, console-first order; corrected the stale `src/console/tui/` surface fact to the six-crate usage map; delta survey `5ff94ee..e1d61f4d` recorded.
- 2026-08-19 — tailrocks-record-decision — recorded: TermRock is jackin❯-controlled and freely extendable/refactorable (breaking changes OK) whenever its API misfits — upstream change over jackin❯-side workaround, keeping TermRock a general reusable TUI library; propagated to Must not (N2 note), the plan hub's repo law (executor BLOCKED route), and GOAL.md prompts; package fingerprint refreshed.
- 2026-08-19 — tailrocks-plan — planned (READY → PLANNED): bump-phase package at plans/termrock-migration/ — coverage ledger, 6-file spec, 4 plans (parity tests → bump → brand/re-baseline → docs/gates), GOAL.md handoff; excerpt-verified per plan, cold-reviewed per plan (all majors fixed, incl. progress-rail recolor defect found in the spec), traceability gate PASS; new research topic jackin-verification-tooling (vetted). Modernization phases deliberately not planned — each waits on its surface's finalization per the item's Deferred triggers.
- 2026-08-19 — tailrocks-finalize — closed (SHAPING → READY): screen-set/flow-preserving declarations written and confirmed; capsule row-0 ownership split decided (pill = brand, rest = product); vocabulary gained "Key screens", "Surface finalization", warp/pill clarifications; quality bar gained side-task ownership, background landing vehicle, dep-ripple coverage, plan-owned delegations; readiness checklist passed in full; planning dry run passed with fresh eyes on the third round (rounds 1–2 findings written back). Next: tailrocks-plan termrock-migration.
- 2026-08-19 — tailrocks-record-decision — recorded six decisions (brand-invariant@bump, bump-scope redesigns+parity-tests, background-at-review, rail=brand, adoption rule, facade deferral); struck all open questions; three Deferred entries added; vocabulary, must-not, and quality bar reconciled. Status stays SHAPING.
- 2026-08-19 — tailrocks-research — deep pass produced [`research/termrock-head-adoption/`](../../research/termrock-head-adoption/README.md) (5 vetted chapters + 2 critic rounds): compile-break inventory answered (384 errors / 15 classes / cargo-deny gate), 40 applicable migration docs, brand-recolor facts confirmed, adoption pairing tables, PNG-pipeline contract; struck the answered research question, added four plan-time research questions and four surfaced decision questions.
