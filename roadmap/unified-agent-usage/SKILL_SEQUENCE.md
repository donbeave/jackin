# Skill Application Sequence — Unified Agent Usage

- **Roadmap item**: [README.md](README.md) (status: SHAPING)
- **Skill source**: <https://github.com/tailrocks/tailrocks-skills> (manual-only; invoke each explicitly by name)
- **Open PR**: #898 `docs(roadmap): Unified Agent Usage Experience` on `chore/roadmap-unified-agent-usage`
- **Constraint**: Sketch-based handoff is excluded; design authority is the in-repo corpus under [`native/Design/UnifiedAgentUsage/`](../../native/Design/UnifiedAgentUsage/) plus live prototypes.

## Current position

Completed: research/readiness reviews, incumbent baseline, native design corpus,
human selection of A without H, and the runnable dark-only prototype reference.
The current gate is human visual signoff from the dark matrix in `SIGNOFF.md`.
Production adaptation follows `PRODUCTION_MAPPING.md`; prototype fixture, store,
and harness code is never lifted.

The sequence below resumes from that gate through design proof, Liquid Glass
craft, TUI design, finalization, planning, and the pull-request lifecycle.

## Phase 0 — Gate (human, no skill; selection complete)

Alternative A without H is recorded. Do not repeat selection. Complete the
dark-only operator matrix in
[`SIGNOFF.md`](../../native/Design/Prototypes/UnifiedAgentUsage/SIGNOFF.md)
without inferring approval from automated evidence.

```text
Use tailrocks-record-decision on roadmap item unified-agent-usage:
the human structural selection for the jackin❯ desktop Usage window is
alternative <A|B|G> (with|without H popover remix), per
native/Design/UnifiedAgentUsage/PrototypeHandoff.md. Propagate to
Alternatives.md and the design package.
```

## Phase 1 — Native baseline remediation (before any prototype code)

The readiness audit and best-practices review produced remediation inputs;
close them so the prototype and the real app share one sound baseline.

**1. `tailrocks-swift-project-setup` — remediate mode**

```text
Use tailrocks-swift-project-setup in remediate mode on native/:
close the approved gaps from native/Design/UnifiedAgentUsage/SwiftProjectReadiness.md
— generation, toolchain pins, deployment target and SDK lanes, local signing,
format/lint gates, test wiring, mise tasks — in never-broken slices. Do not
touch view code.
```

**2. `tailrocks-swift-best-practices` — refactor mode**

```text
Use tailrocks-swift-best-practices in refactor mode on native/Sources/:
close the remediation inputs from
native/Design/UnifiedAgentUsage/SwiftBestPracticesReview.md — strict
concurrency and actor isolation, state ownership, typed boltffi boundary,
availability guards with removal conditions, accessibility — preserving
observable behavior. Keep Swift display-only; Rust stays owner of usage data.
```

## Phase 2 — Liquid Glass prototype (proves the design)

**3. `tailrocks-macos-prototype` — prototype mode**

```text
Use tailrocks-macos-prototype in prototype mode for unified-agent-usage:
build the runnable Liquid Glass prototype for the human-selected alternative
from native/Design/UnifiedAgentUsage/ — brief, component map, fixture matrix
F00–F24, status-item projections — with the standard launch contract
(--tr-scenario/--tr-appearance/--tr-window/--tr-reduce/--tr-backdrop).
Treat views as interaction/visual reference through `PRODUCTION_MAPPING.md`,
not verbatim liftable production code. Drive every scenario live in front of
me, the dark appearance and Reduce settings, and record my
sign-off in SIGNOFF.md with the design artifacts' revision. Gaps found go
back to the design as findings; never resolved ad hoc.
```

**4. `tailrocks-liquid-glass` — audit mode, then remediate**

Runs against the prototype first, later against the production app.

```text
Use tailrocks-liquid-glass in audit mode on the unified-agent-usage prototype:
verify layer split (glass only in the functional layer), standard-component
adoption with adoption-deletion preflight, scroll edge effects, tint policy,
availability against the macOS 26 deployment target, and the accessibility
gate (Increase Contrast, Reduce Transparency, Reduce Motion). Report
violations; do not edit.
```

```text
Use tailrocks-liquid-glass in remediate mode on the unified-agent-usage
prototype: close the approved audit violations in never-broken slices,
preferring standard components over custom glass per the decision order.
```

## Phase 3 — Visual QA baseline (post-signoff only)

**5. `tailrocks-macos-visual-qa` — harness, then verify/regress**

```text
Use tailrocks-macos-visual-qa in harness mode on native/: install the
capture/drive harness (window-ID capture, atomic kill-launch-capture loop,
accessibility-tree driving) wired to the prototype's launch contract.
```

