# Spec — termrock-migration

Contract between roadmap/termrock-migration/README.md and the plans. The bump phase (001–004) is DONE and merged (PR #897, main `955b2fea`); this re-run adds the **console modernization phase** (005+) per the console surface finalization (item READY, decisions 2026-08-19). Remaining surfaces (capsule, launch, small) stay deferred per the item's own triggers.

## Capability index

| File | Covers |
|------|--------|
| [migration-posture.md](migration-posture.md) | S1, W1 (posture), D14 |
| [dependency-bump.md](dependency-bump.md) | F1, B1, B2, B7 (lock/deny), B8, D1 |
| [forced-redesigns.md](forced-redesigns.md) | W1 (parity), B5, D9, D15 |
| [visual-rebaseline.md](visual-rebaseline.md) | B3, B9, D10 |
| [brand-preservation.md](brand-preservation.md) | F3 (bump half), B6, D4, D8, D11, D13 |
| [docs-alignment.md](docs-alignment.md) | B4, B7 (hint.rs drift check) |
| [console-modernization.md](console-modernization.md) | F5, F9, W2, S2, B14, B15, B16, N4, D16–D19, D23–D25 |
| [png-baselines.md](png-baselines.md) | F7, S3, B10, B16, Q4, D20 |
| [console-brand-header.md](console-brand-header.md) | F8, B11 (console half), B16, D21 |
| [facade-retirement.md](facade-retirement.md) | F6, N2, D22 |

## Must-not registry

| ID | Statement | Reason | Enforced in plans |
|----|-----------|--------|-------------------|
| N1 | The migration MUST NOT move any brand composition (BrandHeader, digital rain, launch animation/warp, launch progress rail, capsule brand pill) into TermRock, and MUST NOT change their visual identity | upstream 0331 declined absorption; item Decisions 2026-08-19 make ownership and look invariants | 002, 003, 004, console phase (BrandHeader rebuild plan) |
| N2 | The migration MUST NOT introduce compatibility facades, aliases, or shim layers over renamed TermRock APIs | repository latest-only law; upstream migration directive ("No deprecated aliases are provided. This is a hard break.", 0061) | 001, 002, 003, console phase (every adoption + facade-retirement plan) |
| N3 | Usage surfaces MUST NOT gain price/trend affordances via adopted widgets; `context_meter`/`metric_tile` are not wired unless their render-path read passes the usage-limits-only rule | root AGENTS.md hard rule (limits only, never price or historical trend) | — (console adoption map wires neither widget; binds capsule/modernization rounds that touch usage surfaces) |
| N4 | The console phase MUST NOT add operator-visible screens or overlays beyond the single sanctioned `keyboard_help` overlay, and MUST NOT change operator journeys | item D14 amended by D18: the amendment's scope is exactly one additive help overlay | console phase (every plan) |

## Deferrals

| Ledger ID | What | Why safe | Revisit trigger |
|-----------|------|----------|-----------------|
| F2 (capsule/launch/small slices) | Per-surface re-platform beyond console | item fixes each surface's map at its own finalization (D12); console map settled | capsule finalization → its plan round (next) |
| F4 (non-console slices) | PNG baselines for non-console key screens | CI lane lands with console phase; later surfaces add screens onto it | each surface's plan round |
| F3 + B11 (launch/capsule halves) | Rebuilding rain/warp/rail/pill on new primitives | each brand comp rebuilds in its owning surface's phase (item quality bar); console BrandHeader active this round | launch / capsule plan rounds |
| Q2 | TerminalCell metadata vs capsule Hyperlink/SgrRegion coverage | capsule-phase question, not console | capsule-phase planning |
| Q3 | context_meter/metric_tile render-path read vs usage-limits-only | before any Usage-dialog wiring; console map wires neither | pre-Usage wiring |

## Change log

### 2026-08-19 — console surface finalization (D16–D25)

Bump phase merged as PR #897 (main `955b2fea`, pin `29a16b5b`). Console finalization settled: adoption map (full adoption with recorded carve-outs), key screens (full console inventory), BrandHeader proof (dedicated PNG crop + RGB tests), facade end-state (upstream contracts win, traits retire per surface). New research chapters 06 (mouse parity matrix — Q1 answered: proceed with compensations) and 07 (facade retirement inventory).

#### ADDED Requirements

- `### Requirement: UI/UX parity invariant` — console-modernization.md (D16).
- `### Requirement: Interaction core on upstream primitives` — console-modernization.md (C1/C2/C4/C5/C14 + ch06 compensations).
- `### Requirement: Dialog and form layer on upstream widgets` — console-modernization.md (C6–C8, C10, C11, C19).
- `### Requirement: Layout, chrome, and runtime on upstream machinery` — console-modernization.md (C3, C12, C13, C15–C17 + ch06 row 14).
- `### Requirement: Whole-screen recipes and the create wizard` — console-modernization.md (D19).
- `### Requirement: Op-picker wholly in the console phase` — console-modernization.md (D25).
- `### Requirement: keyboard_help overlay` — console-modernization.md (D18 amendment, D24).
- `### Requirement: No performance gate` — console-modernization.md (D23).
- `### Requirement: Baseline set is the full console inventory` — png-baselines.md (D20).
- `### Requirement: termrock-raster dependency and version coherence` — png-baselines.md (ch05 contract).
- `### Requirement: Zero-tolerance compare with bless workflow` — png-baselines.md.
- `### Requirement: CI lane wired in the console phase` — png-baselines.md (B10, Q4).
- `### Requirement: Text snapshots remain the standing suite` — png-baselines.md (D23).
- `### Requirement: Rebuilt header, identical look` — console-brand-header.md (D21).
- `### Requirement: Brand proof is a dedicated PNG crop plus literal-RGB tests` — console-brand-header.md (D21).
- `### Requirement: Mechanism recorded as the brand-proof template` — console-brand-header.md (D21).
- `### Requirement: Console speaks upstream event contracts` — facade-retirement.md (D22).
- `### Requirement: Console focus on FocusGraph directly` — facade-retirement.md (D22).
- `### Requirement: Console modal bookkeeping on OverlayStack` — facade-retirement.md (D22).
- `### Requirement: Subscription split — ready-once upstream, blocking product-owned` — facade-retirement.md (ch07 MED gap).
- `### Requirement: View and drive_frame inlined` — facade-retirement.md (D22).
- `### Requirement: ModalOutcome re-homed and facade copy deleted` — facade-retirement.md (ch07).
- `### Requirement: No shim, atomic cutovers, facade remnant frozen` — facade-retirement.md (N2, D22).

Plans affected: none stale — bump plans 001–004 DONE and untouched; console plans 005+ new.
