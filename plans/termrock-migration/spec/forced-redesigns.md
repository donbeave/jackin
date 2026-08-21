# Forced redesigns and behavioral parity

## Purpose

The head makes three API surfaces private or setter-less; their jackin❯ wrappers must be re-hosted, and named parity tests prove the operator-visible behavior unchanged. Tests come first, against the old pin, so parity is proven rather than asserted.
Anchors: W1, B5, D9, D15 · Evidence: research/termrock-head-adoption/01-compile-break-inventory.md, 02-migration-doc-map.md (docs 0062/0065/0085)

## Requirements

### Requirement: Parity tests precede the bump
Characterization tests SHALL exist and pass against the OLD pin (`5ff94ee`) before any bump work, covering: (a) modal Esc-cascade — `open_sub` preserves the parent modal, `pop` restores parent and focus scope, `clear` closes the chain (console `ModalFlow` consumers; capsule ExitDirty → ExitInspect walk-back including its "Esc is ignored" rule — existing seam at `crates/jackin-capsule/src/tui/components/dialog/tests.rs:2338-2349`); (b) focus restore — `SurfaceFocus` owner transitions on tab/content moves and modal close (existing seams in `crates/jackin-tui/src/runtime/` tests); (c) launch diff scrolling — the offset handling is function-local in the launch run loop with NO existing test seam (`crates/jackin-launch/src/tui/run.rs:866-874` local state, writes at `:981-1085`), so this capability SHALL first extract it into a behavior-preserving, testable unit at the old pin, then pin its behavior. Old-pin type is termrock `DiffState` with `pub offset` (`widgets/diff.rs:27-31` at `5ff94ee`); the head renames/re-shapes it (`DiffViewState`, accessor-only offset).
Covers: B5, D9 · Evidence: research/termrock-head-adoption/01-compile-break-inventory.md (break classes), research/jackin-verification-tooling/01-gates-and-commands.md (test seams and runner)

#### Scenario: Esc cascade parity witness
- **GIVEN** a capsule ExitDirty dialog open with ExitInspect reachable
- **WHEN** the operator walks forward and presses Esc at each stage
- **THEN** the test asserts the exact pre-bump modal/focus outcome at each step, including Esc being ignored where the pre-bump dialog doc says so

#### Scenario: Focus restore parity witness
- **GIVEN** a console editor screen with a modal opened from a focused content block
- **WHEN** the modal closes via cancel and via commit
- **THEN** the test asserts focus returns to the pre-bump owner in both paths

#### Scenario: Diff scroll parity witness
- **GIVEN** a launch failure diff taller than its viewport
- **WHEN** scroll input moves the view and a redraw occurs
- **THEN** the test asserts the visible-line window matches pre-bump behavior

### Requirement: Wrappers re-host on head primitives without public-contract change
`jackin-tui`'s `SurfaceFocus`/`ModalFlow` (and the launch diff-scroll ownership) SHALL be re-implemented on the head's `InteractionScene`/`FocusGraph`/`OverlayStack` and `DiffViewState` accessor surface while keeping their existing public product contracts, so the parity tests pass unmodified after the bump. The facade keeps its product runtime traits (D15 — facade end-state decision deferred; this is an internal re-host, not a contract change).
Covers: W1, B5, D9, D15 · Evidence: research/termrock-head-adoption/01-compile-break-inventory.md, 02-migration-doc-map.md (0062: FocusRing → InteractionScene; 0065: ModalStack → OverlayStack; 0085: offsets → ScrollAreaState)

#### Scenario: Parity tests green across the bump
- **GIVEN** the parity tests from this capability passing at the old pin
- **WHEN** the bump lands with the re-hosted wrappers
- **THEN** the same tests pass without modification (renamed internal symbols aside)
