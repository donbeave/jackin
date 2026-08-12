# Native component map

Status: **approved A1 component map; runnable proof pending**

Classification:

- **NATIVE** — a standard AppKit or SwiftUI control owns behavior and rendering.
- **NATIVE-COMPOSED** — product-specific composition made only from native
  controls, text, images, layout, and semantic styles.
- **CUSTOM** — a new control or rendering primitive with product-owned behavior.

The proposed baseline has **no CUSTOM visible region**. If selection introduces
one, implementation is blocked until that region has a custom-component
contract covering semantics, states, input, focus, keyboard, accessibility,
appearance, reduced motion/transparency, and testing.

## Menu-bar status surfaces

| Visible region | Class | Exact platform component | Allowed adaptation | Forbidden replacement |
|---|---|---|---|---|
| Provider status item | NATIVE | `NSStatusItem` and `NSStatusBarButton` | Dynamic item count from Rust-detected providers; SwiftUI-rendered or attributed label content | Custom menu-bar window, canvas-drawn hit target |
| Provider mark | NATIVE-COMPOSED | Template `NSImage`/SwiftUI `Image` in the status button | Existing provider asset, template rendering, native accessibility hiding when adjacent label names it | Emoji, colored badge, hand-drawn button bezel |
| Burn-first value label | NATIVE-COMPOSED | `Text`/`NSAttributedString` placed in `NSStatusBarButton` | Rust-owned maximum-three values and ordering; system menu-bar typography | Custom pill, progress ring, graph, trend arrow |
| Status-item interaction | NATIVE | `NSStatusBarButton` target/action and native secondary-click handling | Primary click opens provider context; secondary click opens menu | Gesture-only transparent overlay |
| Context menu | NATIVE | `NSMenu`, `NSMenuItem`, native separators | Open Usage, Refresh, Settings when relevant, Quit | SwiftUI imitation menu, icon on every command, custom shadow/background |

### Proven AppKit boundary

The product creates a runtime-varying number of simultaneous provider status
items. SwiftUI `MenuBarExtra` scenes are statically declared and do not express
that dynamic scene count. `NSStatusItem` is therefore a narrow, documented
AppKit boundary unless Phase 2 API probing proves a current native SwiftUI
replacement. The label content and all transient content remain SwiftUI-first.

## Menu-bar popover

| Visible region | Class | Exact platform component | Allowed adaptation | Forbidden replacement |
|---|---|---|---|---|
| Transient host and arrow | NATIVE | `NSPopover` with `.transient` behavior | Size bounded by approved design and available screen; SwiftUI content via `NSHostingController` | Borderless `NSPanel`, manually positioned window, custom arrow |
| Popover material/shadow | NATIVE | System rendering owned by `NSPopover` | None beyond system appearance | `glassEffect`, `NSVisualEffectView`, custom blur, background clearing, custom stroke/shadow |
| Content viewport | NATIVE | SwiftUI `ScrollView` or `List` | Small control metrics; native scrolling and indicators | Fixed-height clipping, nested horizontal carousels |
| Provider identity | NATIVE-COMPOSED | `Label` built from `Image` and `Text` | Rust-owned name, existing provider mark, native title text style | Header card, decorative logo button |
| Refresh state | NATIVE-COMPOSED | `ProgressView` plus `Text` | Rust-owned status and last-good value; indeterminate progress while active | Rotating custom glyph, custom animation loop |
| Account selector | NATIVE | `Picker(selection:label:content:)` with menu style | Present only for multiple accounts; Rust order and labels | Account pill strip, custom tab rail |
| Plan/status metadata | NATIVE-COMPOSED | `LabeledContent`, `Text`, optional `Section` | Rust-owned labels and values | Metadata card, badge cloud |
| Quota/detail list | NATIVE-COMPOSED | `List`/`Section`, `LabeledContent`, native `ProgressView(value:total:)` | Rust row order, semantic system colors, multiline reset text | Glass/card per row, custom progress track, chart or sparkline |
| Empty/error state | NATIVE-COMPOSED | `ContentUnavailableView` with native `Button` actions | Exact Rust-owned message and permitted recovery action | Illustration-heavy onboarding, fabricated zero state |
| Refresh action | NATIVE | `Button` with system refresh symbol and `ProgressView` state | Native help, keyboard focus, disabled state during invalid operation | Invisible shortcut button, custom glass capsule |
| Open Usage action | NATIVE | `Button` | Opens with current provider/account context | Floating glass footer island |

## Usage window chrome and navigation

