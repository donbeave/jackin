# plans/

Advisor-produced plans and decision records for jackin❯ (improve skill).  
**Not** implementation code — executors follow individual plan files after selection.

| File | Role | Status |
|---|---|---|
| [desktop-design-decisions.md](./desktop-design-decisions.md) | Living **CONFIRMED / PROPOSED / OPEN** decisions for jackin❯ desktop | Active |
| [previews/desktop-ui/index.html](./previews/desktop-ui/index.html) | **Visual reference** (popover + bar, light/dark) — open in browser | Active |
| [previews/desktop-ui/AGENT_HANDOFF.md](./previews/desktop-ui/AGENT_HANDOFF.md) | How implementer agents use HTML + tokens for predictable native Swift | Active |

Implementation plans (`001-*.md`, …) only after freeze sequence + concept picks. Plans must cite decisions file (+ chosen concept IDs).

### `/goal` / implementer agents

**Source of truth stack** is defined in [`desktop-design-decisions.md` §0](./desktop-design-decisions.md):

1. Decisions file (CONFIRMED IDs)  
2. `previews/desktop-ui/index.html` (visual composition, dark/light)  
3. `previews/desktop-ui/AGENT_HANDOFF.md` (token map + checklist)  
4. This index  

Agents must verify native UI against HTML + CONFIRMED rules — not invent a new design.
