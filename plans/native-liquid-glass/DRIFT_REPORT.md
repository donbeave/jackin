# jackin❯ desktop native redesign drift report

**Recorded:** 2026-08-12  
**Baseline:** `48c0369c` on `main`  
**Scope:** Read-only reconnaissance before native design work. No production UI
source changed during this phase.

## Authority used for this report

The current repository state and running toolchain are authoritative for the
baseline. Existing HTML previews are product-structure and fixture inputs only.
They are not authority for material, geometry, typography, control construction,
window behavior, accessibility behavior, or final pixels.

Current Apple guidance establishes two distinct layers:

- Liquid Glass is a functional layer for navigation and controls.
- Content uses standard content surfaces and standard materials.
- Standard components own their platform material and behavior when available.
- Custom Liquid Glass must be scarce and justified by a missing standard
  component.

## Toolchain and project baseline

| Item | Current state | Drift |
|---|---|---|
| Host macOS | 26.5.2 (25F84) | Suitable for current Liquid Glass runtime review. |
| Xcode | 26.6 (17F113) | Current installed stable toolchain. |
| Swift | 6.3.3 | Newer than the package tools declaration. |
| Swift tools | 6.0 | `native/Package.swift` is behind the installed stable toolchain. |
| Deployment target | macOS 14 | Conflicts with the goal's latest-stable baseline and no legacy visual lane. |
| Application model | SwiftPM executable assembled into an app by `cargo xtask desktop` | Must be audited against the current native application baseline before implementation. |

Canonical operator commands already exist in `mise.toml` and delegate to Rust:
`desktop-build`, `desktop-test`, `desktop-verify`, `desktop-run`, and `desktop`.

## Runtime hosting architecture

### Menu-bar surface

- `JackinDesktopMain` creates `NSApplication` directly and runs as an accessory
  application.
- `StatusBarController` creates dynamic per-provider `NSStatusItem` instances.
- One transient `NSPopover` hosts `PopoverRoot` through
  `GlassPopoverHostingController`.
- The custom hosting controller clears AppKit popover/window backgrounds and
  disables the AppKit shadow so SwiftUI paints the panel and shadow.
- Right-click uses a retained native `NSMenu` with Open Usage Window, Refresh,
  and Quit commands.

The dynamic multi-item menu-bar requirement may justify a narrow AppKit host,
but the current boundary has not yet been documented against a demonstrated
current SwiftUI capability gap.

### Usage window

- `UsageWindowController` creates and retains a resizable `NSWindow`.
- `NSHostingController<UsageWindowRoot>` is used so SwiftUI toolbar items attach
  to a unified native `NSToolbar`.
- `UsageWindowRoot` uses `NavigationSplitView`, sidebar `List`, system toolbar
  items, and SwiftUI content views.
- Window creation, activation-policy switching, lifecycle, restoration name,
  and menu integration remain AppKit-owned.

The UI body is SwiftUI-first, but the window lifecycle boundary is broader than
the goal permits without a documented missing SwiftUI capability.

## Liquid Glass inventory

All explicit `glassEffect` calls are centralized in
`native/Sources/JackinDesktop/GlassFallbacks.swift`.

| Region | Current construction | Finding |
|---|---|---|
| Generic chrome tile | Custom `glassEffect(.regular)` with macOS 14 material fallback | No current caller was proven to need a custom component instead of a standard control. |
| Sidebar footer bar | Rectangular custom glass or `ultraThinMaterial` | Functional status chrome, but custom material may duplicate the system sidebar layer. |
| Entire popover panel | Opaque adaptive base, custom regular glass, border, clipping, and custom shadow | Glass spans the content shell and combines multiple depth recipes. Requires structural remediation, not constant tuning. |
| Floating footer/control island | Opaque control fill plus custom glass; caller adds accent stroke | Redundant fill/glass/stroke depth and custom button construction. |
| Usage sidebar | Clear on macOS 26 so system sidebar glass remains unstacked | Correct intent; macOS 14 material fallback creates the legacy visual lane rejected by this goal. |
| Content extension | `backgroundExtensionEffect` on macOS 26 | Intended to support system floating navigation; must be verified in the running app. |
| Scroll edges | Soft top and bottom effects on macOS 26 | Vertical only; horizontal provider/account overflow lacks equivalent native proof. |

No `GlassEffectContainer` exists. No current region has yet demonstrated a need
for one.

## Visible component inventory

### Status items and context menu

- Native: `NSStatusItem`, `NSStatusBarButton`, template `NSImage`, `NSMenu`, and
  `NSMenuItem`.
- Custom-composed: dual-line status title and provider mark loading.
- No status-item glass surface exists.

### Menu-bar popover

- Native: `NSPopover`, `ScrollView`, `Button`, `ProgressView`, and text/image
  primitives.
- Custom-composed: brand header, Overview/Providers segmented control, horizontal
  provider navigation, provider logo plates, account selector, provider header,
  metadata groups, overview provider/account groups, quota rows, meters, refresh
  controls, external-link control, and footer action.
