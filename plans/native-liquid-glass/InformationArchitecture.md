# Information architecture

Status: **approved A1 information architecture; runnable concept explicitly confirmed; production conformance in progress**

## Rust-owned object model

```text
desktop presentation
├── detected providers (DESKTOP_PROVIDER_ORDER)
│   ├── provider identity and refresh state
│   └── accounts
│       ├── account identity
│       ├── plan/status metadata
│       └── ordered usage detail rows
│           ├── metadata row
│           ├── quota bucket row
│           └── provider detail row
└── glance rows for each provider status item
```

Swift must consume this model. It must not sort providers by a Swift-owned
urgency score, merge accounts, relabel plans, synthesize quota buckets, or infer
spend.

## Global hierarchy

```text
macOS
├── menu bar
│   ├── one status item per detected desktop provider
│   └── fallback status item when no provider is detected
├── transient provider surface
│   └── focused provider → account → ordered limit rows
├── Usage window
│   ├── Overview → provider-account rows
│   └── provider → account → ordered limit rows
└── Settings window
    └── existing desktop preferences
```

The status item exposes at most three Rust-owned burn-first glance values. The
popover expands one provider. The Usage window compares all records. These are
progressive levels of disclosure, not three unrelated dashboards.

## Menu-bar surface responsibilities

### Status item

- Preserve one item per detected provider and the Rust-owned provider order.
- Preserve the Rust-owned maximum of three burn-first values.
- Use the fallback item only when no desktop provider is detected.
- Primary click establishes provider context and opens the transient surface.
- Secondary click opens the native context menu.
- Provider art identifies a record; it is not a button nested inside the item.

### Provider popover

Required content, in priority order:

1. Provider identity and refresh state.
2. Account selection when multiple accounts exist.
3. Plan/status metadata supplied by Rust.
4. Ordered quota/detail rows supplied by Rust.
5. Refresh focused provider.
6. Open Usage with the same provider/account context.

The popover does not need global provider navigation: the user already selected
a provider by clicking its status item. Cross-provider Overview belongs in the
Usage window unless the operator selects an alternative that explicitly changes
that responsibility.

### Context menu

Sections:

1. Open Usage.
2. Refresh the represented provider.
3. Settings when required by the no-provider or recovery path.
4. Quit jackin❯.

Use native separators and menu ordering. Icons are system decisions; do not add
an icon to every item.

## Usage window responsibilities

### Sidebar

Top-level destinations:

1. Overview.
2. One row per detected provider in Rust order.

The sidebar does not duplicate accounts. Account choice is subordinate to a
provider and stays in the detail area. This keeps one global selection system.

### Overview

One native table row per provider-account pair. Proposed columns:

- Provider
- Account
- Plan or status
- Most constrained remaining limit
- Reset
- Refresh state

The "most constrained" display must be a Rust-owned glance/detail value, not a
new Swift calculation. Selecting a row navigates to its provider and account.
Columns may collapse at minimum width through native table behavior; the first
two identity columns remain available.

### Provider detail

Priority order:

1. Provider title and provider-page action.
2. Native account picker when several accounts exist.
3. Plan/status metadata.
4. Ordered quota and detail rows.
5. Local refresh status and recovery action.

The detail uses the full available width but keeps a readable measure. It does
not fill unused width with card grids.

### Toolbar

- Sidebar toggle: system-owned.
- Refresh all: visible when space permits; system overflow otherwise.
- Optional provider-page action only while a provider is selected.
- No informational item receives a bordered/glass treatment.
- No hand-built overflow menu.

### App menus

Use standard App, File, Edit, View, Window, and Help placement. Every toolbar
command has a menu equivalent. Refresh remains Command-R. Usage remains
Command-0 if that existing shortcut survives Phase 2 command audit.

## Actions

| Action | Scope | Primary placement | Equivalent |
|---|---|---|---|
| Open provider popover | Provider | Primary status-item click | None required |
| Open status-item menu | Provider/app | Secondary status-item click | None required |
| Choose account | Provider | Native account picker | Keyboard traversal |
| Refresh provider | Provider | Popover/detail button | Context or View menu |
| Refresh all | App | Usage toolbar | View menu, Command-R |
| Open Usage | App/provider | Popover or context menu | Window menu, Command-0 |
| Open provider page | Account/provider | Provider detail | Menu/context equivalent |
| Open Settings | App | App menu | Command-comma |
| Close transient surface | Popover | Outside click | Escape |
| Close window | Window | Window control | File menu, Command-W |
| Quit | App | App menu/status menu | Command-Q |

Refresh is reversible and non-destructive. The product has no destructive data
action in scope; destructive-pending UI is therefore explicitly not applicable.

## Loading, empty, stale, and error hierarchy

- **Initial loading:** native progress plus concise Rust-owned status. Avoid an
  empty chrome shell.
- **Refreshing with last-good data:** preserve data; place progress by the
  refresh control and expose status to assistive technology.
- **No detected providers:** native unavailable view, Settings, and Refresh.
- **Provider has no accounts:** local unavailable view; other providers remain
  navigable.
- **Stale:** retain values and show the Rust-owned age/status adjacent to the
  affected provider, not as a global alarm.
- **Partial provider failure:** local error and Retry; Overview keeps healthy
  rows.
- **Global bridge failure:** window-level unavailable presentation with Retry;
  do not fabricate zero percentages.
- **Offline/permission denied:** show the exact Rust-supplied recovery text and
  the action it permits.

## Continuity model

| State | Persist | Invalid-record fallback |
|---|---|---|
| Usage window frame | Yes | Default 920 × 620 |
| Sidebar visibility/width | Yes | System default |
| Usage destination | Yes | Overview |
| Provider account | When model already owns it | First Rust-ordered account |
| Popover provider | Derived from clicked item | Fallback empty state |
| Popover scroll position | No | Top |
| Refresh progress/error | No UI persistence; source owns current state | Last-good or empty state |

## Accessibility hierarchy

- Provider images are decorative when adjacent text already names the provider.
- Status items expose provider, visible quota values, and refresh state in one
  concise accessibility label.
- Progress controls expose the row label, percentage/value, and reset text.
- Rows whose full text is visually truncated expose the full string through the
  accessibility value and native help.
- Color never carries the only indication of exhausted, stale, or failed state.
- Focus follows sidebar → account picker → detail content → actions.

## Out of scope

- Provider discovery or authentication changes.
- New provider ordering or urgency calculations.
- Token prices, estimated cost, spend totals, history, charts, or trends.
- Custom window controls, custom menu rendering, custom popover chrome, custom
  progress bars, or custom glass.
- A new onboarding or account-management flow.
