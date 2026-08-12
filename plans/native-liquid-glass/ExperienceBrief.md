# Experience brief

Status: **draft; structural direction not selected**

## Shared product promise

jackin❯ desktop answers one question: **which subscription or quota limit needs
attention, and when does it reset?** It must feel like a quiet macOS utility,
not a dashboard imported from the web and not a miniature phone screen.

Rust remains the semantic owner. The native UI may reorganize the presentation,
but it must not invent provider states, reorder canonical quota rows, calculate
new metrics, or introduce cost and trend semantics.

## Menu-bar popover

### Dominant archetype

Menu-bar extra with a focused transient detail surface.

### Named reference model

Use the macOS Battery and Wi-Fi menu extras for transient hierarchy and compact
control density, with Finder-level visual restraint. Do not borrow the layered
card stacks or oversized capsules common to iPhone-shaped utilities.

### Primary job

Confirm the state of the provider represented by the clicked status item, choose
an account when that provider has several, refresh that provider, and move into
the full Usage window when more comparison is needed.

### Primary journey

1. The user notices a provider status item and its burn-first quota values.
2. A primary click opens context for that exact provider.
3. The user reads plan/status metadata and ordered limit rows.
4. The user optionally chooses another account for that provider.
5. The user refreshes the provider or opens the full Usage window.
6. Escape, outside click, or completing the transition closes the transient
   surface.

### Selection hierarchy

- Status-item selection establishes provider context.
- Account selection is secondary and exists only when the focused provider has
  multiple accounts.
- A quota row is informational, not selectable.
- Global cross-provider comparison belongs in the Usage window.

### Density and tone

- Compact but not compressed: small system control metrics, short labels, and
  one vertical reading path.
- Calm, factual, and dependable. Warning state comes from Rust-owned text and
  semantic system color, never animated urgency or decorative tint.
- At rest, no custom motion. Refresh uses the standard indeterminate progress
  affordance and preserves last-good values.

### Sizing and overflow

- Target content size: approximately 380 × 460 points.
- Usable floor when screen space is constrained: 320 × 280 points.
- Maximum design envelope: 420 × 560 points.
- The popover is not user-resizable. Metadata stays above an independently
  scrolling limit list; commands remain reachable when the list overflows.
- Long provider, account, plan, status, and reset strings may wrap where the
  native control permits. Truncation must expose the full value to VoiceOver and
  a native help tag.

### Required commands and equivalents

- Refresh focused provider: visible button; context-menu equivalent.
- Open Usage: visible button; context-menu equivalent.
- Escape: dismiss popover.
- Right-click status item: native context menu with Open Usage, Refresh, and
  Quit.
- No hidden keyboard-only command is the sole route to an action.

### Platform behavior

- The system owns popover material, placement, arrow, shadow, active/inactive
  adaptation, dismissal, and accessibility substitutions.
- The content does not add its own panel, stroke, shadow, corner radius, or glass
  material.
- Focus begins at the first actionable control, follows visual order, and never
  lands on decorative provider art.

### Continuity and recovery

- Reopening from a provider status item restores that provider context.
- The last selected account for that provider may persist only if the existing
  Rust-backed presentation state already owns it.
- Refresh failure keeps last-good data visible and presents Rust-owned recovery
  text with a Retry action.
- No-provider state offers Open Usage and Settings without fabricating usage.

### Explicit anti-reference

Failure mode: a 416-point-wide phone screen made from nested glass cards,
segmented tabs, horizontally scrolling provider pills, account chips, and a
floating footer capsule. That structure duplicates navigation, obscures the
clicked provider context, and places glass in content.

## Usage window

### Dominant archetype

Monitoring and operations workspace with list-detail navigation.

### Named reference model

Use Finder's source-list restraint and Activity Monitor's dense, sortable
overview semantics. Toolbars, sidebars, tables, menus, focus, resizing, and
inactive-window behavior remain system-owned.

### Primary job

Compare every detected provider account, find the limit that needs attention,
then inspect one provider account without losing cross-provider orientation.

### Primary journey

1. Open Usage from the Dock/menu command, a status-item context menu, or the
   popover.
2. See a cross-provider Overview or land on the provider that opened the window.
3. Select a provider in the sidebar.
4. Select an account in the detail when several accounts exist.
5. Read ordered metadata and quota limits.
6. Refresh globally or open the provider's native usage page.

### Selection hierarchy

- Sidebar selection chooses Overview or a provider.
- Account selection is scoped to the selected provider and appears in the
  detail, not as a competing global navigation rail.
- Overview rows identify provider-account records and can navigate to their
  detail.
- Quota rows are informational.

### Density and tone

- Moderately dense, scan-first, and quiet.
- Overview favors a native table over a metric-card grid.
- Provider detail favors labeled values, sections, and native progress
  indicators over decorative containers.
- One semantic accent may indicate the current native selection. No manually
  tinted glass is proposed.

### Window sizing and resizing

- Minimum usable size: 760 × 500 points.
- Default size: approximately 920 × 620 points.
- Expanded validation size: 1200 × 760 points.
- Sidebar can collapse through the native split-view command and toolbar item.
- At minimum size, tables and detail lists scroll; toolbar commands remain
  visible or enter the system-managed toolbar overflow.
- No fixed child frame may prevent the window from honoring its minimum size.

### Commands and menu-bar citizenship

- App menu: About, Settings, Services, Hide, and Quit in standard order.
- File: Close Window.
- Edit: standard editing commands where a control supports them.
- View: Overview, Show/Hide Sidebar, Refresh, and toolbar commands.
- Window: Minimize, Zoom, Bring All to Front, and Usage.
- Help: jackin❯ Help or the existing support destination when available.
- Refresh: toolbar button and View-menu command with Command-R.
- Open provider page: visible detail action and menu/context equivalent when
  applicable.
- Toolbar customization and overflow are system-owned; no custom overflow menu.

### Platform behavior

- Standard window, toolbar, source list, table, picker, form/list sections,
  menus, context menus, and progress controls.
- Window chrome may receive Liquid Glass from the system. Content never receives
  explicit glass.
- Sidebar selection, key-window emphasis, hover, focus ring, inactive state,
  increased contrast, and reduced transparency use native behavior.
- Informational toolbar text, if any, is unbordered and does not masquerade as a
  control.

### Continuity and recovery

- Restore window frame, sidebar visibility and width, Overview/provider
  selection, and the selected account when the underlying record still exists.
- When a restored record vanished, fall back to Overview without a broken
  selection.
- During refresh, keep last-good values and expose progress without shifting the
  whole layout.
- Partial provider errors remain local; healthy provider accounts remain usable.
- Full empty/error states use a native unavailable presentation with actionable
  Refresh or Settings controls.

### Explicit anti-reference

Failure mode: an enlarged mobile dashboard made from provider cards, quota
cards, rounded selection pills, detached account rails, and ornamental glass.
It wastes desktop width, weakens keyboard navigation, and makes the data less
comparable.

## Settings and secondary surfaces

Settings is already part of the product but is not a third redesign surface.
Keep it a standard Settings window with `Form`, system controls, and current
Rust-backed preferences. Remove stale explanatory copy only during an approved
implementation phase. Do not add preferences solely to expose design choices.

## Approval boundary

This brief sets product and platform constraints, not the final structure. The
operator must select an entry from `Alternatives.md` before implementation.
