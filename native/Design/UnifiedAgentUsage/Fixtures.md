# Design Fixtures — Unified Agent Usage

Status: DRAFT

These records are the canonical successor contract shared by every schematic
alternative and later prototype. F00–F14 reuse the current launch catalog's
stable scenario IDs, but the existing `VisualQAFixtures.swift` tuples are legacy
baseline input and do not match this contract. The first prototype-harness task
must replace those executable tuples with this file's records before any new
capture can satisfy candidate coverage. Until then, captures from the current
source are labeled legacy baseline evidence only. Rust-owned strings are treated
as immutable display input; a preview may change layout only.

Frozen environment:

- Time: `2026-08-12T12:00:00+07:00`
- Base locale and layout direction: `en_US`, left-to-right. F19 overrides both.
- Calendar: Gregorian
- Time zone: `Asia/Ho_Chi_Minh`
- Window sizes: 760 × 500 minimum, 920 × 620 typical, 1200 × 760 wide
- Popover: 380 × 520

## Candidate desktop provider order

1. OpenAI / Codex
2. Anthropic / Claude
3. Amp
4. xAI / Grok
5. Z.AI / GLM
6. Kimi
7. MiniMax

OpenCode is intentionally absent from jackin❯ desktop while remaining present
in host CLI and console fixtures. This current-desktop order becomes frozen only
with human structural selection; the host order remains the separately settled
eight-provider order.

## Core records

### OpenAI / Codex

Provider state: current.
Provider summary: `57% left`, `Resets in 3d`.

Canonical accounts:

| Key | Account | Plan | Remaining | Selected | State |
|---|---|---|---:|---|---|
| `codex-personal` | `personal@example.test` | Plus | 57% | default in F02 | current |
| `codex-plus` | `team@example.test` | Plus | 0% | selected in F03/F05 | depleted |
| `codex-organization` | `organization-production-sandbox@example.test` | Enterprise | 88% | optional | current |

Quota windows for `codex-personal`:

| Stable row | Label | Display | Meter | State |
|---|---|---|---:|---|
| `bucket:weekly` | Weekly | `57% left · Resets in 3d` | 57 | warning |
| `bucket:five-hour` | Five-hour | `63% left · Resets in 2h` | 63 | normal |
| `bucket:credits` | Credits | `3 manual resets available · Next expires in 3d 4h` | — | normal |

Quota windows for `codex-plus`:

| Stable row | Label | Display | Meter | State |
|---|---|---|---:|---|
| `bucket:weekly` | Weekly | `0% left · Resets in 3d` | 0 | depleted |

### Anthropic / Claude

Provider state: current or nearly depleted.
Provider summary: `12% left`, `Resets in 1h`.

Canonical account: `personal@example.test`, Pro plan, 12% remaining.

Quota windows:

| Stable row | Label | Display | Meter | State |
|---|---|---|---:|---|
| `bucket:session` | Session | `74% left` | 74 | normal |
| `bucket:weekly` | Weekly | `12% left · Resets in 1h` | 12 | danger |

### Remaining normal catalog

| Provider | Account label | Remaining | Reset | State |
|---|---|---:|---|---|
| Amp | `default` | 100% | `Resets in 18h` | current |
| xAI / Grok | `default` | 72% | unavailable | current |
| Z.AI / GLM | `default` | 81% | unavailable | current |
| Kimi | `default` | 45% | unavailable | current |
| MiniMax | `default` | 33% | unavailable | current |

Missing reset values display the Rust-owned fallback; they never become zero or
an inferred date.

## Required fixture matrix

### F00 — No providers

- Providers: none.
- Accounts: none.
- State: not loading, no global error.
- Required copy: “No providers detected” plus a concrete next step.
- Required controls: Settings/configuration route if available; no fake Refresh
  loop against an empty capability set.

### F01 — Single normal

- Provider: OpenAI / Codex.
- Account: `codex-personal`.
- Summary: 57% left, reset in 3 days.
- Detail: all OpenAI quota windows above.
- Purpose: prove calm single-account hierarchy without empty columns or unused
  account chrome.

### F02 — Full normal catalog

