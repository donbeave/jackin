# Migration posture

## Purpose

Binds every bump-phase plan to the item's screen-set/flow-preserving posture: the migration changes substrate and accepted visuals, never information architecture or operator journeys.
Anchors: S1, W1, D14 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md (screen inventories)

## Requirements

### Requirement: Screen-set preservation
The bump phase SHALL introduce no new operator-visible screens, dialogs, or overlays, and SHALL remove none; every screen in the existing inventory (console stages + 19 modals, capsule multiplexer + 15 dialogs, launch cockpit + overlays + standalone prompts, small surfaces) keeps its purpose, regions, states, interactions, and navigation.
Covers: S1, D14 · Evidence: research/termrock-head-adoption/04-component-adoption-candidates.md

#### Scenario: Dialog census unchanged
- **GIVEN** the pre-bump dialog/modal census (`ConsoleModal` 19 variants at `crates/jackin-console/src/tui/model/modal.rs:24-114`; capsule `Dialog` 15 variants at `crates/jackin-capsule/src/tui/components/dialog.rs:147-287`)
- **WHEN** the bump lands
- **THEN** both enums carry the same variant sets (renames of upstream types inside them notwithstanding)

### Requirement: Flow preservation
The bump phase SHALL change no operator journey: every flow's steps, screens, and failure points remain as before; flow-adjacent behavior moved by forced redesigns is proven unchanged by the parity scenarios in forced-redesigns.md.
Covers: W1, D14 · Evidence: research/termrock-head-adoption/01-compile-break-inventory.md

#### Scenario: Existing non-snapshot tests as journey witnesses
- **GIVEN** the pre-bump test suite (keymap, dialog, input tests across the six crates)
- **WHEN** the bump lands
- **THEN** every pre-existing non-snapshot test passes unmodified except where a test names a renamed upstream symbol, in which case only the symbol reference changes
