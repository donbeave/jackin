# Plan 009: Give desktop changes a PR CI lane and fix actively wrong doc claims

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If a STOP condition
> occurs, stop and report; do not improvise. Update this plan's row in
> `plans/README.md` when finished.
>
> **Drift check (run first)**:
> `git diff --stat 27d0d9b3..HEAD -- .github/workflows TESTING.md HOST_AND_CONTAINER.md crates/jackin-usage/README.md native/Scripts flaky-tests.toml`
> Plans 003/008 run earlier in the unified branch sequence and are expected to have
> edited `HOST_AND_CONTAINER.md`; merge, don't overwrite.
> Any other semantic mismatch with the excerpts below is a STOP condition; a
> citation off by a few lines with the described code clearly present nearby is
> not drift.
>
> Command prefix note: `rtk` is an optional local output-compressor. The
> canonical command is everything after `rtk `; if `rtk` is not installed, drop
> the prefix.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: `plans/003-strict-usage-coordinator.md`,
  `plans/008-backend-parity-fail-closed.md`
- **Category**: dx, tests, docs
- **Planned at**: commit `27d0d9b3`, 2026-08-13
- **Execution state**: BLOCKED — the plan's assumed local CI graph no longer
  exists. `.github/workflows/ci.yml` is generated, hash-authenticated fleet
  output that calls `jackin-project/velnor-actions/.github/workflows/ci-code.yml`;
  local edits are forbidden and would be overwritten. The repository workflow
  policy also forbids ordinary macOS runners, while the active main ruleset
  requires only `ci-required` and DCO. Completion requires an approved native
  extension in the canonical `velnor-actions` code-class template (or a governed
  repository extension point), regenerated fleet pins/caller, and then a ruleset
  decision. Those cross-repository mutations are outside this branch's scope.

## Why this matters

No PR gate runs any Swift/desktop verification: a Swift regression merges green
and is first caught during a release build, while a stale workflow comment tells
reviewers the coverage exists. The canonical testing doc has zero desktop
content and claims Rust-only coverage is complete. The container-layout doc — the
file reviewers are told is the authority on container paths — omits the
usage-shared tree and misnames two credential dirs, and its cleanup example
contains a destructive command with a brand-glyph-corrupted path.

## Current state

- `.github/workflows/hygiene.yml:144-146` — comment claims "Universal static
  menu-bar assembly + Swift tests live on PR CI (`native-usage-menu-bar` in
  ci.yml)". `.github/workflows/ci.yml` contains **no** such job, no
  `runs-on: macos*`, and zero occurrences of `swift` (verified by grep). The
  `native-macos` job in `hygiene.yml` (below that comment) is a scheduled
  workspace-Rust smoke on `macos-latest`, not PR CI and not Swift.
- `crates/jackin-xtask/src/ci.rs` has zero `desktop` references, so
  `cargo xtask ci` (the documented merge gate) skips every desktop lane too.
  Only `release.yml:450,456` runs `desktop build`/`verify` — post-merge, no
  tests/lint.
- `.github/workflows/ci.yml` already has a `changes` path-filter job and a
  `ci-required` aggregation job (`ci.yml:36-1087`) — the wiring pattern to copy.
- `flaky-tests.toml` contains only comments and an example row;
  `.config/nextest.toml:22-27` gates on it. UI tests run outside nextest
  entirely (`native/Scripts/run-ui-tests.sh`, invoked by
  `mise run desktop-test-ui`, `mise.toml:123`), so the flake ledger structurally
  cannot observe the flakiest suite.
- `TESTING.md` — zero occurrences of `swift`/`native`/`desktop`/`xcode` in 377
  lines; the verification matrix (`:133-150`) has no `native/` row; `:162`
  asserts "Every crate is verified by `cargo nextest run -p <crate>`", which
  never builds the Swift shell. Meanwhile `native/AGENTS.md:26-31` mandates
  `mise run desktop-test` after Desktop UI changes.
- `HOST_AND_CONTAINER.md:29-36` — the layout list (`:35`) reads
  `/jackin/{claude,codex,amp,kimi,opencode}/`, but
  `crates/jackin-core/src/container_paths.rs:34` defines `/jackin/grok` (absent)
  and `:38` defines `/jackin/kimi-code` (doc says `kimi`). The Docker launch path
  mounts `/jackin/usage-shared` into every container
  (`launch_runtime.rs:1004`) — never mentioned in the layout.
- `HOST_AND_CONTAINER.md:48` — cleanup example reads `rm -rf /jackin❯` (brand
  glyph inside the path); every real container path is `/jackin`
  (`container_paths.rs:10`). The command removes nothing.
- `crates/jackin-usage/README.md:35-45` — module table has no row for
  `crates/jackin-usage/src/process_telemetry.rs`.

Repository constraints:

