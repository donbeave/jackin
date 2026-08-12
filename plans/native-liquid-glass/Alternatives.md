# Structural alternatives

Status: **operator decision pending**

These are paired alternatives: each defines both the menu-bar popover and Usage
window. Color, radius, blur, and decorative styling are deliberately absent.
Every option uses native controls and the layer rules in `LayerMap.md`; none
requires CUSTOM UI.

## Shared constraints

- One status item per detected provider remains unchanged.
- Rust owns all data, order, labels, selection validity, and refresh state.
- Popover evidence uses a real `NSPopover`; window evidence uses a real native
  window with titlebar and toolbar.
- No option adds cost, spend history, trends, charts, or token pricing.
- No option adds custom glass, custom progress, custom menus, custom window
  chrome, or custom navigation controls.
- Schematics are content-annotated with stable fixture IDs. They are not rendered
  approval evidence.

## A1 — Focused popover + two-column Usage

**Current recommendation.** The clicked status item already establishes provider
context. The transient surface stays focused; global comparison moves to a
native list-detail window.

### Popover — `F03-multi-account`, target 380 × 460

```text
┌ OpenAI                                      ↻ ┐
│ Account  [secondary@example.test          ▾] │
│ Status   fresh                               │
│ Updated  Just now                            │
├ Limits ──────────────────────────────────────┤
│ Session                         0% left       │
│ [native ProgressView: 0]  Resets in 42m      │
│ Weekly                         57% left       │
│ [native ProgressView: 57] Resets in 3d       │
│ … native vertical scrolling …                │
├──────────────────────────────────────────────┤
│ [Open Usage]                                 │
└──────────────────────────────────────────────┘
```

- Structure: provider identity → account picker → metadata → limit list →
  actions.
- Components: `NSPopover`, `Label`, menu-style `Picker`, `LabeledContent`,
  `List`/`Section`, `ProgressView`, `Button`.
- No Overview/provider tabs inside the popover.

### Usage — `F02-catalog-normal`, default 920 × 620

```text
┌ native titlebar/toolbar                 [Refresh] ┐
│ Overview        │ Provider Account Plan Left Reset│
│ OpenAI          │ OpenAI   personal… Pro  57%  3d │
│ Anthropic       │ OpenAI   secondary… Plus 0%  —  │
│ Amp             │ Anthropic Personal Max 12%  1h │
│ xAI             │ Amp      Free      —   100% 18h│
│ Z.AI            │ … native Table …                │
│ Kimi            │                                 │
│ MiniMax         │                                 │
└ native sidebar ┴─────────────────────────────────┘
```

Selecting OpenAI replaces the table with provider detail; account selection
stays in that detail. Overview and providers share one native sidebar.

### Why recommend

- Matches the status-item context instead of asking the user to select the same
  provider twice.
- Gives the popover one job and one reading path.
- Gives comparison to a native `Table`, where desktop width and keyboard
  navigation help.
- Preserves provider-level navigation while keeping accounts subordinate.
- Removes the architecture that enabled the current bug class: duplicate
  provider/account navigation implemented as custom tabs, rails, and cards.

### Risk to prove

The focused popover must still expose enough provider detail at the constrained
height in `S02`; command placement must remain reachable without a custom sticky
footer.

## A2 — Cross-provider popover + table with inspector

The popover becomes the compact comparison surface. Usage makes the Overview
table primary and exposes selected detail in a native inspector.

### Popover — `F02-catalog-normal`, target 400 × 500

```text
┌ Usage                                      ↻ ┐
│ Anthropic   Personal        12% left   1h   >│
│ OpenAI      personal…       57% left   3d   >│
│ Amp         Free           100% left  18h   >│
│ xAI         Team            72% left    —   >│
│ Z.AI        Default         81% left    —   >│
│ Kimi        Default         45% left    —   >│
│ MiniMax     Default         33% left    —   >│
├──────────────────────────────────────────────┤
│ [Open Usage]                                 │
└──────────────────────────────────────────────┘
```

Selecting a row navigates within a native `NavigationStack` to that provider's
focused detail, with a native Back command.

### Usage — `F12-layout-envelope`, default 920 × 620

```text
┌ toolbar                                      ┐
│ Provider Account Plan Left Reset Status │Inspector│
│ OpenAI   personal… Pro  57%  3d    fresh│Account ▾│
│ OpenAI   secondary… Plus 0%  42m   fresh│Limits   │
│ … primary native Table …                │…         │
└─────────────────────────────────────────┴──────────┘
```

- Components: `Table(selection:)` plus SwiftUI `.inspector`, native sections and
  progress inside the inspector.
- No sidebar; the table is the durable orientation surface.

### Strength

Fast cross-provider comparison from either surface; Usage uses desktop table
semantics directly.

### Structural risk

The popover ignores the clicked provider context, and a narrow inspector can
compress long quota rows. `F11-long-labels` and `S04` are decisive tests.

## A3 — Provider picker popover + three-column Usage

