# QI delta: popover-anthropic · Dark + Light (G-P3 multi-limit)

**Date:** 2026-08-10 · **Tip:** anthropic full multi-limit QI fixture  
**Oracle HTML:** `html/popover-anthropic-*.png`  
**Native:** `native/popover-anthropic-*.png` (PopoverRoot + expanded `anthropicDetail`)

## Fail → Pass trail

| Cycle | High residual | Fix |
|-------|---------------|-----|
| Fail | Only Session 74% + Weekly 12% (mini-card) | Expand `QIFixture.anthropicDetail` to HTML stack |
| Fail | No Personal/Work account chips | `anthropicAccounts` Personal selected + Work |
| Pass | Full multi-limit plate + dual-image re-read | Recapture height 1400 |

## Dual-image (this scene only)

| Check | HTML SoT | Native | Match |
|-------|----------|--------|-------|
| Brand | jackin❯ desktop | same | Yes |
| Tabs / strip | Anthropic selected | same | Yes |
| Account chips | Personal · Work | Personal 12% · Work | Yes |
| ACCOUNT meta | Personal · Max 20× · fresh | same | Yes |
| Session | **74% left** green | same · 12% in deficit · Resets 4h 19m | Yes |
| Weekly | **12% left** danger red | same · 52% in reserve · Resets 1h | Yes |
| All models | **28% left** mid | same | Yes |
| Sonnet | **35% left** mid | same | Yes |
| Fable only | **28% left** mid | same | Yes |
| Daily Routines | **100% left** | same · no reset timestamp | Yes |
| Extra usage | Spend bound (limits only) | same copy · no invent % | Yes |
| Footer | Open Usage Window | same | Yes |
| Limits only | no prices | no prices | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Provider strip count | QI fixture 3 vs HTML 5+ |
| Low | Credential source line | HTML shows Keychain OAuth; native surface `credentialOrigin` optional |
| Low | Exact calendar clocks | Native compact Rust segments (“Resets in 6d 12h”) vs HTML wall-clock |
| Low | Extra usage hero weight | Native promotes first layout line; HTML denser k/v |

## Verdict
**Verdict: Pass** (Dark + Light) — multi-limit density matches popover.html Anthropic stack; no High residual.
