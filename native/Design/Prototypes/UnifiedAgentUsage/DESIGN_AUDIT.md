# Liquid Glass design audit — Unified Agent Usage prototype

Date: 2026-08-20

## Platform baseline

| Contract | Value |
|---|---|
| Minimum deployment target | macOS 26.0 (`Package.swift`) |
| Shipping SDK / Xcode | macOS SDK 26.5 / Xcode 26.6 (17F113) |
| Forward-validation SDK / Xcode | Not configured; macOS 27 symbols are forbidden |
| Forward-only fallback | Keep the macOS 26 standard component; add guarded 27 behavior only in a dedicated validation lane |

Local probes reported Swift 6.3.3 and an arm64 macOS 26.0 target.

## Supplied-artifact inventory

| Artifact | Audit use |
|---|---|
| `Package.swift` | Deployment target and resource contract |
| `Brand.swift` | Adaptive color, type, spacing, identity, provider marks |
| `ProtoShell.swift` | AppKit window, split view, toolbar, status items, popover, menus |
| `UsageWindowViews.swift` | Sidebar, overview cards, shared provider detail, meters, toolbar control |
| `PopoverAndSettingsViews.swift` | Popover and Settings native hosts, popover action cluster |
| `ProtoStore.swift` | State, navigation, refresh, semantic status colors |
| `Fixtures.swift` | F00–F29 state, scale, localization, RTL, and accessibility fixtures |
| `Regions.md` / `SIGNOFF.md` | Structural region and operator acceptance contracts |

No embedded repository instruction changed the skill decision order.

## Layer classification

| Region | Layer | Component | Glass source |
|---|---|---|---|
| Window title bar and toolbar | FUNCTIONAL / structural | `NSWindow` + `NSToolbar` | Automatic system material |
| Sidebar | FUNCTIONAL / structural | `NSSplitViewController` sidebar + SwiftUI `List(.sidebar)` | Automatic system material |
| Sidebar wordmark | FUNCTIONAL / structural identity | Image inside sidebar plane | Sidebar material only; no effect |
| Overview stage and provider cards | CONTENT | `ScrollView` + adaptive card grid | Opaque semantic content colors; never glass |
| Provider and account card rows | CONTENT | Buttons with plain style | No glass |
| Provider detail | CONTENT | Native `List` + shared `Section` / `LabeledContent` composition | No glass |
| Quota meters | CONTENT | Deterministic SwiftUI shapes | No glass |
| Popover shell | FUNCTIONAL / transient | `NSPopover` | Automatic system material |
| Popover detail | CONTENT inside transient host | Native grouped `Form` + shared detail composition | Form material; no glass |
| Popover action cluster | FUNCTIONAL / transient | Two standard SwiftUI Buttons in one `GlassEffectContainer` | `.glass` + one `.glassProminent` |
| Settings | CONTENT inside window | Native grouped `Form` | No glass |
| Menu bar items and menus | FUNCTIONAL / structural + transient | `NSStatusItem`, `NSMenu` | Automatic system material |

Every region classifies cleanly. No glass exists in content.

## Decision-order record

1. Standard components satisfy the window, toolbar, sidebar, list, form,
   popover, menu, status-item, picker, toggle, and sheet-like presentation
   needs. They remain authoritative.
2. No custom toolbar, split-view, sheet, popover background, blur, or bezel
   exists to delete.
3. The popover footer is a composition of two standard buttons. Its explicit
   glass styles are appropriate because it is transient functional chrome; one
   shared container batches the cluster.
4. No custom bar or overlay is required.
5. No raw `glassEffect`, `NSGlassEffectView`, or custom glass surface is
   justified or shipped.

## Mechanics

| Check | Result | Evidence |
|---|---|---|
| Modifier order | PASS | No raw `glassEffect`; standard button styles own capture order |
| Container batching | PASS | Popover's two glass buttons share one `GlassEffectContainer(spacing: 8)`; interior stack spacing is also 8 |
| Nesting / overlap | PASS | No nested or independently overlapping glass surfaces |
| Corner concentricity | PASS | Single controls use system-derived capsules; no numeric glass radius |
| Tint count | PASS | Exactly one prominent action in the popover bar: Open Usage |
| Variant choice | PASS | Standard regular glass only; no `clear` variant |
| Toolbar command parity | PASS | Refresh and sidebar toggle also exist in the View menu |
| Icon accessibility | PASS | Refresh and Open Usage icon buttons have explicit labels and help |
| Motion | PASS in code | 200ms opacity handoff and 180ms refresh fade; no geometry/blur morph; Reduce Motion returns identity/no animation |

## Availability

