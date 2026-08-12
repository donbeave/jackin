# Deterministic fixtures

Status: **approved fixture requirements for the A1 native concept**

## Contract

Fixtures enter Swift through the same presentation-model boundary as production
data. They may substitute deterministic Rust-shaped records; they may not create
a second Swift-owned semantic model.

Percentages and quota semantics below come from existing repository fixtures or
existing Rust presentation cases. Synthetic `.test` identities replace personal
addresses. Long strings are layout probes, not proposed production copy.

Every fixture has a stable ID so design schematics, preview commands, snapshots,
and tests refer to the same state.

## Shared record vocabulary

### Accounts

| Key | Provider | Account label | Plan | Remaining headline | Status |
|---|---|---|---|---:|---|
| `codex-personal` | OpenAI | `personal@example.test` | `Pro 20×` | 57% | fresh |
| `codex-plus` | OpenAI | `secondary@example.test` | `Plus` | 0% | fresh |
| `claude-personal` | Anthropic | `Personal` | `Max 20×` | 12% | fresh |
| `claude-work` | Anthropic | `Work` | `Team` | unavailable | fresh |
| `amp-free` | Amp | `Free` | — | 100% | fresh |
| `grok-team` | xAI | `Team` | — | 72% | fresh |
| `zai-default` | Z.AI | `Default` | — | 81% | fresh |
| `kimi-default` | Kimi | `Default` | — | 45% | fresh |
| `minimax-default` | MiniMax | `Default` | — | 33% | fresh |

### OpenAI detail rows

In source order:

| Kind | Label | Value | Meter | Supporting text |
|---|---|---|---:|---|
| Metadata | Status | `fresh` | — | — |
| Metadata | Updated | `Just now` | — | — |
| Metadata | Auth | `OAuth · ~/.codex/auth.json` | — | — |
| Limit | Session | `63% left` | 63 | `On pace · Resets in 2h 14m` |
| Limit | Weekly | `57% left` | 57 | `13% in deficit · Runs out in 2d 17h · Resets in 3d` |
| Limit | Codex Spark 5-hour | `88% left` | 88 | `On pace · Resets in 4h 02m` |
| Limit | Codex Spark Weekly | `100% left` | 100 | `Resets in 7d` |
| Limit | Limit Reset Credits | `3 manual resets available` | — | `Next expires in 3d 4h` |

### Anthropic detail rows

In source order:

| Label | Value | Meter | Supporting text |
|---|---|---:|---|
| Session | `74% left` | 74 | `12% in deficit · Resets in 4h 19m` |
| Weekly | `12% left` | 12 | `52% in reserve · Resets in 1h` |
| All models | `28% left` | 28 | `Weekly all-models window · Resets with weekly` |
| Sonnet | `35% left` | 35 | `Model-scoped · paced · Resets in 6d 12h` |
| Fable only | `28% left` | 28 | `Resets in 12h 19m` |
| Daily Routines | `100% left` | 100 | `No reset timestamp from provider` |
| Extra usage | `Spend bound` | — | `Quota-bound money / spend slot (limits only)` |

The Extra usage record is an allowed provider-supplied quota bound. It is not a
token unit price, estimated session cost, spend history, or trend.

## Required fixtures

### `F00-no-providers`

- Providers: 0.
- Accounts: 0.
- Status item: fallback jackin❯ mark.
- Popover title: `No providers detected`.
- Body: existing Rust/native no-provider explanation.
- Actions: `Refresh`, `Open Settings`, `Open Usage` when the selected structure
  keeps the window useful while empty.
- Purpose: true empty state; must not show zeroed progress.

### `F01-single-normal`

- Providers: OpenAI only.
- Accounts: `codex-personal` only.
- Details: complete OpenAI row set above.
- Status item: `Cx 57%` using the production formatter rather than a fixture
  literal where possible.
- Purpose: minimum normal content and baseline popover.

### `F02-catalog-normal`

- Providers in Rust desktop order: OpenAI, Anthropic, Amp, xAI, Z.AI, Kimi,
  MiniMax.
- Accounts: all nine shared records above.
- Glance remaining values: OpenAI 57, Anthropic 12, Amp 100, xAI 72, Z.AI 81,
  Kimi 45, MiniMax 33.
- Status-item burn-first rows: Anthropic 12, OpenAI 57, MiniMax 33 only when
  emitted by the production Rust ordering contract. Fixtures do not re-sort.
- Purpose: complete provider navigation, Overview comparison, and all
  alternatives.

### `F03-multi-account`

- Provider: OpenAI.
- Accounts, in source order: `codex-personal`, `codex-plus`,
  `organization-production-sandbox@example.test` with plan `Enterprise` and 88%
  remaining.
- Selected account: `codex-plus`.
- Purpose: account picker behavior, zero-percent state, selection restoration,
  and long account labels.

The third record is a layout-only Rust-shaped account; its label and plan do not
establish new provider semantics.

