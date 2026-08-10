# QI delta: usage-provider-nest · Dark + Light (G-U3 / G-U4)

**Date:** 2026-08-10 · **Tip:** goal scene-specific dual-image  
**Oracle HTML:** `html/usage-provider-nest-*.png` (sidebar ACCOUNTS nest under OpenAI)  
**Native:** `native/usage-provider-nest-*.png` (`UsageAccountNestView` harness)

## Dual-image (this scene only)

| Check | HTML nest | Native nest | Match |
|-------|-----------|-------------|-------|
| Provider caption | OpenAI · multi accounts | “OpenAI” + “2 accounts” | Yes |
| Selected account | radio · chainargos · **57%** orange mini-meter | same | Yes |
| Second account | radio off · zhokhov · **0%** empty track | same | Yes |
| Plan under name | Pro 20x / Plus | Pro 20x / Plus | Yes |
| Provider % on provider row | none (identity only) | nest is accounts-only | Yes |
| Limits only | remaining % only | no prices/trends | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Framing | Native is isolated nest component; HTML shows full Usage chrome around nest |
| Low | Truncation | HTML email ellipsis in narrow sidebar; native full email in wider nest snap |

## Verdict
**Pass** (Dark + Light) — 57% mid fill + 0% empty track; radio multi; DATA_CONTRACT fixtures.
