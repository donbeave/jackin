# Coverage Ledger — termrock-migration

Item: roadmap/termrock-migration/README.md at commit `d554dca8`, ingested 2026-08-19.
Override: none (item is READY).
Package scope note: per D12/D15 and the item's Deferred section, per-surface modernization plans are gated behind each surface's finalization — this package plans the **bump phase** fully and records modernization-phase IDs as deferred with their triggers. Research currency: `research/termrock-head-adoption/` vetted 2026-08-19 same-day; termrock HEAD still `e1d61f4d` (git rev-parse, 2026-08-19).

## Screens
| ID | Screen | Item anchor | Spec | Plans | Status |
|----|--------|-------------|------|-------|--------|
| S1 | Screen-set preserving posture (no new screens; existing inventory research-cited) | §Screens | spec/migration-posture.md | 001–004 (constraint) | covered |

## Capabilities
| ID | Capability | Item anchor | Spec | Plans | Status |
|----|-----------|-------------|------|-------|--------|
| F1 | Pin moves `5ff94ee`→`e1d61f4d`, exact-version+rev style (`=0.11.0` stays) | §Capabilities b1, §Decisions D1 | spec/dependency-bump.md | 002 | covered |
| F2 | Every surface re-platformed where upstream equivalent exists | §Capabilities b2, D3/D12 | spec/README.md §Deferrals | — | deferred (per-surface finalization → per-surface plan rounds; D12) |
| F3 | Brand compositions re-implemented on new primitives, look unchanged | §Capabilities b3, D4/D8/D11/D13 | spec/brand-preservation.md (bump-PR compensation half) | 003 | covered (bump half); rebuild-on-primitives deferred (owning surface's phase; B11) |
| F4 | Key screens gain zero-tolerance PNG baselines via termrock-raster | §Capabilities b4, D6 | spec/README.md §Deferrals | — | deferred (CI wiring + key-screen lists land with console phase; D6/B10/DEF2) |

## Flows
| ID | Flow | Screens touched | Spec | Plans | Status |
|----|------|-----------------|------|-------|--------|
| W1 | Flow-preserving posture: no journey changes; three flow-adjacent redesigns gated by parity tests | all existing | spec/forced-redesigns.md | 001, 002 | covered |

## Must-not anchors
| ID | Statement | Reason | Registry |
|----|-----------|--------|----------|
| N1 | No brand composition moves into TermRock or changes visual identity (BrandHeader, rain, launch animation/warp, rail, capsule pill) | upstream 0331 declined; ownership+look invariants | spec/README.md |
| N2 | No compatibility facades or shims over renamed TermRock APIs | repo latest-only law; upstream directive 0061/0331 | spec/README.md |
| N3 | Usage-limits-only rule beats adoption: `context_meter`/`metric_tile` not wired if their render-path read fails it | root AGENTS.md hard rule | spec/README.md |

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
| B10 | §Quality bar/modernization: PNG pipeline per key screens; CI wiring with console phase; binds on CI platform; text snaps additive | spec/README.md §Deferrals | deferred (console-phase plan round; DEF2 trigger) |
| B11 | §Quality bar/brand: each brand comp rebuilt in owning surface's phase; bump only compensates | brand-preservation (constraint noted) + §Deferrals | covered (as bump constraint); rebuild deferred per phase |
| B12 | §Quality bar: usage-limits-only wins over adoption | → N3 registry | covered (registry) |
| B13 | §Quality bar: plan-owned delegations (small-surface granularity/sequencing, parity-test names, compensation mechanism) | manifest + plan Inputs | covered (annotation) |

## Decisions (constraints)
| ID | Decision | Dated | Constrains |
|----|----------|-------|-----------|
| D1 | Target = upstream head `e1d61f4d`, exact-version+rev pin; `=0.11.0` stays, only rev moves | 2026-08-19 | 002 |
| D2 | One-off bump; no freshness policy | 2026-08-19 | package scope |
| D3 | Full modernization scope (not minimal port) | 2026-08-19 | later phases |
| D4 | Brand rebuild allowed, look preserved | 2026-08-19 | 003; later phases |
| D5 | Phasing: bump first, then per-surface PRs | 2026-08-19 | manifest |
| D6 | PNG baseline pipeline adopted in modernization phases | 2026-08-19 | later phases |
| D7 | Order console → capsule → launch → small | 2026-08-19 | later phases |
| D8 | Brand invariant binds from bump PR (consumer compensation) | 2026-08-19 | 003 |
| D9 | Bump = mechanical + forced redesigns + named parity tests | 2026-08-19 | 001, 002 |
| D10 | Background variant decided at bump-PR review, side-by-side | 2026-08-19 | 003 |
| D11 | Progress rail = brand | 2026-08-19 | 003 (rail spans compensated to preserve look — no visual change; rebuild waits for launch phase) |
| D12 | Adoption rule: swap where equivalent; maps at surface finalization | 2026-08-19 | later phases |
| D13 | Capsule row-0: pill = brand, rest = product chrome | 2026-08-19 | 003 |
| D14 | Screen-set and flow preserving | 2026-08-19 | all plans |
| D15 | Facade end-state deferred to console finalization | 2026-08-19 | 002 (facade keeps product traits, re-hosted internally) |

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

## Assumptions
| ID | Assumption | Why safe | Falsified by | Status |
|----|------------|----------|---------------|--------|
| A1 | Rev `e1d61f4d` remains fetchable from the upstream git source | pinned full sha; upstream repo is owner-controlled | `cargo fetch`/`cargo update` failing to resolve the rev | holds |
| A2 | Research-measured break inventory (384 errors / 15 classes) reproduces approximately at execution; executor re-derives counts and treats fresh output as authority | measured 2026-08-19 on `3089538d` clone, docs-only commits since | first `cargo check` after the pin flip diverging in KIND (new break classes), not just count | holds |
| A3 | Two cargo-deny skips (`base64@0.22.1`, `syn@2.0.119`) suffice for the bans gate | measured with cargo-deny 0.20.2 on the patched clone | `cargo deny check bans` reporting further duplicates at execution | holds |
| A4 | Esc-cascade and focus-restore parity tests use existing seams (`dialog/tests.rs:2338-2349`, jackin-tui runtime tests); the diff-scroll seam does NOT exist and is created in plan 001 by behavior-preserving extraction from the launch run loop (old-pin type `DiffState`, `pub offset`) | seams verified 2026-08-19 (planning critic, run.rs:866-874/:981-1085 read); extraction is standard state-hoisting | the extraction cannot compile or provably preserve behavior at the old pin | holds |

## Research questions
| ID | Question | Research topic | Status |
|----|----------|----------------|--------|
| Q1 | Mouse-subsystem parity matrix (ScrollArea/UiContext vs input/mouse tests) | — | deferred (console-phase planning; item trigger) |
| Q2 | TerminalCell metadata vs capsule Hyperlink/SgrRegion coverage | — | deferred (capsule-phase planning) |
| Q3 | context_meter/metric_tile render-path read vs usage-limits-only | — | deferred (before Usage-dialog wiring) |
| Q4 | macOS↔Linux PNG baseline identity | — | deferred (console-phase CI wiring) |
| Q5 | Exact verification/gate commands for this workspace | jackin-verification-tooling | covered (chapter 01) |