### `F04-nearly-exhausted`

- Provider/account: Anthropic / `claude-personal`.
- Weekly: `12% left`, `Resets in 1h`, severity `danger`.
- Other Anthropic rows remain present.
- Purpose: warning hierarchy without color-only communication or an alert.

### `F05-exhausted`

- Provider/account: OpenAI / `codex-plus`.
- Session: `0% left`, meter 0, `Resets in 42m`.
- Status remains `fresh`.
- Purpose: distinguish a valid exhausted quota from unavailable data.

### `F06-stale-last-good`

- Provider/account: OpenAI / `codex-personal`.
- Preserve all OpenAI values.
- Status: `stale`.
- Updated: `47 min ago`.
- Error: `Codex provider usage unavailable; cached quota is stale`.
- Purpose: last-good data plus local stale/error explanation.

### `F07-refreshing-last-good`

- Base: `F02-catalog-normal`.
- OpenAI `isRefreshing = true`; all last-good values remain visible.
- Accessible status: `Refreshing OpenAI usage`.
- Refresh action disabled only if the source rejects a duplicate request.
- Purpose: progress without layout replacement or custom spinning animation.

### `F08-partial-timeout`

- Base: `F02-catalog-normal`.
- Kimi status: `unavailable`.
- Error: `usage provider probe timed out`.
- Healthy providers remain fresh and selectable.
- Purpose: provider-local failure and Retry.

### `F09-permission-denied`

- Provider: Anthropic.
- Account label: `account unavailable`.
- Status: `unavailable`.
- Error: `Claude Keychain access denied`.
- Quota rows: none unless Rust supplies cached rows.
- Purpose: denied state, accessibility, Settings/recovery placement, and no
  fabricated values.

### `F10-offline-cached`

- Provider/account: Kimi / `kimi-default`.
- Preserve 45% last-good value.
- Status: `stale`.
- Error: `Kimi billing endpoint unavailable; local presence only`.
- Updated: `1h 12m ago`.
- Purpose: offline-equivalent cached path using an existing provider error.

### `F11-long-labels`

- Provider label transport value:
  `OpenAI Organization Production Sandbox — Southeast Asia`.
- Account: `organization-production-sandbox@example.test`.
- Plan: `Enterprise workspace with centrally managed weekly limits`.
- Detail label:
  `Organization-wide weekly accelerated-model allocation`.
- Reset:
  `Resets Tuesday, 18 August 2026 at 23:59 Indochina Time`.
- Error:
  `Provider response could not be refreshed; showing the last successful quota snapshot`.
- Purpose: wrapping, truncation, help tags, VoiceOver full values, and toolbar
  overflow. These strings test transport only.

### `F12-layout-envelope`

- Providers: all seven desktop providers.
- Accounts: 12 total: OpenAI 3, Anthropic 3, and one for each remaining
  provider.
- Selected provider/account: Anthropic / third account.
- Selected detail: 4 metadata rows followed by 8 limit/detail rows.
- Longest row uses the `F11-long-labels` label and reset.
- Purpose: maximum expected design envelope, minimum-size scrolling, expanded
  width, and account-picker capacity. This is a layout envelope, not a new hard
  domain maximum.

### `F13-initial-loading`

- Providers/accounts: not yet available.
- Global status: `Loading usage`.
- Progress: indeterminate native `ProgressView`.
- No fake rows or placeholder percentages.
- Purpose: launch before first bridge snapshot.

### `F14-global-bridge-error`

- Providers/accounts: none materialized.
- Error: deterministic bridge test string
  `Usage presentation is unavailable`.
- Action: `Retry`.
- Purpose: full-window/popover failure distinct from no providers.

### `F15-destructive-pending`

Not applicable. The scoped product has no destructive data action. Test code
must assert no delete, revoke, reset-credit-consume, sign-out, or destructive
confirmation control appears in these surfaces.

## Fixture use by surface

| Surface | Baseline | Empty/loading | Stress | Recovery |
|---|---|---|---|---|
| Status items | F02 | F00, F13 | F11 | F06, F08 |
| Popover | F01 | F00, F13 | F03, F11, F12 | F06–F10, F14 |
| Usage Overview | F02 | F00, F13 | F11, F12 | F08, F14 |
| Usage provider detail | F01, F04, F05 | F13 | F03, F11, F12 | F06–F10 |

## Determinism requirements

- Freeze `now` at `2026-08-12T12:00:00+07:00` where relative text is generated.
- Fix locale to `en_US`, calendar to Gregorian, time zone to
  `Asia/Ho_Chi_Minh`, appearance per capture case, and display scale per harness.
- Do not fetch the network, read real credentials, or read the operator's usage
  store.
- Preserve source ordering exactly.
- Store fixture IDs in capture metadata and filenames.
- One fixture builder supplies the popover, Usage window, accessibility tests,
  and screenshot harness. No parallel HTML fixture authority.
