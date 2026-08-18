# Visual re-baseline and background variant

## Purpose

The head's premium overhaul changes visual output; the item accepts upstream visuals wholesale, re-baselines the 18 text snapshots deliberately, and picks the surface-background variant at bump-PR review from a side-by-side render.
Anchors: B3, B9, D10 · Evidence: research/termrock-head-adoption/03-theme-brand-impact.md, 05-png-baseline-pipeline.md (snapshot seams)

## Requirements

### Requirement: Deliberate snapshot re-baseline
All 18 `.snap` fixtures (6 console `crates/jackin-console/src/tui/view/snapshots/`, 10 capsule dialog, 2 capsule branch-context-bar) SHALL be re-baselined exactly once for the bump, after the background variant lands, via the repo-documented `INSTA_UPDATE=new cargo nextest run …` re-bless per crate (`crates/jackin-console/src/tui/view/tests.rs:565-568`; cargo-insta is not installed and ad-hoc tool installs are forbidden) — never by hand-editing `.snap` files — and the diff SHALL be reviewed wholesale as the deliberate acceptance of upstream visuals under TESTING.md's snapshot gate.
Covers: B3 · Evidence: research/termrock-head-adoption/03-theme-brand-impact.md (snapshots are glyph-only), research/jackin-verification-tooling/01-gates-and-commands.md (bless workflow)

#### Scenario: Snapshot suite green after re-bless
- **GIVEN** the bump and the chosen background variant applied
- **WHEN** the snapshot partition runs after the re-bless
- **THEN** it exits 0 with no pending snapshots

#### Scenario: No hand-edited snapshots
- **WHEN** the re-baseline commit is reviewed
- **THEN** every `.snap` change came from the insta workflow (no manual `.snap` edits; TESTING.md hand-edit policy holds)

### Requirement: Background variant decided from a side-by-side render
Before snapshot re-baselining, the bump PR SHALL produce a side-by-side render of the same screens under (a) the head default obsidian surface ladder (`RolePalette::tailrocks_phosphor()`) and (b) `RolePalette::terminal_native()`, present both to the operator, and STOP for the operator's pick; the chosen variant lands inside the bump PR before merge and the re-baseline reflects it.
Covers: B9, D10 · Evidence: research/termrock-head-adoption/03-theme-brand-impact.md (value tables; terminal_native() behavior at `style/mod.rs:443-456`)

#### Scenario: Operator pick gates the re-baseline
- **GIVEN** side-by-side renders of representative screens under both variants
- **WHEN** the executor reaches the re-baseline step without a recorded operator pick
- **THEN** the executor stops (by-design pause) and does not re-baseline

#### Scenario: Chosen variant is what ships
- **GIVEN** the operator picked a variant
- **WHEN** the bump PR is merge-ready
- **THEN** the palette construction in jackin❯ code matches the pick and the 18 snapshots were re-blessed after it landed
