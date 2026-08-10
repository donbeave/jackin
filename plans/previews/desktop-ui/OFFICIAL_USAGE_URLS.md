# Official provider usage pages (Desktop “Open usage page”)

Links open the provider’s **own** usage / quota / billing surface in the
browser. jackin❯ desktop never scrapes these pages — they are escape hatches
when the operator wants the source of truth.

Verified 2026-08-10 against provider docs / official consoles. Prefer HTTPS
canonical paths (not transient `#hash` SPA routes when a clean path exists).

| `surface_id` | Display | Official usage URL | Notes / evidence |
|---|---|---|---|
| `codex` | OpenAI | https://chatgpt.com/codex/settings/usage | OpenAI Codex pricing FAQ: “Codex usage dashboard” |
| `claude` | Anthropic | https://claude.ai/settings/usage | Community + product; prefer path over `…/new#settings/usage` |
| `amp` | Amp | https://ampcode.com/settings | Amp manual: credits / balance in settings (`amp usage` CLI peer) |
| `grok` | xAI | https://console.x.ai/team/default/usage | xAI docs “Usage explorer” under team console |
| `zai` | Z.AI | https://z.ai/manage-apikey/coding-plan/personal/usage | Coding Plan personal usage under manage-apikey |
| `kimi` | Kimi | https://www.kimi.com/membership/subscription?tab=quota | Membership quota tab; coding CLI also: `/code/console` |
| `minimax` | MiniMax | https://platform.minimax.io/console/usage | Console usage; Token Plan detail also under Billing → Token Plan |

## Alternatives (do not default)

| Provider | Alt URL | When |
|---|---|---|
| OpenAI | https://chatgpt.com/codex/cloud/settings/analytics | Some accounts see analytics there; official FAQ still cites `…/settings/usage` |
| Kimi | https://www.kimi.com/code/console | Kimi Code 5h/weekly meters |
| MiniMax | https://platform.minimax.io/user-center/payment/token-plan | Token Plan subscription remains (docs) |
| xAI | https://console.x.ai/team/default/billing | Spend / credits, not the usage explorer |

## UI rule

- One control per **provider** detail: **Open usage page** (external browser).
- Label is fixed English; URL is looked up by `surface_id` only (no invented paths in Swift beyond the table).
- Hide the control only if `surface_id` is unknown (should not happen for `DESKTOP_PROVIDER_ORDER`).

## Limit Reset Credits (Codex)

Rust `CodexResetCredits::detail_label` owns visible copy, e.g.:

`2 manual resets available · Next expires <relative>`

Desktop should surface **all** segments already in `usage_detail_presentation`
for that bucket (count + next expiry). When fixture/API expose more windows,
show them as secondary lines (Available / Next expires / remaining windows) —
never invent counts beyond Rust.