- Brand rule: `jackin❯` in prose, bare `jackin` in paths/commands — the `:48`
  bug is the rule applied in the wrong direction; the fix restores the
  plain-path form inside the code span.
- CI additions must not slow the whole PR queue: use the existing `changes`
  filter so the macOS lane runs only when `native/**` or the usage crates
  change.
- Roadmap freshness and docs-as-source-of-truth gates apply to every PR.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Workflow lint | `rtk actionlint .github/workflows/ci.yml .github/workflows/hygiene.yml` | exit 0 (`actionlint` is pinned in `mise.toml:6`) |
| Docs gates | `rtk cargo xtask docs repo-links && rtk cargo xtask roadmap audit` | exit 0 |
| Readme gate | `rtk cargo xtask lint readme-freshness` | exit 0 (advisory) |
| Desktop lanes (local proof) | `rtk mise run desktop-bindings && rtk mise run desktop-format-check && rtk mise run desktop-lint && rtk mise run desktop-test` | exit 0 |
| Fast gate | `rtk cargo xtask ci --fast` | exit 0 |

## Scope

**In scope**:

- `.github/workflows/ci.yml` (new job + `ci-required` needs + `changes` filter)
- `.github/workflows/hygiene.yml` (comment correction only)
- `native/Scripts/run-ui-tests.sh` (JUnit emission only) **or** `TESTING.md`
  (documented exclusion) — Step 3 decides
- `TESTING.md`
- `HOST_AND_CONTAINER.md`
- `crates/jackin-usage/README.md`
- `plans/README.md` (status row only)

**Out of scope**:

- Changing what any desktop task does (`mise.toml`, `desktop.rs`).
- Rewriting the grep-based architecture tests (Plan 004 covers guard scope).
- Adding UI tests to CI (real-host UI tests need a logged-in runner; document,
  don't wire).
- Any source-code change.

## Git workflow

Stay on the existing `feature/native-liquid-glass-redesign` branch and its new active
PR (`#843` is already merged historical context);
the operator explicitly selected this plan into that branch. Do not create or switch
branches. Use Conventional Commits, `git commit -s`, add
`Co-authored-by: Codex <codex@openai.com>`, and push after every commit. Never
force-push.

## Steps

### Step 1: Add the desktop PR CI lane

In `.github/workflows/ci.yml`, the `changes` routing is a **four-site** edit —
touching only the filter leaves `outputs.native` empty and the job silently
never runs (while this step's grep verify still passes):

1. Add a `native` entry covering `native/**`, `crates/jackin-usage/**`,
   `crates/jackin-usage-ffi/**` in ALL FOUR places: the `dorny/paths-filter`
   `filters:` block (`ci.yml:124-178`); the `route` bash step's env map
   (`:183-194`) and its script (`:198-205`); and the job-level `outputs:` map
   (`:39-58`). Mirror how an existing output (e.g. `rust`) threads through all
   four, including the `workflow_dispatch` force branch (`:100-111`).
2. Add job `native-usage-menu-bar` (use exactly this name — the hygiene.yml
   comment already promises it): `runs-on: macos-26` (the pinned runner
   `release.yml:394` uses; not `macos-latest`), conditional on the `native`
   output, using the repo's standard mise setup step, running in order:
   `mise run desktop-bindings`, `mise run desktop-format-check`,
   `mise run desktop-lint`, `mise run desktop-test`, then
   `cd native && swift test -c release`.
3. Add the job to `ci-required`'s `needs` (the shared
   `.github/actions/aggregate-needs` action already treats `skipped` as
   success, so no extra handling is needed).

Sequencing note (also recorded in `plans/README.md`): plans 004/005 must retire
the frozen assertions in `ArchitectureTests.swift:901-921` and
`bridge/tests.rs:332-338` in their own PRs — while those PRs are open, a red
`native-usage-menu-bar` on exactly those assertions is expected, not a reason to
weaken this lane.

In `.github/workflows/hygiene.yml:144-146`, correct the comment so it describes
what is now true (PR CI runs the lane; hygiene keeps the scheduled Rust smoke).

**Verify**:
`rtk actionlint .github/workflows/ci.yml` -> exit 0 (or CI green on the PR);
`rtk rg -n 'native-usage-menu-bar' .github/workflows/ci.yml` -> job exists;
locally run the four desktop commands from the table -> all exit 0.

### Step 2: Prove the lane catches a regression

Default (no red pushes): verify locally that `mise run desktop-format-check`
fails on a scratch formatting violation (restore it immediately; do not commit it).
The active branch already changes `native/**` through the committed planning bundle,
so the new path filter must trigger without an
artificial source edit. Do not add a whitespace/comment-only trigger change. Only with
explicit operator approval, use the stronger proof: push a deliberate violation
commit, watch the lane fail, then `git revert` (no force-push) — the repo gates
merges on CI-green, so a knowingly-red push is opt-in, never default.

**Verify**: PR checks show `native-usage-menu-bar` executed (green) and
`ci-required` lists it in `needs`.

### Step 3: Make UI-test flakiness observable

Preferred: extend `native/Scripts/run-ui-tests.sh` to export the `xcresult`
bundle to JUnit (`xcrun xcresulttool` or `xcbeautify --report junit`) under
`native/.build/test-results/` (git-ignored), and add one paragraph to
`TESTING.md` stating UI-test flakes are quarantined through the same
`flaky-tests.toml` review rule using that report. If tool support for JUnit
export is unavailable on the pinned Xcode, fall back to documenting in
`TESTING.md` that UI tests are outside the nextest flake ledger and flakes there
are handled by review. Record which branch was taken.

**Verify**:
`rtk mise run desktop-test-ui` locally -> report file appears under
`native/.build/test-results/` (preferred branch), or `TESTING.md` documents the
exclusion (fallback branch).

### Step 4: Correct `HOST_AND_CONTAINER.md`

1. `:48`: change `` `rm -rf /jackin❯` `` to `` `rm -rf /jackin` ``.
2. `:35`: correct the credential-dir list to
   `/jackin/{amp,claude,codex,grok,kimi-code,opencode}/` matching
   `container_paths.rs:28-38`.
3. Layout completeness: Plan 003 has landed in the selected sequence. Add the
   `/jackin/run/usage.sock` relay entry and do not restore a shared-tree row.
   Verify `launch_runtime.rs` no longer mounts `usage-shared`; if it does, Plan 003
   is not actually DONE and this plan must not conceal that failed dependency.

**Verify**:
`rtk rg -n 'rm -rf /jackin❯' HOST_AND_CONTAINER.md` -> 0 hits (the file
legitimately uses `jackin❯` in prose, so a bare glyph grep cannot gate);
`rtk rg -n 'kimi-code' HOST_AND_CONTAINER.md` -> ≥1 hit;
`rtk rg -n '/jackin/grok' HOST_AND_CONTAINER.md` -> ≥1 hit.

### Step 5: Add the desktop row to `TESTING.md` and fix the completeness claim

Add a "Desktop / native Swift" row to the verification matrix (`:133-150`)
pointing at `mise run desktop-test`, `swift test -c release`, and
`mise run desktop-test-ui`, and qualify the sentence at `:162` to say nextest
covers Rust workspace members while the Swift shell is verified through
`cargo xtask desktop test` and the commands above. Mention the new CI lane by
its job name.

**Verify**:
`rtk rg -n 'desktop-test' TESTING.md` -> the row exists; docs gates pass.

### Step 6: Refresh the `jackin-usage` README module table

Add a `process_telemetry.rs` row to `crates/jackin-usage/README.md:35-45`
matching the table's existing format (link, one-line "Owns", Tests column per
the crates/AGENTS.md rule: a Tests link only if `src/process_telemetry/` exists).

