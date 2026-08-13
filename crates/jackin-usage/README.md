# jackin-usage

Usage, telemetry, and token monitors for the `jackin-capsule` daemon.
Also owns the **Capsule-free host runtime** consumed by the macOS usage menu bar
and `jackin usage host snapshot`.

**Product surfaces (Capsule usage UI, jackin❯ desktop):** **usage limits only** —
remaining/used %, resets, plan/status. **Never** token unit prices or historical
usage/spend trends as product features.

## What this crate owns

- Token monitoring (`token_monitor`) and usage accounting (`usage`) for running agents.
- Host orchestration (`host`) — `HostUsageRuntime` for menu bar / CLI without Capsule.
- Rust-owned account discovery (`host/discovery`) — read-only global, workspace,
  role, and workspace-role enumeration; explicit profile/protected-source probes;
  pre-source and post-auth account deduplication; sanitized diagnostics.
- Usage snapshot persistence (`usage_snapshot_store`) and token-accounting telemetry (`telemetry`).
- Usage output shaping (`output`).
- Provider probes (`usage/<provider>.rs`). Amp API/CLI share
  `parse_amp_usage_output`; `Amp Free` maps to `StatusSlot::Daily`, while credit
  balances remain detail-only quota bounds.

## Architecture tier and allowed dependencies

**Infrastructure** (capsule-side + host menu-bar observability/accounting). Allowed
inward dependencies: `jackin-core`, `jackin-config`, `jackin-protocol`, and
`jackin-diagnostics`.
No dependency on `jackin-capsule` (which would be circular), `jackin-tui`,
`jackin-console`, `jackin-launch`, or any presentation crate.

UniFFI lives in sibling crate `jackin-usage-ffi`.

## Structure

| Module | Owns | Tests |
|---|---|---|
| [`lib.rs`](src/lib.rs) | crate root, re-exports | — |
| [`host.rs`](src/host.rs) · [`host/`](src/host) | Capsule-free host runtime | [`tests.rs`](src/host/tests.rs) |
| [`token_monitor.rs`](src/token_monitor.rs) · [`token_monitor/`](src/token_monitor) | token spend monitoring | [`tests.rs`](src/token_monitor/tests.rs) |
| [`usage.rs`](src/usage.rs) · [`usage/`](src/usage) | usage/pricing accounting | [`tests.rs`](src/usage/tests.rs) |
| [`telemetry.rs`](src/telemetry.rs) | telemetry emission | — |
| [`logging.rs`](src/logging.rs) | telemetry-level state and Capsule panic handling | — |
| [`usage_snapshot_store.rs`](src/usage_snapshot_store.rs) · [`usage_snapshot_store/`](src/usage_snapshot_store) | persistent usage snapshot store | [`tests.rs`](src/usage_snapshot_store/tests.rs) |
| [`store_backend.rs`](src/store_backend.rs) | turso SQLite import chokepoint | — |
| [`output.rs`](src/output.rs) | usage output shaping | — |

## Public API

Token-monitor and usage-accounting types consumed by `jackin-capsule`.
`host::HostUsageRuntime` for jackin❯ desktop and the host CLI.

Claude resolves macOS Keychain before file/env and classifies each refresh as
`UsageSnapshotPolicy::Shared` or `LocalOnly`. Local-only outcomes never adopt,
coordinate, persist, or materialize shared state.

`quota_pace_label` emits the Rust-owned `"<pace> · Runs out in <duration>"`
segment only when the exact projection precedes reset.

Grok decodes ACP billing `config`; server `subscription_tier` owns plan copy,
and prepaid/on-demand values render only as quota bounds.

Host display extensions (plan 008; presentation-time only, not persisted):

| API | Role |
|---|---|
| `usage::provider_display_label` | Shared Capsule/Desktop provider remap (`Codex`→`OpenAI`, …) |
| `usage::estimate_caption` | Honesty caption for estimated / local-log views |
| `usage::{UsageFormatPrefs,PercentStyle,ResetStyle}` | left/used + countdown/exact-clock prefs |
| `HostUsageRuntime::set_format_prefs` | Apply presentation prefs |
| `HostUsageRuntime::compact_status_bar_label_for` | Pinned compact status-item label |
| `HostUsageRuntime::compact_status_bar_strip` | Worst-first multi-surface strip |
| `HostUsageRuntime::overview_rows` | Overview rows for popover + Usage window |
| `HostUsageRuntime::next_refresh_label` | `Next update in …` / `Next update due` |
| `usage::usage_bucket_presentation` / `usage_display_status_label` | Rust-owned limits-only quota-bucket segments (shared by Capsule + Desktop) |
| `usage::usage_detail_presentation` | Rust-owned Capsule-parity provider-detail card (`UsageDetailPresentation`): fixed row order, position-based `bucket:<i>` ids, grouped `layout_lines`; consumed verbatim by the Capsule dialog and the Desktop Usage window |
| `host::HostProviderGlanceRow` / `HostUsageRuntime::provider_glance_rows` | Selected-account-aware seven-provider Desktop glance rows (`DESKTOP_PROVIDER_ORDER`) |
| `HostUsageRuntime::desktop_inventory` | Atomic canonical provider/account groups with complete display fields |
| `host::HostProbePolicy` | `Live` / `Disabled` (smoke-mode probe suppression) |

`CanonicalAccountIdentity` uses closed provider aliases; routing slugs never own
accounts. Presence-only evidence stays provider state. Each inventory scans durable
and shared inputs once and pins one durable source. `DESKTOP_PROVIDER_ORDER` is the
detected seven-provider boundary; OpenCode remains host-only.

Avoid cloning full usage views during account materialization — serialize from borrowed views/iterators.

## Desktop account contract

Keys hash the canonical surface with a provider subject or account label. Same
email across providers remains distinct. Empty, unknown, presence-only, and
fabricated local-auth labels never become keys.

`desktop_inventory` scans durable and shared inputs once, pins exactly one source per
durable fetch generation, merges provenance, and separates account lifecycle
from snapshot freshness. Selection accepts only keys owned by that surface;
stale choices clear, and only current accounts become implicit fallbacks.

Host Desktop discovery reads the global config plus every effective workspace/role
scope at open and before explicit manual Refresh. Background polling reuses the last
completed catalog and never rereads config or retries protected-source interaction.
The current catalog is membership authority: durable/shared history may enrich a
current account but cannot create one. Profile paths and protected values stay in
Rust; native DTOs contain only account identity, scope provenance, and sanitized
diagnostics. OpenCode and GitHub are outside the seven-provider Desktop quota catalog.

Capsule discovery is capability-only. It never scans host config or other host
accounts; broker transport and cross-process generation joining are owned by the
strict coordinator follow-up.

Each account owns its plan/status, remaining label and geometry, reset phrase
and exact reset, severity, recency, and error. Native clients render all DTO fields
exactly.

## How to verify

```sh
cargo nextest run -p jackin-usage -p jackin-usage-ffi
cargo clippy -p jackin-usage -p jackin-usage-ffi --all-targets -- -D warnings
```
