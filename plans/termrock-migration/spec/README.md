# Spec — termrock-migration (bump phase)

Contract between roadmap/termrock-migration/README.md (READY @ `d554dca8`) and the plans. This package specifies the **bump phase**; modernization phases are deferred per the item's own triggers (see Deferrals).

## Capability index

| File | Covers |
|------|--------|
| [migration-posture.md](migration-posture.md) | S1, W1 (posture), D14 |
| [dependency-bump.md](dependency-bump.md) | F1, B1, B2, B7 (lock/deny), B8, D1 |
| [forced-redesigns.md](forced-redesigns.md) | W1 (parity), B5, D9, D15 |
| [visual-rebaseline.md](visual-rebaseline.md) | B3, B9, D10 |
| [brand-preservation.md](brand-preservation.md) | F3 (bump half), B6, D4, D8, D11, D13 |
| [docs-alignment.md](docs-alignment.md) | B4, B7 (hint.rs drift check) |

## Must-not registry

| ID | Statement | Reason | Enforced in plans |
|----|-----------|--------|-------------------|
| N1 | The migration MUST NOT move any brand composition (BrandHeader, digital rain, launch animation/warp, launch progress rail, capsule brand pill) into TermRock, and MUST NOT change their visual identity | upstream 0331 declined absorption; item Decisions 2026-08-19 make ownership and look invariants | 002, 003, 004 |
| N2 | The migration MUST NOT introduce compatibility facades, aliases, or shim layers over renamed TermRock APIs | repository latest-only law; upstream migration directive ("No deprecated aliases are provided. This is a hard break.", 0061) | 001, 002, 003 |
| N3 | Usage surfaces MUST NOT gain price/trend affordances via adopted widgets; `context_meter`/`metric_tile` are not wired unless their render-path read passes the usage-limits-only rule | root AGENTS.md hard rule (limits only, never price or historical trend) | — (bump plans touch no usage widgets; binds modernization plan rounds) |

## Deferrals

| Ledger ID | What | Why safe | Revisit trigger |
|-----------|------|----------|-----------------|
| F2 | Per-surface re-platform on new component set | item defers adoption maps to surface finalizations (D12); research ch04 tables ready | each surface's finalization → its plan round |
| F4 + B10 | PNG baseline pipeline adoption + CI wiring + key-screen lists | item assigns wiring to console phase; pipeline contract vetted (research ch05) | console-phase finalization/plan round |
| B11 (rebuild half) | Rebuilding each brand composition on new primitives | bump PR only compensates colors (D8); rebuild belongs to owning surface's phase | owning surface's plan round |
| Q1–Q4 | Mouse parity matrix; TerminalCell metadata; context_meter read; PNG cross-OS identity | item marks each with its phase trigger; none blocks the bump | console/capsule planning, pre-Usage wiring, CI-lane wiring |
| DEF (item) | Background variant pick; adoption maps; facade end-state | decided-at-review / per-surface / console finalization per item Deferred section | as named in item |
