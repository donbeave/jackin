# 05 — Verification ledger

Vetted: 2026-08-20
Source revision: `b0c2abbd58b7177c6bc9942116af50dfbff3fda7`
Questions: Which findings have reproducible source searches or executable proof, and which target contracts remain unimplemented?
Informs: unified-agent-usage

## Reproducible bypass audit

Run from repository root at the source revision above. The audit is static source
evidence; matching a path proves a route exists, not that it executes in every
runtime configuration.

### Provider work and alternate freshness owners

```sh
rg -l --glob '*.rs' 'run_claude_usage_diagnostic|refresh_credential_binding|request_refresh(_all)?|pending_usage_refresh|no_refresh|sync_host_cache|accounts\.db' crates | sort
rg -n --glob '*.rs' 'run_claude_usage_diagnostic\(|refresh_credential_binding\(|pending_usage_refresh|no_refresh|sync_host_cache|accounts\.db' crates/jackin crates/jackin-capsule crates/jackin-runtime crates/jackin-usage
```

Result: PASS for audit reproducibility. The result identifies:

- direct Claude diagnostic definition and Capsule call;
- the broker-owned `refresh_credential_binding` call;
- CLI `no_refresh`, `sync_host_cache`, and second `accounts.db` store;
- Capsule `pending_usage_refresh` scheduling.

Expected assertion: every production provider/refresh/cache route is classified
as canonical broker work, presentation-only read, or explicit bypass. A new
unclassified route fails architecture review.

### Exhaustive provider and outbound inventory

The first command inventories provider entry and fetch definitions. The second
inventories every network/process primitive in the provider implementation. Both
exclude tests. Definitions are deliberately separate from the third command so
a definition cannot be mistaken for an active production caller.

```sh
rg -n --glob '*.rs' --glob '!**/tests.rs' --glob '!**/tests/**' \
  '^pub(?:\(crate\))? fn (?:amp_snapshot|amp_api_key_snapshot|claude_snapshot|claude_view_from_wave|codex_snapshot|codex_profile_snapshot|grok_snapshot|grok_snapshot_from_rpc_result|kimi_snapshot|minimax_snapshot|provider_key_snapshot|provider_credential_snapshot|fetch_amp_api_usage|fetch_amp_cli_usage|fetch_claude_oauth_usage|fetch_claude_cli_usage|run_claude_usage_diagnostic|fetch_codex_rpc_usage|fetch_codex_oauth_usage|fetch_codex_oauth_usage_refreshing|fetch_codex_oauth_reset_credits|refresh_codex_access_token|fetch_grok_billing|fetch_grok_rpc_billing|fetch_grok_web_billing|fetch_kimi_usage|fetch_minimax_usage|fetch_zai_usage)\(' \
  crates/jackin-usage/src

rg -n --glob '*.rs' --glob '!**/tests.rs' --glob '!**/tests/**' \
  '(?:reqwest::blocking::Client::builder|\.send\(\)|Command::new\()' \
  crates/jackin-usage/src/usage.rs crates/jackin-usage/src/usage

rg -n --glob '*.rs' --glob '!**/tests.rs' --glob '!**/tests/**' \
  '\b(?:amp_snapshot|amp_api_key_snapshot|claude_snapshot|claude_view_from_wave|codex_snapshot|codex_profile_snapshot|grok_snapshot|grok_snapshot_from_rpc_result|kimi_snapshot|minimax_snapshot|provider_key_snapshot|provider_credential_snapshot|fetch_amp_api_usage|fetch_amp_cli_usage|fetch_claude_oauth_usage|fetch_claude_cli_usage|run_claude_usage_diagnostic|fetch_codex_rpc_usage|fetch_codex_oauth_usage|fetch_codex_oauth_usage_refreshing|fetch_codex_oauth_reset_credits|refresh_codex_access_token|fetch_grok_billing|fetch_grok_rpc_billing|fetch_grok_web_billing|fetch_grok_web_billing_request|fetch_kimi_usage|fetch_minimax_usage|fetch_zai_usage)\(' \
  crates | awk -F: \
  '$3 !~ /^[[:space:]]*(pub([[:space:]]*\([^)]*\))?[[:space:]]+)?fn[[:space:]]/'
```

Result: PASS for complete static inventory at the recorded revision. The eight
outbound primitives are the shared bearer GET in `usage.rs`, MiniMax HTTP,
Codex app-server, Codex token refresh HTTP, Grok ACP, Grok web HTTP, Amp HTTP,
and the shared CLI runner used by Claude/Amp. `provider_http_client` constructs
the client but does not itself perform I/O. Every production call match is
classified below:

| Production match class | Classification |
|---|---|
| `host/discovery.rs` Claude, Codex, Amp, Grok, and Kimi calls | Canonical broker executor path reached through `refresh_credential_binding`; Grok profile refresh intentionally calls the web fetch directly inside that authority. |
| `host/credential_resolver.rs` `provider_credential_snapshot` | Canonical broker capability path; dispatches configured secrets to Claude/Amp/Z.AI/Kimi/MiniMax/Grok adapters without returning the secret. |
| Calls among `usage/{amp,claude,codex,grok,kimi,minimax,zai}.rs` | Internal provider call chains below one selected broker executor: API/CLI fallback, Codex RPC/OAuth/token-refresh/reset-credit sequence, and Grok RPC/web fallback. Not independent freshness owners. |
| `usage.rs` dispatch within `provider_credential_snapshot` | Internal configured-credential dispatch below the broker capability path. |
| `jackin-capsule/src/client.rs` `run_claude_usage_diagnostic` | Active bypass: a direct provider CLI process outside the broker. It must be removed from production dispatch. |

