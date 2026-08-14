# jackin❯ desktop

Native macOS limits display over `jackin-usage-ffi` (UniFFI). Product identity is **jackin❯ desktop** (`JackinDesktop.app`, bundle id `com.jackin-project.desktop`). Rust owns probes, provider ordering, accounts, quota semantics, refresh policy, severity, and every domain string. Swift owns AppKit/SwiftUI presentation and OS integration.

Production Swift passes no config, home, or data paths. Rust derives canonical host
paths, loads the global/workspace/role configuration read-only, resolves configured
credential sources, deduplicates accounts, and exports only immutable sanitized
inventory/diagnostic DTOs. Swift never scans configuration or handles credentials.
One host Rust broker owns canonical refresh generations, provider calls, atomic
last-good state, and shared rate-limit deadlines. Desktop sends refresh intent and
renders the returned phase; it never starts a local probe or uses Swift task
cancellation as coordination.

One `desktopProjection` call returns the complete generation: provider groups,
account children, selected identities, quota/detail rows, status-item rows, activity,
and sanitized diagnostics. `PresentationStore` replaces visible state only after that
whole projection decodes. A transient failure preserves the exact last-good rows and
destination; an older generation can never overwrite a newer one.

Product scope is limits only: remaining/used percentages, resets, plan/status, multi-account selection, and provider-supplied quota caps. Never add token unit prices, session-cost estimates, historical spend/usage, trends, sparklines, or aggregate charts.

## Shipping baseline

- Deployment target and release floor: **macOS 26.0**.
- Release toolchain: **Xcode 26.6** on GitHub's `macos-26` image.
- Architecture: Apple Silicon (`arm64`) static XCFramework assembly.
- Swift language mode: Swift 6 strict concurrency.
- No compatibility branch, custom material, explicit `glassEffect`, or `GlassEffectContainer` exists in production UI.

Liquid Glass is owned by the system hosts and standard functional chrome: `NSPopover`, unified `NSToolbar`, `NSSplitViewController`, sidebar/list/table, menus, pickers, buttons, and window titlebars. Quota content uses ordinary `Form`, `List`, `Section`, `LabeledContent`, `Table`, and `ProgressView` surfaces. The status bar remains template monochrome. jackin❯ phosphor appears only as adaptive identity/healthy-state emphasis; warning and danger retain textual state plus system semantic color.

## Native surfaces

### Status items and popover

`StatusBarController` owns native `NSStatusItem` instances selected from the Rust projection. A primary click opens one real transient `NSPopover` focused on that provider. The popover contains:

- a centered, noninteractive generated jackin❯ monogram plus `jackin❯ desktop` identity row;
- provider identity, selected account, and one Rust-owned activity phrase;
- a native account menu when multiple identities are known;
- Limits before useful, nonduplicated Details;
- visible Retry actions for global/provider failures;
- visible Refresh (Command-R) and Open Usage actions.

There is no cross-provider navigation inside the popover. A secondary click opens the fixed native menu: Open Usage Window, Refresh, Quit jackin❯ desktop.

### Usage window

`UsageWindowController` lazily creates and retains one normal `NSWindow`. A native `NSSplitViewController` owns two columns while SwiftUI renders their content:

- sidebar: Overview plus Rust-ordered providers;
- quiet footer: generated `jackin❯ by tailrocks` wordmark;
- Overview: expanded native hierarchical `Table` with provider parents, account
  children, and Provider/Account/Plan or status/Remaining/Reset columns;
- provider detail: selected identity, account menu, Details, Limits, and recovery;
- titlebar: the standard split-view sidebar button in its fixed leading slot;
- detail top accessory: centered `jackin❯ desktop` identity and trailing Refresh.

The standard `.toggleSidebar` item and `NSSplitViewController.toggleSidebar(_:)` responder action are the only visibility authority. Its native width is retained while its accessibility label changes between Show Sidebar and Hide Sidebar, so the control stays stationary through collapse and retained-window reopen. The sidebar owns the full leading structural height. The detail-only native split-item accessory centers the noninteractive product identity over the detail pane and keeps Refresh trailing; no root header or `Usage` heading spans both panes. Reopening preserves valid destination, account, sidebar state, and frame. A removed/disabled provider normalizes to Overview at `PresentationStore`, not in a view-only fallback.

Standard commands: Command-R Refresh, Command-comma Settings, Command-W Close, Control-Command-S Toggle Sidebar.

### Settings

Settings is a standard titled `NSWindow` containing a grouped `Form`. It owns menu-bar display selection, percent/reset preferences, screen-sharing privacy, launch at login, enabled surfaces, and refresh floor. It does not render quota data or create custom Liquid Glass.

## Layout

