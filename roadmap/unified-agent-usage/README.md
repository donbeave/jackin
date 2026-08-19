# Unified Agent Usage Experience

- **Status**: DRAFT
- **Slug**: unified-agent-usage
- **Created**: 2026-08-20 · **Updated**: 2026-08-20
- **Plan**: — (plans/unified-agent-usage/ once planned)

## Intent

Finalize one agent usage experience across jackin❯ desktop, `jackin console`, the `jackin usage` command, and `jackin-capsule`.

## Vocabulary

## Decisions

## Capabilities

- Provide agent usage CLI output through `jackin usage`.
- Make agent usage available inside `jackin console`.
- Show subscription and quota usage limits only, including remaining or used percentage, reset countdowns, plan and status, and provider-supplied limit windows such as money caps when they are quota bounds, as required by [`AGENTS.md`](../../AGENTS.md).

## Screens

### Console usage

- **Purpose**: Show a basic usage overview plus detailed views per provider and account across all available agents and configurations.
- **States**: Overview; provider detail; account detail.
- **Key interactions**:
- **Design**: An intuitive TUI similar to the existing `jackin-capsule` usage experience.

### Desktop usage

- **Purpose**: Provide the agent usage experience as a native macOS app.
- **States**:
- **Key interactions**:
- **Design**: Swift and native Liquid Glass.

## Flows

## Data & integrations

## References

- [`crates/jackin-capsule/`](../../crates/jackin-capsule/) — existing capsule usage experience named as the console TUI reference.
- [`native/`](../../native/) — native macOS application surface.

## Research

## Must not

- MUST NOT display duplicated accounts in the console usage interface — each account should appear once across available agent configurations.
- MUST NOT show token unit prices, session cost estimates, spend-over-time history, usage trends, aggregate-spend charts, or cost rankings — [`AGENTS.md`](../../AGENTS.md) restricts usage surfaces to subscription and quota limits.

## Quality bar

- The console TUI feels very good and intuitive.
- The desktop app has a nice look and feel and presents a very native macOS Liquid Glass experience.

## Open questions

## Open research questions

- Does `jackin-capsule` currently display usage only from resolved configurations for agents available inside its Docker container, using each agent's relevant container configuration?

## Deferred

## Log

- 2026-08-20 — tailrocks-idea — created (DRAFT).
