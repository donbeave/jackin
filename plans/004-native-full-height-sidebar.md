# Plan 004: Restore native full-height Liquid Glass pane ownership

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If a STOP condition
> occurs, stop and report; do not improvise. Update this plan's row in
> `plans/README.md` when finished.
>
> **Drift check (run first)**:
> `git diff --stat 27d0d9b3..HEAD -- native/Sources/JackinDesktop native/Tests native/UITests native/Tools/DesktopArchitectureLint native/README.md docs/content/reference/adrs/adr-011-native-macos-usage-menu-bar.mdx 'docs/content/roadmap/(operator-surface)/native-macos-usage-menu-bar.mdx'`
> Plan 003 may have changed Refresh state plumbing — the Refresh toolbar excerpt
> (`UsageWindowRoot.swift:101-122` driving from `store.refreshInProgress`) is
> **expected** to differ after 003; preserve whatever phase model 003 left. Any
> other semantic mismatch with the excerpts below is a STOP condition; a citation
> off by a few lines with the described code clearly present nearby is not drift.
>
> Command prefix note: `rtk` is an optional local output-compressor. The
> canonical command is everything after `rtk `; if `rtk` is not installed, drop
> the prefix. `mise run desktop-test` runs nextest + three `swift run` harnesses
> only — XCTest classes (e.g. `ArchitectureTests`) run via
> `cd native && swift test -c release`.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: `plans/003-strict-usage-coordinator.md`,
  `plans/009-ci-testing-docs-hygiene.md`
- **Category**: bug, tech-debt, tests, docs
- **Planned at**: commit `27d0d9b3`, 2026-08-13

## Why this matters

The Usage window currently attaches brand, sidebar toggle, and Refresh to one root
toolbar. That makes the titlebar read as a full-width header above both panes and
pushes the sidebar below it. The custom replacement toggle is therefore outside the
sidebar's structural region. macOS 26 already supplies the desired Liquid Glass
sidebar when `NavigationSplitView`/native split ownership is preserved. This plan
re-homes controls to their panes, keeps one stable native toggle authority, and
removes the last app-painted popover bar.

## Current state

- `native/Sources/JackinDesktop/UsageWindow/UsageWindowRoot.swift:46-79` uses
  `NavigationSplitView` and `.listStyle(.sidebar)`, but explicitly removes the
  framework sidebar toggle:

  ```swift
  .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
  .toolbar(removing: .sidebarToggle)
  ```

- `UsageWindowRoot.swift:83-122` attaches a root `.principal` brand, custom
  `.navigation` sidebar button, and trailing Refresh to the same toolbar.
- `UsageWindowController.swift:24-26,119-123` owns a parallel
  `UsageWindowNavigationState`; AppMainMenu invokes that custom state rather than
  dispatching through the native split-view responder path.
- `native/UITests/JackinDesktopUITests.swift:12-31` currently asserts the brand's
  midpoint equals the whole window midpoint. The required geometry is the detail
  pane midpoint.
- `native/UITests/JackinDesktopUITests.swift:82-111` correctly tests one toggle and
  stable expanded/collapsed coordinates; retain that behavioral invariant without
  requiring app-owned chrome.
- `native/Sources/JackinDesktop/PopoverRoot.swift:44-48` paints the control footer:

  ```swift
  controls
      .padding(.horizontal, 12)
      .frame(height: 48)
      .background(.bar)
  ```

  This conflicts with `native/AGENTS.md`: `NSPopover` and standard controls own
  material; production adds no explicit material/background chrome.
- `native/Tests/JackinUsageBridgeTests/ArchitectureTests.swift:901-921`
  (`testProductIdentityUsesNativeNoninteractivePlacements`) requires root
  `.principal` branding. The material guard is a separate test,
  `testProductionHasNoHandPaintedSystemMaterial` at `ArchitectureTests.swift:91-105`;
  its regex matches only `*Material` variants and `NSVisualEffectView`, so it
  misses `.background(.bar)`. `DesktopArchitectureLint/main.swift` has **no**
  material check at all (only `glassEffect`/`NSVisualEffectView` substrings at
  `:153-157`) and scans only `Sources/JackinDesktop` (`main.swift:16`); the
  XCTest guard already enumerates both targets via `sourcesRoot`
  (`ArchitectureTests.swift:10-31`).
