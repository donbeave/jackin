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
| Themes | active Dark and Light renderings | Dark glass fallback; Light inactive | Blocked |

## False-pass correction

Earlier full-window Dark and Light captures were byte-identical while the
manifest reported both as Pass. Window appearance was inherited implicitly,
and no cross-theme evidence gate existed. The harness now sets
`NSWindow.appearance` and rejects byte-identical theme pairs.

Second re-audit found live account rows owned separate full-width List
backgrounds while the isolated QI component used different code. Live sidebar
and QI host now share one `UsageAccountRailView`, preventing that drift.

Third re-audit found region-based screen capture had accepted pixels from an
unrelated Telegram window occupying the same coordinates. Region capture is now
forbidden; evidence uses window ID only. Current Dark fallback whites out the
Liquid Glass sidebar, while Light is a valid but inactive window capture.

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| High | Active full shell | Screen-capture permission / key-window state unavailable in harness |

## Verdict

**Verdict: Blocked** (structure proven; active full-shell pixels unproven)
