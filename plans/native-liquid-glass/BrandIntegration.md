# jackin❯ identity inside native Liquid Glass

Status: **D-005 implementation complete; final visual revalidation pending**

## Finding

The first A1 build put `jackin❯ desktop` in the free-floating native title position. D-002 removed it, moved the canonical wordmark into the sidebar footer, and introduced semantic phosphor. The operator later required persistent identity on both native surfaces and explicitly centered window branding. D-005 therefore restores a restrained product title through native principal placement and adds a plain popover identity row without undoing the sidebar signature or material rules.

Reference shape: Finder/Safari restraint. The Usage window is a dense records browser, not a media canvas. System components own chrome and material; product identity appears in content, data vocabulary, semantic color, and the real mark.

## Ownership split

| Region | Owner | Decision |
|---|---|---|
| Window title | macOS + native composition | Keep `jackin❯ desktop` as the internal Window-menu/accessibility title and show the same text once through a native `.principal` toolbar item. macOS owns centered geometry and adaptation. |
| Toolbar, sidebar, selection, popover, menus | macOS | System components own Liquid Glass, shapes, active/inactive adaptation, focus, and accent behavior. |
| Sidebar toggle | macOS + native composition | Remove the automatic relocating item at the sidebar source. Keep one SwiftUI toolbar `Button` in `.navigation`, bound to `NavigationSplitViewVisibility`, using Apple's `sidebar.left` SF Symbol and system toolbar treatment. |
| Sidebar signature | jackin❯ | Place the canonical full `jackin❯ by tailrocks` wordmark in a quiet, noninteractive sidebar footer. No background, border, glass, or hit target. |
| Popover identity | jackin❯ | Center the real generated template monogram with `jackin❯ desktop` text in one noninteractive content row. No background, border, glass, or hit target. |
| Provider identity | Provider assets | Keep provider marks beside provider-owned data. Do not replace them with the product mark. |
| Healthy quota meter | jackin❯ data semantics | Use adaptive phosphor: `#0B774E` in Light, `#5CF07A` in Dark. Text still states the value. |
| Warning/exhaustion | System semantic colors | Keep orange/red only for source-owned severity; text remains the primary state signal. |
| Empty status item | jackin❯ | Keep the canonical compact `j❯` monogram as the product fallback. |

## Canonical asset contract

- Geometry remains owned by `docs/scripts/brand-geometry.ts` and `docs/scripts/gen-brand.ts`; native files are generated outputs, never a separate drawing.
- Full wordmark includes the required `by tailrocks` byline.
- Dark surfaces use the white-word asset. Light surfaces use the dark-word asset. The chevron stays canonical green in both.
- The signature is transparent and rectangular only by its vector bounds. No rounded block, glow, blur, shadow, or custom material is added.
- Operational UI remains SF Pro with monospaced digits. JetBrains Mono exists only as outlined paths inside the generated mark.

## Liquid Glass synergy

Brand and Liquid Glass do different jobs:

- Liquid Glass supplies quiet functional depth and platform behavior.
- The wordmark supplies product identity without impersonating a control.
- Phosphor supplies a restrained semantic thread through healthy quota content, not a tint over glass or every action.
- The popover product row identifies the application; the separate provider identity keeps source context. Neither becomes a control or material surface.

Custom glass count remains zero. The sidebar action is a standard native toolbar button with an Apple SF Symbol; only its fixed placement and visibility binding are app-owned. The wordmark is a generated image composition, not a control or material surface.

## Rejected treatments

- **Custom titlebar or popover header strip:** rejected because it would duplicate system chrome or introduce another material layer.
- **Logo button in toolbar:** rejected because a non-action would look interactive on functional glass.
- **Logo card or colored block:** rejected because it violates the transparent, square-cap brand contract and adds content-layer decoration.
- **Phosphor toolbar/sidebar backgrounds:** rejected because multiple tinted controls weaken system hierarchy and Liquid Glass adaptation.

## Acceptance

- One `jackin❯ desktop` title is visible at the native toolbar's centered principal placement; no `Usage` title is visible.
- The popover begins with one centered, noninteractive real monogram plus `jackin❯ desktop` identity row.
- Exactly one sidebar toggle remains in one leading toolbar slot before and after collapse; Apple owns its SF Symbol and native toolbar material, hover, focus, and help.
- Real generated wordmark remains legible in Light, Dark, Increase Contrast, Reduce Transparency, and inactive-window captures.
- Healthy meters use adaptive phosphor; warning/danger retain text plus semantic color; Differentiate Without Color leaves all states understandable.
- No custom material, custom background, hard-coded control radius, or branded glass surface is introduced.