- Seven desktop providers in canonical order.
- One account each.
- All values from the normal catalog.
- Purpose: typical light/dark, inactive-window, sidebar, popover, and overview
  evidence.

### F03 — Multi-account provider

- Provider: OpenAI / Codex only.
- Accounts: personal 57%, team 0%, organization 88%.
- Selected account: team / `codex-plus`.
- Selected detail: exhausted weekly window.
- Purpose: prove deduplication, account selection, stable IDs, and exact handoff
  from popover to Usage.

### F04 — Nearly exhausted

- Provider: Anthropic / Claude.
- Account: personal / Pro.
- Remaining: 12%, reset in 1 hour.
- Purpose: warning remains legible without color and does not disable launch or
  navigation.

### F05 — Exhausted

- Provider: OpenAI / Codex.
- Account: team / Plus.
- Remaining: 0%, reset in 3 days.
- Purpose: depleted is informational, explicit, and never a disabled-state
  substitute.

### F06 — Stale last-good

- Provider: OpenAI / Codex.
- Account: personal, 57% last-good.
- Age: `Updated 47m ago`.
- Error: `Codex provider usage unavailable; cached quota is stale`.
- Purpose: preserve usable values, label stale state, and place Retry locally.

### F07 — Refreshing last-good

- Base: full normal catalog.
- OpenAI generation: refreshing.
- Last-good values remain visible.
- Purpose: busy state never erases data, shifts layout, or blocks other
  navigation; repeated Refresh joins existing work.

### F08 — Partial provider timeout

- Base: full normal catalog.
- Kimi state: unavailable.
- Error: `usage provider probe timed out`.
- Other six providers: usable current rows.
- Purpose: provider-local failure, structured partial success, global command
  remains successful.

### F09 — Permission denied

- Provider: Anthropic / Claude.
- Accounts: none usable.
- State: unavailable.
- Error: `Claude Keychain access denied`.
- Purpose: explicit permission state and recovery without a modal alert or
  leaked credential path/value.

### F10 — Offline cached

- Provider: Kimi.
- Account: default, stale last-good 45%.
- Age: `Updated 1h ago`.
- Error: `Kimi billing endpoint unavailable; local presence only`.
- Purpose: offline and stale remain distinguishable from permission failure and
  empty inventory.

### F11 — Long labels

- Provider: `OpenAI Organization Production Sandbox — Southeast Asia`.
- Account: `organization-production-sandbox@example.test`.
- Plan: `Enterprise workspace with centrally managed weekly limits`.
- Window: `Organization-wide weekly accelerated-model allocation`.
- Value: `57% left`.
- Reset: `Resets Tuesday, 18 August 2026 at 23:59 Indochina Time`.
- Error: `Provider response could not be refreshed; showing the last successful quota snapshot`.
- State: stale.
- Purpose: 760 × 500 wrapping/truncation, complete accessibility text, and no
  overlapping columns.

### F12 — Layout envelope / large dataset

- Seven providers plus at least 40 canonical accounts total.
- Selected provider: Anthropic / Claude.
- Selected account: `Research workspace`.
- Mixed remaining values: 88%, missing, 28%, 0%, 12%, 57%, and 100%.
- Each selected account may contain up to eight quota windows, including duplicate
  visible labels with distinct stable row IDs.
- Purpose: minimum/typical/wide geometry, native scrolling, disclosure stability,
  selection survival, and deterministic ordering.

### F13 — Initial loading

- Providers/accounts: none yet.
- State: loading true, no error.
- Purpose: reserved layout with native indeterminate progress; no blank window,
  disabled app, or shifting controls.

### F14 — Global bridge error

- Providers/accounts: no usable projection.
- Error: `Usage presentation is unavailable`.
- Purpose: `ContentUnavailableView`, one Retry, and normal access to Settings and
  Quit.

### F15 — Accepted preference mutation

- Setting: percent style changes from remaining to used.
- Rust accepts mutation and returns the next projection.
- Purpose: values change only from Rust-supplied strings; selected setting and
  all surfaces update together.

### F16 — Rejected preference mutation

- Setting: refresh floor changes from 5 to 1 minute.
- Rust rejects the operation with a typed recoverable error.
- Expected: control returns to accepted 5-minute value; contextual message and
  exact Retry remain beside Refresh settings.
