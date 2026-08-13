# Phase 2 Liquid Glass audit

Status: **audit and production remediation complete; no accepted exception**

The inventory below records the pre-remediation Phase 2 baseline. The runnable
A1 concept now removes every explicit custom-glass surface named here and passes
the architecture, parity, native UI, accessibility, build, and
bundle-verification gates.

Phase 2 audit mode was read-only. This report inventories the approved A1 design
and pre-remediation native implementation, then records the concept outcome. It
does not authorize full production work.

## Baseline

| Item | Evidence | Audit consequence |
|---|---|---|
| Current deployment target | `native/Package.swift` and `crates/jackin-xtask/src/desktop.rs`: macOS 14.0 | Every macOS 26 symbol currently needs an availability guard, but this compatibility lane conflicts with the approved latest-only redesign. |
| Selected deployment target | A1 objective and project-setup policy: macOS 26.0 | Phase 3 must remove pre-26 visual branches rather than preserve fallback architecture. |
| Installed shipping toolchain | Xcode 26.6 (17F113), Swift 6.3.3, macOS 26.5 SDK | Compile authority for the concept proof. Apple’s Xcode 26.6 release notes also identify Swift 6.3 and the macOS 26.5 SDK. |
| Current runtime | macOS 26.5.2 (25F84) | Can render shipping macOS 26 Liquid Glass, but is behind the current macOS 26.6.1 patch release. This limits final latest-runtime evidence until the host is updated. |
| Forward SDK | No Xcode 27 installation under `/Applications` | No forward-validation capture/build is presently possible. No macOS 27 API may enter the shipping concept. |