| Visible region | Class | Exact platform component | Allowed adaptation | Forbidden replacement |
|---|---|---|---|---|
| Window chrome | NATIVE | `NSWindow` today; SwiftUI `Window` scene if Phase 2 proves lifecycle parity | Standard title, traffic lights, restoration, minimum/default size | Borderless window, custom traffic lights, custom rounded shell |
| Title and represented state | NATIVE | Native window title/titlebar APIs | `Usage` as the window title; provider context stays in content | Branded principal-title capsule |
| Root navigation | NATIVE | SwiftUI `NavigationSplitView` | Two-column adaptive layout; native sidebar collapse | Hand-built split panes or dividers |
| Sidebar | NATIVE | `List(selection:)` with sidebar style and `NavigationLink(value:)`/selection values | Overview plus Rust-ordered providers; system accent and selection | Rounded custom selection backgrounds, account chips |
| Sidebar rows | NATIVE-COMPOSED | `Label` with provider `Image` and `Text` | Existing provider mark and Rust label | Glass rows, hover-only action buttons |
| Toolbar | NATIVE | SwiftUI `.toolbar`, `ToolbarItem`, native sidebar toggle and system overflow | Refresh and contextual provider link; system grouping | Custom top bar, manual overflow menu, explicit glass modifiers |
| Toolbar refresh | NATIVE | `Button` and `ProgressView` state | View-menu Command-R equivalent, disabled/help/accessibility states | Detached custom refresh capsule |
| App menu bar | NATIVE | SwiftUI `Commands` or standard `NSMenu` hierarchy | Standard App/File/Edit/View/Window/Help ordering and shortcuts | Missing standard menus, custom in-window command strip |

The window-lifecycle owner is intentionally left for Phase 2 project/API audit.
The visible contract is native either way; retaining an AppKit controller is not
permission to hand-style the window.

## Usage Overview

| Visible region | Class | Exact platform component | Allowed adaptation | Forbidden replacement |
|---|---|---|---|---|
| Overview content | NATIVE | SwiftUI `Table` | One provider-account record per row; native selection, column sizing, sorting only when Rust semantics permit | Metric-card grid, dashboard canvas |
| Identity columns | NATIVE-COMPOSED | `TableColumn`, `Label`, `Text` | Provider mark, provider/account labels | Custom avatar cell or glass badge |
| Plan/status column | NATIVE-COMPOSED | `TableColumn` and `Text` | Rust-owned string; system semantic color plus text | Invented severity score |
| Remaining-limit column | NATIVE-COMPOSED | `TableColumn`, `Text`, native `ProgressView` where space permits | Rust-owned glance/detail value | Sparkline, donut, aggregate cost rank |
| Reset column | NATIVE-COMPOSED | `TableColumn` and `Text` | Rust-owned reset text | Swift-derived countdown semantics |
| Refresh-state column | NATIVE-COMPOSED | `TableColumn`, `ProgressView`, `Text` | Rust-owned state; accessible status | Animated decorative indicator |
| Empty/error overlay | NATIVE-COMPOSED | `ContentUnavailableView` | Refresh or Settings action when valid | Custom full-window illustration |

## Usage provider detail

| Visible region | Class | Exact platform component | Allowed adaptation | Forbidden replacement |
|---|---|---|---|---|
| Detail scroller | NATIVE | `List` or `Form` with native `Section` | System insets and scrolling; readable maximum content measure | Fixed content canvas, nested scroll views |
| Provider heading | NATIVE-COMPOSED | `Label`, `Text` | Provider mark and Rust label | Hero card or oversized app icon |
| Account selector | NATIVE | Menu-style `Picker` | Multiple accounts only; current selection restored when valid | Horizontal account rail, custom segmented pills |
| Metadata | NATIVE-COMPOSED | `Section` and `LabeledContent` | Rust-owned label/value pairs | Metadata cards, colored status chips |
| Quota/detail rows | NATIVE-COMPOSED | `Section`, `LabeledContent`, native `ProgressView(value:total:)`, `Text` | Rust order and values; native accessibility | Per-row material, custom progress, graph, cost/trend display |
| Provider-page action | NATIVE | `Link` or `Button` opening the Rust-mapped URL | Native external-link semantics and help | Raw URL text as primary UI |
| Local error/retry | NATIVE-COMPOSED | Inline `ContentUnavailableView` or `Section` with `Button` | Rust-owned error; preserves last-good rows | Modal alert for a recoverable local failure |

## Settings and secondary presentation

| Visible region | Class | Exact platform component | Allowed adaptation | Forbidden replacement |
|---|---|---|---|---|
| Settings window | NATIVE | SwiftUI `Settings` scene or native settings-window host | Standard Command-comma behavior and restoration | Custom tab/window chrome |
| Settings content | NATIVE | `Form`, `Section`, `Picker`, `Toggle` | Existing preference model only | Design-choice preferences, card grid |
| Alerts | NATIVE | `.alert` or `NSAlert` only for blocking conditions | Exact source-owned message and native buttons | Custom modal card |
| Help text/tooltips | NATIVE | `.help`, accessibility labels/values/hints | Full value for visually truncated content | Custom hover bubble |

## Custom-component ledger

None proposed.

Provider marks and product-specific view compositions are assets/compositions,
not custom controls. If later implementation needs a custom progress, picker,
table, popover shell, navigation bar, toolbar, menu, focus model, or glass view,
that is design drift and must return to operator review before code lands.

## Expected deletion candidates after approval

These are not implementation instructions yet. They identify architecture that
the native map supersedes:

- custom popover shell, border, background clearing, and shadow;
- custom Overview/Providers segmented control and provider tab strip;
- custom account pills/rails;
- content cards and per-row rounded backgrounds;
- custom progress tracks;
- detached glass footer action island;
- branded principal toolbar title;
- hidden shortcut-only buttons and duplicated command routing.
