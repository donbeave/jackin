# Desktop visual fixtures ↔ `jackin-usage` data contract

HTML mock numbers are **fixtures** that must stay consistent with Rust host
presentation APIs. Implementers render **Rust strings** mechanically; they do
not re-derive %.

## Status bar (compact dual stack)

| Visual | API field | Rule |
|---|---|---|
| Bottom stack `%` | `HostProviderGlanceRow.bar_label` | `"57%"` or `"–"` |
| Top stack countdown | Compact form of `reset_label` | From glance bucket `resets_at` when present |
| Glance bucket | Weekly for Codex/Claude/…; **Daily for Amp** | `glance_bucket` / `StatusSlot` — never Session, never min-of-all |
| Provider set | `DESKTOP_PROVIDER_ORDER` | Codex, Claude, Amp, Grok, Zai, Kimi, Minimax |
| Display name | `provider_display_label` | Codex→**OpenAI**, Claude→**Anthropic**, Grok Build→**xAI**, GLM/Z.AI→**Z.AI** |
| Strip ranking | Worst-first | Low remaining / soonest reset first (fixture shows Anthropic first) |

## Usage window (detail)

| Visual | API |
|---|---|
| Page title | `header` row / `provider_display_label` |
| Subtitle | `account` + optional `plan` |
| Status / Updated / Auth | `status`, `updated`, `auth` (`credential_origin` exact) |
| Each limit row | `bucket:<i>` from `usage_detail_presentation` |
| Primary line | `remaining_label` e.g. `57% left` |
| Pace lines | Flattened pace segments (`" · "` split) |
| Reset line | `reset_label` alone (trailing) |
| Bound-only row | e.g. Amp Credits `$4.76`, Limit Reset Credits text — **no glance %** |
| Meter | `meter_percent` from `usage_bucket_presentation` |

### Codex bucket order (labels)

Session → Weekly → Codex Spark 5-hour → Codex Spark Weekly → Limit Reset Credits → Credits (when present).

### Amp

- **Bar / glance:** Daily % only.  
- **Window also:** Credits / bounds as detail-only (never status-bar %).

## Consistency rule

If the bar shows OpenAI **57%**, the Usage window **Weekly** row for that
selected account must show **57% left**. Session/Spark/etc. appear **only** in
the window.

## Source

`crates/jackin-usage/src/host.rs` (`HostProviderGlanceRow`, `provider_glance_rows`)  
`crates/jackin-usage/src/usage/format.rs` (`usage_detail_presentation`, `usage_bucket_presentation`)  
`crates/jackin-usage/README.md`