**Verify**:
`rtk rg -n 'process_telemetry' crates/jackin-usage/README.md` -> 1 hit (the
`readme-freshness` gate only fires on added/renamed/deleted source files vs
`origin/main`, and this plan changes no source — it cannot gate this edit).

## Test plan

CI wiring is proven by Step 2's trigger test; docs by the gates named per step.
No Rust/Swift source changes, so no new unit tests.

## Done criteria

- [ ] PR CI runs bindings/format/lint/harness/XCTest for desktop-affecting
  changes, and `ci-required` gates on it.
- [ ] `hygiene.yml`'s comment describes reality.
- [ ] UI-test results feed the flake process, or the exclusion is documented.
- [ ] `HOST_AND_CONTAINER.md` layout matches `container_paths.rs` and the
  cleanup command uses the real path.
- [ ] `TESTING.md` has the desktop row and no false completeness claim.
- [ ] `jackin-usage` README lists every module.
- [ ] Docs gates and fast gate pass; only in-scope files and `plans/README.md`
  changed.

## STOP conditions

- macOS runners are unavailable to this repository's plan/billing — report; do
  not silently keep the lane Linux-only.
- The pinned Xcode/mise toolchain cannot run `swift test` on the `macos-26`
  runner image — report the version gap instead of switching images ad hoc.
- Step 4 finds `HOST_AND_CONTAINER.md` already restructured by Plan 003 —
  merge into its new structure; if the merge is ambiguous, report.

## Maintenance notes

The CI lane's path filter must grow when new desktop-facing crates appear —
reviewers should check the filter whenever a `jackin-usage*` crate is added.
Consider (deferred, not in scope) generating the `HOST_AND_CONTAINER.md` layout
list from `container_paths.rs` so it cannot drift again; and adding a lint that
rejects the `❯` glyph inside backticked spans, which would have caught `:48`.
