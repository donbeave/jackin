# Plan 005: Adopt the termrock-raster PNG pipeline — full console inventory baselines + CI lane

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED (new supply-chain/license surface: swash/tiny-skia/arrayref; cross-OS identity carried as assumption A6 with a recorded fallback)
- **Depends on**: none — this plan runs first; baselines are blessed on the pre-modernization rendering
- **Covers**: F7 (termrock-raster pipeline adopted), S3 (full console inventory as the baseline set), B10 (PNG pipeline + CI wiring; text snaps additive), B16 (parity proof set — the PNG half), Q4 (macOS↔Linux identity — measured once here), A6/A7 (assumptions executed/verified)
- **Guardrails**: plan-specific, inlined below
- **Research basis**: `research/termrock-head-adoption/05-png-baseline-pipeline.md` (R10: git dep at same rev, deny.toml BSD-2/3-Clause exceptions, REUSE annotations for PNGs; pipeline anatomy, bless pattern, cross-OS status), `research/termrock-head-adoption/04-component-adoption-candidates.md` (console screen inventory); commands from `research/jackin-verification-tooling/01-gates-and-commands.md`
- **Planned at**: commit `f320b51f`, 2026-08-19

## Why this matters

Every later console plan (006–013) re-platforms machinery while the UI/UX parity invariant (D16) forbids any visible change. Text snapshots prove byte-level parity of the buffer; the PNG baselines are the pixel-level gate — decoded-pixel, zero-tolerance — that catches drift a text snapshot cannot (glyph rasterization, color resolution, cell metrics). They must be blessed on the **pre-modernization** rendering: blessing after any modernization plan would bake drift into the gate. After this plan lands, `termrock-raster` is a pinned workspace dependency, the full console inventory (6 stage views + 19 `ConsoleModal` variants) has committed baselines, the comparison runs in the existing jackin-console CI lane, and the macOS↔Linux identity question (Q4) has a recorded answer.

## Preconditions — run before anything else

Run each; any failure is a STOP.

