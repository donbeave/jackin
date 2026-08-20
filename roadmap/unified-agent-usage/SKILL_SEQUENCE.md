# Skill Application Sequence — Unified Agent Usage

- **Roadmap item**: [README.md](README.md) (status: READY)
- **Open PR**: #898 on `chore/roadmap-unified-agent-usage`
- **Delivery constraint**: Finalization and planning remain on this branch and
  PR. Production implementation receives its own later delivery branches/PRs
  according to repository policy.

## Completed evidence

- architecture and provider research;
- Swift project-readiness and best-practices audits;
- incumbent macOS visual baseline and structural alternatives;
- human selection of alternative A without H;
- blessed dark-only runnable prototype, production mapping, and complete
  operator matrix in `native/Design/Prototypes/UnifiedAgentUsage/SIGNOFF.md`;
- confirmed Console Overview/Account Detail schematics and lifecycle states;
- confirmed compact CLI output;
- confirmed Capsule Overview and multi-account detail grammar.

## Completed gate

`tailrocks-finalize unified-agent-usage` closed the product frontier on
2026-08-21. A fresh-context planning dry run reported no guesses or user
questions, so the roadmap is READY.

## Next gate

`tailrocks-plan unified-agent-usage` runs immediately after READY on the same
branch and PR. It owns gap research, technical-contract closure, coverage
ledger, executable work-item plans, and `plans/unified-agent-usage/GOAL.md`.
It must consume the roadmap's settled decisions, open research questions,
planning-owned technical closure, blessed native reference, and confirmed TUI
schematics without reopening product choices.

## After planning

Refresh PR #898 so its body reflects READY and the plan package, then run the
repository's review and merge gates. Implementation branch/PR topology comes
from the approved plan and repository contribution rules, not this shaping
artifact.
