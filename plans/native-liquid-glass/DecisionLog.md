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
