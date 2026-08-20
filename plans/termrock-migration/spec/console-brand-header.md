# Console BrandHeader rebuild

## Purpose

Rebuild the console BrandHeader on TermRock head primitives with its visual identity unchanged — ownership and look are the invariants, implementation is not. The "renders identically" proof is a dedicated zero-tolerance PNG baseline cropped to the BrandHeader region plus the bump phase's 12 literal-RGB span tests; this mechanism is the template for the remaining brand compositions (launch rain/warp/rail, capsule pill) at their own phases.

Anchors: F8, B11 (console half), B16 · Evidence: roadmap item §Decisions (BrandHeader proof ruling, 2026-08-19), research/termrock-head-adoption/03-theme-brand-impact.md (brand span inventory), research/termrock-head-adoption/05-png-baseline-pipeline.md (PNG pipeline)

## Requirements

### Requirement: Rebuilt header, identical look

The console BrandHeader SHALL be re-implemented on TermRock head primitives and MUST render identically to its pre-rebuild output — same glyphs, same brand colors, same layout within its region. The header stays jackin❯-owned; it MUST NOT move into TermRock and MUST NOT change visual identity (N1).

Covers: F8 · Evidence: roadmap item §Decisions (brand rebuild allowed, look preserved; BrandHeader proof ruling), research/termrock-head-adoption/03-theme-brand-impact.md

#### Scenario: Header across console stages

- **WHEN** the rebuilt header renders on any console stage view
- **THEN** its region shows the identical brand composition as before the rebuild (PNG crop compare, zero-tolerance)

### Requirement: Brand proof is a dedicated PNG crop plus literal-RGB tests

The BrandHeader's look SHALL be proven by a zero-tolerance PNG baseline cropped to the BrandHeader region — isolated from surrounding chrome so re-blessing a surrounding screen never touches the brand baseline — and the bump phase's 12 literal-RGB span tests MUST be kept as the value-level gate. Re-blessing the brand crop follows the same deliberate-review rule as any baseline; a brand-crop diff outside an intended brand change is a parity break and a STOP.

Covers: F8, B11, B16 · Evidence: roadmap item §Decisions (BrandHeader proof ruling, 2026-08-19)

#### Scenario: Chrome churn does not touch the brand baseline

- **GIVEN** a surrounding screen's PNG baseline is re-blessed after an intended chrome change
- **WHEN** the BrandHeader crop suite runs
- **THEN** the brand crop baseline is untouched and still passes

#### Scenario: Value-level gate survives the rebuild

- **WHEN** the rebuilt header lands
- **THEN** all 12 literal-RGB span tests pass against the rebuilt implementation

### Requirement: Mechanism recorded as the brand-proof template

The crop-plus-RGB proof mechanism SHALL be recorded (in the plan that lands it) as the template the remaining brand compositions adopt at their owning surfaces' phases — launch rain/warp/rail and the capsule pill — so each later phase reuses the pattern instead of re-deriving it.

Covers: B11 · Evidence: roadmap item §Decisions (BrandHeader proof ruling: "the template for the remaining brand compositions")

#### Scenario: Template reusable

- **WHEN** the launch or capsule phase plans its brand composition rebuild
- **THEN** the console BrandHeader plan's proof mechanism (crop isolation, RGB test retention, re-bless review rule) is cited as the pattern to copy
