# 01 — jackin verification gates and commands

Vetted: 2026-08-19

Questions: Which build/test/lint/docs/snapshot/gate commands are proven for this workspace?
Informs: termrock-migration (bump-phase plans)
Method: codebase read + read-only command probes at commit d554dca8 (`git rev-parse --short HEAD` observed `d554dca8`; note the conversation git snapshot showed `c9be126c` — probes were run against the actual checkout HEAD `d554dca8`).

All commands run from repo root `/Users/donbeave/Projects/jackin-project/jackin`. `cargo xtask` is a cargo alias: `xtask = "run --quiet --package jackin-xtask --"` (`.cargo/config.toml`, `[alias]` block at end of file). The xtask binary was already built (`target/debug/jackin-xtask` present), so `--help` probes were cheap and did not trigger builds.

## Findings

### Merge-readiness gates

**`cargo xtask ci` — full non-Docker gate.** HIGH. Proven by `cargo xtask ci --help`, which printed:

> "Run the local CI merge-readiness gate. Partitions (`--only`, repeatable): lint, policy, tests, powerset, docs, snapshots. `--only` is a local-dev tool; merge readiness is the full `ci` (or `ci --fast` without powerset). Use as `cargo xtask ci --fast` for the non-e2e gate, or add `--e2e` to include Docker-backed smoke tests."

Partition set defined at `crates/jackin-xtask/src/ci.rs:13-21` (`PARTITIONS = ["lint","policy","tests","powerset","docs","snapshots","e2e"]`). Default run (no flags) executes lint + tests + policy + powerset + docs + snapshots; e2e only when `--e2e` or `--only e2e` (`ci.rs:134-136` `e2e_selected`). TESTING.md:163 verification matrix: "Full non-Docker gate | `cargo xtask ci` | merge readiness".

**`cargo xtask ci --fast`.** HIGH. Skips the powerset step only among default steps (`ci.rs:25-27` flag doc "Skip intentionally slow lanes: feature-powerset and Docker E2E"; `ci.rs:224-228`: `want_powerset = !args.fast` when `--only` empty). E2E is already off by default, so `--fast` = lint + policy + tests + docs + snapshots. TESTING.md:162: "Cross-crate Rust | `cargo xtask ci --fast` | before PR".

**`cargo xtask ci --e2e`.** HIGH. Adds Docker preflight (`docker info`, `ci.rs:311-318`), capsule export via `cargo run --bin build-jackin-capsule -- --export` unless `--e2e-capsule <PATH>` given (`ci.rs:320-332`), then runs `cargo nextest run -p jackin --features e2e --profile docker-e2e --locked --offline` with `JACKIN_CAPSULE_BIN` set (`ci.rs:333-349`). Optional focus: `--e2e-filter <EXPRESSION>` appends `-E <expr>` (`ci.rs:345-347`). Help output confirmed all four e2e flags (`--e2e`, `--e2e-capsule <PATH>`, `--e2e-filter <EXPRESSION>`, `--base <BASE>` default `origin/main`).

**`mise run ci` is NOT equivalent to `cargo xtask ci`.** HIGH. `mise.toml:87-89`:

```toml
[tasks.ci]
description = "Run unified build and policy gates"
run = "git fetch --no-tags origin main:refs/remotes/origin/main && cargo xtask ci --only policy --only docs --only snapshots"
```

It runs only 3 of 6 partitions (policy, docs, snapshots) after a git fetch. CONTRIBUTING.md ("Merge-Readiness Check": `cargo xtask ci` "or" `mise run ci`) implies equivalence that the task definitions contradict — see Dead ends. Sibling tasks (`mise.toml:91-101`, confirmed in `mise tasks ls` output):

- `mise run test` → `cargo xtask ci --only tests --fast` (mise.toml:91-93; `--fast` is a no-op under `--only`, see ci.rs:224-228)
- `mise run lint` → `cargo xtask ci --only lint --fast` (mise.toml:95-97)
- `mise run fmt` → `cargo fmt --check` (mise.toml:99-101)

