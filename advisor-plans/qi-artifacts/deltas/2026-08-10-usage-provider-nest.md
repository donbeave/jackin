# QI delta: usage-provider-nest · Dark + Light (G-U3/G-U4)

**Date:** 2026-08-10 · **Tip:** `f1e17a38` + audited worktree  
**Oracle HTML:** `html/usage-provider-nest-{dark,light}.png` (sidebar ACCOUNTS nest)  
**Native:** `native/usage-provider-nest-{dark,light}.png` (UsageAccountNestView)

## Dual-image

| Check | HTML nest | Native nest | Match |
|-------|-----------|-------------|-------|
| Provider caption | OpenAI · multi | OpenAI · 2 accounts | Yes |
| Rail shell | one labeled inset well | same | Yes |
| Selected | radio · chainargos · **57%** orange meter | same | Yes |
| Second | radio off · zhokhov · **0%** empty | same | Yes |
| Plans | Pro 20× / Plus | same | Yes |
| Provider % on provider row | none | nest is accounts-only | Yes |
| Light theme | same nest IA | same | Yes |

## False-pass correction

Earlier full-shell evidence rendered each account as a separate full-width List
row while the isolated QI component rendered a different nested structure. One
shared `UsageAccountRailView` now owns the label, inset shell, stroke, rows, and
selected-account fill in both live sidebar and deterministic captures.

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Framing | Native isolated nest; HTML full window chrome around nest |

## Verdict
**Verdict: Pass** (Dark + Light)
