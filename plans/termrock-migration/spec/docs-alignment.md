# Docs alignment and drift checks

## Purpose

Repository law requires same-PR docs updates for TUI changes; three contributor-docs pages pin API names the head deletes, one AGENTS.md table row points at a directory that does not exist, and one comment mirrors an upstream convention that may have drifted.
Anchors: B4, B7 (drift check) · Evidence: research/termrock-head-adoption/README.md conclusion 7 (rg survey 2026-08-19)

## Requirements

### Requirement: Dead-name docs pages updated in the bump PR
The bump PR SHALL update the three pages pinning soon-dead termrock names so every named API matches the head: `docs/content/reference/tui/visual-design.mdx` (lines 10, 24, 64, 76: `Theme::default().style(role)`, `PanelEmphasis::Focused/Normal`), `docs/content/reference/tui/dialogs.mdx` (line 174: "FocusRing + ModalStack lifecycle"), `docs/content/reference/tui/navigation.mdx` (lines 24, 26, 142, 249, 359: `FocusRing`, `PanelEmphasis`) — and SHALL re-grep all of `docs/content/reference/tui/` for remaining dead names as the closing check.
Covers: B4 · Evidence: research/termrock-head-adoption/README.md c7; page/line survey verified 2026-08-19

#### Scenario: No dead API names in TUI docs
- **WHEN** `rg -n "PanelEmphasis|FocusRing|ModalStack|Theme::default" docs/content/reference/tui/` runs after the docs update
- **THEN** zero hits remain (or each remaining hit is a deliberate historical reference explicitly marked as such)

### Requirement: Stale AGENTS.md surface path fixed
The bump PR SHALL fix the AGENTS.md TUI table's host-console row from the nonexistent `src/console/tui/` to the real surfaces (`crates/jackin-console/src/tui/` and `crates/jackin/src/console/`), keeping the CLAUDE.md symlink arrangement untouched.
Covers: B4 · Evidence: research/termrock-head-adoption/02-migration-doc-map.md; item References note

#### Scenario: TUI table points at real directories
- **WHEN** the AGENTS.md TUI surface table is read after the fix
- **THEN** every directory it names exists in the repository

### Requirement: chord_glyph mirror drift check
The bump PR SHALL verify the comment-level convention mirror at `crates/jackin-capsule/src/tui/components/dialog/hint.rs:25` ("Mirrors the `Ctrl-` prefix convention used by `termrock::keymap::chord_glyph`") still matches the head's `chord_glyph` behavior, updating the jackin❯ hint formatting or the comment if the convention drifted.
Covers: B7 · Evidence: research/termrock-head-adoption/02-migration-doc-map.md (keymap module preserved; glyph submodule verified)

#### Scenario: Mirror verified against head
- **WHEN** the head's `chord_glyph` output for a Ctrl-chord is compared with the capsule hint formatting
- **THEN** they agree, or the divergence is fixed on the jackin❯ side in the same PR