1. **No dependency plans** — this plan is first. Confirm the hub row is eligible: `grep -E '^\| 005 \|' plans/termrock-migration/README.md` → row exists with status `TODO` or `IN PROGRESS`.
2. **Pin**: `grep -n 'rev = "29a16b5bff84ea8609854711b774e87acbc456cc"' Cargo.toml` → prints the termrock pin line (planning time: line 118).
3. **TermRock input checkout**: `git -C <TERMROCK_CHECKOUT> rev-parse HEAD` → `29a16b5bff84ea8609854711b774e87acbc456cc`.
4. **Raster crate exists at the pin**: `test -f <TERMROCK_CHECKOUT>/crates/termrock-raster/Cargo.toml && grep -n 'publish = false' <TERMROCK_CHECKOUT>/crates/termrock-raster/Cargo.toml` → prints the publish line (planning time: line 12).
5. **Toolchain**: `rustc --version` → `rustc 1.97.1`; `cargo nextest --version` → `cargo-nextest 0.9.140`; `cargo deny --version` → `cargo-deny 0.20.2`.
6. **No raster machinery yet**: `grep -c 'swash\|tiny-skia\|termrock-raster' Cargo.lock` → `0` (planning-time measurement; any nonzero count is drift — STOP).
7. **Parity gate starts green**: `cargo nextest run -p jackin-console --locked` → all pass.
8. **Clean tree**: `git status --porcelain` → empty.
9. **Branch** (hub law): `git branch --show-current` → `feature/termrock-console-modernization` (create it off `roadmap/termrock-migration` if this is the package's first code commit, per the hub).

## Spec contract

The requirements this plan implements, inlined **verbatim** from `plans/termrock-migration/spec/png-baselines.md` — the executor does not read `spec/`:

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

## Screen contract

Console full inventory as the PNG baseline set (S3), from the spec:

- Mockup: none — visual truth is the committed baselines themselves.
- **Regions**: per screen, unchanged from current console layout (parity invariant).
- **States**: workspaces list — populated and empty (both baselined); every other screen at its canonical default state; each of the 19 `ConsoleModal` variants as its own baseline.
- **Interactions**: none at the baseline layer — baselines render canonical states; interaction parity is owned by spec/console-modernization.md and the text snapshot suite
- **Navigation**: not applicable at the baseline layer

## Must NOT

Plan-specific guardrails. These override anything a step seems to imply:

- **Blessing happens only via the explicit env-var bless path (`JACKIN_BLESS_PNGS=1`), never as a test side effect** — spec requirement "Zero-tolerance compare with bless workflow"; an implicit write hides unintended paint changes from review.
- **Do not modify, re-bless, or hand-edit any `.snap` text snapshot in this plan** — spec requirement "Text snapshots remain the standing suite"; the 18 text snapshots stay byte-identical through the whole console phase (D23), and hand-edited snapshots are rejected in review (TESTING.md:181).
- **Do not copy TermRock's vendored font files (or any TermRock source) into the jackin❯ tree** — the fonts ride inside the `termrock-raster` crate's cargo git checkout via `include_bytes!`; vendoring them here would duplicate an OFL-licensed artifact into our REUSE scope for no reason.
- **Do not hand-edit or hand-generate a baseline PNG** — every committed PNG is produced by the bless path from an actual render; a hand-made image is unreviewable drift.
- **Do not re-bless after this plan's initial bless** — later plans (006–013) run the comparison and must never re-bless (hub law: PNG re-blesses happen only in plan 005 and plan 014); if a comparison failure appears during this plan's own CI wiring with no intended paint change, that is the A6 cross-OS case — follow step 6's fallback, do not re-bless on macOS.

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — local clone of the TermRock repository at `https://github.com/tailrocks/termrock`. Needed by preconditions 3–4 and step 1 (confirming the raster crate manifest at the pin). Planning-time location on the operator machine: `/Users/donbeave/Projects/tailrocks/termrock`.
  - If absent: `git clone https://github.com/tailrocks/termrock <path-of-choice>` then `git -C <path-of-choice> checkout 29a16b5bff84ea8609854711b774e87acbc456cc`, and use that path as `<TERMROCK_CHECKOUT>` throughout. Do NOT block waiting. Read-only use — never edit the checkout (hub TermRock-misfit route covers the edit case; none is expected here).

## Starting state

The facts, inlined:

- **Workspace pin**: root `Cargo.toml:118` —
  `termrock = { version = "=0.11.0", git = "https://github.com/tailrocks/termrock.git", rev = "29a16b5bff84ea8609854711b774e87acbc456cc", features = ["crossterm", "serde"] }`.
  `termrock-raster` must be pinned at the **same rev** or cargo resolves two termrock copies with incompatible types (research ch05, version-coherence constraint; `publish = false` gates registry publishing, not git-dependency resolution — assumption A7).
- **Raster crate public API** (`<TERMROCK_CHECKOUT>/crates/termrock-raster/src/lib.rs:14-24` at the pin): `render_png(&ratatui::buffer::Buffer, &termrock::style::RolePalette)` and `compare_png_pixels(&[u8], &[u8]) -> Result<(), PixelDiff>` — `compare_png_pixels` decodes both PNGs and reports the first differing pixel (decoded pixels, never encoded bytes; zero tolerance). `RolePalette::default()` is `RolePalette::tailrocks_phosphor()`. No cargo features of its own; fonts embedded.
- **Console screen inventory** (research ch04, verified at planning time): six stage views of `ConsoleManagerStage` — List / Editor / Settings / CreatePrelude / ConfirmDelete / ConfirmInstancePurge (`crates/jackin-console/src/tui/model/stage.rs:12-26`). The 19 `ConsoleModal` variants (`crates/jackin-console/src/tui/model/modal.rs:24-114`): TextInput:48, FileBrowser:52, MountDstChoice:56, WorkdirPick:60, Confirm:63, SaveDiscardCancel:67, GithubPicker:70, ConfirmSave:73, ErrorPopup:76, ContainerInfo:79, StatusPopup:82, OpPicker:85, RolePicker:89, RoleOverridePicker:92, AuthRolePicker:95, SourcePicker:98, AuthSourcePicker:102, ScopePicker:105, AuthForm:108. Stage states per the spec: workspaces list populated AND empty (two baselines); editor five tabs (general, mounts, roles, secrets, auth — `EditorTab`, `screens/editor/model.rs:22`); settings five tabs (general, mounts, environments, auth, trust — `SettingsTab`, `screens/settings/model.rs:48`); create-prelude wizard steps; confirm-delete; confirm-instance-purge.
- **Existing render seam**: text snapshots render closures into a fresh ratatui `TestBackend` — helper documented "Render a closure into a fresh `TestBackend` and return the resulting …" at `crates/jackin-console/src/tui/view/tests.rs:452-455`, e.g. `insta::assert_snapshot!("list_empty_80x24", rendered)` at `tests.rs:767`. The PNG harness reuses this rendering pattern: same screen constructors, same canonical sizes (the existing snapshots use 80x24), but takes the backend's `Buffer` and calls `termrock_raster::render_png`.
- **deny.toml today**: `[licenses] allow = ["Apache-2.0", "MIT"]` with a per-crate `exceptions` table (deny.toml:15-23 area). Neither `swash`, `tiny-skia`, nor `arrayref` appears in `Cargo.lock` today (planning-time grep: zero hits) — adoption adds new license exceptions: tiny-skia (BSD-3-Clause), arrayref (BSD-2-Clause); TermRock widened its own allowlist the same way (research ch05). `deny.toml:206` already allowlists `https://github.com/tailrocks/termrock.git` under `[sources].allow-git` — no sources change needed.
- **REUSE**: root `REUSE.toml` carries a `[[annotations]]` block with `path = "**"`, `precedence = "aggregate"`, SPDX `Apache-2.0` — its comment says files that cannot hold a comment header ("JSON, Markdown, lock files, images") are covered by that annotation. The REUSE lane is `.github/workflows/reuse-compliance.yml`. Verify the baseline PNGs pass under the existing `**` annotation; add an explicit per-path annotation for the baseline directory only if the gate demands it.
- **CI lane shape**: `.github/workflows/ci.yml` is a generated velnor-actions consumer delegating to external SHA-pinned `ci-native.yml`; the in-repo reusable workflow is `.github/workflows/rust-nextest.yml` (`workflow_call`, no in-repo caller — invoked from velnor-actions), which runs per-package `cargo nextest run … --profile ci` over an injected runner matrix. The xtask `snapshots` partition is `cargo nextest run -p jackin-capsule -p jackin-console --locked` (`crates/jackin-xtask/src/ci.rs:258-272`). Consequence: a PNG suite placed in the `jackin-console` package runs automatically in both the existing per-package CI lane and `cargo xtask ci --only snapshots` — **no new workflow file is required**. The runner OS mix is injected externally (open unknown in-repo, research ch05); the cross-OS measurement (step 6) is how Q4 gets its answer.
- **Upstream bless pattern to mirror**: TermRock's own suite blesses via `TERMROCK_BLESS_PNGS=1 cargo nextest run -p termrock-lookbook --all-features --test png_baselines --no-capture`, where the env var makes the test write the first render instead of comparing. jackin❯'s mirror uses `JACKIN_BLESS_PNGS=1`.
- **Planning-time counts are snapshots**: the 6 stages / 19 modals / 18 `.snap` files / line numbers above are 2026-08-19 measurements; re-derive with the cited greps (`rg -n 'enum ConsoleModal' -A60 crates/jackin-console/src/tui/model/modal.rs`, `rg -n 'enum ConsoleManagerStage' -A15 crates/jackin-console/src/tui/model/stage.rs`) — the fresh enumeration is the authority.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Resolve/check workspace | `cargo check --workspace --all-targets --locked` | exit 0 |
| Console suite (text snaps + PNG) | `cargo nextest run -p jackin-console --locked` | all pass |
| Snapshot lane (xtask partition) | `cargo xtask ci --only snapshots` | exit 0 |
| Supply-chain | `cargo deny check advisories bans licenses sources` | exit 0 |
| Lint | `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` | exit 0 |
| Format | `cargo fmt --check` | exit 0 |
| Merge-readiness gate (fast) | `cargo xtask ci --fast` | exit 0 |

All proven by `research/jackin-verification-tooling/01-gates-and-commands.md` (partition table at ci.rs:159-272; nextest 0.9.140 pinned; cargo-deny 0.20.2 pinned; `cargo xtask ci` is the merge-readiness gate — `mise run ci` is NOT equivalent). One derived (not repo-proven) command this plan introduces: the focused PNG compare/bless forms in steps 4–5 — they follow the repo-proven `cargo nextest run -p <crate> -E 'test(...)'` filter form (TESTING.md:22-32).

**Canonical PNG comparison command** (this is the name later plans 006–013 reference as "the plan-005 PNG comparison command"):

```sh
cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)'
```

and its bless form (plan 005 and plan 014 only):

```sh
JACKIN_BLESS_PNGS=1 cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)' --no-capture
```

## Scope

**In scope** (the only files to create or modify):

- `Cargo.toml` (root — workspace dependency entry for `termrock-raster`)
- `crates/jackin-console/Cargo.toml` (dev-dependency on `termrock-raster`, workspace-inherited)
- `Cargo.lock` (regenerated in the same commit as the dependency)
- `deny.toml` (BSD-2-Clause/BSD-3-Clause exceptions for the raster stack)
- New: `crates/jackin-console/src/tui/view/png_baselines.rs` (harness module + tests; per the repo test-layout rule the module lives beside the view code it renders; declare it from `crates/jackin-console/src/tui/view.rs` or the module's parent as the codebase's layout dictates)
- New: `crates/jackin-console/src/tui/view/baselines/png/*.png` (the blessed baseline set)
- `crates/jackin-console/src/tui/view.rs` (one-line `mod png_baselines;` declaration only, if that is where the module hangs)
- `REUSE.toml` (only if the `**` aggregate annotation proves insufficient for the PNGs — verify first)

**Out of scope** (do NOT touch, even though related):

- Any modernization cutover — plans 006–013 own all component/facade adoption; this plan renders the **current** code as-is.
- `crates/jackin-console/src/tui/components/brand_header.rs` and any BrandHeader-specific PNG crop — plan 007 defines and rides that proof on this harness; the full-stage baselines here already include the header pixels.
- Any `.snap` file or insta configuration (Must NOT above).
- `.github/workflows/*.yml` — the existing per-package nextest lane already picks up jackin-console tests; if step 6 proves a workflow edit is genuinely required, STOP and report rather than editing the generated velnor consumer.
- Capsule/launch/oppicker baselines — deferred to their own surface phases.
- Docs pages under `docs/content/reference/tui/` — plan 014 owns the docs alignment pass.
- `<TERMROCK_CHECKOUT>` — read-only input, never edited.

## Git workflow

Commit boundaries for this plan (all on `feature/termrock-console-modernization` per the hub):

1. `build(deps): add termrock-raster at termrock pin rev 29a16b5b` — root `Cargo.toml` + `crates/jackin-console/Cargo.toml` + `Cargo.lock` + `deny.toml` in ONE commit (hub law: deny/lock deltas ride the dependency change).
2. `test(console): add PNG baseline harness over full screen inventory` — the harness module with its inventory-enumeration tests, before any PNG exists (compare mode must fail cleanly naming missing baselines, or skip-with-explicit-list behavior of your choosing that CI step 6 renders impossible to pass silently — prefer fail).
3. `test(console): bless pre-modernization PNG baselines (6 stages + 19 modals)` — the blessed PNGs plus any `REUSE.toml` delta; the PR diff shows every PNG for review.
4. After step 6: `gh pr create --draft --body-file` per `.github/PULL_REQUEST_TEMPLATE.md` (hub law: draft PR opens after plan 005's first push) — if not already opened by the operator.

## Steps

### Step 1: Add the `termrock-raster` dependency with its supply-chain deltas

In root `Cargo.toml` `[workspace.dependencies]`, next to the `termrock` entry (line 118 area), add `termrock-raster` as a git dependency at the SAME rev (`29a16b5bff84ea8609854711b774e87acbc456cc`), no features (the crate declares none). In `crates/jackin-console/Cargo.toml` add `termrock-raster = { workspace = true }` under `[dev-dependencies]`. Run `cargo check -p jackin-console --all-targets` to regenerate `Cargo.lock`; confirm the lock contains exactly one `termrock` and one `termrock-raster`, both from the same git rev. Then run `cargo deny check advisories bans licenses sources`; it will fail on the new BSD-licensed crates (expect tiny-skia → BSD-3-Clause, arrayref → BSD-2-Clause, possibly further transitive ones — the fresh `cargo deny` output is the authority over this planning-time list). Add the narrowest per-crate `exceptions` entries to `deny.toml` that make the gate pass, mirroring the existing exception style (deny.toml:23+), and re-run until green. This is the A7 verification: if cargo fails to resolve `termrock-raster` as a git dep at all, assumption A7 is falsified — STOP and report.

**Verify**: `cargo check --workspace --all-targets --locked` → exit 0; `cargo deny check advisories bans licenses sources` → exit 0; `grep -A2 'name = "termrock-raster"' Cargo.lock` → shows `source = "git+https://github.com/tailrocks/termrock.git?rev=29a16b5b..."`.

### Step 2: Build the baseline harness

Create `crates/jackin-console/src/tui/view/png_baselines.rs`. Shape:

- A single source of truth enumerating the inventory: the six stage views (with the workspaces list in both populated and empty states, editor's five tabs, settings' five tabs, create-prelude steps, confirm-delete, confirm-instance-purge) and all 19 `ConsoleModal` variants. Derive the enumeration from the actual enums (`ConsoleManagerStage`, `ConsoleModal`, `EditorTab`, `SettingsTab`) — iterate the enum variants where the codebase's construction allows, so adding a variant/screen requires no harness change (spec scenario "Inventory complete"). Where a variant needs fixture state to render (e.g. populated workspaces), the harness carries the minimal constructor for that canonical state — the existing text-snapshot tests in `crates/jackin-console/src/tui/view/tests.rs` are the model for how screens are constructed headlessly.
- For each inventory item: render the screen at its canonical size into a ratatui buffer (reuse the TestBackend pattern from `view/tests.rs:452-455`), then `termrock_raster::render_png(buffer, &RolePalette::default())`.
- Baseline path convention: `crates/jackin-console/src/tui/view/baselines/png/<screen-id>.png`, screen id derived from the inventory enumeration (stable, kebab-case, e.g. `workspaces-list-empty.png`, `modal-text-input.png`).
- Compare mode (default): read the committed baseline bytes, call `termrock_raster::compare_png_pixels(baseline, rendered)`; on failure, report the differing screen id and the first-difference coordinates/RGBA from `PixelDiff`. A missing baseline file is a failure naming the screen.
- Bless mode (`JACKIN_BLESS_PNGS=1` env var present): write the rendered PNG to the baseline path instead of comparing; print each written path. No other side effect; without the env var the test NEVER writes.
- Include the upstream in-process identity guard: render each screen twice per run and assert pixel identity of the two renders, with a failure message in the spirit of the upstream one — a render-twice mismatch is a pipeline/harness bug and must never be resolved by blessing.
- Include a rot guard: assert the enumerated inventory count is at least the planning-time count (6 stage-derived view groups + 19 modals; re-derive the exact expected minimum from the enums at execution and stamp the fresh number in a comment — the fresh count is the authority).

Model after the upstream test shape (`<TERMROCK_CHECKOUT>/crates/termrock-lookbook/tests/png_baselines.rs:24-72` at the pin) but against jackin❯'s own screens.

**Verify**: `cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)'` → runs and FAILS, naming every missing baseline PNG (proves the compare path works and nothing passes silently); `cargo clippy -p jackin-console --all-targets -- -D warnings` → exit 0.

### Step 3: Bless the initial pre-modernization set

With the tree carrying NO modernization change (this plan edits none), run the bless form: `JACKIN_BLESS_PNGS=1 cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)' --no-capture`. Confirm every inventory item produced a PNG: count files under `crates/jackin-console/src/tui/view/baselines/png/` and compare against the harness's enumerated count (they must match exactly). Then run the compare form — it must pass on this host. This bless IS the pre-modernization pixel truth; do not re-run it after any later edit in this plan except to fix a harness defect discovered before the CI wiring (compare-then-bless for the same defect is fine; re-blessing to make a comparison green is not).

**Verify**: `cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)'` → all pass; `ls crates/jackin-console/src/tui/view/baselines/png/*.png | wc -l` → equals the harness inventory count (stamp both numbers in the commit message or PR body).

### Step 4: REUSE gate over the PNGs

Run the repository's REUSE check (workflow `.github/workflows/reuse-compliance.yml` runs `reuse lint` — run that locally). The root `REUSE.toml` `**` aggregate annotation is expected to cover the PNGs ("images" named in its comment); only if `reuse lint` flags the baseline PNGs, add an explicit `[[annotations]]` entry for the baseline directory to `REUSE.toml` and re-run.

**Verify**: `reuse lint` → exit 0 with the baseline PNGs committed.

### Step 5: Prove the gate fails on an unintended paint change

Temporarily introduce a visible paint change to one baselined screen (e.g. flip a character or color in one view's render — the smallest possible local edit, do NOT commit it), run the compare form, and confirm it fails naming that screen. Revert the edit.

**Verify**: with the temporary edit, `cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)'` → fails, naming the edited screen; after `git checkout -- <edited file>`, the same command → all pass; `git status --porcelain` → clean.

### Step 6: Wire and measure the CI lane (Q4, once)

No workflow file is added: the suite lives in `jackin-console`, so the existing per-package nextest lane (`.github/workflows/rust-nextest.yml`, invoked by the external velnor consumer) and `cargo xtask ci --only snapshots` both execute it. After pushing, confirm on the PR that the jackin-console lane ran the `png_baselines` tests on the CI runner platform and passed. That first CI run on the (Linux) runner against the macOS-blessed baselines IS the cross-OS identity measurement:

- If the lane passes with no intended paint change: macOS↔Linux bit-identity holds (Q4 answered: identity holds). Record the outcome in the PR body.
- If the lane fails ONLY on the Linux runner with no intended paint change: assumption A6 is falsified — do NOT re-bless on macOS. Engage the recorded fallback: pinned-Linux / CI-produced bless (upstream A3 pattern — produce the baselines on the CI platform and commit those). Record "fallback engaged" in the PR body and report the A6 falsification per the hub's assumption-failure route. This fallback is not a merge blocker for the lane itself.

**Verify**: PR check for the jackin-console package lane → green (or fallback engaged and recorded, then green); `cargo xtask ci --only snapshots` locally → exit 0.

## Test plan

- New tests, all in `crates/jackin-console/src/tui/view/png_baselines.rs`:
  - One baseline comparison test driving the whole inventory (spec scenarios "Inventory complete", "Unintended paint change fails", "Deliberate re-bless" — the latter two are exercised by steps 5 and 3 respectively; the test's compare/bless branching IS the scenario implementation).
  - Render-twice in-process identity assertion per screen (pipeline-defect guard, upstream pattern).
  - Rot guard on the inventory count (≥ freshly-derived enum count).
  - Bless-mode-never-writes-without-env assertion: with the env var unset, run the harness write path check against a temp location or assert the code path is inert (structural test that compare mode performs no filesystem writes).
- Expected values come from an independent source of truth: the blessed PNGs are produced once from the pre-modernization render (step 3) and the compare decodes both images independently (`compare_png_pixels` semantics) — no test recomputes an expected pixel value with the code under test.
- Structural model: upstream `<TERMROCK_CHECKOUT>/crates/termrock-lookbook/tests/png_baselines.rs:24-72` for the compare/bless split; `crates/jackin-console/src/tui/view/tests.rs:452-455` for headless screen construction.
- **Verify**: `cargo nextest run -p jackin-console --locked` → all pass, including the new png_baselines tests; `cargo xtask ci --fast` → exit 0.

## Done criteria

ALL must hold:

- [ ] `cargo check --workspace --all-targets --locked` exits 0 with `termrock-raster` resolved at rev `29a16b5bff84ea8609854711b774e87acbc456cc` (spec scenario "Workspace resolves").
- [ ] `cargo deny check advisories bans licenses sources` exits 0 with the BSD-2-Clause/BSD-3-Clause exceptions recorded (spec scenario "supply-chain gates").
- [ ] `reuse lint` exits 0 over every committed baseline PNG (spec scenario "REUSE gate passes").
- [ ] `cargo nextest run -p jackin-console --locked` exits 0: text snapshot suite byte-identical AND png_baselines suite passing independently (spec scenario "Both gates run").
- [ ] `cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)'` exits 0; every stage view and all 19 `ConsoleModal` variants have committed baselines at canonical sizes, count matching the harness enumeration (spec scenario "Inventory complete").
- [ ] Step 5's tamper proof observed: an unintended paint change fails the compare naming the screen (spec scenario "Unintended paint change fails"); tree clean afterward.
- [ ] CI jackin-console lane green on the PR with the png_baselines tests executed; cross-OS identity outcome (identity holds / fallback engaged) recorded in the PR body (spec scenario "Lane green on CI"; Q4 answered; A6 verified or falsified-and-routed).
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status row and the roadmap item.
- [ ] `plans/termrock-migration/README.md` status row updated.

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails — in particular: raster crate absent at the pin (precondition 4), raster machinery already present in `Cargo.lock` (precondition 6), or the console suite not green before any edit (precondition 7).
- Assumption **A7** fails: `termrock-raster` does not resolve as a git dependency at the same rev as `termrock`.
- Assumption **A6** fails at step 6 (Linux CI fails against macOS-blessed baselines with no intended paint change): engage the pinned-Linux/CI-produced bless fallback and report the falsification — do not re-bless on macOS.
- Assumption **A5**-adjacent drift: the enums cited in "Starting state" (stage/modal counts, module paths) have drifted in KIND (a variant renamed/removed beyond count drift) from what the harness section assumes.
- A step's verification fails twice after a reasonable fix attempt.
- The work requires touching an out-of-scope file (including any `.github/workflows/*.yml` edit, any `.snap`, or any modernization change) or violating a Must NOT.
- `termrock-raster`'s public API at the pin does not match the cited signatures (`render_png`, `compare_png_pixels`) — that is a TermRock misfit route per the hub, not a consumer workaround.

## Maintenance notes

- **Plan 006** builds directly on this: its behavior-preserving facade refactor is gated on these baselines catching accidental pixel drift.
- **Plan 007** rides this harness for the dedicated BrandHeader PNG crop — its baseline crop files belong in the same baselines directory convention.
- **Plans 006–013** run the comparison command named above and must never re-bless; **plan 014** owns the only other deliberate, reviewed re-bless.
- Later surfaces (capsule, launch, small) add their own key screens onto this same lane in their own phases — the harness pattern here (inventory enumeration + bless env var + baselines directory) is the template.
- Reviewer scrutiny: the deny.toml exception entries (narrowest possible set), that bless mode cannot write without the env var, and that the blessed set visibly matches the current console look (the PR's PNG diffs are the review artifact).
- Deferred follow-up: baseline-set size/git-history growth (~0.7 MB per full-set rewrite at TermRock's 107-PNG scale; jackin❯'s set is smaller) is accepted deliberately per the spec; no LFS, plain git PNGs for rich PR diffs.