`mise tasks ls` observed listing all of: `ci`, `test`, `lint`, `fmt`, `desktop-*`, `construct-*` with the descriptions above.

### Partition selection

HIGH. `--only <PARTITION>` is repeatable (`ci.rs:40-45`, clap arg `only: Vec<String>`); unknown names hard-fail with "unknown CI partition `{name}`" (`ci.rs:146-155`). Valid names: `lint`, `policy`, `tests`, `powerset`, `docs`, `snapshots`, `e2e` (`ci.rs:13-21`). Proven syntax:

```sh
cargo xtask ci --only lint
cargo xtask ci --only tests
cargo xtask ci --only docs
cargo xtask ci --only snapshots
cargo xtask ci --only policy
cargo xtask ci --only powerset
cargo xtask ci --only lint --only tests   # repeatable combination
```

TESTING.md:164: "One CI partition | `cargo xtask ci --only <lint|policy|tests|snapshots|docs|powerset>` | inner loop mirroring a CI lane". Help output caveat (verbatim): "Local-dev convenience only — merge readiness remains the full `ci`."

Exact step-to-partition mapping (`ci.rs:159-272`):

| Partition | Steps (exact commands, run from repo root) |
|---|---|
| lint | `actionlint <each .github/workflows/*.yml>` (ci.rs:160-165, 287-309); `cargo fmt --check` (ci.rs:166); `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` (ci.rs:167-180); `cargo xtask lint --strict` (ci.rs:181) |
| tests | `cargo check --workspace --all-targets --locked` (ci.rs:185-189); `cargo nextest run --workspace --all-features --locked` (ci.rs:190-200); `cargo test --doc --workspace --locked` (ci.rs:201-205) |
| policy | `cargo audit` (ci.rs:209); `cargo deny check advisories bans licenses sources` (ci.rs:210-214); `cargo xtask schema-check --base origin/main` (ci.rs:215-219; base overridable via `--base`); `cargo shear --deny-warnings` (ci.rs:220) |
| powerset | `cargo hack check --workspace --feature-powerset --all-targets --locked` (ci.rs:229-242) |
| docs | `cargo xtask roadmap audit` (ci.rs:245); `cargo xtask docs repo-links` (ci.rs:246-250); `cargo xtask research check` (ci.rs:251-255) |
| snapshots | `cargo nextest run -p jackin-capsule -p jackin-console --locked` (ci.rs:258-272) |
| e2e | `docker info` preflight; capsule export; `cargo nextest run -p jackin --features e2e --profile docker-e2e --locked --offline` + `JACKIN_CAPSULE_BIN` env (ci.rs:311-354) |

### Test runner and profiles

**cargo-nextest installed and pinned.** HIGH. `cargo nextest --version` observed: `cargo-nextest 0.9.140 (a9fef2964 2026-07-05)`. Pin: `mise.toml:18` `"aqua:nextest-rs/nextest/cargo-nextest" = "0.9.140"` — installed and pinned versions match.

**Profiles** (`.config/nextest.toml`). HIGH:

- `[profile.default]` (lines 4-6): `default-filter = 'not binary(/dind_e2e|usage_broker_e2e/)'`, slow-timeout 60s × terminate-after 3. So a plain `cargo nextest run` already excludes the Docker E2E binaries.
- `[profile.docker-e2e]` (lines 8-17): `default-filter = 'binary(/dind_e2e|usage_broker_e2e/)'` (only the E2E binaries), terminate-after 10, retries 2 fixed 1s, `final-status-level = "flaky"`, JUnit at `junit.xml`.
- `[profile.ci]` (lines 21-27): retries 2 fixed 1s, `failure-output = "immediate-final"`, `final-status-level = "flaky"`, JUnit. Flake policy: pass-on-retry reported FLAKY; unquarantined flake fails review; ledger `flaky-tests.toml` at repo root (nextest.toml:18-20 comment; TESTING.md:234).
- `[profile.soak]` (lines 29-32): `default-filter = 'test(/soak/)'`.
- Test groups (lines 34-58): `docker-e2e` max-threads 1; `load-agent` max-threads 2 with 90s slow-timeout overrides.

