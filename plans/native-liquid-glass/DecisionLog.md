# Native redesign decision log

## D-001 — A1 selected

- **Date:** 2026-08-12
- **Decision maker:** Operator
- **Operator statement:** `Select A1`
- **Decision:** Use A1 — Focused popover + two-column Usage — as the native
  concept direction.
- **Reason:** The operator accepted the recommended structure after the eight
  alternatives were explained. The recommendation preserves the provider
  context established by the clicked status item, removes duplicate custom
  provider/account navigation from the transient surface, and assigns
  cross-provider comparison to native desktop components in the Usage window.

### Structure now approved for concept proof

- One status item per Rust-detected desktop provider remains the entry point.
- Primary click opens a popover focused on that provider.
- Account selection appears only when the provider has multiple accounts.
- The popover presents provider metadata, ordered quota/detail rows, provider
  refresh, and Open Usage. It has no Overview/provider tab system.
- Usage uses a two-column `NavigationSplitView`.
- The sidebar contains Overview followed by Rust-ordered providers.
- Overview uses a native `Table` of provider-account records.
- Provider detail keeps account selection inside the detail.
- System popover, toolbar, sidebar, controls, and menus own Liquid Glass.
- Content rows, tables, metadata, quota presentations, and progress are not
  glass.

### Not approved by this decision

- Final pixels or rendered craft.
- Any CUSTOM component.
- Any custom glass surface.
- Production implementation.
- A Swift-owned provider catalog, ordering rule, quota meaning, or string.
- Changes to the limits-only product policy.

The next gate is a separately confirmed runnable native concept. The agent may
not treat this design selection as confirmation of that concept.

## D-002 — A1 identity placement revised

- **Date:** 2026-08-12
- **Decision maker:** Operator
- **Operator direction:** Move `jackin❯ desktop` out of its current toolbar-title position, place the real product logo in a principled location, and make the result coherent with both jackin❯ identity and Apple Liquid Glass.
- **Decision:** Keep A1 structure. Remove the visible product-name title, add the generated full wordmark as a noninteractive sidebar footer, and tint healthy quota meters with adaptive phosphor only.
- **Reason:** Selection and detail provide orientation, the wordmark provides restrained product identity, and semantic phosphor connects data to the product without tinting system-owned glass or controls.
- **Rejected:** branded principal title, popover brand header, toolbar logo button, logo card, and phosphor glass/control backgrounds.
- **Scope:** Runnable A1 concept only. Production remains behind the separately confirmed running-concept gate.

## D-003 — Visible title removed; native sidebar toggle fixed

- **Date:** 2026-08-12
- **Decision maker:** Operator
- **Operator direction:** Remove visible `Usage` text and keep one sidebar open/close control in the left sidebar position at all times.
- **Decision:** Retain `Usage` only as the internal native window title for the Window menu and accessibility. Set native title visibility to hidden. Remove `NavigationSplitView`'s automatic relocating item at the sidebar-column source, then bind one native SwiftUI toolbar `Button` in the fixed `.navigation` slot to `NavigationSplitViewVisibility`. The button uses Apple's `sidebar.left` SF Symbol, native toolbar material, help, focus, hover, accessibility label, and stable identity.
- **Reason:** Apple's automatic item moves to the trailing detail group when the sidebar collapses. Explicit navigation placement preserves the requested invariant while keeping rendering and interaction system-owned.
- **Rejected:** duplicate toggles, a control that migrates into the detail group, hand-drawn icon, colored/custom-glass button, conditional placement, and a logo that acts like a sidebar control.
- **Scope:** A1 concept refinement. Production gate remains closed.