Both surfaces expose provider and account as explicit hierarchical selectors.

### Popover — `F03-multi-account`, target 400 × 500

```text
┌ Usage                                      ↻ ┐
│ Provider [OpenAI                         ▾]  │
│ Account  [secondary@example.test         ▾]  │
├──────────────────────────────────────────────┤
│ Status / Updated                             │
│ Ordered limits with native ProgressView      │
├──────────────────────────────────────────────┤
│ [Open Usage]                                 │
└──────────────────────────────────────────────┘
```

### Usage — `F12-layout-envelope`, expanded 1200 × 760

```text
┌ toolbar                                           ┐
│ Providers  │ Accounts             │ Detail        │
│ Overview   │                      │               │
│ OpenAI     │ personal@example…    │ OpenAI        │
│ Anthropic  │ secondary@example…   │ Plus          │
│ Amp        │ organization-prod…   │ 0% Session    │
│ …          │                      │ … limits …    │
└────────────┴──────────────────────┴───────────────┘
```

- Components: two menu-style `Picker`s in the popover;
  three-column `NavigationSplitView` in Usage.

### Strength

The provider → account → detail hierarchy is explicit and stable for large
multi-account inventories.

### Structural risk

Provider choice in the popover duplicates the clicked status item, and three
columns are fragile at the required 760 × 500 minimum. Native collapse behavior
must not erase orientation.

## A4 — Dual-mode popover + tabbed Usage

Native segmented selection separates comparison from focused detail on both
surfaces.

### Popover — `F02-catalog-normal`, target 416 × 520

```text
┌ Usage                                      ↻ ┐
│ [ Overview | OpenAI ]                         │
├──────────────────────────────────────────────┤
│ Overview: provider rows and headline limits  │
│     or                                       │
│ OpenAI: account picker and ordered limits    │
├──────────────────────────────────────────────┤
│ [Open Usage]                                 │
└──────────────────────────────────────────────┘
```

The switch is a native segmented `Picker`, not the current custom control.

### Usage — `F02-catalog-normal`, default 920 × 620

```text
┌ toolbar                                      ┐
│ [ Overview | Providers ]                     │
│                                              │
│ Overview tab: native Table                   │
│ Providers tab: provider List + detail        │
└──────────────────────────────────────────────┘
```

### Strength

Both comparison and detail are visible concepts without a persistent sidebar.

### Structural risk

This preserves the current dual-mode concept that enabled duplicated navigation
and a phone-like segmented root. A native control fixes rendering, not the
information-architecture duplication.

## A5 — Glance-only popover + provider/account outline

The popover stays intentionally shallow. Full quota detail always belongs in
Usage; the Usage sidebar expands providers to reveal accounts.

### Popover — `F01-single-normal`, target 360 × 300

```text
┌ OpenAI                                      ↻ ┐
│ Session    63% left       Resets in 2h 14m   │
│ Weekly     57% left       Resets in 3d        │
│ Spark      88% left       Resets in 4h 02m    │
├──────────────────────────────────────────────┤
│ [Open Full Usage]                            │
└──────────────────────────────────────────────┘
```

Only Rust-owned status-item/detail headline rows appear. Metadata and secondary
details are omitted from the transient surface.

### Usage — `F12-layout-envelope`, default 920 × 620

```text
┌ toolbar                                      ┐
│ Overview       │ Detail                      │
│ ▾ OpenAI       │ selected provider/account   │
│   personal…    │ metadata                    │
│   secondary…   │ ordered limits              │
│ ▸ Anthropic    │                             │
│ ▸ Amp          │                             │
│ … native outline/list …                      │
└────────────────┴─────────────────────────────┘
```

- Components: native `DisclosureGroup`/outline-style `List` in the sidebar.

### Strength

Smallest transient surface; Usage exposes provider/account hierarchy without a
separate picker.

### Structural risk

The popover may become too shallow for the product promise, while a deeply
expanded sidebar can become noisy with 12 accounts and weak at minimum width.

## A6 — Account-first popover + account-first Usage

Provider grouping remains visible, but the durable selectable object is an
account rather than a provider.

### Popover — `F03-multi-account`, target 400 × 500

```text
┌ OpenAI                                      ↻ ┐
│ personal@example.test          57% left      │
│ secondary@example.test          0% left      │
│ organization-production…       88% left      │
├ selected account detail ─────────────────────┤
│ Session / Weekly / … native scrolling …      │
├──────────────────────────────────────────────┤
│ [Open Usage]                                 │
└──────────────────────────────────────────────┘
```

Accounts are a native single-selection `List`; the selected account detail
follows below.

### Usage — `F12-layout-envelope`, default 920 × 620

```text
┌ toolbar                                      ┐
│ Accounts                     │ Detail         │
│ OPENAI                       │                │
│   personal@example.test      │ selected       │
│   secondary@example.test     │ account limits │
│ ANTHROPIC                    │                │
│   Personal                   │                │
│ … grouped native List …                       │
└──────────────────────────────┴────────────────┘
```

