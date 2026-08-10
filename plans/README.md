# plans/

Advisor-produced plans and decision records for jackin❯ (improve skill).  
**Not** implementation code — executors follow individual plan files after selection.

| File | Role | Status |
|---|---|---|
| [desktop-design-decisions.md](./desktop-design-decisions.md) | Living **CONFIRMED / PROPOSED / OPEN** decisions for jackin❯ desktop | Active |
| [previews/desktop-ui/index.html](./previews/desktop-ui/index.html) | **Hub:** status interactions, Usage window, Liquid Glass check | Active |
| [previews/desktop-ui/popover.html](./previews/desktop-ui/popover.html) | Full popover + bar craft reference | Active |
| [previews/desktop-ui/AGENT_HANDOFF.md](./previews/desktop-ui/AGENT_HANDOFF.md) | How implementer agents use HTML + tokens for predictable native Swift | Active |

**UI parity program (design-first):**  
- Master: [`../advisor-plans/UI_PARITY_MASTER.md`](../advisor-plans/UI_PARITY_MASTER.md)  
- **QI verification (screenshots / multimodal / `/goal` loop):** [`../advisor-plans/QI_VERIFICATION.md`](../advisor-plans/QI_VERIFICATION.md)  
- Index: [`../advisor-plans/README.md`](../advisor-plans/README.md)  

HTML + decisions in this tree remain the visual/product SoT — agents implement toward them and **prove** parity with QI, not harness-only.

### `/goal` / implementer agents

**Source of truth stack** is defined in [`desktop-design-decisions.md` §0](./desktop-design-decisions.md):

1. Decisions file (CONFIRMED IDs)  
2. `previews/desktop-ui/index.html` (visual composition, dark/light)  
3. `previews/desktop-ui/AGENT_HANDOFF.md` (token map + checklist)  
4. This index  

Agents must verify native UI against HTML + CONFIRMED rules — not invent a new design.
