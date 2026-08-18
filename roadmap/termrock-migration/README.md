# TermRock migration

- **Status**: DRAFT
- **Slug**: termrock-migration
- **Created**: 2026-08-19 · **Updated**: 2026-08-19
- **Plan**: — (plans/termrock-migration/ once planned)

## Intent

Migrate jackin❯ to use the latest and greatest TermRock (https://github.com/tailrocks/termrock), which is located locally at `/Users/donbeave/Projects/tailrocks/termrock`.

## Vocabulary

## Decisions

## Capabilities

## Screens

## Flows

## Data & integrations

## References

- https://github.com/tailrocks/termrock — upstream TermRock repository named in the request.
- `/Users/donbeave/Projects/tailrocks/termrock` — local TermRock checkout named in the request; head `e1d61f4d` ("feat: achieve Jackin-TermRock parity (#34)", 2026-08-17), 56 commits ahead of the rev the workspace pins.
- `Cargo.toml:118` — the workspace pins `termrock = "=0.11.0"` at git rev `5ff94ee117fd4a1b72fdd0d1b1847815055a93ac` (2026-07-17) with features `crossterm`, `serde`.
- `crates/jackin-capsule/src/tui/` — capsule TUI surface built on TermRock shared components (repository TUI table in AGENTS.md).
- `src/console/tui/` — host console TUI surface built on TermRock shared components (repository TUI table in AGENTS.md).
- `docs/content/reference/tui/index.mdx` — TUI design decisions; repository law requires reading it before any TUI change.

## Research

## Must not

## Quality bar

## Open questions

- What does "latest and greatest" pin to: the upstream repository's latest published release/rev, or the current state of the local checkout at `/Users/donbeave/Projects/tailrocks/termrock`? The request names both.
- After the migration, does the dependency keep the current exact-version + git-rev pinning style (`Cargo.toml:118`), or change how TermRock is pinned?

## Open research questions

- What changed in TermRock between the pinned rev `5ff94ee` (0.11.0, 2026-07-17) and the local head `e1d61f4d` (2026-08-17) — 56 commits, including "feat: achieve Jackin-TermRock parity (#34)" — and which of those changes break or alter APIs used by `crates/jackin-capsule/src/tui/` and `src/console/tui/`?

## Deferred

## Log

- 2026-08-19 — tailrocks-idea — created (DRAFT).
