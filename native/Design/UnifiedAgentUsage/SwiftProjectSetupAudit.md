# Swift Project Setup Audit — 2026-08-20

Mode: `audit` under `tailrocks-swift-project-setup` 0.21.0. Read-only; no files
edited during the audit. Supersedes the gap lists in
`SwiftProjectReadiness.md` for baseline mechanics.

## Pin freshness (re-resolved live this date)

| Tool | Pinned | Latest (source) | State |
|---|---|---|---|
| swiftlint | 0.65.0 | 0.65.0 (github realm/SwiftLint) | current |
| xcodegen | 2.46.0 | 2.46.0 (github yonaskolb/XcodeGen) | current |
| xcbeautify | 3.2.1 | 3.2.1 (github cpisciotta/xcbeautify) | current |
| periphery | 3.8.0 | 3.8.0 (github peripheryapp/periphery) | current |
| boltffi + boltffi_cli | 0.30.1 | 0.30.1 (crates.io) | current |

Xcode/SDK lanes attributed to the skill verified baseline of 2026-08-11
(shipping Xcode 26.6 / macOS 26.5 SDK / Swift 6.3; forward Xcode 27 beta /
macOS 27 SDK). Apple's release-notes page is JS-rendered and was not
live-resolvable during the audit; repo records match the skill baseline.

## Pass rows

- Declarative generation with synchronized folders: `project.yml`, 6 targets,
  all `type: syncedFolder`; `*.xcodeproj` and `DerivedData/` gitignored.
- Toolchain pins, four declared values, both SDK lanes in agent instructions
  (`native/AGENTS.md`) and as manifest comments (`project.yml`).
- Ad-hoc local signing (`CODE_SIGN_IDENTITY: "-"`, hardened runtime off);
  real signing/notarization confined to the release lane.
- Derived data outside any temporary directory (`native/DerivedData`).
- Strict format gate: `xcrun swift-format lint --strict`; generated boltffi
  bindings tree excluded by path (Apple swift-format honors no inline
  disables).
- Strict lint gate: `swiftlint lint --strict`; bindings tree excluded in
  `.swiftlint.yml`.
- Counted unit tests: `cargo xtask desktop test-swift` proves nonzero XCTest +
  Swift Testing totals — a zero-test run cannot read green.
- UI tests: exact XCTest selectors, one passed test per invocation
  (`native/Scripts/run-ui-tests.sh`).
- Accessibility audit wired and scoped to app-owned elements via the system
  false-positive handler (`JackinDesktopUITests.swift`).
- False-green trap 1 (format linter exits 0 without `--strict`): absent —
  strict everywhere.
- False-green trap 2 (selector matches nothing, exits success): defended by
  the counted driver and exact-selector UI script.
- Agent integration: one-owner responsibility table in `native/README.md`;
  third-party skills pinned (tailrocks plugin 0.21.0).
- Apple agent skills export: recorded blocker — Xcode 26.6 (`17F113`) probed
  2026-08-20 ships no exportable skill documents; re-probe rule recorded.
- Rust-core lane: single FFI crate (`jackin-usage-ffi`, boltffi `=0.30.1` ==
  CLI `0.30.1`); one-way package chain Bindings → Bridge → UI enforced by
  architecture tests; split layout; `desktop-release` profile (thin LTO, one
  codegen unit, line tables); symbol + dSYM archival in release; arm64-only
  decision recorded; binding-drift gate exists.
- PR CI/local command parity: generated `ci.yml` → pinned reusable
  `ci-native.yml` → macos-26 job runs `mise run desktop-ci` verbatim, so the
  drift gate, format, lint, tests, and build are PR-enforced.
- Release pipeline parity: `release.yml` invokes `mise run desktop-build /
  desktop-verify / desktop-sign-notarize / desktop-release-state` verbatim;
  workspace nextest runs in the same pipeline.
- Forward-lane exception dated 2026-08-20 with owner and exit condition.

## Gaps

1. **Merge cadence never runs.** `desktop-merge` (PR graph plus
   `desktop-test-ui` — UI tests and the accessibility audit against the real
   app host) is defined in `mise.toml` but no event invokes it; the pinned
   reusable workflow calls only `mise run desktop-ci`. The skill's merge tier
   (UI tests + accessibility audit at merge) is unmet.
   Owner: `velnor-actions` `ci-native.yml` (local `ci.yml` is generated —
   never hand-edited).
2. **Scheduled cadence never runs.** `desktop-scheduled` (merge graph plus the
   periphery dead-code scan) has no caller; the weekly cron in `ci.yml`
   re-runs `desktop-ci` only. The dead-code scan is local-only.
   Owner: same upstream reusable workflow.

Both gaps live in the pinned upstream reusable workflow, the same source that
owns the recorded forward-lane exception.
