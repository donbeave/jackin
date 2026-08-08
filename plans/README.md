# Implementation Plans

Plans hold **unfinished** multi-step work. Fully shipped plan bodies are removed after source audit; code and git history are the source of truth.

## Active unfinished

| Path | Scope | Status |
|------|--------|--------|
| [agent-status/](agent-status/) | Product detection (real goldens, pack rewrite, live authority, signed remote packs) | Open residuals; authoritative summary: `docs/content/docs/roadmap/(agent-orchestrator-research)/(phase-2-operator-surface)/agent-runtime-status.mdx` |

## Terminal program records with open product residuals

These plan directories preserve executed decisions and evidence. Do not resume their numbered plans. Their unfinished product outcomes now live in the related roadmap item.

| Path | Historical program state | Current residual authority |
|------|--------------------------|----------------------------|
| [jackin-desktop/](jackin-desktop/) | Plans 001–009 and 011 done; plan 010 rejected because release authority was unavailable | `docs/content/docs/roadmap/(operator-surface)/native-macos-usage-menu-bar.mdx` — production activation/proof, live visual acceptance, deterministic render snapshots, and capture-gated Amp paid-plan support |
| [native-macos-usage-menu-bar/](native-macos-usage-menu-bar/) | Retired and superseded by the jackin❯ Desktop program | Same roadmap item; unresolved 003/004 activation and the still-relevant 013 acceptance/deferred candidates were reconciled there |

## Removed (shipped)

These program tracks shipped on PR #759 (`chore/rust-code-health-roadmap`) and were deleted after multi-agent verification (2026-07-13):

- Code-health numbered plans **003–069** + residual ledger (waves 0–6 drained)
- Launch-speed **001–008** (including 008c early restore-scan reuse)
- Goal prompts: `GOAL-CODE-HEALTH-AND-LAUNCH-SPEED`, `GOAL-CLOSE-ALL-REMAINING`

Individually verified codebase-health plans removed on 2026-07-15:

- **014** — OSC 8 hyperlink identity repointing fix
- **025** — deterministic-time seam and first boundary conversions

Shared TUI extraction plans **001–009** and their follow-through roadmap item were removed after the standalone TermRock repository, canonical-API migration, neutral-duplication cleanup, immutable latest-reviewed dependency, donor retirement, and ownership/test-boundary audit shipped. Durable boundaries live in the TUI reference documentation.

Application observability plans **001–016** and their roadmap item were removed after the complete direct-OTLP implementation, exact legacy-site and artifact-removal audits, real-receiver conformance, privacy/cardinality/volume/soak/performance proof, canonical documentation cutover, and green PR #793 checks (2026-07-18). Durable behavior lives in the application observability reference and run-telemetry guide.

The completed routine code-health plan archive was removed after audit. Its durable completion record lives in the published roadmap overview and git history.

Hard external pin only (no plan file): **iai-callgrind** — project CI has no valgrind; re-evaluate when a valgrind-capable runner exists.

Do not re-add numbered plan files without new residual evidence large enough for a dedicated PR.