Sources: [Xcode 26.6 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_6-release-notes),
[macOS 26.6 release notes](https://developer.apple.com/documentation/macos-release-notes/macos-26_6-release-notes),
and [Apple security releases](https://support.apple.com/en-us/100100).

## Decision-order result

A1 stops at step 1 or step 3 of the Liquid Glass decision order for every
region:

1. standard component; or
2. composition of standard components.

No approved region reaches custom-bar or custom-glass steps. Therefore:

- custom `glassEffect` count required by A1: **0**;
- `GlassEffectContainer` count required by A1: **0**;
- custom glass tint count required by A1: **0**;
- custom glass per-surface acceptance records required by A1: **0**, once the
  current invalid surfaces are removed.

## Approved A1 region audit

| Region | Layer | Approved owner | Glass source | Audit verdict |
|---|---|---|---|---|
| macOS menu bar | FUNCTIONAL / structural | macOS | automatic | Pass by design. |
| Provider status item | FUNCTIONAL / structural | `NSStatusItem`, `NSStatusBarButton` | automatic | Pass. Dynamic item count proves the narrow AppKit boundary. |
| Status-item mark and values | CONTENT inside native control | `NSImage`, attributed title | none beyond owning control | Pass if native metrics and accessibility label remain. |
| Status-item context menu | FUNCTIONAL / transient | `NSMenu`, `NSMenuItem` | automatic | Pass. Keep system rendering and keyboard behavior. |
| Popover host, arrow, shadow | FUNCTIONAL / transient | `NSPopover` | automatic | Pass only after custom host clearing, shell, shadow, and material are deleted. |
| Popover provider identity | CONTENT | `Label` composition | none | Pass by design. |
| Popover account selection | FUNCTIONAL control | menu-style `Picker` | control-owned | Pass by design; current custom account strip fails. |
| Popover metadata | CONTENT | `LabeledContent`, `Section` | none | Pass by design; current card is superseded. |
| Popover quota rows | CONTENT | native `List`/`Section`, `ProgressView` | none | Pass by design; current cards and custom meters are superseded. |
| Popover Refresh/Open Usage | FUNCTIONAL controls | native `Button` | control/host-owned | Pass by design; no detached glass island or custom bezel. |
| Popover empty/loading/error | CONTENT plus native actions | `ContentUnavailableView`, `ProgressView`, `Button` | none | Pass by design. |
| Usage window/titlebar | FUNCTIONAL / structural | native window and toolbar | automatic | Pass when `jackin❯ desktop` uses native `.principal` placement without a custom titlebar, background, or material. |
| Usage toolbar | FUNCTIONAL / structural | `.toolbar` / `NSToolbar` | automatic | Pass if every item has a menu equivalent and system overflow owns collapse. |
| Usage sidebar | FUNCTIONAL / structural | `NavigationSplitView`, sidebar `List` | automatic | Pass after custom background/footer/selection wells are removed. |
| Overview table | CONTENT | `Table` | none | Pass by design; current card list is superseded. |
| Provider detail | CONTENT | `List` or grouped `Form`, `Section` | none | Pass by design; current rounded card stack is superseded. |
| Detail account selection | FUNCTIONAL control | menu-style `Picker` | control-owned | Pass by design; current sidebar account rail is superseded. |
| Detail quota progress | CONTENT | `ProgressView(value:total:)` | none | Pass by design; current custom capsules are superseded. |
| Menus, picker menu, blocking alert | FUNCTIONAL / transient | native menu/sheet/alert | automatic | Pass by design. |
| Settings form | CONTENT with native controls | `Form`, `Section`, `Picker`, `Toggle` | control-owned | Pass if stale glass copy is removed. |

## Pre-remediation explicit glass inventory

At the Phase 2 baseline, all explicit calls were in `GlassFallbacks.swift`.

| Surface/helper | Caller | Current construction | Finding |
|---|---|---|---|
| `chromeBackground` | No caller | `.glassEffect(.regular)` with fixed radius 12; pre-26 material branch | Dead custom-glass API. Remove. |
| `footerBarBackground` | Usage sidebar footer | Explicit rectangular `.glassEffect(.regular)` inside a system Liquid Glass sidebar | Hard failure: independently nested structural glass. Replace footer with native sidebar/content placement or remove it. |
| `panelSurfaceBackground` | Entire popover root | Solid base + explicit regular glass + stroke, fixed radius 20 | Hard failure: custom background on `NSPopover`, content-shell glass, duplicate material, fixed adjacent radius. Delete the surface. |
| `floatingChromeIsland` | Popover Open Usage footer | Opaque control fill + explicit regular glass, fixed radius 12; caller adds phosphor stroke | Hard failure: nested glass inside custom popover glass; duplicate depth; standard `Button` is sufficient. |

### Custom popover host

`GlassPopoverHostingController` and `StatusBarController.togglePopover` clear
the hosting view and popover window, disable the native shadow, then make the
SwiftUI shell draw replacement material and shadow.

- **Rule:** popovers are standard transient components; remove custom
  backgrounds and effects from their content.
- **Mechanism:** the custom surface overlays/replaces system material, so native
  appearance adaptation, clear/tinted preference, inactive behavior, and
  accessibility substitutions no longer own the result.
- **Remediation:** use ordinary `NSHostingController<PopoverRoot>` in the real
  `NSPopover`; do not mutate opacity, background color, or shadow.

## Mechanics checks

### Container batching

- Current: no `GlassEffectContainer` or `NSGlassEffectContainerView`.
- Violation: the popover shell and footer island are independent nested effects.
- A1 resolution: delete both. Do not add a container because A1 has no custom
  glass cluster.

### Modifier order

- `glassEffect` follows each helper's fill, but callers add clipping, strokes,
  and shadows outside the material helper. This creates an app-owned composite
  rather than a coherent system surface.
- `backgroundExtensionEffect()` currently follows the detail background and has
  no later overlay in that chain. Its local modifier order is not proven wrong.
- A1 resolution: delete all explicit glass modifier chains. Apply any retained
  background extension at the window content root before overlays; prove it from
  a running window.

### Corner concentricity

- Fixed glass radii: 20 and 12 points.
- Related fixed selection/content radii: 14, 12, 10, 8, and 7 points.
- No radius derives from its system container.
- Violation mechanism: window and popover radii vary with platform/runtime;
  literals cannot remain concentric.
- A1 resolution: standard controls own their shapes. No custom glass corner
  remains. Content grouping should use native sections rather than replace the
  fixed constants with different constants.

### Tint count

- No explicit `.tint` is applied to the four glass effects.
- Custom phosphor fills/strokes color multiple actions, selections, brand plates,
  and progress tracks. This is not technically glass tint, but it competes with
  system accent and makes several controls read as primary.
- A1 resolution: native selection/control accent owns functional emphasis;
  provider color is content identity only. Adaptive jackin❯ phosphor is allowed
  on healthy quota progress because the meter is content, not glass; textual
  values preserve non-color meaning. No prominent toolbar or popover action is
  proposed.

### Scroll-edge behavior

- Current `SoftScrollEdges` forces `.soft` at both top and bottom on every
  popover, Overview, and provider-detail scroll view.
- Rule: edge effects exist only where content scrolls behind floating controls;
  prefer automatic and one effect per relevant edge/pane.
- Mechanism: forcing bottom effects where no floating bottom chrome exists turns
  a structural separator into decoration and can weaken dense text/pinned-header
  legibility.
- A1 resolution: remove the centralized forced-soft modifier. Begin with native
  automatic behavior; use hard only after rendered evidence proves a pinned
  table header or free-floating title needs it.

### Background extension

- Current: one `backgroundExtensionEffect()` on the Usage detail group.
- The one-instance count is acceptable, but necessity and placement are not
  proven in the running A1 structure.
- A1 resolution: retain only if the native sidebar visibly requires content
  extension. Otherwise delete it. Never use it to make content look glassy.

## Anti-pattern checks

| Anti-pattern | Current result | Rule and mechanism | A1 disposition |
|---|---|---|---|
| Glass in content | Fail | Entire popover shell contains readable content on the same app-owned glass plane, destroying content/control separation. | Delete shell glass; system popover owns transient material. |
| Glass-on-glass | Fail | Footer effect samples already refracted shell output; Usage footer adds glass inside native sidebar glass. | Delete both footer effects. |
| Custom background on popover/split view | Fail | Custom background blocks or replaces system material and adaptation. | Delete popover shell and sidebar background/footer. |
| Hard-coded radii | Fail | Literal radius cannot track system container geometry. | Use standard components; no custom glass shape. |
| Tint abuse | Needs remediation | Multiple phosphor control/selection treatments weaken one-primary-action and system-accent hierarchy. | Remove custom functional tint; retain provider identity plus adaptive phosphor on healthy native quota progress only. |
| Accessibility settings ignored | Fail | No Reduce Transparency, Increase Contrast, Reduce Motion, or differentiate-without-color branches/evidence exist for custom surfaces. | Delete custom glass; validate standard components live. |
| Per-view unbatched effects | Fail | Four helper effects exist without a container; two nest in the same popover. | Delete all effects; no container needed. |
| iOS-shaped macOS UI | Fail | Segmented root, horizontal provider tabs, account pills, card stacks, and detached CTA form a phone-screen hierarchy. | A1 replaces with focused popover and list-detail window. |
| Wrong modifier order | Superseded | Current composite distributes appearance outside material helper; no custom surface can be accepted from this chain. | Delete the chain. |
| Compatibility-key strategy | Pass | No `UIDesignRequiresCompatibility` key exists. | Keep absent. |
| Mid-merge spacing | Not applicable | No container/morph system exists. | No custom glass cluster proposed. |

### Performance framing

No numeric glass budget is claimed. Current custom effects cause independent
backdrop passes, with the popover shell covering a large region. Deletion is the
performance remediation. Later profiling validates the running result; it does
not justify keeping an invalid layer.

## Availability checks

| Symbol | Shipping availability | Current guard | Result |
|---|---:|---|---|
| `glassEffect` / `Glass.regular` | macOS 26.0 | `#available(macOS 26, *)` | Compiles for current 14 target; removed under A1. |
| `backgroundExtensionEffect()` | macOS 26.0 | guarded | Compiles; retain only with structural proof. |
| SwiftUI `scrollEdgeEffectStyle` | macOS 26.0 | guarded | Compiles; forced soft policy is rejected. |
| `NSScrollEdgeEffectStyle` | macOS 26.1 | not used | No issue. |
| macOS 27 concentric/interactive AppKit APIs | macOS 27 | not used | Keep absent from shipping proof. |
| Cross-platform invalid APIs | not macOS | not used | `glassBackgroundEffect`, custom toolbar overflow, and iOS button configurations are absent. |

After the target moves to macOS 26.0, the pre-26 branches become dead by policy
and must be removed. A guard is not a reason to retain a rejected visual lane.

## Accessibility and rendered acceptance gate

Every current custom glass surface fails the Liquid Glass acceptance gate
because no authoritative running-app evidence covers:

- clear and tinted Liquid Glass preference;
- Reduce Transparency;
- Increase Contrast;
- Reduce Motion and Differentiate Without Color;
- active/key and inactive/non-key window behavior;
- accent/highlight variations;
- Full Keyboard Access/focus ring;
- VoiceOver/Voice Control;
- minimum size and toolbar overflow;
- 1×/2× displays and display movement;
- bright/dark/high-frequency backgrounds.

The existing snapshot harness cannot cure these failures: detached/offscreen
glass is not evidence, and blocked/transparent placeholders cannot pass.

A1 deliberately removes all custom glass. Phase 4 must still prove system-owned
popover/sidebar/toolbar behavior across the required state matrix from the
running application.

## Phase 3 remediation boundary

The runnable concept must:

1. use the real `NSPopover` without `GlassPopoverHostingController` or manual
   window chrome mutation;
2. delete all explicit `glassEffect` helpers and callers;
3. remove custom popover/sidebar/toolbar backgrounds, fixed glass shapes,
   custom shadows, and decorative separators;
4. use native account picker, buttons, progress controls, sidebar, table,
   list/form sections, toolbar, and menus;
5. start with automatic scroll-edge behavior;
6. keep content on the standard content plane;
7. add no CUSTOM component without a new operator-approved contract.

This audit has no accepted exception.

## Production reconciliation

Production removed every explicit glass helper, custom popover host mutation, app-owned material, custom content card, custom progress track, forced scroll-edge effect, and pre-macOS-26 visual lane identified above. Current source scans report zero `glassEffect`, `GlassEffectContainer`, `NSGlassEffectView`, `NSVisualEffectView`, material, blur, or custom-glass uses in application sources. The real app evidence records system `NSPopover`, `NavigationSplitView`, toolbar, sidebar, table, list/form, picker, button, and progress behavior across Light, Dark, active, inactive, minimum, default, expanded, collapsed, long-content, loading, stale, error, partial-failure, and recovery states.

The generated jackin❯ wordmark is a noninteractive sidebar-footer content asset. Adaptive phosphor appears only on healthy native quota progress. System accent owns selection and controls; warning/danger remain textual plus system semantic color. [Final evidence](evidence/final/) records the remaining host-only accessibility captures and operator-owned clear/tinted observations without granting an exception to material architecture.
