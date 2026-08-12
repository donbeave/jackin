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

## One information architecture

Every research page is one of five reader-facing types. Do not invent another shape.

### Shared page rules

- Frontmatter always contains a concise `title` and one-sentence `description`.
- The renderer owns the page title. Do not repeat it as an explicit `#` heading.
- Use sentence-case headings and preserve real initialisms such as API, CI, PR, and TUI.
- Put the answer before the supporting detail. Define specialized terms on first use.
- Use site-absolute links for published documentation and `<RepoFile>` for repository files.
- Use `**Research state:**` only on standalone studies and dossier indexes. Keep the value short: `Current`, `Needs refresh`, `Incomplete`, or `Reference`. Put nuance in normal prose.
- Keep implementation commitments and progress tracking in Roadmap. Research may state implications and link the owning roadmap item.

### Domain or category index

Order: purpose, browse cards, how to choose a page, and related domains. Every category with multiple studies gets a dedicated landing page. A category with one study uses that study as `index.mdx`, so parent cards never target an arbitrary child or add a one-card intermediary.

### Dossier index

Order: research question, headline findings, method and evidence, limitations and open questions, how to read, and related work. State one verification cutoff for volatile evidence. Link the external brief with `<RepoFile>` when one exists.

### Evidence chapter

Order: summary, question and scope, method, findings, implications for jackin❯, limitations and unknowns, sources, and related work. Omit a section only when it truly does not apply; do not rename it to a synonym.

### Standalone study

Order: summary, research question, current evidence, analysis or design implications, limitations and open questions, sources, and related work. Alternatives may appear between analysis and limitations.

### Supporting reference

Registers, command catalogs, image galleries, and watchlists state their purpose and usage first, then present entries in the reader's decision order. They still carry standard frontmatter and evidence cutoffs where claims are volatile.

## Evidence contract

- Put evidence near the claim it supports. End each study with `## Sources`; use `## Method` for local measurements.
- Prefer descriptive links to primary sources. Record the exact release, tag, commit, issue, or document section when material.
- State a `YYYY-MM-DD` verification cutoff for volatile claims. One page or dossier uses one cutoff.
- Mark indirect evidence and confidence limits explicitly. Unknown remains unknown.
- Local measurements use checked-in tools or a fully reproducible procedure. Never cite an ephemeral host path.

## Navigation and scale

- `meta.json` titles use sentence case with correct initialisms. All use two-space JSON indentation and `defaultOpen: false` below the domain level unless deliberate.
- Number multi-page dossier chapters in reading order. Use absolute docs routes in chapter maps.
- Split a page when independent reader questions push it beyond roughly 400 lines. Preserve one clear question per page.
- `cargo xtask research check` enforces sidebar parity, frontmatter, state-label syntax, page titles, link shape, and page size. Page-type section order and evidence quality remain review requirements. Run it with the docs build, repository-link check, typecheck, and tests after changing this tree.
