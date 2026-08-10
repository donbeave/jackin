# jackin❯ desktop visual specification

This directory is the durable visual source of truth for jackin❯ desktop:

- [`index.html`](./index.html) defines the system menu-bar scene, status-item interactions, context menu, and full Usage window.
- [`popover.html`](./popover.html) defines the complete Overview and provider popover in Dark and Light appearances.

Open the HTML directly in a browser and use its built-in theme and state controls. The composed pages—not historical screenshots, progress logs, or an implementation-specific approximation—define the intended look and feel.

## Current implementation status

The current native implementation is an acceptable functional baseline, but it is **not** visual parity. It remains materially different from the HTML in composition, spacing, density, materials, hierarchy, and overall feel. We are deliberately merging that baseline and will continue visual alignment in a follow-up pull request. Never treat the current Swift pixels, old screenshots, or passing structural tests as authority over these HTML pages.

## Product boundary

- Brand rich text is always **jackin❯ desktop**. Code identifiers, paths, commands, package names, and URLs use `jackin` without the chevron.
- The desktop app shows subscription and quota **limits only**: remaining/used percentage, reset timing, plan/status, and provider-supplied bounded caps.
- Never add token prices, cost estimates, spend history, usage trends, sparklines, aggregate-spend charts, or cost rankings.
- Rust owns provider detection, account selection, quota semantics, ordering, severity, refresh behavior, and every displayed data string. Swift is display and interaction only.
- Do not invent provider data, credential explanations, percentages, bucket labels, or reset copy in Swift.

## Surface contract

### Status items

- Use one native status item per auto-detected provider, ordered by Rust's burn-first ranking and capped by the Rust presentation.
- Status items use transparent template marks with compact countdown and percentage text. They have no colored plate or glass capsule.
- Left-click opens the full popover focused on that provider. Do not substitute a simplified mini-popover.
- Right-click opens exactly: **Open Usage Window**, **Refresh**, separator, **Quit jackin❯ desktop**.

### Popover

- Keep the complete HTML information architecture: Overview, provider selection, account selection, account metadata, every Rust-provided limit row, and the Usage-window action.
- Provider selection and account selection are separate visual systems. Provider navigation is primary; account navigation is secondary and left-aligned.
- Preserve HTML hierarchy and density. Do not collapse the design into sparse cards or generic settings rows.
- Each quota row renders the Rust presentation mechanically: hero/remaining label, pace text, reset line, and meter. Meter geometry is exact; `0%` means an empty track.

### Usage window

- Use a real native macOS window with unified toolbar/titlebar behavior.
- Match the HTML's continuous shell, floating glass navigation, solid readable content, provider/account nesting, and single divided limit-list.
- Do not build a generic three-pane admin UI, repeat provider progress in multiple places, or restate the same quota as tiles plus cards.
- Provider rows show identity; account rows own account-specific glance percentage and mini-meter.

## Visual language

- Map the CSS custom properties in the HTML to named Swift tokens. Avoid rogue hex values.
- Phosphor is reserved for selection, calls to action, the `❯` brand mark, and high-status emphasis.
- Brand colors belong on provider marks/plates, not on quota meters.
- Quota states use the HTML's high, medium, low, and depleted bands.
- Preserve the HTML's label/secondary/tertiary text hierarchy, SF system type, monospaced metrics, radii, and spacing rhythm.
- Liquid Glass belongs to navigation and control chrome only. Content remains on readable standard material. All availability and accessibility fallback behavior stays centralized in `GlassFallbacks.swift`.
- System-owned menu-bar, window, traffic-light, focus, keyboard, contrast, and Reduce Transparency behavior remains native rather than pixel-simulated.

## Data mapping

- Desktop provider order/domain: OpenAI (`codex`), Anthropic (`claude`), Amp, xAI (`grok`), Z.AI, Kimi, MiniMax.
- Status and account glance use the Rust-selected glance bucket: Weekly for most providers, Daily for Amp Free.
- The Usage window renders every row returned by `usage_detail_presentation`; status/sidebar glance never substitutes Session or the minimum of all buckets.
- The same selected account must show the same glance percentage in its status item, sidebar/account row, and matching Weekly/Daily detail row.
- Multi-account selection uses `list_accounts` and `set_selected_account`; switching account refreshes every dependent surface.
- Credential source is the exact Rust `credential_origin` string. No resolver narrative appears in the app.
- Provider usage links remain defined by `ProviderUsageLinks` and open through the system browser.

## Follow-up implementation rule

Future visual work starts by opening both HTML files in Dark and Light modes, then comparing the running native app directly against them. Temporary captures may be produced outside the repository, but progress screenshots, visual-diff artifacts, generated baselines, and execution journals are not durable source files and must not be committed. Tests may protect behavior and architecture; they must not be used to claim visual parity without operator review of the running app.