- Custom surfaces: full popover glass shell and footer glass island.
- Content cards use custom rounded fills, strokes, fixed radii, and CSS-derived
  hierarchy rather than native content composition.

### Usage window

- Native: `NSWindow`, `NSHostingController`, `NavigationSplitView`, sidebar
  `List`, sections, unified toolbar, toolbar button, and scroll views.
- Custom-composed: sidebar provider rows, selection wells, account rail, account
  buttons, mini meters, overview header, overview inventory container, provider
  header, metadata container, quota list, quota rows, logo plates, and external
  usage-page control.
- Content surfaces use custom rounded fills and hairline strokes. They are not
  Liquid Glass, but still encode HTML-derived geometry.

### Settings

- Primarily native `Form`, `Section`, `Picker`, `Toggle`, and `Slider` controls.
- Copy still describes menu-bar Liquid Glass chip capsules although the shipped
  status items intentionally have no glass chips.

## State and fixture coverage

`PresentationStore.applyQIFixture` can inject Rust-shaped presentation rows, but
the visual harness currently provides one principal fixture family:

- Seven catalog glance rows.
- Three materialized provider surfaces: OpenAI, Anthropic, and Amp.
- Multi-account OpenAI and Anthropic examples.
- Healthy, warning, danger, and one depleted percentage.
- One deterministic date/time family.

Required coverage not represented as independently switchable runnable fixtures:

- No detected providers.
- One provider and one account.
- Maximum expected providers/accounts/content.
- Stale data.
- Active refresh as a complete application state.
- Provider error and recovery.
- Long provider/account labels.
- Minimum content.
- Explicit loading state.
- Expanded and minimum window configurations.

The app launch environment supports an isolated smoke data directory, not a
general deterministic fixture selector for design and visual QA.

## Visual and accessibility QA drift

The existing `DesktopVisualSnapshotHarness` is useful structural evidence but
does not satisfy the requested native QA contract:

- It captures some real `NSPopover` and `NSWindow` hosts.
- It prefers `screencapture -l <window-id>` and falls back to CGWindow or view
  bitmap capture.
- It also renders hosted/offscreen SwiftUI scenes that cannot approve live
  Liquid Glass.
- It records blocked dark-toolbar and sidebar-compositing cases.
- It does not exercise the complete app state matrix.
- It has no `performAccessibilityAudit`, XCUITest application driver, or
  accessibility-tree interaction harness.
- It does not toggle and restore Reduce Transparency, Increase Contrast, or
  Reduce Motion.
- Visible keyboard focus, full focus order, active/inactive windows, and
  key/non-key windows are not proven.

Passing architecture and parity harnesses proves static ownership and data
projection rules, not final native appearance or interaction.

## Authority and contract contradictions

### HTML still claims final visual authority

- `plans/previews/desktop-ui/SPECIFICATION.md` calls the directory the durable
  visual source of truth and rejects native pixels as authority.
- `plans/previews/desktop-ui/index.html` labels itself the visual source of
  truth.
- The desktop roadmap calls for direct HTML-to-running-app alignment.
- Swift comments repeatedly name HTML as the source of truth.
- Architecture tests and lints enforce HTML-specific colors, radii, sizes,
  strokes, and component anatomy.

These contracts directly conflict with the new authority order and must be
replaced after a native direction is approved.

### Latest-only versus compatibility lane

- `native/Package.swift` targets macOS 14.
- `GlassFallbacks.swift` contains a complete pre-macOS-26 material lane.
- `native/README.md` explicitly documents macOS 14+ compatibility.

This conflicts with the requested current stable macOS baseline and prohibition
on preserving a second handcrafted visual lane.

### Provider catalog

- `native/AGENTS.md` names the eight-entry host universe, which includes
  OpenCode.
- Rust separately defines the desktop contract as the seven-entry
  `DESKTOP_PROVIDER_ORDER` and intentionally excludes OpenCode.
- Provider marks, usage links, preview fixtures, and the primary native visual
  fixture follow that seven-provider desktop contract.

Rust remains the catalog authority. Design work must preserve the explicit
desktop order instead of promoting the broader host universe into Swift UI.

### Product and delivery artifacts

Older desktop research discusses spend/history surfaces and sequential stacked
pull requests. Current binding rules require limits-only presentation and
exactly one branch/one pull request for this goal. The older research is not an
implementation contract.

## Phase-0 conclusion

The current application is a functional native baseline, not a valid final
Liquid Glass architecture. Root problems are structural:

- HTML-derived constants and tests currently own visual decisions.
- Custom composition replaces standard native control behavior in key regions.
- Custom glass is applied to broad shells and combined with redundant fills,
  strokes, and shadows.
- The deployment target preserves a legacy visual lane.
- Fixture and QA infrastructure cannot prove the required state and
  accessibility matrix.

Production Swift must remain unchanged until the operator approves a native
design alternative. Phase 1 must use the mandatory `tailrocks-macos-design`
workflow and remain artifact-only.
