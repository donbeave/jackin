# QI delta: popover-overview · Dark + Light

**Date:** 2026-08-10 · **Tip:** `f05f6cd7` + audited worktree  
**Oracle:** `html/popover-overview-{dark,light}.png`  
**Native:** `native/popover-overview-{dark,light}.png`

## Dual-image / craft

| Check | SoT | Native | Match |
|-------|-----|--------|-------|
| Overview tab | selected | selected | Yes |
| Provider order | OpenAI · Anthropic · Amp | same | Yes |
| Group header | logo · name · trailing product role | same | Yes |
| Account anatomy | divided rows; 22 pt % | same | Yes |
| Refresh | 28 pt phosphor tint + hairline | same shared control | Yes |
| Inventory | per-provider / per-account | Anthropic · OpenAI multi · Amp | Yes |
| OpenAI multi | 57% + 0% | same | Yes |
| OV-5 calendar | exact reset | present when known | Yes |
| Amp | 100% full | same | Yes |
| Footer | Open Usage Window | same | Yes |
| Brand | jackin❯ desktop | same | Yes |
| Limits only | remaining % | no prices | Yes |

## False-pass correction

Earlier verdict had no HTML PNG and missed reversed provider order, subscription
plans in provider headers, an extra Anthropic account, stacked header geometry,
missing dividers, undersized metrics, and bare refresh glyphs. Oracle capture is
now mandatory. QI fixture separates canonical catalog order from burn-first
status ranking, while product code uses frozen provider roles and shared refresh
craft.

## Different (not High)

None.

## Verdict
**Verdict: Pass** (Dark + Light)