```text
Use tailrocks-macos-visual-qa in verify mode on the signed-off
unified-agent-usage prototype: capture the full state matrix — every fixture
scenario, dark only, Increase Contrast, Reduce Transparency, Reduce
Motion, declared window sizes — freeze the approved baseline, and confirm
each state answers where am I / what can I do / where can I go. Then
regress mode for every subsequent change against that baseline.
```

## Phase 4 — TUI design (console usage + capsule preview)

**6. `tailrocks-tui-design` — design mode**

The console usage route and the Capsule quota preview are ratatui surfaces;
the design reference is blessed golden frames, reusing the existing
`jackin-capsule` usage experience as the incumbent reference.

```text
Use tailrocks-tui-design in design mode for the jackin console Usage route:
top-level route opening on Overview, left-list/right-detail per
crates/jackin-console's workspace pattern, settled eight-provider order,
canonical accounts, and explicit loading / refreshing / empty / stale
last-good / partial-provider error / global failure states, `r` refresh,
Back/Escape, footer hints. Build the fixture-rendered gallery crate from the
same view functions the console will ship; iterate frames with me and record
my blessing as the byte-exact golden-frame contract. Reference experience:
crates/jackin-capsule usage dialog.
```

```text
Use tailrocks-tui-design in design mode for the jackin-capsule quota preview:
membership only from the fully resolved instance launch configuration, rows
ordered by resolved agent then canonical account, typed agent_uninitialized
with optional limits preview, no-capability / stale / resolution / refresh
states, selection preserved through initialization. Blessed golden frames as
the contract; no fixed global provider tabs.
```

## Phase 5 — Finalize and plan

**7. `tailrocks-finalize`**

```text
Use tailrocks-finalize on unified-agent-usage: close the remaining shaping
frontier — prototype sign-off recorded, TUI frames blessed, macOS design
rubric with zero hard failures — one question at a time with a recommended
answer each, and grant READY only when the readiness gate passes in full.
```

**8. `tailrocks-plan`**

```text
Use tailrocks-plan on unified-agent-usage: convert the READY item into
plans/unified-agent-usage/ — coverage ledger, gap research, OpenSpec spec,
one zero-context plan per work item in the settled slice order
(identity/protocol, broker/projection, CLI/diagnostics, console/Capsule,
FFI/Swift, native QA, signed distribution), plus GOAL.md. Every plan carries
the invariants: one broker authority, no direct provider fetch, Rust-owned
labels verbatim, limits-only surfaces.
```

## Phase 6 — Pull-request lifecycle (throughout, then at merge)

PR #898 is open now and keeps accruing commits this whole sequence; the
lifecycle skills apply at these moments:

**9. `tailrocks-refresh-pr`** — after each milestone batch lands (prototype
sign-off, TUI frames, finalize READY, plan package):

```text
Use tailrocks-refresh-pr on PR #898: reconcile title and body against the
current diff; keep accurate prose verbatim, rewrite drifted sections,
re-select template sections the diff now earns.
```

**10. `tailrocks-review-pr`** — before asking to merge, and on any future
implementation PR:

```text
Use tailrocks-review-pr on PR #898: report verified findings only —
adversarially validated bugs, structural regressions with named restructures,
specialist lanes the diff triggers (docs, roadmap gates). Read-only; no
--comment unless I ask.
```

**11. `tailrocks-merge-pr`** — when the operator approves merge:

```text
Use tailrocks-merge-pr on PR #898: run the fail-closed gates — CI green,
blast-radius classification, metadata reconcile, the repo's pre-merge
worklist (roadmap freshness, docs-as-source-of-truth) — then merge with the
repo-selected method.
```

**12. `tailrocks-create-pr`** — for each implementation PR after planning
(one branch per slice from the plan):

```text
Use tailrocks-create-pr for the current change: branch per CONTRIBUTING.md
(<prefix>/<short-hyphen>), Conventional Commits subject with DCO sign-off,
body from the repository template, every placeholder filled.
```

(`tailrocks-checkout-pr` and `tailrocks-pr-template` are supporting skills —
checkout when resuming someone else's PR, template only if the repository's
`.github/PULL_REQUEST_TEMPLATE.md` is ever regenerated; neither is a required
step here.)

## Dependency summary

```text
human selection (gate)
  └─ record-decision
       └─ swift-project-setup remediate ── swift-best-practices refactor
            └─ macos-prototype (live sign-off)
                 └─ liquid-glass audit → remediate
                      └─ macos-visual-qa harness → verify (baseline frozen)
                           ├─ tui-design (console Usage)
                           ├─ tui-design (capsule preview)
                           └─ finalize → READY
                                └─ plan → plans/unified-agent-usage/
                                     └─ create-pr (per slice) → review-pr → merge-pr

refresh-pr on #898 after every milestone batch.
liquid-glass + macos-visual-qa regress re-run on the production app during
FFI/Swift and native-QA slices.
```
