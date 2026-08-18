# TermRock migration

- **Status**: SHAPING
- **Slug**: termrock-migration
- **Created**: 2026-08-19 · **Updated**: 2026-08-19
- **Plan**: — (plans/termrock-migration/ once planned)

## Intent

Migrate jackin❯ to use the latest and greatest TermRock (https://github.com/tailrocks/termrock), which is located locally at `/Users/donbeave/Projects/tailrocks/termrock`.

Destination: all six consuming crates build against the TermRock head rev `e1d61f4d`, every surface runs on the new component set, brand compositions keep their look on new primitives, and PNG baselines prove each modernized surface's rendering.

## Vocabulary

- **Surface**: the TUI area of one consuming crate — console (`jackin-console`), capsule (`jackin-capsule`), launch (`jackin-launch`), adapter (`jackin`), facade (`jackin-tui`), oppicker (`jackin-oppicker`). The host-console adapter code in `crates/jackin/src/console/` belongs to the adapter surface, not console. _Avoid_: screen, app.
- **Bump phase**: the first PR — rev bump plus mechanical API migration only; no judgement changes. _Avoid_: upgrade PR, port.
- **Modernization phase**: a per-surface PR that re-platforms that surface's hand-rolled machinery on the new TermRock component set. _Avoid_: refactor, redesign.
- **Brand compositions**: BrandHeader, digital rain, launch animation — jackin❯-owned visuals upstream declined to absorb. _Avoid_: brand widgets, chrome.

## Decisions

- 2026-08-19 — **Migration target is the upstream GitHub head rev (`e1d61f4d`, 2026-08-17), pinned in the current style: exact version + git rev in `Cargo.toml`.** Because tags lag far behind main (newest tag ~v0.9.0 while head `Cargo.toml` says 0.11.0), the local checkout is byte-identical to origin/main today (verified: clean tree, 0 ahead / 0 behind), and a path dependency would not build in CI. Upstream's version string is unchanged at head, so the pin after the bump reads `=0.11.0` at rev `e1d61f4d` — only the rev moves; the version string is not a compatibility signal (see References).
- 2026-08-19 — **One-off catch-up bump; no recurring freshness policy in this item.** Because the research watchlist already tracks the pinned rev, and future bumps are routine dependency work rather than roadmap items.
- 2026-08-19 — **Scope is full modernization, not a minimal port.** Re-platform all six consuming crates on the new TermRock component set (patterns, overlays, virtualization, animation, experience layer), not just the mechanical compile-fix. Chosen over the recommended minimal-port option: the point of the migration is the latest-and-greatest experience, not merely a fresh pin.
- 2026-08-19 — **Brand compositions: rebuild allowed, look preserved.** BrandHeader, digital rain, and the launch animation stay jackin❯-owned and keep their current visual identity, but may be re-implemented on new TermRock primitives (`Spring`/`FrameClock` instead of hand-rolled timers). Because ownership and look are the invariants, not the implementation.
- 2026-08-19 — **Phasing: bump first, then modernize surface-by-surface.** PR 1 is the rev bump + mechanical migration (compiles everywhere, snapshots re-baselined, upstream visuals accepted); each subsequent PR modernizes one surface (console, capsule, launch, …). Because the mechanical layer must never mix with judgement changes — bisectable, and each surface gets its own TUI-design-decision review.
- 2026-08-19 — **Visual proof: adopt the upstream `termrock-raster` PNG baseline pipeline in jackin❯ during modernization phases, in addition to re-baselined text snapshots.** Because zero-tolerance pixel baselines are the strongest visual-regression proof for a look-changing migration, and upstream built that pipeline specifically for jackin❯ parity.
- 2026-08-19 — **Modernization order: console → capsule → launch → small surfaces (jackin adapter, jackin-tui facade, oppicker).** Because console is the largest surface (636 refs, most component variety) and modernizing it first sets the patterns every other surface copies, with the cheapest host-side smoke path.

## Capabilities

- The workspace pin moves from rev `5ff94ee` (2026-07-17) to upstream head `e1d61f4d` (2026-08-17), same exact-version + git-rev style.
- Every surface is re-platformed on the new TermRock component set (overlays, virtualization, patterns, runtime animation, experience layer) wherever an upstream equivalent replaces hand-rolled machinery.
- Brand compositions are re-implemented on new TermRock primitives with their visual identity unchanged.
- Key screens of each modernized surface gain zero-tolerance PNG baselines via the `termrock-raster` pipeline.

## Screens

## Flows

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

- MUST NOT move brand/domain compositions (BrandHeader, digital rain, launch animation) into TermRock or change their visual identity — upstream explicitly declined to absorb them (migration doc 0331); ownership and look are invariants, implementation is not (see Decisions 2026-08-19).
- MUST NOT introduce compatibility facades or shim layers over renamed TermRock APIs — repository latest-only law; upstream migration docs direct the same.

## Quality bar

- Bump phase: all six crates compile against rev `e1d61f4d`, full test suite green, the 18 existing text snapshots deliberately re-baselined (upstream visuals accepted), TUI docs under `docs/content/reference/tui/` updated in the same PR.
- Modernization phases: each surface additionally adopts the `termrock-raster` PNG baseline pipeline for its key screens — zero-tolerance pixel compare with a bless workflow, per the pipeline upstream built for jackin❯ parity (decision 2026-08-19).
- Brand surfaces: the brand compositions' own rendering stays identical before/after re-implementation; surrounding chrome may change with its surface's modernization. The exact proof mechanism (text snapshot vs PNG-baseline crop) is settled at finalization.

## Open questions

- Per-surface component adoption map: which hand-rolled machinery in each surface swaps to which new TermRock component (e.g. does the capsule command palette move to upstream `command_palette`?), and which screens count as that surface's "key screens" for PNG baselines. Recommendation: swap wherever an upstream equivalent exists; settle the concrete map and key-screen list per surface at finalization, console first.
- Does the brand-look invariant bind already in the bump PR? Research settled the facts (2026-08-19): the swap **does** recolor BrandHeader, the launch header, and capsule row-0 chrome (29 of 38 roles changed values), and no text snapshot catches it. Recommendation unchanged: yes — the invariant binds from the bump PR onward, and the bump PR compensates in consumer code.
- Can the bump PR stay strictly mechanical? Three break classes are redesigns, not renames: `FocusRing`/`ModalStack` went crate-private (jackin-tui `SurfaceFocus`/`ModalFlow` must move to `InteractionScene`/`FocusGraph`/`OverlayStack`), and `DiffViewState.offset` lost its setter (12 launch sites). Their behavior (Esc cascade, focus restore, diff scrolling) has no test proving parity. Decide: allow these three redesigns inside the bump PR with named behavioral parity tests, or split them into a gate of their own. Recommendation: keep them in the bump PR but add explicit parity tests — a bump that doesn't compile isn't shippable, so they cannot be deferred past it.
- jackin-tui facade end-state: keep the product runtime traits (`Component`/`View`/`Subscription`) or adopt upstream `event_result`/`runtime` contracts? Both satisfy the arch gate; they cannot coexist (research chapter 04, Dead ends). Recommendation: decide at console-phase finalization, after the first surface exercises the upstream contracts.
- Surface background treatment: adopt the new obsidian surface ladder (upstream default — backgrounds on every surface) or `RolePalette::terminal_native()` (restores background-free surfaces, keeps new text values)? Changes the look of every jackin❯ surface. Recommendation: decide with a side-by-side render during bump-PR review.
- Is the launch progress rail inside the protected "launch animation" brand boundary? Settled ground names BrandHeader, rain, launch animation; the rail is unlisted. Recommendation: treat the rail as product UI (modernizable), not brand.

## Open research questions

- ~~Full per-crate compile-break inventory~~ — answered 2026-08-19 by [`research/termrock-head-adoption/`](../../research/termrock-head-adoption/01-compile-break-inventory.md): 384 measured errors across 15 classes, each mapped to its migration doc; plus a cargo-deny bans failure needing two skip entries.
- Mouse-subsystem behavioral parity: side-by-side interaction matrix of upstream `ScrollArea`/`UiContext` vs the pixel rules in `input/mouse/*` tests (console phase planning).
- `TerminalCell` metadata coverage vs capsule `HyperlinkRegion`/`SgrRegion` compositor caches (capsule phase planning).
- `context_meter`/`metric_tile` full render-path read against the usage-limits-only hard rule, before any Usage-dialog wiring.
- macOS↔Linux PNG baseline identity for `termrock-raster` (upstream measured per-arch only; measure once when wiring the jackin❯ CI lane).

## Deferred

## Log

- 2026-08-19 — tailrocks-idea — created (DRAFT).
- 2026-08-19 — tailrocks-brainstorm — shaped (DRAFT → SHAPING): settled target rev, one-off cadence, full-modernization scope, bump-first phasing, brand invariants, PNG-baseline quality bar, console-first order; corrected the stale `src/console/tui/` surface fact to the six-crate usage map; delta survey `5ff94ee..e1d61f4d` recorded.
- 2026-08-19 — tailrocks-research — deep pass produced [`research/termrock-head-adoption/`](../../research/termrock-head-adoption/README.md) (5 vetted chapters + 2 critic rounds): compile-break inventory answered (384 errors / 15 classes / cargo-deny gate), 40 applicable migration docs, brand-recolor facts confirmed, adoption pairing tables, PNG-pipeline contract; struck the answered research question, added four plan-time research questions and four surfaced decision questions.
