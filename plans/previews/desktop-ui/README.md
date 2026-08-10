# jackin❯ desktop — HTML visual reference

**Source of craft truth until Swift ships.**  

| File | Contents |
|---|---|
| [`index.html`](./index.html) | **Hub:** status left-click → **real** `popover.html` embed, right-click glass menu, **Usage window**, Liquid Glass check |
| [`popover.html`](./popover.html) | **Single** glance-popover craft SoT: Overview + all 7 providers. Status interaction loads this file (`?embed=1&mode=providers&provider=…`) |
| [`AGENT_HANDOFF.md`](./AGENT_HANDOFF.md) | Agent procedure |

Open in Safari/Chrome. Toggle **Dark / Light**.

### Status interaction (do not reimplement mini-pops)

Left-click a status chip on the hub → iframe loads:

```
popover.html?embed=1&mode=providers&provider=anthropic&theme=dark
```

That is the **same** Liquid Glass popover as the standalone template. Never ship a simplified “mini-pop” for demos or native.

## For operators

Reply with `LIKE` / `DISLIKE` / `CHANGE` on what you see.  
Decisions are recorded in [`../../desktop-design-decisions.md`](../../desktop-design-decisions.md).

## For implementer agents (Swift)

1. **Read** `desktop-design-decisions.md` CONFIRMED IDs (especially FB1-*, VS-*, OV-*, LG-*).  
2. **Open this HTML** in **both** themes; match hierarchy, spacing, materials, color rules.  
3. **Do not invent** multi-color meters per provider — only logo plates use brand colors.  
4. **Metrics** = **3 status levels only**: high / medium / low (+ depleted grey). Default bands: ≥40% high, 15–39% mid, &lt;15% low. **Status bar** = transparent template icons.  
5. **Provider strip**: centered + H-scroll. **Account chips**: **left-aligned** + H-scroll.  
6. **Provider detail templates** (must match Rust):  
   - OpenAI: Session, Weekly, Codex Spark 5-hour, Codex Spark Weekly, Limit Reset Credits  
   - Anthropic: Session, Weekly, All models, Sonnet, Fable, Daily Routines, Extra usage  
   - Amp: Daily, Credits  
   - xAI: Weekly, Extra usage credits  
   - Kimi: Rate Limit, Weekly  
   - Z.ai: 5-hour, Tokens, MCP  
   - MiniMax: General · 5h, General · Weekly, Video  
5. **Product title** = `jackin` + phosphor `❯` + `desktop` in primary label color.  
6. **Logos** = official kit PDFs as template `NSImage` on the bar; popover may use colored plates.  
7. Preview SVGs are **stand-ins**, not final trademark assets.

## Apple fidelity in HTML

| Need | Technique |
|---|---|
| SF Pro | `-apple-system, BlinkMacSystemFont` |
| Liquid glass | `backdrop-filter: blur() saturate()` + translucent fill + hairline border |
| Semantic text | label / secondary / tertiary opacities |
| Dual theme | `[data-theme=dark\|light]` CSS variables |
| Menu bar | Translucent strip, no chip chrome |
| 8pt rhythm | 8/12/16/20 padding; 10/14 card radius |

When Swift is built, re-screenshot native UI against this reference (dark + light).