**Whole suite.** HIGH. `cargo nextest run --all-features` — TESTING.md:34-38 ("Run all feature-gated Rust tests except profile-isolated environment-backed smoke tests"). The ci tests partition uses the locked form: `cargo nextest run --workspace --all-features --locked` (ci.rs:190-200). Bare `cargo nextest run` also documented (TESTING.md:16-19).

**One package.** HIGH. `cargo nextest run -p <crate>` (TESTING.md:161, 184: "Every Rust workspace member is verified by `cargo nextest run -p <crate>`").

**One test / one module.** HIGH. `cargo nextest run -E 'test(test_name)'` (TESTING.md:22-26); `cargo nextest run -E 'test(/module::tests/)'` (TESTING.md:28-32).

**Docker smoke.** HIGH. `cargo nextest run -p jackin --features e2e --profile docker-e2e` (TESTING.md:40-44); requires capsule env: `eval "$(cargo run --bin build-jackin-capsule -- --export)"` outside the PR sync flow (TESTING.md:46-49).

**Insta usage.** HIGH. Workspace pin `insta = "=1.48.0"` (root `Cargo.toml:69`). Dev-dependency in exactly two crates (grep of `crates/*/Cargo.toml`): `crates/jackin-capsule/Cargo.toml:86` and `crates/jackin-console/Cargo.toml:32`, both `insta = { workspace = true, features = ["filters"] }`. TESTING.md:172 confirms: "insta snapshots live only in these two crates today". Snapshot files found (`find crates -name '*.snap'`): 12 in jackin-capsule (10 under `crates/jackin-capsule/src/tui/components/dialog/snapshots`, 2 under `crates/jackin-capsule/src/tui/components/branch_context_bar/snapshots`), 6 in jackin-console (`crates/jackin-console/src/tui/view/snapshots`). Insta-using test modules (grep `assert_snapshot|insta::`; the same grep also hits `crates/jackin-term/tests/conformance.rs:202`, a local non-insta helper `assert_snapshot_invariants` — excluded): `crates/jackin-capsule/src/tui/components/dialog/tests.rs`, `crates/jackin-capsule/src/tui/components/branch_context_bar/tests.rs`, `crates/jackin-console/src/tui/view/tests.rs`.

**ONLY snapshot lane (repo-proven form).** HIGH. The repo's snapshot lane is package-scoped, not filter-scoped: `cargo xtask ci --only snapshots` = `cargo nextest run -p jackin-capsule -p jackin-console --locked` (ci.rs:258-272), i.e. it runs ALL tests in those two crates, not only insta tests. Equivalent direct command in TESTING.md:172: `cargo nextest run -p jackin-capsule -p jackin-console`. There is no repo-proven insta-only filter; the three insta test modules also contain non-snapshot assertions (observed in `crates/jackin-console/src/tui/view/tests.rs`, which mixes geometry asserts and snapshot tests).

**Everything EXCEPT the snapshot crates (derived, not repo-proven).** MED. No such command exists in repo docs or xtask. nextest filterset syntax supports it as `cargo nextest run --workspace --all-features --locked -E 'not (package(jackin-capsule) + package(jackin-console))'` — this is standard nextest filterset semantics (same `package()`/`binary()`/`test()` DSL the repo already uses in `.config/nextest.toml:5,9` and TESTING.md:25,31), but I did not execute it (suite run forbidden) and no repo file contains it. Treat as unproven until run once.

### Snapshot workflow

**Policy (TESTING.md:179-181, "Snapshot review policy").** HIGH. Verbatim decisive line (TESTING.md:181): "Changed `.snap` files are enumerated in CI against the PR merge-base with `origin/main` (step summary + job log). Reviewers must acknowledge each listed snapshot; hand-edited snapshots that merely match buggy output are rejected in review. Pending files (`*.pending-snap`) still fail CI. Prefer `cargo insta review` / `cargo insta accept` over hand-editing `.snap` bodies." No `*.pending-snap` files currently exist in the tree (`find` returned none).