The used Liquid Glass symbols—`GlassEffectContainer`, `.glass`, and
`.glassProminent`—are macOS 26.0 and match the deployment target. No guard is
required. No macOS 27 beta, visionOS-only, UIKit-only, or unavailable toolbar
symbol is present.

Blocked spellings were searched and are absent:
`glassBackgroundEffect`, `toolbarOverflowMenu`,
`topBarPinnedTrailing`, `containerConcentric`,
`effectIsInteractive`, `prominentGlass`, and `clearGlass`.

## Custom-surface records

### Popover action cluster

| Field | Record |
|---|---|
| Layer | FUNCTIONAL / transient |
| Why no earlier component sufficed | A native popover and standard Buttons do suffice; step 3 only composes them into one compact action cluster |
| Container | One `GlassEffectContainer`, spacing 8; interior HStack spacing 8 |
| Variant | Regular for Refresh; prominent regular for the sole primary Open Usage action |
| Shape | System button-style capsule; no numeric radius; concentric derivation does not apply to a single free-floating capsule |
| Availability | macOS 26.0, equal to minimum target |
| Reduce Transparency | System Button and NSPopover substitutions; no app-painted material |
| Reduce Motion | No glass morph; app-authored opacity animations resolve to identity/no animation |
| Verified | Light/Dark launch stability and process-local reduction fixtures |
| Blocked | Real Clear/Tinted setting, real Reduce Transparency, hover, inactive window, focus-ring and VoiceOver inspection require operator visual QA |

### Toolbar Refresh control

| Field | Record |
|---|---|
| Layer | FUNCTIONAL / structural |
| Why no earlier component sufficed | Standard `NSToolbar` hosts a standard SwiftUI Button; custom hosted view is needed only for the fixed-size glyph/spinner swap |
| Container | System toolbar grouping; single button, so no app container |
| Variant | Regular; never prominent or tinted independently |
| Shape | System button-style capsule; no numeric radius |
| Availability | macOS 26.0, equal to minimum target |
| Reduce Transparency | System toolbar/Button substitution |
| Reduce Motion | 180ms opacity swap is disabled; no morph or blur animation |
| Verified | Light/Dark launch stability and refresh fixture behavior |
| Blocked | Real accessibility settings, inactive-window rendering, hover and focus-ring inspection require operator visual QA |

## Anti-pattern gate

| Anti-pattern | Result | Mechanism evidence |
|---|---|---|
| Glass in content | PASS | Cards, rows, meters, Lists and Forms use opaque/system content material; functional/content distinction remains visible |
| Glass-on-glass | PASS | No nested sampling; popover sibling controls share one container |
| Custom bar/split/popover backgrounds | PASS | None; scroll-edge and content-derived adaptation remain system-owned |
| Hard-coded glass radii | PASS | No numeric glass radius |
| Tint abuse | PASS | One prominent action; semantic content colors never create extra glass primaries |
| Missing accessibility substitutions | PASS in architecture | All material is system component material; app-authored motion is removed |
| Unbatched effects | PASS | Only multi-control explicit cluster is batched |
| iOS API leakage | PASS | No cross-platform-only symbol |
| Wrong modifier order | PASS | No raw modifier |
| Compatibility-key strategy | PASS | No `UIDesignRequiresCompatibility` |
| Mid-merge spacing | PASS | Container and interior spacing equal 8 |
| Raw effect on Button | PASS | Standard glass button styles used |

## Color system

Every authored color resolves through `JackinBrand`. The content hierarchy is:

- stage: warm industrial neutral #F3F4F1 Light and blue-black #101618 Dark;
- cards: paper white #FCFCFA Light and raised graphite #162022 Dark;
- boundary: #D4D7D2 Light and #343D3F Dark;
- meter track: #E2E5E0 Light and #293335 Dark;
- healthy/brand: phosphor #0B774E Light and #5CF07A Dark;
- metadata: #59615D Light and #ADB5B2 Dark;
- quiet metadata: #6A726E Light and #858E8B Dark;
- warning: #7A4B00 Light and #FFC15A Dark;
- danger: #B42318 Light and #FF7B72 Dark;
- brand wash: #E3F3E7 Light and #16372A Dark.

Status-bar and content severity now share the same adaptive endpoints. Increase
Contrast strengthens the authored card edge from 1pt to 1.5pt. State always pairs
color with a symbol or label. System glass keeps its content-derived color;
brand color enters it only through the standard accent and the sole prominent
action.

WCAG contrast against the adaptive card ground:

| Token | Light | Dark |
|---|---:|---:|
| Phosphor | 5.43:1 | 11.24:1 |
| Metadata | 6.21:1 | 7.94:1 |
| Quiet metadata | 4.82:1 | 4.94:1 |
| Warning | 7.21:1 | 10.31:1 |
| Danger | 6.40:1 | 6.59:1 |