- ADR-011 line 45 and `native/README.md:40-42` explicitly codify the custom
  toggle/window-wide principal design. Framing note: these docs accurately
  describe the code as shipped — this is a **supersession** (the operator's
  feedback overrides the recorded decision), not doc/code drift. Step 6 rewrites
  the decision; do not present it as fixing a stale doc.

Normative design sources already selected in `native/DESIGN_FEEDBACK.md`:

- [Apple Sidebars HIG](https://developer.apple.com/design/human-interface-guidelines/sidebars)
- [Apple Toolbars HIG](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [WWDC25: Build an AppKit app with the new design](https://developer.apple.com/videos/play/wwdc2025/310/)
- [WWDC25: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)

Required ownership:

```text
traffic lights + stable sidebar toggle | detail-centered jackin❯ desktop + Refresh
full-height system sidebar             | detail content
```

The diagram is ownership, not custom painting. System glass shape, inset, shadow,
overlap, safe area, scroll edge, contrast, and transparency adaptation remain native.

Repository constraints:

- Brand text is exactly `jackin❯ desktop` in rich UI.
- Keep the quiet `jackin❯ by tailrocks` signature inside the sidebar, noninteractive.
- No `glassEffect`, `GlassEffectContainer`, material, blur, `.background(.bar)`,
  hand-drawn header, fake titlebar, or compatibility renderer.
- macOS 26/Xcode 26 only. Do not add macOS 14/15 branches.
- Use ignored `native/.build/visual-qa/` for temporary captures and delete them after
  acceptance. Do not commit screenshots, sketches, or progress logs.
- Current `feature/native-liquid-glass-redesign` branch and its new active PR (`#843`
  is already merged historical context); signed Conventional Commits with Codex co-author,
  immediate normal push, no force-push.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Format | `rtk mise run desktop-format-check` | exit 0 |
| Lint | `rtk mise run desktop-lint` | exit 0 |
| Dead code | `rtk mise run desktop-deadcode` | exit 0 |
| Unit/architecture | `rtk mise run desktop-test` | exit 0 |
| Real UI | `rtk mise run desktop-test-ui` | exit 0 |
| Swift release | `cd native && rtk swift test -c release` | exit 0 |
| Docs | `rtk cargo xtask roadmap audit && rtk cargo xtask docs repo-links` | exit 0 |

## Scope

**In scope**:

- `native/Sources/JackinDesktop/UsageWindow/UsageWindowRoot.swift`
- `native/Sources/JackinDesktop/UsageWindowController.swift`
- `native/Sources/JackinDesktop/AppMainMenu.swift`
- `native/Sources/JackinDesktop/PopoverRoot.swift`
- a small AppKit split-view/toolbar adapter under
  `native/Sources/JackinDesktop/UsageWindow/` only if the standard SwiftUI hierarchy
  cannot satisfy verified pane ownership
- `native/Tests/JackinUsageBridgeTests/UsageWindowNavigationStateTests.swift`
  (renamed to `UsageSidebarToggleAuthorityTests` per Step 1)
- relevant assertions in `ArchitectureTests.swift`
- `native/Tools/DesktopArchitectureLint/main.swift` (guard widening, Step 3)
- `native/UITests/JackinDesktopUITests.swift`
- `plans/README.md` (status row only)
- `native/README.md`
- `docs/content/reference/adrs/adr-011-native-macos-usage-menu-bar.mdx`
- `docs/content/roadmap/(operator-surface)/native-macos-usage-menu-bar.mdx`

**Out of scope**:

- Provider/account/Overview row content: Plan 005.
- Custom glass/material/background, a replacement full-width header, or a custom
  painted sidebar.
- Changing product colors, logos, provider marks, window minimum size, or retained
  selection behavior.
- Committed screenshots/visual plans or redesign prototypes.

## Steps

### Step 1: Make native split visibility the single authority

Remove `.toolbar(removing: .sidebarToggle)` and the custom root
`ToolbarItem(id: "usage.sidebar-toggle", placement: .navigation)`. Start with the
system-supplied `NavigationSplitView` toggle and its real column visibility.

Delete `UsageWindowNavigationState` (declared at `UsageWindowRoot.swift:8`) —
it exists only to mirror the native controller — and rewrite its suite
`UsageWindowNavigationStateTests` as `UsageSidebarToggleAuthorityTests`, testing
the single native authority below. Wire
View -> Show/Hide Sidebar and Control-Command-S through the responder chain's native
`NSSplitViewController.toggleSidebar(_:)` action, or through one binding owned by the
actual split view if SwiftUI does not expose the responder state. Menu validation must
read the real visible/collapsed state. There must be one action path, not a hidden
system toggle plus custom state.

The visible toggle must stay at the same far-leading coordinate while expanded and
collapsed. It must label itself Show Sidebar/Hide Sidebar for accessibility and stay
available after collapse. Do not wrap it in material/background.

**Verify**:
`cd native && rtk swift test -c release --filter UsageSidebarToggleAuthorityTests`
-> native action/menu tests pass; and
`rtk rg -n 'toolbar\(removing: \.sidebarToggle\)|"usage\.sidebar-toggle"|UsageWindowNavigationState' native/Sources/JackinDesktop`
-> no matches.

### Step 2: Give sidebar and detail separate top-region ownership

Attach the centered `jackin❯ desktop` identity and trailing Refresh to the detail
pane's toolbar/accessory scope instead of the root split view. The brand midpoint must
track the detail pane midpoint, not the combined window. Keep Refresh at the trailing
detail edge and preserve Plan 003's Rust refresh phase.

The sidebar list/signature stack remains the leading split content and must occupy the
full leading structural height allowed by the system, including the native floating
Liquid Glass relationship with the traffic-light/toggle region. No root header may
reserve vertical content space above it.

Implementation decision order (write the Step 4 geometry tests **first**, as the
failing acceptance for this step, then):

1. First use standard SwiftUI `NavigationSplitView`, sidebar placement, and pane-local
   toolbar modifiers on macOS 26.
2. Run the Step 4 geometry tests against that implementation.
3. Only if SwiftUI demonstrably produces a window-wide toolbar or moves/hides the
   toggle, use the macOS 26 AppKit split-item/top-region accessory mechanism described
   in WWDC25 session 310. The adapter may own native placement and bridge selection,
   but it must not draw material, background, borders, or a fake header.

Do not keep both implementations or an OS-version fallback. Keep the one verified
macOS 26 production path.

Rewrite the architecture assertions in this step (not Step 4): replace the
root-`.principal` requirement in
`testProductIdentityUsesNativeNoninteractivePlacements`
(`ArchitectureTests.swift:901-921`) with detail-pane ownership assertions and a
ban on any root custom header/toggle. Add
`.accessibilityIdentifier("usage.detail-pane")` to the detail container so
geometry tests (Step 4) have a deterministic locator — no detail-pane identifier
exists today (the current test measures the whole window,
`JackinDesktopUITests.swift:20`).

**Verify**:
`(cd native && rtk swift test -c release --filter ArchitectureTests)`
-> rewritten architecture tests find one native split ownership path,
detail-owned brand/Refresh, and zero root custom header/toggle.

### Step 3: Remove app-painted popover chrome

Remove `.background(.bar)` from the popover footer and let the real `NSPopover`,
Divider, buttons, and layout provide hierarchy. Do not replace it with another
material, color fill, blur, capsule, overlay, or custom footer renderer.

Expand the architecture guard to reject `.background(.bar)`, `.background(.material)`,
explicit Material variants, `glassEffect`, `GlassEffectContainer`, visual-effect
views, and project-defined glass helpers in production Desktop sources. Two known
guard gaps to close while doing it: the XCTest material guard
(`testProductionHasNoHandPaintedSystemMaterial`, `ArchitectureTests.swift:91-105`)
already scans both targets but its regex misses `.background(.bar)` — extend the
pattern; and `DesktopArchitectureLint` has no material check at all and scans
only `Sources/JackinDesktop` (`main.swift:16`, substring checks at `:153-157`) —
widen the lint to all of `native/Sources/` (excluding generated
`jackin_usage_ffi.swift`) and add the material pattern there, with no per-file
exemptions. Fixture-only
launch code may select OS appearance but may not paint an alternate surface.

**Verify**:
`rtk mise run desktop-test && (cd native && rtk swift test -c release --filter ArchitectureTests)`
-> lint harness and XCTest material guard both pass, and
`rtk rg -n 'background\(\.bar\)|glassEffect|GlassEffectContainer|VisualEffect' native/Sources --glob '!**/jackin_usage_ffi.swift'`
returns no production chrome matches (explain any unrelated system API match).

### Step 4: Replace superseded geometry and accessibility tests

Update real-host UI tests to prove:

- expanded sidebar owns the leading top-to-bottom split region; no full-width header
  pushes its list plane down;
- toggle exists exactly once, is far leading, and keeps its midpoint within 1 point
  across hide/show cycles;
- collapsed detail expands into released width;
- brand midpoint equals the detail pane midpoint within 2 points, not window
  midpoint — measured against the `usage.detail-pane` accessibility identifier
  added in Step 2;
- Refresh stays trailing in the detail region;
- selection/account/window frame survive hide, close, reopen;
- View menu, Control-Command-S, visible control, and accessibility action mutate the
  same native state;
- the toggle uses the standard sidebar SF symbol and exposes the native
  tooltip/help text;
- keyboard focus is preserved across a hide/show cycle (focus does not jump to a
  different control when the sidebar collapses or returns);
- VoiceOver labels change between Show Sidebar/Hide Sidebar;
- Full Keyboard Access reaches the toggle in native order;
- minimum 760x500 and normal 920x620 sizes do not clip controls behind traffic lights.

Do not require the old custom accessibility identifier if the system element cannot
carry one. Locate it by its unique native label/role and assert exactly one matching
button.

Replace the architecture test that requires root `.principal` text. Require detail
ownership and forbid root custom toggle/full-width header. Keep exact brand spelling.

**Verify**:
`rtk mise run desktop-test-ui`
-> all geometry, command, retained-context, keyboard, and accessibility assertions
pass against the real app host.

### Step 5: Validate native adaptations and clean temporary evidence

Using the canonical built app, visually inspect expanded/collapsed states at 760x500
and 920x620 in:

- light and dark appearance;
- Increased Contrast;
- Reduce Transparency;
- Clear and Tinted system styles where available.

Acceptance is structural: system sidebar/glass adapts naturally, no custom fallback
appears, brand remains detail-centered, toggle does not move, and controls remain
legible. Store temporary captures only in ignored `native/.build/visual-qa/final/`.
After review, delete the capture directory and restore any changed OS appearance/
accessibility settings. Do not add screenshots or logs to git.

**Verify**:
`rtk git status --short`
-> no screenshots/logs/prototypes appear; only intended source/tests/docs and existing
operator-owned files are listed. (This command verifies artifact hygiene only —
layout acceptance itself is the Step 4 automated tests plus this step's human
inspection; do not treat a clean `git status` as visual acceptance.)

### Step 6: Amend source-of-truth docs

Update ADR-011, native README, and native roadmap page to replace the old decision:

- the standard/native sidebar toggle is the single authority;
- sidebar owns the full leading structural region;
- detail owns centered `jackin❯ desktop` and trailing Refresh;
- stable collapsed reveal position is required;
- system Liquid Glass only; no explicit material/background;
- test expectations are detail-centered, not window-centered.

Do not describe an AppKit fallback if the final implementation is pure SwiftUI, or
vice versa. Document only the retained production path.

**Verify**:
`rtk cargo xtask roadmap audit && rtk cargo xtask docs repo-links`
-> both exit 0;
`rtk rg -n "removes the framework's automatic sidebar|system-supplied split-view toggle is removed" native/README.md docs/content/reference/adrs/adr-011-native-macos-usage-menu-bar.mdx`
returns no matches (those are the actual superseded sentences at
`adr-011…mdx:45` and `native/README.md:42`; the old grep pattern matched nothing
even before the edit).

## Test plan

- Unit: menu/responder state, one authority, retained visibility.
- Architecture: no custom toggle/header/material; exact brand; detail-pane ownership.
- UI: stable toggle coordinates, sidebar top/full-height geometry, detail expansion,
  detail-centered brand, retained selection/frame, native menu/shortcut parity.
- Accessibility: dynamic toggle label, one button, keyboard reachability, system
  adaptations.
- Visual: Clear/Tinted, light/dark, contrast/transparency, two window sizes; temporary
  evidence deleted.

Final gate:

```bash
rtk mise run desktop-format-check
rtk mise run desktop-lint
rtk mise run desktop-deadcode
rtk mise run desktop-test
rtk mise run desktop-test-ui
(cd native && rtk swift test -c release)
rtk cargo xtask roadmap audit
rtk cargo xtask docs repo-links
```

All commands exit 0.

## Done criteria

Machine-checkable — each box is decided by the named command exiting 0:

- [ ] `(cd native && swift test -c release --filter UsageSidebarToggleAuthorityTests)` —
  one toggle authority; menu/shortcut/control/AX share one state.
- [ ] `(cd native && swift test -c release --filter ArchitectureTests)` —
  detail-owned brand/Refresh, no root custom header/toggle, material guard incl.
  `.background(.bar)`.
- [ ] `mise run desktop-test-ui` — full Step 4 suite: sidebar full-height
  geometry, toggle stability across collapse, detail expansion, detail-centered
  brand (`usage.detail-pane` midpoint), retained selection/frame, keyboard focus
  preservation, VoiceOver labels, Full Keyboard Access, both window sizes.
- [ ] `rg -n 'toolbar\(removing: \.sidebarToggle\)|"usage\.sidebar-toggle"|UsageWindowNavigationState|background\(\.bar\)' native/Sources` — no matches.
- [ ] Step 6 grep for the superseded ADR/README sentences — no matches; docs
  gates exit 0.
- [ ] `git status --porcelain` — only in-scope files and `plans/README.md`.
- [ ] Step 5 visual matrix (Clear/Tinted, contrast, transparency) inspected by a
  human — recorded in the PR description, not committed (this one criterion is
  intentionally human).

## STOP conditions

- The standard SwiftUI path and the allowed AppKit split-item accessory path both fail
  stable far-leading toggle or detail-pane title geometry. Report measured frames and
  the minimal reproducer; do not paint custom chrome.
- Fix requires explicit material/glass/background, an OS compatibility lane, or a
  second toggle authority.
- Native View-menu state cannot be read from the real split view.
- Plan 003 refresh changes would be discarded or replaced by Swift-local semantics.
- Real-host UI tests cannot run on macOS 26/Xcode 26.

## Maintenance notes

Future toolbar actions belong to the pane whose content they affect. Do not attach
them to the root `NavigationSplitView` merely for convenience. Reviewers should inspect
actual expanded/collapsed frame assertions and appearance adaptations, not accept a
static screenshot. Final project cleanup must retain only the canonical app/source;
temporary capture directories are disposable.
