# A1 runnable concept handoff

Status: **implemented and explicitly confirmed by the operator on 2026-08-12**

## Run

```sh
mise run desktop-build -- 0.6.0 1
open -n native/dist/JackinDesktop.app --args \
  --fixture F03-multi-account --open-usage --selection codex
```

Popover proof:

```sh
open -n native/dist/JackinDesktop.app --args \
  --fixture F03-multi-account --open-popover --selection codex
```

Optional arguments are `--appearance light|dark`, `--window-size WIDTHxHEIGHT`,
`--selection overview|SURFACE_ID`, `--open-usage`, and `--open-popover`.

## Final visual proof

- [Light, sidebar visible](evidence/concept/usage-brand-light-F03.png)
- [Light, sidebar collapsed](evidence/concept/usage-brand-light-collapsed-F03.png)
- [Dark, sidebar visible](evidence/concept/usage-brand-dark-F03.png)

The expanded/collapsed pair proves one leading sidebar button remains visible in
the same toolbar slot. UI automation separately proves one matching control,
stable coordinates, changing Hide/Show semantics, and hit testing in both
states.

## Stable fixtures

The runnable catalog implements `F00` through `F14` from [Fixtures.md](Fixtures.md).
It is process-local, reads no live credentials or usage store, and performs no
network refresh. One catalog drives both hosts, unit tests, UI automation, and
real capture.

## A1 component proof

| Region | Native owner | Layer |
|---|---|---|
| Provider popover | `NSPopover` + SwiftUI `Form` | System functional chrome + content |
| Account selection | `Picker` with menu style | Functional control |
| Limit rows | `LabeledContent` + `ProgressView` | Content |
| Usage shell | `NavigationSplitView` | Functional navigation + content |
| Usage sidebar | selection `List` | Functional navigation |
| Sidebar visibility | fixed leading SwiftUI toolbar `Button` + `NavigationSplitViewVisibility` | System functional chrome |
| Product signature | generated adaptive `jackin❯ by tailrocks` wordmark | Noninteractive content identity |
| Overview | `Table` | Content |
| Provider detail | inset `List` | Content |
| Usage toolbar/window | `NSToolbar` through SwiftUI toolbar hosting | System functional chrome |

No region uses custom `glassEffect`, `GlassEffectContainer`, custom material,
blur, saturation, border, shadow, or CSS-derived geometry. macOS owns popover,
sidebar, toolbar, menu, picker, button, and window material.

## AppKit boundary

AppKit owns the menu-bar status items, real `NSPopover`, native window lifecycle,
and unified toolbar hosting. SwiftUI owns all visible content and navigation.
The capture-only launch seam anchors the same `NSPopover` to a transparent 2×2
non-interactive panel when no physical status-item click exists; normal product
interaction remains status-item anchored.

## Gates

Run:

```sh
mise run desktop-format-check
mise run desktop-lint
mise run desktop-test
mise run desktop-deadcode
mise run desktop-test-ui
mise run desktop-verify
```

The operator passed this gate with `I confirm the runnable A1 native concept.` Production execution is tracked in [ProductionPlan.md](ProductionPlan.md).
