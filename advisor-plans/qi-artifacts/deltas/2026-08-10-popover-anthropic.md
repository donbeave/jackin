# QI delta: popover-anthropic · Dark + Light (G-P3 multi-limit)

**Date:** 2026-08-10 · **Tip:** `bd3f3dc9`  
**Oracle HTML:** `html/popover-anthropic-{dark,light}.png`  
**Native:** `native/popover-anthropic-{dark,light}.png`

## Fail → Pass trail

| Cycle | High residual | Fix |
|-------|---------------|-----|
| Fail | Only Session+Weekly mini-card | Expand QIFixture anthropicDetail |
| Fail | No Personal/Work chips | anthropicAccounts Personal+Work |
| Pass | Full multi-limit plate dual-image | cdf62bcb + recapture hold |

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Brand | jackin❯ desktop | same | Yes |
| Strip | Anthropic selected | same | Yes |
| Chips | Personal · Work | Personal 12% · Work | Yes |
| ACCOUNT | Personal · Max 20× | same | Yes |
| Session | **74% left** green | same · 12% in deficit · 4h 19m | Yes |
| Weekly | **12% left** danger | same · 52% in reserve · 1h | Yes |
| All models | **28% left** mid | same | Yes |
| Sonnet | **35% left** mid | same | Yes |
| Fable only | **28% left** mid | same | Yes |
| Daily Routines | **100% left** | same | Yes |
| Extra usage | Spend bound limits-only | same · no invent % | Yes |
| Footer | Open Usage Window | same | Yes |
| Light theme | same multi-limit stack | same | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Strip count | QI 3 vs HTML 5+ |
| Low | Credential line | HTML Keychain OAuth; native optional credentialOrigin |
| Low | Extra usage weight | Native promotes first line; HTML denser k/v |

## Verdict
**Verdict: Pass** (Dark + Light) — multi-limit density matches popover.html; not mini-card.