**Re-bless via env var (repo-proven).** HIGH. `crates/jackin-console/src/tui/view/tests.rs:559-568` comment block documents the generation command verbatim:

```sh
INSTA_UPDATE=new cargo nextest run -p jackin-console -E 'test(view::tests)' --no-capture
```

and states "Any change to rendered output fails CI until reviewed and accepted with `cargo insta review`" (tests.rs:561-562).

**`cargo insta` binary is NOT installed and NOT pinned.** HIGH. Probe: `cargo insta --version` → `error: no such command: `insta``. `cargo-insta` is absent from `mise.toml` [tools] (full read, lines 4-38). So the TESTING.md-preferred `cargo insta review` / `cargo insta accept` flow is not currently executable on this host as provisioned; the executable re-bless path today is the `INSTA_UPDATE` env form above (insta crate reads `INSTA_UPDATE`; values like `new`/`always` per insta 1.x behavior — only `new` is repo-documented). See Dead ends.

### Lint/format/deny

All HIGH, from ci.rs lint/policy partitions (exact strings, see table above):

- Format: `cargo fmt --check` (ci.rs:166; also `mise run fmt`, mise.toml:99-101). Fix-up: `cargo fmt` (CONTRIBUTING.md, "Fmt fail → `cargo fmt`, re-check").
- Clippy: `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` (ci.rs:167-180; also crates/AGENTS.md "Clippy CI-enforced with" block). Per-crate inner loop: `cargo clippy -p <crate> --all-targets -- -D warnings` (TESTING.md:161).
- actionlint over every `.github/workflows/*.yml` (ci.rs:160-165 + file enumeration ci.rs:287-309). Installed 1.7.12 (probe) = mise.toml:7 pin.
- xtask lint umbrella: `cargo xtask lint --strict` (ci.rs:181). Named sub-gates exist (`cargo xtask lint files`, `cargo xtask lint agents`, `cargo xtask lint readme-freshness --base origin/main` — TESTING.md:169-171; `cargo xtask lint ratchet --only suite-time` — TESTING.md:329).
- Deny: `cargo deny check advisories bans licenses sources` (ci.rs:210-214). Probe: `cargo deny --version` → `cargo-deny 0.20.2` = mise.toml:11 pin. (crates/AGENTS.md splits it differently for CI workflows: PR gate `cargo deny check licenses bans sources`, scheduled `cargo deny check advisories` — the local xtask policy partition runs all four at once.)
- Audit: `cargo audit` (ci.rs:209). Probe: 0.22.2 = mise.toml:10 pin.
- Shear: `cargo shear --deny-warnings` (ci.rs:220). Probe: 1.13.4 = mise.toml:19 pin.
- Schema: `cargo xtask schema-check --base origin/main` (ci.rs:215-219).

### Docs gate

Two distinct layers — do not conflate:

**1. xtask `docs` partition (Rust-side, what `cargo xtask ci --only docs` runs).** HIGH. Exactly three steps, no bun (ci.rs:244-256): `cargo xtask roadmap audit`, `cargo xtask docs repo-links`, `cargo xtask research check`. Matches TESTING.md:168 ("Docs/roadmap | `cargo xtask roadmap audit && cargo xtask docs repo-links && cargo xtask research check` | any docs edit").

**2. Docs-site verification gate (bun, run from `docs/`).** HIGH. PULL_REQUESTS.md:204: "Run `bun run build`, `cargo xtask docs repo-links`, `cargo xtask roadmap audit`, `cargo xtask research check`, `bunx tsc --noEmit`, `bun test`." Canonical copy-paste block from `.github/PULL_REQUEST_TEMPLATE.md:183-193`:

```sh
(
  cd docs
  bun install --frozen-lockfile
  bun run build
  cargo xtask docs repo-links
  cargo xtask roadmap audit
  bunx tsc --noEmit
  bun test
)
```