## Typography, rhythm, hierarchy, and multi-account

- Type ramp: 28pt rounded semibold hero, system headline/callout, caption and
  caption2 metadata. Every quota/reset numeral uses monospaced digits.
- Rhythm: authored 4/8/12/16/20/24 scale; native controls retain system metrics.
- Scan: provider → hero remaining percentage → meter → reset.
- The preferred overview card grid remains. It is content, never glass, and its
  custom opaque boundary is justified by provider grouping and fast scanning.
- F25 keeps five accounts inside one provider card with restrained dividers.
- Usage detail and popover now consume one `ProviderDetailSections`
  implementation, removing duplicated labels, ordering, state, and retry logic.

## Provider detail coverage

The prototype fixtures mirror the complete limits-only projection currently
normalized by `crates/jackin-usage/src/usage/`. Detail pages render every bucket
in source order; they do not collapse provider data into a generic weekly row.

| Provider | Detailed output represented |
|---|---|
| OpenAI / Codex | Account, plan, auth origin, session and weekly limits, provider-named additional limits, limit-reset credits, credit balance |
| Anthropic / Claude | Account, plan, auth origin, session, all-model weekly, every named model-scoped weekly limit, extra-usage cap, provider dollar-budget windows |
| Amp | Account, inferred Amp Free plan, auth origin, daily allowance, individual credit balance, every named workspace balance |
| xAI / Grok | Account, server plan tier, auth origin, billing-cycle limit, prepaid extra-usage credits, bounded on-demand usage cap |
| Z.AI / GLM | Plan, auth origin, short token window, primary token window, MCP count limit |
| Kimi | Auth origin, rate-limit window, weekly coding limit, provider counts and resets |
| MiniMax | Plan, auth origin, general five-hour and weekly windows, every available model interval, provider counts and resets |

The Rust detail contract additionally supports distinct username, freshness,
last-good data plus error, meter severity, pace/run-out projection, exact reset,
and unavailable/auth-required states. Fixtures exercise the user-visible forms.
New provider-supplied named/model windows are already planned by the generic
bucket projection: they append as clear items without a Swift provider matrix.
No token price, cost history, or usage trend is represented or planned.

## Motion and transitions

Navigation and scenario changes use a 200ms ease-in/out opacity handoff.
Refresh glyph/spinner state uses a 180ms ease-out opacity swap. These durations
are quick enough to preserve direct manipulation and slow enough to prevent a
visual cut. No scale, geometry, glass morph, blur animation, or continuous
decoration exists. Both real Reduce Motion and the prototype reduction contract
remove app-authored animation.

System window, menu, popover, hover, press, and focus transitions remain
system-owned.

## Acceptance-gate evidence

| Axes | Status |
|---|---|
| Light / Dark | PASS for launch/render stability across all fixtures and three window sizes |
| Localization / RTL / long strings | PASS for launch/render stability via F11 and F19 variants |
| Reduce Motion / Transparency flags | PASS for process-local launch stability; real settings remain unverified |
| Clear / Tinted Liquid Glass | BLOCKED pending operator visual QA; no read API exists |
| Auto appearance and live appearance switch | BLOCKED pending operator visual QA |
| macOS 27 Liquid Glass slider / Show Borders | BLOCKED; no macOS 27 validation lane |
| Increase Contrast / Differentiate Without Color | BLOCKED pending real-setting visual QA; code paths and redundant symbols are present |
| Accent/highlight palette matrix | BLOCKED pending operator visual QA |
| Active/inactive window | BLOCKED pending operator visual QA |
| Sidebar sizes, scroll bars, displays, scale, wallpaper, color profiles | BLOCKED pending operator visual QA |
| Minimum/full-screen layout | Minimum sizes launch clean; full-screen interaction pending operator QA |
| VoiceOver, Voice Control, Full Keyboard Access, focus ring | BLOCKED pending operator accessibility QA |
| Hover | BLOCKED; macOS 26 outside-toolbar glass hover defect is known |

## Automated stability evidence

All 36 supported fixture names (F00–F29 plus named F18, F19, and F24 variants)
remained alive after initial render at 760 × 500, 920 × 620, and 1200 × 760 in
Light and Dark: 216 launches. F18-f02 and F18-f11 also passed at 920 × 620 in
both appearances with reduction unset, Transparency, Motion, and Transparency
+ Motion: 16 launches.

This evidence proves build and launch/render stability. It does not replace the
operator-owned running-app acceptance rows above. No screenshots were taken.
