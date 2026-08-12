# Current token-optimization tools research brief

> **Current-state rule:** Verify one current cutoff, publish only the latest value and state found at
> that cutoff, and replace superseded findings instead of preserving them. Git history is the only
> archive. If a current value cannot be verified, report it as unknown rather than using an older
> value.

## Mission

Re-research the latest versions of **Caveman**, **RTK**, **Headroom**, and **lean-ctx**. Find other fast-growing tools in the same token-optimization market. Produce a clean, current, objective comparison that explains what each tool changes, what benefit it can provide, where it is a poor fit, and how strong the supporting evidence is.

## Required questions

1. What exact layer does each tool affect: model output, shell observations, API-wire input, native file reads, retrieval, history, tool schemas, or prompt representation?
2. Is the transform deterministic, lossy, reversible, cache-safe, and local?
3. What is the latest stable release and current maintenance state?
4. Which reported savings are payload ratios, which are end-to-end token changes, and which are accepted-task cost changes?
5. Did an independent evaluator reproduce the claim while holding task quality constant?
6. What fixed overhead, latency, compute, host writes, telemetry, licensing, and operational risks accompany the saving?
7. Which rising tools add a genuinely different mechanism rather than another wrapper around the same one?
8. Which workload is each tool good for, and what measurement should precede adoption?

## Evidence policy

- **T1 — observed mechanism or metadata:** source, release artifacts, registries, reproducible local inspection.
- **T2 — controlled independent evidence:** paired or randomized task runs on the current release with version, model, quality, and token classes reported.
- **T3 — observational evidence:** replay or production field data without a randomized control.
- **T4 — first-party claim:** vendor benchmark, README percentage, self-counter, or projection.

Percentages are never moved between denominators. A reduction in one large JSON payload is not a session reduction; a session-token reduction is not automatically a bill or subscription-quota reduction; raw-token savings do not prove accepted-task efficiency when retries, extra turns, quality, and prompt-cache behavior differ. Results from superseded tool versions are excluded rather than projected onto current code.

## Deliverables

- Current release/adoption register with one declared verification cutoff and direct sources.
- Equal-depth comparison of the four named tools.
- Independent-evidence table and explicit conflicts with vendor claims.
- Rising-tools watchlist separated into direct compressors, retrieval/prevention tools, and adjacent packers.
- Workload-based selection guide, composition rules, and a neutral benchmark protocol.
- No historical release narrative, superseded architecture, or benchmark from an older tool version in the active dossier.

## Stop condition

The refresh is complete only when every active page describes the state at the declared current cutoff, superseded snapshots have been retired, every load-bearing external claim has a direct URL, the docs/research gates pass, and the result states uncertainty instead of manufacturing a universal winner.