Top-level `amp_snapshot`, `claude_snapshot`, `codex_snapshot`, and
`grok_snapshot` have definition matches but no non-test production caller; the
module-level `dead_code` expectation says they are retained provider fixtures.
They are latent I/O-capable alternatives and must not be wired into a consumer.
The inventory found no direct provider HTTP/process primitive in desktop, CLI,
console, runtime relay, or Capsule other than the explicit Capsule Claude
diagnostic bypass. This is a source audit, not a syscall trace; the later gate
must keep this inventory and add concurrent end-to-end proof.

### Identity, process ownership, deadlines, and queueing

```sh
rg -n --glob '*.rs' 'source-\{:04\}|leader\.pid|kill\(Pid::from_raw|ensure_usage_broker_with_executor|pending_usage_refresh|success_deadline_epoch|retry_deadline_epoch' crates/jackin-usage crates/jackin-runtime crates/jackin-capsule crates/jackin
```

Result: PASS for audit reproducibility. It locates ordinal `source-0001` identity,
PID-only leader liveness, live-broker early return, local Capsule post-flight
queue, and persisted success/retry deadlines. Expected assertion: planning must
remove ordinal identity and every caller-owned freshness path while retaining
one broker-owned deadline/generation state.

### Exact source excerpts used to classify load-bearing bypasses

```sh
sed -n '790,865p' crates/jackin-usage/src/host/discovery.rs
sed -n '530,585p' crates/jackin-usage/src/host/broker.rs
sed -n '775,815p' crates/jackin-usage/src/host/broker.rs
sed -n '210,285p' crates/jackin/src/cli/usage.rs
sed -n '230,288p' crates/jackin-capsule/src/daemon/multiplexer_utils.rs
```

Result: PASS. These excerpts prove respectively: order-derived source IDs; a
first owning process plus live-broker executor discard; PID-only takeover; the
CLI no-refresh broker bypass; and Capsule queued refresh state.

## Executed Rust proof suites

| Exact command | Result on 2026-08-20 | What it proves / does not prove |
|---|---|---|
| `rtk cargo test -p jackin-usage coordinator::tests -- --test-threads=1` | PASS — 14 passed, 266 filtered | Current single-flight, persistence, deadlines, failure, and recovery seams. Does not prove independent service lifetime. |
| `rtk cargo test -p jackin-usage host::broker::tests -- --test-threads=1` | PASS — 7 passed, 273 filtered | Current transport/election/scoped-operation seams. Does not prove PID reuse or client-owner exit survival. |
| `rtk cargo test -p jackin-runtime usage_relay::tests -- --test-threads=1` | PASS — 8 passed, 577 filtered | Relay authorization and capability routing. Does not prove target multi-account Capsule presentation. |
| `rtk cargo test -p jackin-capsule usage -- --test-threads=1` | PASS — 48 passed across 8 suites, 821 filtered | Current Capsule usage/cache/refresh behavior, including tests that expose queued-refresh defects. Does not prove resolved-launch inventory target behavior. |
| `rtk cargo test -p jackin cli::usage -- --test-threads=1` | PASS — 9 passed across 28 suites, 637 filtered | Current account formatting, verification, and second-cache behavior. It has no bare host overview or end-to-end instance transport proof. |
| `rtk cargo test -p jackin-usage-ffi bridge::tests -- --test-threads=1` | PASS — 8 passed, 3 filtered | Current nonblocking bridge/projection seams. Does not prove target versioned canonical envelope. |
| `rtk cargo test -p jackin cli::format -- --test-threads=1` | INCOMPLETE — 0 passed, 646 filtered | No matching JSON/schema evolution tests exist; zero tests is not a pass for the target contract. |
| `rtk cargo test -p jackin --test usage_broker_e2e -- --test-threads=1` | UNAVAILABLE ON THIS HOST — 0 tests | The integration target contains no macOS tests; no owner-exit or container/process proof was obtained. |

## Current proof gaps that planning must not mislabel

- Bare `jackin usage` host overview and `jackin console` Usage do not exist, so
  shared-adapter parity has no executable current test.
- The candidate V1 envelope is research input, not an implemented schema. There
  is no unknown-major, additive-field, stable-order, or JSON exit-code fixture.
- Instance `accounts`/`verify` tests cover formatting and trust evaluation, not a
  complete daemon-transport plus canonical-broker projection flow.
- Capsule tests exercise the current session-centered/fixed-tab model, not the
  target fully resolved launch-config inventory, `agent_uninitialized`, or
  multiple canonical accounts.
- The current macOS broker remains owned by an activating client process. The
  Linux/container end-to-end target executed zero tests here.

## Required implementation proof commands

These commands are targets for the later plans; they cannot pass until the named
behavior exists. Plans must bind them to exact test targets rather than leaving
them as prose:

```sh
rtk cargo test -p jackin-usage canonical_projection -- --test-threads=1
rtk cargo test -p jackin-usage broker_service_lifecycle -- --test-threads=1
rtk cargo test -p jackin-runtime usage_relay::resolved_launch_inventory -- --test-threads=1
rtk cargo test -p jackin-capsule usage_projection -- --test-threads=1
rtk cargo test -p jackin cli::usage::canonical_overview -- --test-threads=1
rtk cargo test -p jackin-console usage -- --test-threads=1
rtk cargo test -p jackin-usage-ffi canonical_projection -- --test-threads=1
```

Expected target assertions: one canonical account row per evidence identity; one
cross-process generation under concurrent CLI/console/Capsule/desktop callers;
owner-exit survival; catalog/credential revision replacement; exact host and
desktop orders; resolved Capsule membership; typed `agent_uninitialized` plus
optional preview; instance inspection; stable V1 human/JSON output and exit
semantics; no direct provider call from any consumer.

Names above are required plan-owned test targets, not claims that current Cargo
filters already exist. A zero-test result fails the later goal gate.
