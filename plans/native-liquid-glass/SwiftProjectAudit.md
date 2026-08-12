# Phase 2 Swift project audit

Status: **audit complete; concept migration implemented; production baseline reconciliation in progress**

Audit mode is read-only. The current app builds, but it does not satisfy the
approved current-native project baseline needed for a runnable A1 proof and
exhaustive UI/accessibility testing.

## Proven current state

| Area | Repository evidence | Result |
|---|---|---|
| App definition | `native/Package.swift` exposes `JackinDesktop` as an executable product | Gap: a package executable is not an application target. |
| Bundle assembly | `cargo xtask desktop build` manually copies the SwiftPM binary/resources, writes `Info.plist`, and signs the bundle | Functional existing path, but not a declarative native application project. |
| Deployment | Package, Rust xtask constant, release workflow, README: macOS 14.0 | Gap: contradicts the selected current-stable Liquid Glass baseline and preserves a legacy lane. |
| Shipping toolchain | Local Xcode 26.6, Swift 6.3.3, SDK 26.5 | Meets the shipping compiler baseline. |
| Forward lane | No Xcode 27 installation/configuration | Gap: no scheduled forward validation. |
| Language mode | tools version 6.0; no explicit `swiftLanguageVersions`, `SWIFT_VERSION`, or strict-concurrency setting | Gap: project does not record Swift 6 language/strict concurrency explicitly. |
| Project generation | No `project.yml`; no generated/ignored Xcode project | Gap. |
| Local signing | Rust xtask runs `codesign --sign -` | Partial pass: bundle is ad-hoc signed, but no declarative Debug signing setting exists. |
| Derived data | SwiftPM uses `native/.build`; no Xcode derived-data contract | Gap for Xcode build/UI-test/visual-QA lane. No forbidden temporary derived-data path is configured. |
| Formatting | No `.swift-format` or strict task | Gap; installed Xcode formatter is 6.3.0. |
| Lint | No `.swiftlint.yml`, SwiftLint pin, or strict task | Gap. Generated bindings contain comments for a linter not configured. |
| Dead-code lane | No Periphery pin/config/task | Gap. |
| Build log formatter | No xcbeautify pin/task | Gap. |
| Unit tests | 52 XCTest-style tests in one SwiftPM test target | Useful coverage; gap against the current Swift Testing baseline and Xcode test-count assertion. |
| UI tests | No application UI-test target or `XCUIApplication` use | Blocking gap for real host driving. |
| Accessibility audit | No `performAccessibilityAudit` | Blocking gap for required Phase 4 evidence. |
| Visual harness | Custom executable with real and offscreen capture paths | Partial asset; not a UI-test application driver and cannot approve detached glass. |
| CI parity | Desktop tasks exist, but CI does not invoke shared generate/format/lint/build/test task names | Gap. Release workflow directly restates cargo commands. |
| Skill ownership | Root objective names one owner per responsibility; repo does not pin/vendor those dependencies or Apple agent knowledge | Gap under project-setup policy. |
| Compatibility key | No `UIDesignRequiresCompatibility` in generated plist | Pass; keep absent. |

## Freshness record

Official release notes and local probes establish:

```text
Minimum deployment target selected for concept: macOS 26.0
Shipping SDK / Xcode: macOS 26.5 SDK / Xcode 26.6
Shipping Swift compiler: Swift 6.3.3 locally (Apple release notes: Swift 6.3)
Forward-validation SDK / Xcode: macOS 27 / Xcode 27 beta; not installed
Forward-only behavior: never enters shipping unguarded; scheduled validation only
```

Apple's macOS 26.6 release notes call the bundled SDK 26.6, while Xcode 26.6
release notes and the installed `xcrun --show-sdk-version` report 26.5. The
installed SDK is compile authority.

The host is macOS 26.5.2 while Apple lists 26.6.1 as current. Building is
supported; final "latest runtime" proof remains limited until the operator
updates the host.

## Project-generation audit

### Gap

SwiftPM defines libraries, executables, and tests. It does not define an Xcode
application/UI-test product with bundle metadata, launch arguments,
accessibility automation, build settings, or scheme actions. The Rust assembler
creates a real bundle, but target structure remains implicit in Rust code and
cannot host an XCUITest target.

### Required migration

- Add `native/project.yml` as the declarative authority.
- Generate `native/JackinDesktop.xcodeproj`; never commit it.
- Use `type: syncedFolder` for every source/test target so adding a file causes
  no project-file edit.
- Define app, bridge/UI modules as required, unit tests, and UI tests.
- Keep the Rust-built static XCFramework ownership boundary.
- Keep `cargo xtask desktop` and `mise run desktop-*` as canonical operator
  commands; change their internals to generate/build/test the Xcode project.
- Do not add shell assembly scripts.
- Remove the package app product after Xcode project parity is proven. Retain
  SwiftPM only for any harness/library role that remains uniquely useful; do
  not keep two production app build authorities.

## Toolchain and lanes audit

### Shipping lane

- Xcode 26.6 is installed and current for this proof.
- `Package.swift` tools version 6.0 is not a full toolchain declaration.
- Release CI prefers Xcode 26.1/26.0 paths and otherwise accepts an unspecified
  default. This is stale, not a pin to Xcode 26.6.
