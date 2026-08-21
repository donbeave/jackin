# Dependency bump

## Purpose

Moves the workspace TermRock pin from `5ff94ee` to head `e1d61f4d` with all forced dependency-graph and supply-chain consequences, mechanically migrating every renamed API.
Anchors: F1, B1, B2, B7, B8, D1 · Evidence: research/termrock-head-adoption/01-compile-break-inventory.md, 02-migration-doc-map.md

## Requirements

### Requirement: Pin moves to head rev in the current style
The workspace `Cargo.toml` SHALL pin `termrock = { version = "=0.11.0", git = "https://github.com/tailrocks/termrock.git", rev = "e1d61f4d67ea6f0f3adee578caa2c5dba642217e", features = ["crossterm", "serde"] }` — only the rev changes; version string, git source, and features stay (upstream head keeps 0.11.0 and both features).
Covers: F1, D1 · Evidence: research/termrock-head-adoption/01-compile-break-inventory.md (feature flags unchanged; version semantics)

#### Scenario: Pin line after the bump
- **WHEN** the bump commit lands
- **THEN** `Cargo.toml:118`'s termrock entry carries rev `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`, version `=0.11.0`, features `["crossterm", "serde"]`
- **AND** `Cargo.lock` resolves termrock from that rev

### Requirement: Lockfile wave and supply-chain gate
The bump SHALL absorb the forced lock deltas — serde/serde_core/serde_derive to 1.0.229, `syn 3.0.3` added, `base64 0.23.1` added, `web-time` added — and `cargo deny check` SHALL pass with exactly two new bans skips (`base64@0.22.1`, `syn@2.0.119`); licenses and sources need no change.
Covers: B7, B8 · Evidence: research/termrock-head-adoption/01-compile-break-inventory.md (deny measurement, cargo-deny 0.20.2)

#### Scenario: Bans gate green after skips
- **GIVEN** the bumped lockfile
- **WHEN** `cargo deny check bans` runs with the two skip entries added to `deny.toml`
- **THEN** it exits 0 with no duplicate-version errors

#### Scenario: No third skip smuggled in
- **WHEN** `git diff deny.toml` is reviewed
- **THEN** exactly two new skip entries exist and no license or source allowlist changed

### Requirement: Workspace compiles at head
All six consuming crates (jackin, jackin-capsule, jackin-console, jackin-launch, jackin-oppicker, jackin-tui) SHALL compile — lib and test targets — against rev `e1d61f4d`, with every renamed API migrated directly per the upstream migration docs (no aliases): `termrock::Theme` → `style::DesignSystem`/`RolePalette` (305 measured errors), `PanelEmphasis` → `PanelChrome`, `focused` → `cursor` on ChoiceDialog/ActionBar state, struct literals → builders/constructors (StatusSlot, Tab/TabsState, ListRow, DiffLine, DialogSpec), scroll offsets → `ScrollAreaState`, `ListState::for_count` const-loss absorbed.
Covers: B1, B8 · Evidence: research/termrock-head-adoption/01-compile-break-inventory.md (15 break classes), 02-migration-doc-map.md (40 applicable docs)

#### Scenario: Workspace compiles at head
- **WHEN** `cargo check` runs for all six crates including `--tests`
- **THEN** it exits 0 with zero errors

### Requirement: Suite green post-bump
After the bump, `cargo nextest run --workspace --all-features --locked` SHALL pass with the ONLY failures being insta snapshot assertions in the three snapshot modules (`crates/jackin-capsule/src/tui/components/dialog/tests.rs`, `crates/jackin-capsule/src/tui/components/branch_context_bar/tests.rs`, `crates/jackin-console/src/tui/view/tests.rs`), each failure enumerated by test name in the run output; those failures are expected pending visual-rebaseline.md, and the bump PR's CI stays red between this requirement and the re-baseline by design. There is no repo-proven "exclude snapshots" filter — the xtask `snapshots` partition runs the whole capsule+console packages, so exclusion would also skip this package's parity tests.
Covers: B2 · Evidence: research/jackin-verification-tooling/01-gates-and-commands.md (snapshots-partition misnomer; runner commands)

#### Scenario: Suite green post-bump
- **WHEN** `cargo nextest run --workspace --all-features --locked` runs after the bump
- **THEN** every failure in the output is an insta snapshot assertion in one of the three named modules, and nothing else fails
- **AND** after visual-rebaseline lands, the same command exits 0