- Purpose: prevent silent optimistic persistence or invisible global error.

### F17 — Reordered mutation completion

- Two rapid setting changes: value A starts, value B starts, B completes first,
  A completes last.
- Expected: value B remains accepted; A cannot overwrite newer intent.
- Purpose: prove task ownership, generation ordering, and shutdown guards.

### F18 — Accessibility display settings

- Variants: Reduce Transparency, Increase Contrast, Differentiate Without Color,
  Reduce Motion, Full Keyboard Access, light/dark, key/inactive window.
- Data: F02 and F11.
- Expected: opacity adapts through system material; all rows remain separated;
  every state has non-color identity; focus remains visible; no spatial/blur
  animation survives Reduce Motion.

### F19 — Localization and direction

- `en_US`, left-to-right: 2× English versions of every label.
- `ar_SA`, right-to-left: Arabic provider/account/error sample with mixed
  left-to-right technical IDs and Arabic locale formatting.
- `ja_JP`, left-to-right: CJK provider/account/plan sample and Japanese locale
  formatting.
- `de_DE`, left-to-right: German reset and permission messages and German locale
  formatting.
- Expected: system mirroring, no clipped primary action/identity, locale-safe
  value grouping, complete accessibility summaries.

### F20 — Destructive pending sentinel

- No destructive action exists in the usage experience.
- Expected: no confirmation dialog, destructive tint, Delete/Remove/Buy action,
  or quota-based launch disablement appears.
- Purpose: keep future implementations inside the informational product boundary.

### F21 — Keyboard and VoiceOver task completion

- Starting point: provider status item focused through the macOS menu bar.
- Sequence: open the popover; hear provider/account/value/reset/state; move
  through account picker, Refresh, and Open Usage; select `codex-plus`; open
  Usage; confirm the same account; traverse provider group, account row, quota
  windows, stale/error detail, and Retry; close Usage and dismiss the popover.
- Async event: F07 replaces one refreshing row with current data during
  traversal; announcement is concise and does not restart the entire table.
- Expected: no anonymous groups, duplicate row summaries, focus trap, pointer-only
  action, or lost focus. Escape returns focus to the originating status item;
  reopening restores the accepted selection.

### F22 — Provider-supplied money cap

- Provider: MiniMax.
- Account: default / Pro.
- Window stable ID: `bucket:monthly-credit-cap`.
- Label: `Monthly credit allowance`.
- Display: `$6 available of $20 cap · Resets Sep 1`.
- Purpose: prove a provider-supplied money cap can be presented as a quota bound
  without token prices, cost estimates, spend history, charts, ranking, or an
  inferred amount spent.

### F23 — Physical display and restoration

- Displays: built-in 2× plus external 1× and external 2×, each tested with and
  without its own menu bar where the system permits.
- Sequence: open from each clicked status item; verify popover anchoring; move
  Usage between displays; resize; hide/show sidebar; select a provider/account;
  close/reopen; disconnect the last display; relaunch.
- Expected: the unique Usage window stays fully visible, restores safe geometry
  and selection, and never opens on a removed display. Popover remains anchored
  to the clicked item rather than app-owned coordinates.

### F24 — Continuous resize and overflow

- Sweep the Usage window continuously from 1200 × 760 to 760 × 500 and back,
  including 900 and 860-point candidate thresholds.
- Repeat with F02, F11, F12, Increase Contrast, sidebar shown/hidden, and toolbar
  items forced into overflow.
- Expected: no overlapping or concatenated text, horizontal scroll for the
  primary job, hidden focus, selection loss, oscillating layout, or inaccessible
  action. Every toolbar action remains available in its menu.

## Capture coverage

Preselection ASCII schematics use only exact core or named-fixture records;
OpenAI multi-account examples use F03 tuples. After human structural selection,
every selected prototype view is rendered against F00, F02, F03,
F06, F08, F11, F12, F13, F14, F16, F18, F19, F21, F23, and F24 before live
signoff. Final visual QA additionally covers F01, F04, F05, F07, F09, F10, F15,
F17, F20, and F22.