| Path | Role |
|---|---|
| `../crates/jackin-usage` | Host probes and `HostUsageRuntime` |
| `../crates/jackin-usage-ffi` | Synchronous UniFFI facade |
| `Generated/` | Generated UniFFI C header/module map |
| `Sources/JackinUsageBridge` | Generated Swift, `PresentationStore`, pure projections |
| `Sources/JackinDesktop` | AppKit hosts and SwiftUI native surfaces |
| `Sources/JackinDesktop/VisualQAFixtures.swift` | Explicit synthetic F00–F14 visual-QA states |
| `UITests/JackinDesktopUITests.swift` | Real-host interaction and accessibility audits |

## Build and verify

```bash
mise install

# Build + verify + launch.
mise run desktop

# Individual steps.
mise run desktop-generate
mise run desktop-build -- 0.6.0 1
mise run desktop-verify
mise run desktop-run
```

The default bundle is `native/dist/JackinDesktop.app`. Build/verify/run print its absolute path and `DESKTOP_APP=…`. The app begins as an `LSUIElement` status-item process; opening a normal window temporarily gives it regular app menu/window citizenship.

## Tests

```bash
mise run desktop-format-check
mise run desktop-lint
mise run desktop-deadcode
mise run desktop-test
mise run desktop-test-ui

cd native
swift test -c release
```

`desktop-test` covers 251 Rust/FFI tests plus native architecture/parity harnesses. SwiftPM tests protect ownership, navigation normalization, native component confinement, brand tokens, and visual-QA fixture isolation. The UI suite runs the real app host and audits popover, Overview, provider detail, sidebar coordinates, commands, scrolling, recovery, and retained context.

Explicit visual-QA launch flags (`--fixture`, `--open-popover`, `--open-usage`, `--selection`, `--window-size`, `--appearance`) never activate unless `--fixture` is present in argv and never call the bridge or real credentials. Fixture runs carry a persistent visible Fixture badge, and their frozen account/refresh projections exercise immediate selection plus `Updating…` → terminal activity. Environment variables cannot enable fabricated data. Moving fixture code into a debug-only target remains a maintenance follow-up.

## Visual QA

```bash
native/Scripts/VisualQA/capture-final-matrix.sh native/dist/JackinDesktop.app
```

The script rebuilds and verifies the canonical branch-head app, then drives deterministic fixtures through the real popover and Usage-window hosts. Captures use actual window IDs and default to the ignored `native/.build/visual-qa/final/` directory. They are temporary verification output: inspect them, restore any changed system appearance or accessibility settings, and do not commit them. The retained distributable is `native/dist/JackinDesktop.app`.

## Static assembly

One path builds local, PR, and release apps:

1. `mise install` installs pinned tools.
2. `cargo xtask desktop xcframework` creates the arm64 static `target/xcframework/JackinUsageFFI.xcframework`.
3. `native/Package.swift` consumes it as a binary target.
4. `mise run desktop-build -- <version> <build>` generates bindings/project, builds `JackinDesktop.app`, and ad-hoc signs local/validation output.
5. `mise run desktop-verify` proves bundle architecture, metadata, dependency, and signature shape. Release verification additionally requires Developer ID, notarization, staple, and Gatekeeper acceptance.

## CI and release contract

| Surface | Contract |
|---|---|
| PR/local validation | macOS 26.0, Xcode 26.6, arm64 static app, tests and bundle verification |
| Secret-free release validation | fixture version, ad-hoc rejection by release verifier, read-only reconciliation |
| Publication | `main`/tag only, environment `release-macos`, GitHub-hosted macOS only |
| Artifact | `jackin-desktop-<VERSION>-aarch64-apple-darwin.zip` plus SHA-256, Sigstore bundle, SBOM, attestation |
| Homebrew | formula and `Casks/jackin-desktop.rb` in one independently reviewed tap PR |

Required `release-macos` secret names:

- `DEVELOPER_ID_APPLICATION_P12_BASE64`
- `DEVELOPER_ID_APPLICATION_P12_PASSWORD`
- `APP_STORE_CONNECT_API_KEY_P8`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`

Required repository variables:

- `JACKIN_DEVELOPER_ID_TEAM_ID`
- `JACKIN_DEVELOPER_ID_CERT_SHA256`

Credential material is never committed. CI removes temporary signing/notary material before supply-chain tooling runs. Until an operator provisions these values and performs the first notarized publication/cask proof, validation is complete but public distribution remains externally gated.

## Local notarization rehearsal

```bash
export DEVELOPER_ID_APPLICATION='Developer ID Application: Your Name (TEAMID)'
export NOTARY_PROFILE=jackin-notary
export JACKIN_APP_VERSION=0.6.0 JACKIN_APP_BUILD=1
mise run desktop-build -- 0.6.0 1
mise run desktop-sign-notarize
```

See the [public macOS guide](<../docs/content/(public)/guides/macos-usage-menu-bar.mdx>) and [ADR-011](../docs/content/reference/adrs/adr-011-native-macos-usage-menu-bar.mdx) for operator behavior, architecture, component ownership, and verification boundaries.
