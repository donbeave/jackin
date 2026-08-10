# Liquid Glass → jackin❯ desktop (Apple-first)

HTML is a **visual proxy** (blur + translucency). Native implements real Liquid Glass with **SwiftUI** APIs gated in `GlassFallbacks.swift`.

## Required Apple reading

| Document | URL |
|---|---|
| **Liquid Glass** | https://developer.apple.com/documentation/technologyoverviews/liquid-glass |
| **Adopting Liquid Glass** | https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass |
| **SwiftUI** (UI stack) | https://developer.apple.com/documentation/technologyoverviews/swiftui |
| Applying Liquid Glass to custom views | https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views |
| Landmarks sample (LG) | https://developer.apple.com/documentation/SwiftUI/Landmarks-Building-an-app-with-Liquid-Glass |
| HIG Materials | https://developer.apple.com/design/human-interface-guidelines/materials |
| WWDC25 Meet Liquid Glass | https://developer.apple.com/videos/play/wwdc2025/219/ |
| WWDC25 Build a SwiftUI app with the new design | https://developer.apple.com/videos/play/wwdc2025/323/ |

**Decisions:** `plans/desktop-design-decisions.md` §6.0 **LG-A1–LG-A12**, **AR-5**, **AR-6**, **VS-1**.

## Apple principles (summary)

1. **Navigation layer = Liquid Glass** — sidebars, toolbars, menus, popovers, floating controls sit above content and may refract what is underneath.  
2. **Content layer ≠ Liquid Glass** — lists, cards, meters, long text use standard materials so hierarchy stays clear.  
3. **Hierarchy over decoration** — separate nav structure from content more clearly than before.  
4. **Sparing custom glass** — system `NavigationSplitView`, toolbars, lists first; custom `glassEffect` only for essential chrome, always via `GlassFallbacks`.  
5. **No glass-on-glass stacks** — one chrome glass layer.  
6. **Scroll edge effects** — content dissolves under floating chrome (soft by default).  
7. **Edge-to-edge / ambient under sidebar** — content can extend under the glass sidebar so glass has something to refract.  
8. **Toolbar grouping** — related actions together on the glass toolbar surface.  
9. **Selective tint** — color for function (jackin phosphor on selection/CTA/high metrics only).  
10. **Accessibility** — honor Reduce Transparency / Reduce Motion via material fallbacks.

## jackin❯ surface map

| Surface | Layer | Native (SwiftUI) | HTML proxy |
|---|---|---|---|
| Status menu bar items | Template mono (not glass chips) | Transparent status item | Transparent dual stack |
| Glance popover shell | **Glass nav** | `GlassFallbacks.panelSurfaceBackground` | `.pop` blur + hairline |
| Popover content / meters | **Content** | Standard fills | `--glass-inset` cards |
| Popover footer CTA | **Glass control** | Glass capsule via fallbacks | `.cta-btn` |
| Usage sidebar | **Glass nav** | `NavigationSplitView` + `sidebarBackground()` | Floating `.side` |
| Usage toolbar / title | **Glass nav** | `.toolbar` + system LG | Continuous `.titlebar` |
| Usage detail | **Content** | `windowContentBackground` + cards | Solid `.main` + `.limit-list` |
| Context menu | **Glass nav** | System menu | `.ctx-menu` |

## SwiftUI implementation rules

```
// Allowed glass entry point — only GlassFallbacks.swift
.glassEffect(.regular, in: …)   // macOS 26+
// Fallback: .ultraThinMaterial / .thinMaterial / window background

// Structure
NavigationSplitView { sidebar } detail: { content }
  .toolbar { ToolbarItemGroup / primary actions }
// Data: UniFFI / PresentationStore only — no invented %
```

- **Do not** call `glassEffect` outside `GlassFallbacks.swift` (enforced by architecture tests).  
- **Do not** put glass behind provider detail text blocks.  
- **Do** use continuous corner radii consistent with `GlassFallbacks` constants.

## HTML craft rules (visual SoT until native matches)

1. Transparent window shell so ambient stage bleeds under glass.  
2. Continuous glass titlebar (Safari-like — no hard four-pane chrome).  
3. Floating glass sidebar (soft depth, no hard vertical wall).  
4. Solid content + single limit list (no glass data tables, no tile+bucket dupes).  
5. Provider selection ≠ account selection (LG-A3 hierarchy).  
6. Soft scroll edge dissolves under chrome.

## Secondary references (inspiration only — not binding)

Telegram / third-party “liquid glass” skins may inspire density, **not** materials policy.  
When they conflict with Apple docs, **Apple wins**.

## Product law (always)

Limits only · no spend/trends · Rust owns numbers · phosphor accent restraint · brand `jackin❯ desktop`.
