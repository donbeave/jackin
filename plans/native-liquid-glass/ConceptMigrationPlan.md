# A1 runnable-concept migration plan

Status: **executed through the confirmed runnable-concept gate; superseded for production by [ProductionPlan.md](ProductionPlan.md)**

This plan is limited to the smallest real native proof required for the second
operator gate. It is not the final production implementation.

## Stop condition

Stop after a real A1 popover and Usage window are runnable, deterministic,
drivable, captured, and audited well enough for operator confirmation. Do not
finish secondary production behavior or delete the old path beyond what is
required to avoid two active visual authorities.

## Slice 1 — Declarative native app baseline

Owned files:

- `native/project.yml`
- native format/lint configs
- root `mise.toml`
- `.gitignore`
- `crates/jackin-xtask/src/desktop.rs`
- project/test setup documentation

Work:

1. Add an XcodeGen application project with synchronized source folders, app,
   unit-test, and UI-test targets.
2. Set macOS 26.0, Swift language mode 6, complete strict concurrency, ad-hoc
   Debug signing, and a stable `native/DerivedData` path.
3. Keep the Rust XCFramework input; do not move domain logic into Swift.
4. Make `cargo xtask desktop` generate and build the Xcode project while
   preserving current mise command entry points.
5. Add pinned XcodeGen, SwiftLint, xcbeautify, and Periphery tools and strict
   shared tasks.
6. Remove the macOS 14 build/release lane in the same coherent slice.
7. Prove regeneration creates no unexplained tracked diff.

Verification:

- generator version and project listing;
- generation twice with clean git diff;
- strict format/lint;
- Xcode Debug build with nonzero target evidence;
- ad-hoc `codesign -dv`;
- bundle minimum OS and architecture verification;
- existing Rust/Swift bridge tests.

Rollback: revert the complete slice. Do not leave Package.swift and Xcode project
as competing production app authorities.

## Slice 2 — Deterministic fixture and launch control

Owned files:

- presentation launch configuration and fixture builder
- app entry/delegate fixture routing
- UI-test launch support
- deterministic fixture tests

Work:

1. Implement the `F00`–`F14` catalog behind a test-only/explicit launch
   selector using the production presentation shapes.
2. Freeze clock, locale, calendar, and time zone for fixtures.
3. Add launch arguments/environment for fixture ID, initial Usage destination,
   popover auto-open/anchor, window geometry, and evidence metadata.
4. Never read real credentials, stores, or network in fixture mode.
5. Give every interactive app-owned element a stable accessibility identifier.

Verification:

- every fixture ID resolves exactly once;
- source ordering preserved;
- unknown fixture fails launch visibly;
- real mode cannot accidentally activate fixture data;
- no personal identity exists in committed fixtures.

## Slice 3 — A1 focused popover proof

Owned files:

- status/popover host
- `PopoverRoot` and focused provider content
- popover-specific tests

Work:

1. Retain dynamic `NSStatusItem` and one real transient `NSPopover`.
2. Replace `GlassPopoverHostingController` with ordinary native hosting.
3. Remove Overview/provider tabs, provider carousel, account pills, custom
   shell, custom shadow, footer island, cards, and custom progress tracks.
4. Compose provider identity, menu-style account picker, metadata sections,
   native limit progress, local Refresh, and Open Usage.
5. Add native empty/loading/error states and bounded scrolling.
6. Preserve provider click context and Rust-owned values/order.

Verification:

- F00, F01, F03, F04–F11, F13, F14;
- constrained and target popover envelopes;
- real anchor/dismissal/Escape;
- keyboard focus and VoiceOver labels;
- no explicit glass/custom popover background in source.

## Slice 4 — A1 two-column Usage proof

Owned files:

- Usage window host/root
- Overview table
- provider detail/account picker
- commands and restoration seam
- window tests

Work:

1. Keep a two-column `NavigationSplitView` with native sidebar selection.
2. Sidebar contains Overview plus Rust-ordered providers only.
3. Overview becomes native `Table` with provider-account records.
4. Provider detail uses native `List` or grouped `Form`, `Section`,
   `LabeledContent`, `ProgressView`, and account `Picker`.
5. Restore native window title; remove custom principal title, selection wells,
   sidebar account rails/footer material, content cards, custom meters, and
   forced soft edges.
6. Preserve native toolbar Refresh and add/verify standard menu equivalents,
   sidebar command, File, Services, and Help citizenship.
7. Preserve selection/context from popover to Usage.

Verification:

- F00–F14 at 760 × 500, 920 × 620, and 1200 × 760;
- native table/sidebar keyboard behavior;
- menu commands and system toolbar overflow;
- provider/account transition;
- active/inactive window and restored valid/invalid selection;
- no explicit glass/content-card helpers.

## Slice 5 — UI automation, accessibility, and real capture

Owned files:

- XCUITest target
- app driver and window-ID capture helpers
- evidence manifest/output policy
- visual QA documentation

Work:

1. Add positive test-count assertion and scoped
   `performAccessibilityAudit`.
2. Drive real status items, real `NSPopover`, and real Usage window.
3. Use atomic kill → launch → drive → window-ID capture.
4. Capture the required A1 state matrix on the actual built app.
5. Snapshot and restore every changed macOS appearance/accessibility setting on
   success, failure, and interruption.
6. Reject offscreen/detached captures for system chrome.
7. Record current-runtime limitation if the host remains below macOS 26.6.1.

Verification:

- UI test count is positive and expected;
- accessibility audit has no app-owned issue;
- capture manifest has commit, fixture, OS/Xcode/SDK, geometry, appearance,
  accessibility settings, and key-window state;
- no blocked placeholder counts as evidence;
- system settings restore receipt exists.

## Phase 4 handoff

Present:

- exact commit and build/run commands;
- real popover/window captures;
- fixture and component mapping;
- Liquid Glass audit closure;
- accessibility/keyboard results;
- known differences and current-runtime limitation.

Then stop. Full production implementation begins only after the operator
explicitly confirms the runnable concept.