(Note: the template block omits `cargo xtask research check`; PULL_REQUESTS.md:204 includes it.) Supporting `docs/package.json` scripts (lines 6-20): `build` = `bun run scripts/gen-crate-pages.ts && vite build && bun run scripts/prerender-static.ts`; `types:check` = `fumadocs-mdx && tsc --noEmit`; `test` = `bun test`; `check:repo-links`/`check:roadmap-sidebar`/`check:research-sidebar` wrap the xtask commands; `check:links`/`check:links:fresh` need the `lychee` CLI (docs/AGENTS.md:70 area). CI workflows use `bun ci` for locked install (docs/AGENTS.md:68). Dev server: `bun run dev`, serves `http://localhost:3000/` (PULL_REQUEST_TEMPLATE.md:245-253).

### Toolchain

All HIGH (file reads + version probes):

- Rust: `rust-toolchain.toml:9-12` — channel `1.97.1`, components clippy+rustfmt, targets `aarch64-unknown-linux-gnu`, `x86_64-unknown-linux-gnu`. Probe `rustc --version` → `rustc 1.97.1 (8bab26f4f 2026-07-14)` — matches. mise reads it via `idiomatic_version_file_enable_tools = ["rust"]` (mise.toml:44; comment mise.toml:39-40).
- mise: probe `mise --version` → `2026.8.6 macos-arm64`. Setup: `mise install` from repo root (CONTRIBUTING.md step 2; TESTING.md:5-14 — "Do not install these tools with ad hoc `cargo install`").
- Pins in `mise.toml` [tools] (lines 4-38), probes in parentheses where run: bun 1.3.14 (probe `bun --version` → 1.3.14), cargo-nextest 0.9.140 (probe match), cargo-deny 0.20.2 (probe match), cargo-audit 0.22.2 (probe match), cargo-hack 0.6.45 (probe match), cargo-shear 1.13.4 (probe match), actionlint 1.7.12 (probe match), cargo-binstall 1.21.1, cargo-fuzz 0.13.2, cargo-hakari 0.9.38, cargo-llvm-cov 0.8.7, cargo-mutants 27.1.0, cargo-dylint/dylint-link 6.0.4, cargo-zigbuild 0.23.0, codebook-lsp 0.3.42, sccache 0.16.0, uniffi 0.32.0 (cli), node 24.18.0, zig 0.16.0, shellcheck 0.11.0, hyperfine 1.20.0, plus macOS-only tools (swiftlint 0.65.0, periphery 3.8.0, xcbeautify 3.2.1, xcodegen 2.46.0 — listed with the macOS group but carrying no os constraint in mise.toml:36 — and apple/container 1.2.2).
- cargo-insta: NOT pinned, NOT installed (see Snapshot workflow).

### Behavioral test seams

**Keymap/interaction test files — all three exist.** HIGH (probe `ls`, sizes observed):

- `/Users/donbeave/Projects/jackin-project/jackin/crates/jackin-console/src/tui/keymap/tests.rs` (24.6K)
- `/Users/donbeave/Projects/jackin-project/jackin/crates/jackin-capsule/src/tui/keymap/tests.rs` (8.4K)
- `/Users/donbeave/Projects/jackin-project/jackin/crates/jackin-launch/src/tui/keymap/tests.rs` (7.5K)

Per the repo test-layout rule (crates/AGENTS.md "Tests in own file"), each is the sibling suite of `src/tui/keymap.rs` in its crate; runnable via module filter, e.g. `cargo nextest run -p jackin-console -E 'test(/keymap::tests/)'` (filter form proven at TESTING.md:28-32).

**Render-conformance harness (TESTING.md:192-201, "Recording capsule render-conformance fixtures").** HIGH. Harness = capsule echo-back tests in `crates/jackin-capsule/src/daemon/tests.rs` (file exists, 301.5K) — "replays reviewed PTY byte streams through the multiplexer and asserts that emitted frames reproduce the pane model on a virtual client terminal" (TESTING.md:194). Fixture-capture workflow (TESTING.md:196-199, verbatim steps):

