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
| Themes | active Dark and Light renderings | active key/main window-ID captures | Yes |

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
forbidden; evidence uses window ID only.

Fourth re-audit activated each window through a bounded AppKit modal event loop.
Active pixels exposed solid-blue system List selection hidden by inactive captures.
Sidebar navigation now owns selection through plain buttons and the HTML phosphor
well; both themes recaptured key/main.

## Verdict

**Verdict: Pass** (active Dark + Light full-shell parity)
