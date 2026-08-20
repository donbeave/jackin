# Coverage Ledger — termrock-migration

Item: roadmap/termrock-migration/README.md at commit `d554dca8`, ingested 2026-08-19.
Override: none (item is READY).
Package scope note: per D12/D15 and the item's Deferred section, per-surface modernization plans are gated behind each surface's finalization — this package plans the **bump phase** fully and records modernization-phase IDs as deferred with their triggers. Research currency: `research/termrock-head-adoption/` vetted 2026-08-19 same-day; termrock HEAD still `e1d61f4d` (git rev-parse, 2026-08-19).

Re-run 2026-08-19 (console modernization package): item ingested at `f320b51` (console finalization closed — bump phase merged as PR #897, main `955b2fea`, pin `29a16b5b`). Activated: F2/F3/F4 console slices, B10/B11 console halves, Q1/Q4. New: S2/S3, F5–F9, W2, N4, B14–B16, D16–D25, A5–A7. Numbering monotonic — plans 005+; plans 001–004 DONE and untouched. New research: 06 (mouse parity matrix), 07 (facade retirement inventory). D15 resolved by D22; D7 amended by D25; D1's pin superseded in fact (style constraint stands).

## Screens
| ID | Screen | Item anchor | Spec | Plans | Status |
|----|--------|-------------|------|-------|--------|
| S1 | Screen-set preserving posture (no new screens; existing inventory research-cited) | §Screens | spec/migration-posture.md | 001–004 (constraint) | covered |
| S2 | keyboard_help overlay — the item's single sanctioned new overlay (`?` trigger, all console stages) | §Decisions D18 amendment, D24 | spec/console-modernization.md | — | new (console package) |
| S3 | Console full screen inventory as the PNG baseline set (6 stages + 19 modals; enumeration research ch04) | §Decisions D20 | spec/png-baselines.md | — | new (console package) |

## Capabilities
| ID | Capability | Item anchor | Spec | Plans | Status |
|----|-----------|-------------|------|-------|--------|
| F1 | Pin moves `5ff94ee`→`e1d61f4d`, exact-version+rev style (`=0.11.0` stays) | §Capabilities b1, §Decisions D1 | spec/dependency-bump.md | 002 | covered |
| F2 | Every surface re-platformed where upstream equivalent exists | §Capabilities b2, D3/D12 | spec/console-modernization.md (console slice) | — | console slice active this package; capsule/launch/small deferred (own finalizations) |
| F3 | Brand compositions re-implemented on new primitives, look unchanged | §Capabilities b3, D4/D8/D11/D13 | spec/brand-preservation.md (bump-PR compensation half); spec/console-brand-header.md (console rebuild) | 003 | covered (bump half); console BrandHeader rebuild active this package; launch/capsule rebuilds deferred (owning surfaces' phases; B11) |
| F4 | Key screens gain zero-tolerance PNG baselines via termrock-raster | §Capabilities b4, D6 | spec/png-baselines.md (console set + CI lane) | — | console slice active this package; other surfaces deferred (their phases) |
| F5 | Console re-platformed per the settled adoption map (C1–C19 + whole-screen recipes + form_wizard + op-picker UI and crate) | §Decisions D17/D18/D19/D25 | spec/console-modernization.md | — | new (console package) |
| F6 | Console surface speaks upstream contracts; facade duplicate traits retired for console, no shim | §Decisions D22 | spec/facade-retirement.md | — | new (console package) |
| F7 | termrock-raster PNG pipeline adopted: full console inventory baselined, CI lane wired | §Decisions D20, §Quality bar/modernization B10 | spec/png-baselines.md | — | new (console package) |
| F8 | Console BrandHeader rebuilt on new primitives; look proven by dedicated PNG crop + 12 literal-RGB tests | §Decisions D21 | spec/console-brand-header.md | — | new (console package) |
| F9 | keyboard_help adopted: `?` trigger, keymap_bridge-sourced content, footer-hint discoverability, PNG-baselined | §Decisions D18/D24 | spec/console-modernization.md | — | new (console package) |

## Flows
| ID | Flow | Screens touched | Spec | Plans | Status |
|----|------|-----------------|------|-------|--------|
| W1 | Flow-preserving posture: no journey changes; three flow-adjacent redesigns gated by parity tests | all existing | spec/forced-redesigns.md | 001, 002 | covered |
| W2 | Console journeys unchanged through re-platforming; keyboard_help is additive, not a journey step | all console screens | spec/console-modernization.md | — | new (console package) |

## Must-not anchors
| ID | Statement | Reason | Registry |
|----|-----------|--------|----------|
| N1 | No brand composition moves into TermRock or changes visual identity (BrandHeader, rain, launch animation/warp, rail, capsule pill) | upstream 0331 declined; ownership+look invariants | spec/README.md |
| N2 | No compatibility facades or shims over renamed TermRock APIs | repo latest-only law; upstream directive 0061/0331 | spec/README.md |
| N3 | Usage-limits-only rule beats adoption: `context_meter`/`metric_tile` not wired if their render-path read fails it | root AGENTS.md hard rule | spec/README.md |
| N4 | No new operator-visible screens or overlays beyond keyboard_help; no journey changes | amended D14 — amendment scope is exactly one overlay | spec/README.md |

## Quality bar
| ID | Statement anchor | Spec scenario(s) | Status |
|----|------------------|------------------|--------|
| B1 | §Quality bar/bump: six crates compile at `e1d61f4d` | dependency-bump §Scenario: workspace compiles at head | covered |
| B2 | §Quality bar/bump: full test suite green | dependency-bump §Scenario: suite green post-bump | covered |
| B3 | §Quality bar/bump: 18 snapshots deliberately re-baselined wholesale under TESTING.md gate | visual-rebaseline §Scenarios "Snapshot suite green after re-bless" + "No hand-edited snapshots" | covered |
| B4 | §Quality bar/bump: TUI docs same-PR (3 pages + AGENTS.md path) | docs-alignment §Scenarios | covered |
| B5 | §Quality bar/bump: parity tests pass (Esc cascade, focus restore, diff scrolling) | forced-redesigns §Scenarios ×3 | covered |
| B6 | §Quality bar/bump: brand renders identically via consumer compensation | brand-preservation §Scenarios | covered |
| B7 | §Quality bar/bump side-tasks: lock wave, two cargo-deny skips, hint.rs drift check | dependency-bump + docs-alignment §Scenarios | covered |
| B8 | §Quality bar: toolchain/dep ripples covered by compile gate, no separate gate | dependency-bump (note under requirement) | covered |
| B9 | §Quality bar: background variant chosen at bump-PR review lands in bump PR | visual-rebaseline §Scenarios "Operator pick gates the re-baseline" + "Chosen variant is what ships" | covered |
| B10 | §Quality bar/modernization: PNG pipeline per key screens; CI wiring with console phase; binds on CI platform; text snaps additive | spec/png-baselines.md §Scenarios | active (console package) |
| B11 | §Quality bar/brand: each brand comp rebuilt in owning surface's phase; bump only compensates | spec/console-brand-header.md §Scenarios (console half) | console half active; launch/capsule deferred |
| B12 | §Quality bar: usage-limits-only wins over adoption | → N3 registry | covered (registry) |
| B13 | §Quality bar: plan-owned delegations (small-surface granularity/sequencing, parity-test names, compensation mechanism) | manifest + plan Inputs | covered (annotation) |
| B14 | §Decisions D23: console-phase text snapshots byte-identical; any diff = parity break, STOP for operator review | spec/console-modernization.md §Scenario | active (console package) |
| B15 | §Decisions D23: no performance budget/gate this phase | annotation under B14 | active (console package) |
| B16 | §Decisions D16: parity proof set = bump text snapshots + trparity tests + new PNG baselines + BrandHeader crop | spec/console-modernization.md + spec/png-baselines.md §Scenarios | active (console package) |

## Decisions (constraints)
| ID | Decision | Dated | Constrains |
|----|----------|-------|-----------|
| D1 | Target = upstream head `e1d61f4d`, exact-version+rev pin; `=0.11.0` stays, only rev moves | 2026-08-19 | 002 (superseded in fact by the `29a16b5b` re-pin; pin-style constraint stands) |
| D2 | One-off bump; no freshness policy | 2026-08-19 | package scope |
| D3 | Full modernization scope (not minimal port) | 2026-08-19 | console package; later phases |
| D4 | Brand rebuild allowed, look preserved | 2026-08-19 | 003; console package (F8); later phases |
| D5 | Phasing: bump first, then per-surface PRs | 2026-08-19 | manifest |
| D6 | PNG baseline pipeline adopted in modernization phases | 2026-08-19 | console package (F7); later phases |
| D7 | Order console → capsule → launch → small | 2026-08-19 | amended by D25 (console+oppicker first) |
| D8 | Brand invariant binds from bump PR (consumer compensation) | 2026-08-19 | 003 |
| D9 | Bump = mechanical + forced redesigns + named parity tests | 2026-08-19 | 001, 002 |
| D10 | Background variant decided at bump-PR review, side-by-side | 2026-08-19 | 003 (resolved: obsidian) |
| D11 | Progress rail = brand | 2026-08-19 | 003 (rail spans compensated to preserve look — no visual change; rebuild waits for launch phase) |
| D12 | Adoption rule: swap where equivalent; maps at surface finalization | 2026-08-19 | console package (map settled); later phases |
| D13 | Capsule row-0: pill = brand, rest = product chrome | 2026-08-19 | 003 |
| D14 | Screen-set and flow preserving | 2026-08-19 | all plans (amended by D18: keyboard_help is the one sanctioned overlay) |
| D15 | Facade end-state deferred to console finalization | 2026-08-19 | resolved by D22 |
| D16 | UI/UX parity invariant: substrate changes, experience does not; divergences compensated (consumer config → upstream change), never accepted | 2026-08-19 | console package; all later phases |
| D17 | Console adoption map: interaction core + dialog/form layer, full adoption with recorded carve-outs | 2026-08-19 | console package (F5) |
| D18 | Console adoption map: layout/chrome/runtime full adoption; keyboard_help amendment (single sanctioned overlay) | 2026-08-19 | console package (F5, F9); N4 |
| D19 | Console adoption map: whole-screen recipes + form_wizard; op-picker drill-down hand-rolled with breadcrumbs re-base | 2026-08-19 | console package (F5) |
| D20 | Console key screens = full console inventory (6 stages + 19 modals), PNG-baselined | 2026-08-19 | console package (F7, S3) |
| D21 | Console BrandHeader proof: dedicated PNG-baseline crop + literal-RGB unit tests; template for other brand comps | 2026-08-19 | console package (F8) |
| D22 | Facade end-state: upstream contracts win; product traits retire per surface phase, no shim; facade → tokens + operator_info | 2026-08-19 | console package (F6); later phases |
| D23 | Console-phase snapshots byte-identical (diff = parity break, STOP for operator review); no perf gate | 2026-08-19 | console package (B14, B15) |
| D24 | keyboard_help: PNG-baselined, `?` trigger all console stages, keymap_bridge-sourced content, footer-hint discovery | 2026-08-19 | console package (F9, S2) |
| D25 | Op-picker wholly into console phase (UI + jackin-oppicker crate); order becomes console+oppicker → capsule → launch → small | 2026-08-19 | console package (F5); manifest |

## External references & integrations
| ID | Reference | Kind | Research topics |
|----|-----------|------|-----------------|
| R1 | TermRock git source (`Cargo.toml:118` pin, `deny.toml:204` allowlist) | integration | termrock-head-adoption/01,05 |
| R2 | https://github.com/tailrocks/termrock + local checkout `/Users/donbeave/Projects/tailrocks/termrock` | repo | termrock-head-adoption (all) |
| R3 | Six-crate usage map; stale AGENTS.md `src/console/tui/` path | codebase fact | termrock-head-adoption/02,04 |
| R4 | Arch gate `crates/jackin-xtask/src/arch.rs:253-275` | constraint | termrock-head-adoption/04 |
| R5 | 18 `.snap` fixtures; ~25 test modules importing termrock | codebase fact | termrock-head-adoption/03,05 |
| R6 | 3 TUI docs pages pinning dead names (+7 mentioning termrock); `docs/content/research/watchlist.mdx:63-65` | docs surface | termrock-head-adoption/README c7 |
| R7 | `hint.rs:25` chord_glyph mirror | drift risk | termrock-head-adoption/02 |
| R8 | Delta survey (version-string semantics, break classes, new capabilities, feature flags, web-time/ratatui/MSRV) | upstream delta | termrock-head-adoption/01,02 |
| R9 | Verification gates for this workspace | tooling | jackin-verification-tooling/01 |
| R10 | termrock-raster crate (git dep at same rev; deny.toml BSD-2/3-Clause exceptions; REUSE annotations for PNGs) | integration | termrock-head-adoption/05 |

## Assumptions
| ID | Assumption | Why safe | Falsified by | Status |
|----|------------|----------|---------------|--------|
| A1 | Rev `e1d61f4d` remains fetchable from the upstream git source | pinned full sha; upstream repo is owner-controlled | `cargo fetch`/`cargo update` failing to resolve the rev | holds |
| A2 | Research-measured break inventory (384 errors / 15 classes) reproduces approximately at execution; executor re-derives counts and treats fresh output as authority | measured 2026-08-19 on `3089538d` clone, docs-only commits since | first `cargo check` after the pin flip diverging in KIND (new break classes), not just count | holds |
| A3 | Two cargo-deny skips (`base64@0.22.1`, `syn@2.0.119`) suffice for the bans gate | measured with cargo-deny 0.20.2 on the patched clone | `cargo deny check bans` reporting further duplicates at execution | holds |
| A4 | Esc-cascade and focus-restore parity tests use existing seams (`dialog/tests.rs:2338-2349`, jackin-tui runtime tests); the diff-scroll seam does NOT exist and is created in plan 001 by behavior-preserving extraction from the launch run loop (old-pin type `DiffState`, `pub offset`) | seams verified 2026-08-19 (planning critic, run.rs:866-874/:981-1085 read); extraction is standard state-hoisting | the extraction cannot compile or provably preserve behavior at the old pin | holds |
| A5 | Pairing APIs ch04 verified at `e1d61f4d` persist at pin `29a16b5b` | `29a16b5b` is tree-identical to the `e35f1aa5` stack tip = `e1d61f4d` + six additive jackin-authored PRs (git-diff verified at re-pin); additive delta removes nothing | console-plan precondition greps/compile finding a cited API renamed or removed | holds |
| A6 | macOS↔Linux PNG bit-identity holds for the jackin console baselines | upstream cross-arch identity measured; jackin renders measured on macOS; fallback is pinned-Linux/CI-produced bless (upstream A3 pattern) | first CI PNG run failing only on the Linux runner with no intended paint change | holds (measured once at CI wiring — Q4) |
| A7 | `termrock-raster` resolves as a git dependency at the same rev as `termrock` (`publish = false` gates registry, not git) | Cargo Book publish-field semantics (ch05); version-coherence constraint satisfied by same-rev pins | first `cargo fetch`/`cargo check` after adding the dep failing to resolve | holds |

## Research questions
| ID | Question | Research topic | Status |
|----|----------|----------------|--------|
| Q1 | Mouse-subsystem parity matrix (ScrollArea/UiContext vs input/mouse tests) | termrock-head-adoption/06 | active (console package; C14 cutover gate) |
| Q2 | TerminalCell metadata vs capsule Hyperlink/SgrRegion coverage | — | deferred (capsule-phase planning) |
| Q3 | context_meter/metric_tile render-path read vs usage-limits-only | — | deferred (before Usage-dialog wiring) |
| Q4 | macOS↔Linux PNG baseline identity | — | active (console CI wiring; measure once, fallback per A6) |
| Q5 | Exact verification/gate commands for this workspace | jackin-verification-tooling | covered (chapter 01) |