- Release CI exports `MACOSX_DEPLOYMENT_TARGET=14.0`.

Required: record Xcode 26.6, SDK 26.5, Swift language mode 6,
`SWIFT_STRICT_CONCURRENCY=complete`, and macOS 26.0 in project artifacts and
instructions. Update the release lane to use the same baseline when production
migration occurs.

### Forward lane

No Xcode 27 beta exists locally and no scheduled job records a forward build.
Required: add a scheduled forward-validation lane when an approved runner has
Xcode 27. It is never a shipping dependency and cannot introduce unguarded APIs.

## Signing and build paths

- Ad-hoc local signing is already real and verified through `codesign`.
- Declarative Debug configuration must record `CODE_SIGN_IDENTITY = "-"` and
  `ENABLE_HARDENED_RUNTIME = NO`.
- Distribution signing/notarization remains owned by the existing Rust release
  path and GitHub environment.
- Add one stable ignored path such as `native/DerivedData/`; do not use `/tmp` or
  `/private/tmp`.
- The exact app produced from that path must feed UI tests and real capture.
- Copying the validated build to `native/dist/JackinDesktop.app` may remain an
  xtask packaging step, but it cannot recompile through a different authority.

## Format, lint, and dead-code audit

Missing artifacts:

- `.swift-format`;
- `.swiftlint.yml` plus narrow test overrides;
- pinned SwiftLint, xcbeautify, and Periphery in root `mise.toml`;
- shared strict tasks.

Required gates:

```text
xcrun swift-format lint --strict …
swiftlint --strict
xcodegen generate
xcodebuild … | xcbeautify   # with pipefail
periphery scan              # scheduled
```

Generated UniFFI sources need an explicit exclusion or generated-code policy;
a blanket application-source disable is not acceptable.

### False-green trap 1 — format

No current format gate exists. If added without `--strict`, violations print but
the command exits successfully. The shared task must use `--strict` and a test
must prove a known malformed fixture fails.

## Test audit

### Unit tests

Current XCTest tests cover bridge, ownership, ordering, and HTML-era structural
contracts. They are valuable but not enough for the new app target. New unit
tests should use Swift Testing unless XCTest is required; legacy tests can
migrate in slices.

### UI tests

There is no UI-test target, deterministic app-launch fixture selector,
application driver, test plan, or app-owned accessibility-identifier policy.
This blocks:

- real popover driving;
- native window-ID capture orchestration;
- keyboard/focus validation;
- lifecycle/restoration tests;
- `performAccessibilityAudit`.

The generated project must include an XCUITest target that launches the actual
application and scopes audits to app-owned identifiers.

### False-green trap 2 — test selectors

No Xcode exact-selector lane currently exists. When it is added, an unmatched
`-only-testing` selector can run zero tests and still exit successfully.
Every task must parse/inspect the result bundle or test summary and assert a
positive expected test count. Swift Testing function identifiers include
trailing parentheses.

## Agent-integration audit

- No Xcode project exists to open for the bridge.
- No project-local `Vendor/AppleAgentSkills` export exists.
- The required Tailrocks skill family is available to this session through a
  pinned plugin cache, not recorded as a reviewed project dependency.
- Responsibility ownership is nevertheless unambiguous in the objective:
  Swift correctness, material, visual direction, QA, and project mechanics each
  have one named owner. No competing aesthetic skill is active.

Required migration artifact: document the exact owners in `native/AGENTS.md`,
record plugin/version provenance without copying global executable content, and
add read-only Apple agent knowledge only if Xcode exposes a verifiable export.
The unsupported export must not become a build dependency.

## Shared-task/CI parity audit

Current root mise tasks delegate desktop build/test/verify/run to Rust, which is
a sound ownership pattern. Gaps:

- no `desktop-generate`;
- no `desktop-format-check`;
- no `desktop-lint`;
- no `desktop-test-ui` or accessibility audit task;
- no desktop test-count assertion;
- CI restates cargo commands rather than calling the shared task set;
- no PR desktop job is visible in current workflows despite README claims.

Required ordering:

```text
desktop-generate
desktop-format-check
desktop-lint
desktop-build
desktop-test
desktop-test-ui
desktop-accessibility-audit
```

CI must call these task names verbatim where graphical permissions permit.
Visual capture remains a provisioned development-machine/scheduled capability,
not a false-green hosted-runner checkbox.

## Audit disposition

| Requirement | Disposition |
|---|---|
| Declarative generation and synchronized folders | Migration required |
| Exact shipping toolchain and deployment | Migration required |
| Forward lane | Blocked locally; scheduled lane required later |
| Ad-hoc signing | Existing behavior retained; declare in project |
| Stable non-temporary derived data | Add during migration |
| Strict format/lint | Add during migration |
| Unit/UI tests and positive count | UI project migration required |
| Accessibility audit | UI project migration required |
| Agent integration/provenance | Documentation migration required |
| Compatibility key absent | Preserve |

The runnable A1 concept cannot honestly pass Phase 4 using the current
package-only app/test arrangement. Project migration is part of Phase 3 proof,
not deferred production polish.
