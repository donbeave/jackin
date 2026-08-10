# QI delta: usage-window-openai · Dark + Light (G-U1–G-U6)

**Date:** 2026-08-10 · **Tip:** `427a1439` + audited worktree  
**Oracle HTML:** `html/usage-window-{dark,light}.png`  
**Native:** `native/usage-window-openai-{dark,light}.png`

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Toolbar | centered brand + Refresh | same | Yes |
| Sidebar | floating glass navigation | same | Yes |
| Provider nest | labeled inset rail + two accounts | same | Yes |
| Detail head | identity + external usage action | same | Yes |
| Meta | one quiet details group | same | Yes |
| Limits | one inset divided list | same | Yes |
| Themes | distinct Dark and Light renderings | same | Yes |

## False-pass correction

Earlier full-window Dark and Light captures were byte-identical while the
manifest reported both as Pass. Window appearance was inherited implicitly,
and no cross-theme evidence gate existed. The harness now sets
`NSWindow.appearance` and rejects byte-identical theme pairs.

Second re-audit found live account rows owned separate full-width List
backgrounds while the isolated QI component used different code. Live sidebar
and QI host now share one `UsageAccountRailView`, preventing that drift.

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Provider inventory | Fixed QI fixture has three providers; HTML scene has five |
| N/A | Traffic lights | System chrome |

## Verdict

**Verdict: Pass** (Dark + Light)
