# PNG baselines (termrock-raster adoption)

## Purpose

Adopt the upstream `termrock-raster` Ratatui→PNG baseline pipeline in jackin❯: zero-tolerance decoded-pixel baselines for the full console screen inventory, with a bless workflow and a CI lane. The console phase is the first modernization phase and therefore owns the pipeline's CI wiring; later surfaces add their own key screens onto the same lane. Text snapshots remain the standing suite — PNG baselines are additive.

Anchors: F7, S3, B10, B16, Q4 · Evidence: research/termrock-head-adoption/05-png-baseline-pipeline.md, roadmap item §Decisions (key screens ruling, 2026-08-19), item §Quality bar (modernization phases)

## Requirements

### Requirement: Baseline set is the full console inventory

The PNG baseline set SHALL cover every console screen: all six stage views — workspaces list populated and empty, editor tabs (general, mounts, roles, secrets, auth), settings tabs (general, mounts, environments, auth, trust), the create-prelude wizard steps, confirm-delete, and confirm-instance-purge — and all 19 `ConsoleModal` variants, each rendered at its canonical size. The maintenance and flake cost of the maximal set is accepted deliberately (the console is the largest surface and the pattern-setter).

Covers: F7, S3 · Evidence: roadmap item §Decisions (console key screens ruling), research/termrock-head-adoption/04-component-adoption-candidates.md (screen inventory enumeration)

#### Scenario: Inventory complete

- **WHEN** the baseline suite runs
- **THEN** every stage view and every one of the 19 `ConsoleModal` variants has a committed baseline PNG at its canonical size
- **AND** adding a baseline for a new screen variant requires no harness change (the harness enumerates the inventory)

### Requirement: termrock-raster dependency and version coherence

`termrock-raster` SHALL be consumed as a git dependency pinned at the same rev as the `termrock` pin (`29a16b5b`); its `publish = false` gate does not block git consumption. The `deny.toml` license exceptions (BSD-3-Clause, BSD-2-Clause) and the REUSE annotations for every committed PNG baseline SHALL land with the dependency.

Covers: F7 · Evidence: research/termrock-head-adoption/05-png-baseline-pipeline.md (consumer adoption contract, license/REUSE deltas)

#### Scenario: Workspace resolves and passes supply-chain gates

- **WHEN** the dependency lands
- **THEN** `cargo check` resolves `termrock-raster` at the same rev as `termrock`
- **AND** `cargo deny check` passes with the recorded BSD exceptions
- **AND** the REUSE gate passes over every committed baseline PNG

### Requirement: Zero-tolerance compare with bless workflow

Baseline comparison SHALL be zero-tolerance on decoded pixels (upstream `compare_png_pixels` semantics: any pixel difference fails). Blessing (writing/updating baselines) SHALL happen only via the explicit bless path (environment variable per the upstream pattern), never as a test side effect.

Covers: F7, B10 · Evidence: research/termrock-head-adoption/05-png-baseline-pipeline.md (pipeline anatomy)

#### Scenario: Unintended paint change fails

- **GIVEN** a code change that alters any rendered pixel of a baselined screen
- **WHEN** the baseline suite runs without the bless variable
- **THEN** the compare fails and names the differing screen

#### Scenario: Deliberate re-bless

- **WHEN** a look change is intentional and reviewed
- **THEN** baselines update only via the bless path, and the re-blessed PNGs are visible in the diff for review

### Requirement: CI lane wired in the console phase

The PNG baseline lane SHALL run in CI as part of the console phase; the gate binds on the CI runner platform. macOS↔Linux bit-identity is measured once when the lane is wired (Q4); if identity fails, the fallback is pinned-Linux / CI-produced blessing per assumption A6, recorded in the plan — it is not a merge blocker for the lane itself.

Covers: B10, Q4 · Evidence: research/termrock-head-adoption/05-png-baseline-pipeline.md (cross-OS status), roadmap item §Quality bar (modernization phases)

#### Scenario: Lane green on CI

- **WHEN** the console phase's CI runs
- **THEN** the PNG baseline job executes the zero-tolerance compare and passes on the CI runner platform
- **AND** the cross-OS identity measurement outcome (identity holds / fallback engaged) is recorded

### Requirement: Text snapshots remain the standing suite

The existing text snapshot suite SHALL remain in force unchanged; PNG baselines are additive gates and do not replace, weaken, or re-bless text snapshots. Console text snapshots stay byte-identical through the modernization per the parity rule (any diff = STOP for operator review).

Covers: B10, B16 · Evidence: roadmap item §Decisions (console-phase parity rule, 2026-08-19)

#### Scenario: Both gates run

- **WHEN** the console phase's verification runs
- **THEN** both the text snapshot suite (byte-identical) and the PNG baseline suite (zero-tolerance) execute and pass independently

## Screen: Console full inventory as the PNG baseline set (S3)

Mockup: none — visual truth is the committed baselines themselves; the item's key-screens ruling enumerates the set.

- **Regions**: per screen, unchanged from current console layout (parity invariant)
- **States**: workspaces list — populated and empty (both baselined); every other screen at its canonical default state; each of the 19 `ConsoleModal` variants as its own baseline
- **Interactions**: none at the baseline layer — baselines render canonical states; interaction parity is owned by spec/console-modernization.md and the text snapshot suite
- **Navigation**: not applicable at the baseline layer
