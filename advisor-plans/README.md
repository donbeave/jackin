# Plans — jackin❯ desktop UI parity (design-first)

**Active program of record:** **[UI_PARITY_MASTER.md](./UI_PARITY_MASTER.md)**  
**QI (how agents prove parity):** **[QI_VERIFICATION.md](./QI_VERIFICATION.md)**  
**Paste into `/goal` when ready to implement:** **[FINAL_GOAL_PROMPT.md](./FINAL_GOAL_PROMPT.md)**  

Stamp: foundations **`f4ec1247`**; plan+QI docs ready for `/goal` (2026-08-10). Focus: **look / feel / IA / interactions** vs HTML SoT.

> **Plan package frozen for implementers.** Start via **[FINAL_GOAL_PROMPT.md](./FINAL_GOAL_PROMPT.md)** → paste into `/goal`.  
> Foundations in the tree are a baseline — **visual parity requires the QI loop** (baselines, screenshots, multimodal deltas), not harness-only green.

---

## Read order (implementer / `/goal` agent / reviewer)

1. [UI_PARITY_MASTER.md](./UI_PARITY_MASTER.md) — goal, oracle, residual gaps, matrix, phases, `/goal` paste  
2. [QI_VERIFICATION.md](./QI_VERIFICATION.md) — **detailed integration verification** (pyramid, capture, multimodal, anti-patterns)  
3. HTML: `plans/previews/desktop-ui/index.html` + `popover.html` (Dark + Light)  
4. `plans/previews/desktop-ui/MACOS_CHROME_REFERENCES.md`  
5. `plans/desktop-design-decisions.md` (CONFIRMED FB1 / LG-A)  
6. Micro-plans 001–005 only if a **foundation regresses**

---

## Program phases (from master plan)

| Phase | Focus | Status |
|-------|--------|--------|
| **A** | Freeze & re-baseline gaps vs HTML | **TODO** (planning complete; freeze is operator) |
| **B** | Status bar + click interactions craft | **TODO** |
| **C** | Popover = `popover.html` craft | **TODO** |
| **D** | Usage window = `index.html` Usage craft | **TODO** |
| **E** | Cross-cut polish + VISUAL_QA_LOG sign-off | **TODO** |

Structural foundations (code already landed) are summarized in the master plan §4 — do not treat “code exists” as Phase B–E Pass.

---

## Foundation micro-plans (historical)

Generated earlier for structural closure. **Superseded as program of record by UI_PARITY_MASTER.md.**

| Plan | Title | Status |
|------|-------|--------|
| [001](./001-status-left-click-focuses-provider.md) | Status left-click focuses provider | DONE (foundation) |
| [002](./002-popover-sot-craft-and-data.md) | Popover data path + shell | DONE (foundation) |
| [003](./003-usage-account-nest-and-overview.md) | Account nest + Overview inventory | DONE (foundation) |
| [004](./004-usage-detail-polish-and-links.md) | Detail / links harden | DONE (foundation) |
| [005](./005-activation-toolbar-harness-guards.md) | Activation / NSToolbar / harness guards | DONE (foundation) |

---

## Shared verification (when implementing)

```sh
python3 plans/previews/desktop-ui/check_usage_liquid_glass.py

cd native
swift run -c release DesktopArchitectureLint
swift run -c release DesktopSoTParityHarness   # prefer ≥3 runs if touching identity maps
swift run -c release DesktopParityMatrixHarness
swift run -c release StatusItemChipHarness
```

Visual: side-by-side HTML hub + running app; fill `VISUAL_QA_LOG.md` (template in master plan §10).

---

## Git rules

- Stay on active feature branch (e.g. `plan/desktop-visual`); never commit `main`.  
- Conventional Commits + DCO `git commit -s`; push after each commit.  
- Brand: **jackin❯ desktop**.

---

## Design SoT (repo)

Design sources live under `plans/` (not this folder):

- `plans/previews/desktop-ui/*`  
- `plans/desktop-design-decisions.md`  

This `advisor-plans/` tree is the **execution program** for native UI parity.
