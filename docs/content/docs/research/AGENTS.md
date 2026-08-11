---
title: "Research documentation rules"
---

# Research documentation rules

These rules apply to every file below this directory.

## Current state only

- Research is a living description of the latest verified state, never a history of the research.
- Store only the latest verified value for every volatile fact, including versions, release dates,
  repository metrics, prices, limits, feature state, maintenance state, and benchmark results.
- Never retain superseded values, before/after snapshots, old release rows, change logs, or prose
  describing how a researched value used to differ. Git history is the only research archive.
- A refresh must update all volatile facts in the touched dossier to one declared verification
  cutoff. Never mix numbers or states collected at different cutoffs.
- When no current value can be verified, omit it or mark the current value unknown. Never substitute
  an older known value.
- Cite the newest primary evidence available. Keep an older study result only when it remains the
  latest available evidence for that exact claim; never present it as current product state.

## Prompts live outside documentation

- Never store research prompts, execution briefs, or reusable agent instructions under `docs/`.
- Store prompts under the repository-root `prompts/` directory as plain `.md` files, never `.mdx`.
- Documentation may link to a prompt's repository file, but prompts must not appear in documentation
  sidebars or be rendered as documentation pages.
