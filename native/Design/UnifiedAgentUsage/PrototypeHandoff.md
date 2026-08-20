# Prototype Handoff — Unified Agent Usage

Status: PRECONDITIONS MET — selection A without H recorded 2026-08-20; live
blessing still required before any READY claim

This is the exact gate from approved design to the committed runnable prototype.
It does not replace live blessing or `SIGNOFF.md`.

## Preconditions

All must exist before prototype source is written:

1. `ExperienceBrief.md` records human approval with selector and date. ✅
   Approved by Alexey Zhokhov, 2026-08-20.
2. `Alternatives.md` records selected A, B, or G; optional H; selector and date;
   chosen hierarchy, toolbar/accessory, minimum-width, and popover structure;
   why the winner won; why every unselected eligible direction lost; and risks. ✅
   A without H, Alexey Zhokhov, 2026-08-20.
3. `AntiReferences.md` appends the newly rejected eligible directions with
   reason, correction, and learned rule. ✅ B, G, and H appended 2026-08-20.
4. The selected direction is compatible with `NativeComponentMap.md` and every
   canonical record/subscenario in `Fixtures.md`. ✅ A maps to the
   component-map sidebar/split/toolbar/accessory/popover regions and binds to
   the canonical fixtures without a new tuple.

Preconditions 1–4 are met as of 2026-08-20; the prototype invocation below is
authorized. Live blessing and `SIGNOFF.md` remain mandatory after the package
exists.

## Exact invocation and package

After the preconditions, invoke
`$tailrocks-skills:tailrocks-macos-prototype prototype unified-agent-usage`.
Create and retain this package:

```text
native/Design/Prototypes/UnifiedAgentUsage/
├── Package.swift
├── Sources/UnifiedAgentUsageProto/
│   ├── ProtoMain.swift
│   ├── Fixtures.swift
│   └── <production-liftable views>.swift
├── Regions.md
└── SIGNOFF.md
```

The package follows the audited Swift project baseline. It contains fixture data
only: no credentials, network, provider CLI, persistence, broker, or production
application state.

## Revision-bound inputs

At package creation, `SIGNOFF.md` names the exact Git commit and path for every
consumed artifact:

- `ExperienceBrief.md`
- `NativeComponentMap.md`
- `Alternatives.md`
- `AntiReferences.md`
- `Fixtures.md`
- `BaselineVisualQA.md`
- `SwiftProjectReadiness.md`
- `SwiftBestPracticesReview.md`

A later rendering change or input revision invalidates blessing until the live
walk is repeated and the human records a new approval.

## Fixed launch contract

The executable accepts only `--tr-scenario`, `--tr-appearance`, `--tr-window`,
`--tr-reduce`, and `--tr-backdrop` with the standard skill semantics. `default`
is an exact F02 alias. Unknown scenarios and malformed sizes fail nonzero. The
harness wipes its defaults domain, freezes fixture time, disables restoration
under a window clamp, stabilizes backdrop/appearance/geometry, then prints
`TR-READY <windowNumber>`.

Every executable scenario and subscenario in `Fixtures.md` renders through that
contract. No incumbent `--fixture` flag, production visual fixture, or custom
capture loop enters the package.

## Live blessing gate

Before any screenshot baseline, the user walks the running prototype through:

- every executable scenario and subscenario;
- `default` alias equivalence;
- both light and dark;
- Usage at 760 × 500, 920 × 620, and 1200 × 760;
- popover at 380 × 520;
- every declared process-local reduction, task sequence, locale/direction, and
  display/resize state that can be evaluated live.

`SIGNOFF.md` enumerates every walked combination, pending post-signoff capture
and real-settings work, and anything not proven live. Only the human writes the
final `Blessed: YYYY-MM-DD by <name>` record. An empty Blessed field means draft.
No agent or subagent may infer approval from a passing build, test, or capture.

## `Regions.md` gate

Before post-signoff visual QA, `Regions.md` contains one executable row for every
visible region in the selected prototype. Each row records region, component-map
class, top-left point rect, match mode, and budget. Inventory must cover at least:

- provider status items and context menu;
- focused popover host, title, provider content, account selector, and footer;
- Usage window chrome, split, toolbar, top accessory, sidebar, Overview, detail,
  empty/loading/global failure, and provider-local feedback;
- Settings host/content, main command model, scrolling/focus presentation, and
  app icon wherever the prototype renders them;
- every selected-alternative-only region.

Native and native-composed control internals use structural accessibility-tree
matching. Custom or product-drawn content uses a point rect and explicit changed-
pixel budget. Glass pixels are compared only under identical deterministic
backdrops. No region may be omitted, use a whole-window zero-diff claim, or leave
content/custom budget blank. Cross-binary metadata names binary/version, OS/SDK,
scale, profile, appearance, size, backdrop, and scenario.

## Post-signoff handoff

Only after recorded human blessing does `tailrocks-macos-visual-qa` drive the
prototype through the five standard flags. That lane freezes the complete
baseline, executes real accessibility settings with restoration proof, performs
the accessibility/interaction audit, and applies `Regions.md`. Prototype source
never takes screenshots and no bespoke diff stack is added.

After blessing, the roadmap Desktop screen gains a Design pointer to
`native/Design/Prototypes/UnifiedAgentUsage/SIGNOFF.md`. Before blessing, no such
pointer and no READY claim are valid.
