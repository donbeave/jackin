# Brand preservation (bump-PR compensation)

## Purpose

The theme swap recolors brand-adjacent spans even with jackin❯ code untouched. The brand-look invariant binds from the bump PR: affected brand spans are compensated in consumer code so brand compositions render identically; everything else adopts the accepted upstream look. Rebuild-on-primitives is a later, per-surface concern (deferred).
Anchors: F3 (bump half), B6, D4, D8, D11, D13, N1 · Evidence: research/termrock-head-adoption/03-theme-brand-impact.md

## Requirements

### Requirement: Brand spans render identically across the bump
The following spans SHALL render with byte-identical colors/attributes before and after the bump, via consumer-code compensation (pinning to jackin-brand constants or explicit styles — mechanism is plan/executor choice): the BrandHeader line in console (`crates/jackin-console/src/tui/components/brand_header.rs:22-48`: chevron was `Role::Text` white, separator was `Role::ScrollTrack` 0,80,18, label was `Role::TextMuted` 0,140,30) and its launch duplicate (`crates/jackin-launch/src/tui/components/header.rs:15-41`), the capsule brand pill's chevron (`crates/jackin-capsule/src/tui/components/chrome.rs:144-158`, was `Role::Text` white), and the launch progress rail's theme-fed spans whose roles changed value at head — the rail is brand (D11) and is `Theme::default()`-fed, not hard-coded (`crates/jackin-launch/src/tui/components/progress_rail.rs:43`; `Role::Text` arms at `:125,:145`, `Role::TextStrong` at `:235`, `Role::TextMuted` at `:247` all shift; its `Role::Danger`/`Role::Accent` spans are value-unchanged at head and stay untouched). Already-immune elements (pill block/word, digital rain, warp animation, CLI rain, menu backgrounds, the launch header ripple's hard-coded lerps at `header.rs:106-117`) SHALL NOT be touched.
Covers: F3, B6, D8, D11 · Evidence: research/termrock-head-adoption/03-theme-brand-impact.md (span inventory with old/new RGB values)

#### Scenario: Compensated spans match pre-bump values
- **GIVEN** the pre-bump rendered colors of the four affected brand span groups (white 255,255,255 chevron; 0,80,18 separator; 0,140,30 label; the rail's Text/TextStrong/TextMuted spans at their pre-bump values)
- **WHEN** the compensated code renders after the bump
- **THEN** a color-asserting test (not a glyph-only snapshot) proves each span's fg/bg/attributes equal the pre-bump values

#### Scenario: Immune brand code untouched
- **WHEN** `git diff` of the bump PR is filtered to `crates/jackin-brand/`, rain, warp/animation, and CLI brand-output files
- **THEN** no changes exist beyond renamed upstream symbols forced by compilation (expected: none — these files are termrock-free)

### Requirement: Capsule row-0 split honored
Within capsule status-bar row 0, ONLY the brand pill (block + word + chevron) SHALL be compensated; tabs, underline, menu foreground, and tab fills SHALL adopt the upstream look (fills vanish for non-hovered tabs at head) without compensation.
Covers: D13 · Evidence: research/termrock-head-adoption/03-theme-brand-impact.md (row-0 element-by-element source table)

#### Scenario: Row-0 product chrome follows the theme
- **WHEN** the capsule status bar renders after the bump
- **THEN** tab foregrounds/fills/underline/menu use the new theme values with no compensation code attached to them
- **AND** the pill's chevron matches its pre-bump white
