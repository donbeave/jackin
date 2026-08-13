# jackin❯ desktop (native)

Display-only Swift shell over `jackin-usage-ffi` (UniFFI). Product: **jackin❯ desktop**
(`JackinDesktop.app`). Rust owns probes, cache, severity, and every usage number.

> **CLAUDE.md = symlink to AGENTS.md beside it** — recreate: `ln -s AGENTS.md CLAUDE.md`.

## Hard rules

- **Display-only Swift.** No HTTP/OAuth/CLI scrapes, no second provider matrix, no
  config/workspace discovery, credential/path resolution, account deduplication, or
  inventing percentages. Numbers, identities, provenance, diagnostics, and limit
  strings come from UniFFI / Rust only. Production passes no host paths to the bridge.
- **Broker client only.** Refresh sends intent once and renders Rust generation/phase.
  Swift never schedules provider work, owns a retry deadline, or treats task
  cancellation as single-flight authority. Active manual/background requests join;
  broker failure preserves last-good data and fails closed.
- **Limits only — never token price or historical usage trend.** The status item,
  glance popover, Usage window, and Settings show **subscription / quota limits
  only** (remaining or used %, dual-bucket stacks, resets, plan/status, multi-
  account switcher, provider-supplied **limit** windows). **Never** implement:
  - token unit prices or “cost of this usage” money-as-price surfaces
  - historical usage or spend **trends** (sparklines, bar charts, 30-day series)
  - aggregate-spend donuts, cost legends, ranked spend-by-model UI
  - Buy Credits or other commercial write actions
  OpenUsage/CodexBar may include those — **do not copy them**. See root
  product limits-only rules and the `jackin-usage` crate agent rules.
- **System-owned Liquid Glass only.** `NSPopover`, `NavigationSplitView`, toolbar, sidebar, controls, and menus own material. No explicit glass, custom material, custom blur, content glass, or fallback visual lane.
- **Frozen desktop provider contract only** — Codex, Claude, Amp, Grok Build, GLM/Z.AI, Kimi, and MiniMax in Rust order. OpenCode belongs to the wider host universe but is intentionally excluded from jackin❯ desktop.
- Build/verify/run: `mise run desktop-*` / `cargo xtask desktop` only (no shell
  assembly scripts).
- **Test display parity:** after Desktop UI changes run `mise run desktop-test`
  (or `cargo xtask desktop test`). That drives host nextest + pure Swift harnesses
  (`StatusItemChipHarness`, `DesktopArchitectureLint`, `DesktopParityMatrixHarness`)
  proving multi-provider remaining % strips, dual-bucket, depleted countdown, and
  displayability of Rust-supplied Desktop catalog fixtures without inventing token
  prices or trends.
  Full Xcode CI may also run `cd native && swift test -c release`.
