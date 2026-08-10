# Desktop visual fixtures ↔ `jackin-usage` data contract

HTML mock numbers are **fixtures** that must stay consistent with Rust host
presentation APIs. Implementers render **Rust strings** mechanically; they do
not re-derive %.

**Source of truth for craft:** `plans/previews/desktop-ui/index.html` + this file.  
**Source of truth for numbers / labels:** `crates/jackin-usage` (never invent in Swift).

## Status bar (compact dual stack)

| Visual | API field | Rule |
|---|---|---|
| Bottom stack `%` | `HostProviderGlanceRow.bar_label` | `"57%"` or `"–"` |
| Top stack countdown | Compact form of `reset_label` | From glance bucket `resets_at` when present |
| Glance bucket | Weekly for Codex/Claude/…; **Daily for Amp** | `glance_bucket` / `StatusSlot` — never Session, never min-of-all |
| Provider set | `DESKTOP_PROVIDER_ORDER` | Codex, Claude, Amp, Grok, Zai, Kimi, Minimax |
| Display name | `provider_display_label` | Codex→**OpenAI**, Claude→**Anthropic**, Grok Build→**xAI**, GLM/Z.AI→**Z.AI** |
| Strip ranking | Worst-first | Low remaining / soonest reset first (fixture shows Anthropic first) |
| Multi-account | Selected account only | Glance row is **selected-account-aware** (`set_selected_account`) |

## Multi-account APIs

| Visual / action | API | Fields (render only) |
|---|---|---|
| Account list for a surface | `list_accounts(surface_id)` | `account_key`, `account_label`, `plan_label?`, `selected`, `remaining_percent?`, `status_word` |
| Switch account | `set_selected_account(surface_id, account_key)` | Then re-fetch glance + detail for that surface |
| Provider sidebar trail | `HostProviderGlanceRow` after select | `bar_label`, `account_label`, `glance_remaining_percent`, `severity` for **selected** account |
| Detail card | `usage_detail_presentation` | Full metadata + every `bucket:<i>` for **selected** account |

### UI systems (must stay distinct)

| Role | Chrome | When shown |
|---|---|---|
| **Provider** (primary) | Full-fill selection, brand plate, mini meter + % | Always in sidebar for each enabled surface |
| **Account** (secondary) | Soft inset **radio well** (sidebar nest) + left **chip strip** (detail) | Only when `list_accounts` length **> 1** |
| Single account | No switcher, no rail | Subtitle/meta carries the one `account_label` |

**Do not** reuse provider full-fill / brand-plate / mini-meter chrome for accounts.  
**Do not** use solid phosphor slab chips for selected accounts (phosphor **tint** + radio only).

## Usage window (detail)

| Visual | API |
|---|---|
| Page title | `header` row / `provider_display_label` |
| Subtitle | `account` + optional `plan` |
| Status / Updated / Plan / Auth | `status`, `updated`, optional `plan`, `auth` (`credential_origin` exact) |
| Each limit row | `bucket:<i>` from `usage_detail_presentation` |
| Primary line | `remaining_label` e.g. `57% left` |
| Pace lines | Flattened pace segments (`" · "` split) |
| Reset line | `reset_label` alone (trailing) |
| Bound-only row | e.g. Amp Credits `$4.76`, Limit Reset Credits text — **no glance %** |
| Meter | `meter_percent` from `usage_bucket_presentation` |

### Codex bucket order (labels)

Session → Weekly → Codex Spark 5-hour → Codex Spark Weekly → Limit Reset Credits → Credits (when present).

Every multi-account Codex fixture must keep this label order (depleted accounts still list the same buckets when the provider exposes them).

### Amp

- **Bar / glance:** Daily % only.  
- **Window also:** Credits / bounds as detail-only (never status-bar %).

## Consistency rule

If the bar shows OpenAI **57%**, the Usage window **Weekly** row for that
selected account must show **57% left**, the sidebar provider trail must show
**57%**, and the account radio/chip for that key must show **57%**.  
Session/Spark/etc. appear **only** in the window.

### OpenAI multi-account fixture (implementer lock)

| account_key | account_label | plan_label | Weekly glance (= bar) | Weekly detail |
|---|---|---|---|---|
| `a1` | `alexey@chainargos.com` | `Pro 20×` | **57%** | `57% left` (+ pace/reset) |
| `a2` | `alexey@zhokhov.com` | `Plus` | **0%** | `0% left` |

Switching a1→a2 must update: detail card, sidebar trail, account radio, detail chips.  
Overview lists **one inventory row per account** (not one row per provider).

## Source

`crates/jackin-usage/src/host.rs` (`HostProviderGlanceRow`, `provider_glance_rows`, account selection)  
`crates/jackin-usage/src/usage/format.rs` (`usage_detail_presentation`, `usage_bucket_presentation`)  
`crates/jackin-usage/README.md`  
UniFFI: `list_accounts`, `set_selected_account`, glance + detail DTOs in `jackin-usage-ffi`