1. Set `JACKIN_PTY_FIXTURE_CAPTURE` to an operator-selected temporary capture path and run the specific capture scenario.
2. Review the temporary capture for secrets and unstable content.
3. `cargo xtask pty-fixture <capture.bin> crates/jackin-capsule/tests/fixtures/pty/<fixture.bin>`
4. Reference the fixture with `include_bytes!` and add the scenario to the fixture README.

Without the capture variable, no PTY streams are written (TESTING.md:201).

**TUI snapshot seam.** HIGH. `cargo nextest run -p jackin-capsule -p jackin-console` for TUI render changes (TESTING.md:172); console view snapshots at `crates/jackin-console/src/tui/view/tests.rs` + `.../view/snapshots/`, capsule component snapshots under `crates/jackin-capsule/src/tui/components/{dialog,branch_context_bar}/{tests.rs,snapshots/}`.

## Dead ends and contradictions

- **`mise run ci` ≠ `cargo xtask ci`.** CONTRIBUTING.md ("Run `cargo xtask ci` # or `mise run ci`") presents them as alternatives, but `mise.toml:87-89` defines `ci` as `git fetch … && cargo xtask ci --only policy --only docs --only snapshots` — no lint, tests, or powerset. Plans should treat `cargo xtask ci` as the merge-readiness gate and `mise run ci` as a policy/docs/snapshots subset.
- **`cargo insta review`/`accept` recommended but tool absent.** TESTING.md:181 prefers `cargo insta review` / `cargo insta accept`; `cargo insta --version` fails ("no such command") and `cargo-insta` is not in `mise.toml`, while TESTING.md:13 + crates/AGENTS.md:210 forbid ad-hoc `cargo install`. Executable re-bless today = `INSTA_UPDATE=new cargo nextest run …` (crates/jackin-console/src/tui/view/tests.rs:567).
- **"snapshots" partition is a misnomer**: it runs the full test suites of jackin-capsule + jackin-console (ci.rs:258-272), not insta tests specifically. There is no insta-only selection anywhere in the repo.
- **Docs gate command drift**: `.github/PULL_REQUEST_TEMPLATE.md:183-193` docs-checks block lacks `cargo xtask research check`, which PULL_REQUESTS.md:204 and the xtask docs partition (ci.rs:251-255) both include.
- **cargo-deny sub-check split differs by surface**: local xtask policy = all four checks in one invocation (ci.rs:210-214); crates/AGENTS.md documents CI as PR-gate `licenses bans sources` + scheduled `advisories`. Not a conflict for local use — `cargo deny check advisories bans licenses sources` is the local proven form.
- Prompt hypothesis "docs partition runs bun install/build/tsc/bun test" — false for the xtask partition (ci.rs:244-256 is bun-free); the bun commands are the separate PR-template docs-site gate.
- Embedded-instruction scan: repo docs read during this task contain normative contributor instructions (expected); no injected/malicious instructions encountered.

## Open unknowns

- No command was executed that builds or tests, per task constraints — every gate command above is source/help/doc-proven but not run-proven in this session (except `--help`, `--version`, `mise tasks ls`).
- Exclusion filter `-E 'not (package(jackin-capsule) + package(jackin-console))'` is derived from nextest filterset syntax, not found in any repo file; unverified by execution.
- Whether `INSTA_UPDATE=always` (vs the documented `new`) is acceptable practice here — only `new` is repo-documented; the review/acknowledge policy (TESTING.md:181) suggests any bulk-accept must still be reviewed per snapshot.
- `cargo xtask lint --strict` sub-gate inventory (which named gates `--strict` promotes) was not enumerated — `crates/jackin-xtask/src/lint.rs` not read in this pass.
- Exact behavior of `--only e2e` without `--e2e` flag: e2e_selected() accepts it (ci.rs:134-136) and build_steps produces no non-e2e steps, so `cargo xtask ci --only e2e` should run only the Docker lane — logic-proven, not run-proven.