### Strength

Direct for users whose providers contain many independently meaningful
accounts; one selectable object across both surfaces.

### Structural risk

Provider-level refresh and provider identity become secondary, and a grouped
account sidebar grows quickly. It also diverges from the current provider-first
Rust surface contract.

## A7 — Overview popover + single-column Usage browser

The popover compares only. Usage is a native drill-down browser with no sidebar
or inspector.

### Popover — `F02-catalog-normal`, target 400 × 460

```text
┌ Overview                                   ↻ ┐
│ Anthropic  Personal       12% left  1h      │
│ OpenAI     personal…      57% left  3d      │
│ Amp        Free          100% left 18h      │
│ … provider/account rows …                    │
├──────────────────────────────────────────────┤
│ [Open Usage]                                 │
└──────────────────────────────────────────────┘
```

Selecting a row opens Usage directly at that record instead of navigating
inside the popover.

### Usage — `F02-catalog-normal`, default 920 × 620

```text
┌ toolbar                                      ┐
│ Overview Table                               │
│ Provider Account Plan Left Reset Status      │
│ …                                            │
│ select/double-click row →                    │
│ Provider detail in NavigationStack           │
│ [Back to Overview]                           │
└──────────────────────────────────────────────┘
```

### Strength

Overview receives the full width, and provider detail has the full window when
opened.

### Structural risk

Back-stack navigation is weaker than persistent desktop orientation and makes
cross-provider comparison slower after drill-down.

## A8 — Alert-focused popover + multiwindow detail

The status item and popover expose only the most relevant Rust-owned limit. The
Overview table launches independent provider-detail windows.

### Popover — `F04-nearly-exhausted`, target 340 × 260

```text
┌ Anthropic                                  ↻ ┐
│ Weekly                                      │
│ 12% left                                    │
│ [native ProgressView: 12]  Resets in 1h     │
│ 52% in reserve                              │
├──────────────────────────────────────────────┤
│ [Open Anthropic Usage] [Overview]            │
└──────────────────────────────────────────────┘
```

"Most relevant" must be the Rust-owned glance row; Swift does not rank.

### Usage — `F02-catalog-normal`, default 920 × 620

```text
┌ Usage Overview — native Table                ┐
│ Provider Account Plan Left Reset Status      │
│ … select row → open value-keyed detail window│
└──────────────────────────────────────────────┘

┌ OpenAI — personal@example.test               ┐
│ Account metadata + ordered limit detail      │
└──────────────────────────────────────────────┘
```

Detail windows use native value-keyed window scenes if Phase 2 proves lifecycle
compatibility; otherwise this alternative is invalid.

### Strength

Supports side-by-side provider inspection and the smallest glance surface.

### Structural risk

Multiple windows introduce restoration, activation, and stale-record complexity;
the popover may hide valid secondary limits. This structure depends on an API
and lifecycle proof not yet established.

## Comparison without scoring

| Alternative | Popover responsibility | Usage orientation | Main unresolved question |
|---|---|---|---|
| A1 | Clicked provider detail | Sidebar + Overview/detail | Can commands remain reachable in constrained popover height? |
| A2 | Cross-provider compare + drill-in | Table + inspector | Is the inspector wide enough for quota detail? |
| A3 | Explicit provider/account selection | Three columns | Does minimum-width collapse preserve orientation? |
| A4 | Overview/detail mode switch | Tabs | Does duplicated mode navigation remain confusing? |
| A5 | Headline glance only | Provider/account outline | Is popover detail sufficient and outline calm at scale? |
| A6 | Account selection + detail | Account-first sidebar | Does this conflict with provider-first domain actions? |
| A7 | Comparison and handoff | Single-column drill-down | Is back-stack orientation acceptable on Mac? |
| A8 | One Rust-owned alert/glance | Overview + detail windows | Can lifecycle/restoration be proven without broad AppKit? |

## Recommendation

Choose **A1 — Focused popover + two-column Usage** as the direction to render.
It is the most consistent with the existing status-item interaction, Rust's
provider-first contract, native macOS hierarchy, and the goal of removing the
structural causes of the current custom-glass/card system.

Recommended details to carry into a selected concept:

- Popover remains provider-focused and uses a native account picker.
- Usage opens to Overview when contextless and to the matching provider/account
  when invoked from a status item or popover.
- Overview is a native table; provider detail is a native list/form composition.
- Sidebar contains Overview plus providers, not accounts.
- System popover/window/sidebar/toolbar materials are the only glass.

## Operator decision gate

No selection is recorded yet. Reply with one of:

- `Select A1` through `Select A8`;
- `Reject all` with the missing structural requirement; or
- `Remix A# popover + A# Usage` with any required adjustment.

After selection, the decision is frozen in a decision log. Phase 2 may inspect
project/API setup, but production Swift still waits for a separately confirmed
runnable native preview.
