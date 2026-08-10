# QI delta: popover-openai · dark + light + live

## Oracle
- HTML: advisor-plans/qi-artifacts/html/popover-openai-dark.png (+ light)
- Source: popover.html OpenAI provider

## Candidate
- Hosted: advisor-plans/qi-artifacts/native/popover-openai-{dark,light}.png (`PopoverRoot`)
- Live: advisor-plans/qi-artifacts/native/popover-live-openai-dark.png
- Dual-image review: HTML = full glass panel, provider strip, multi chips, SESSION 63% hero; native PopoverRoot = Overview+providers tabs, OpenAI selected, chips 57%/0%, SESSION 63% + WEEKLY 57% heroes, meters 1:1, Refresh footer; live left-click focuses OpenAI

## Same (keep)
- Full glance popover (not mini-pop); provider strip selection; multi-account chips; hero remaining; Open usage; glass Refresh footer
- DATA_CONTRACT fixture 63/57/88/100 on hosted path

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Mode chrome | Overview/Providers segmented + brand | Tab grid (Overview+providers) | G-P1 | Native product path |
| Med | Footer | Open Usage Window CTA | Refresh (FB1/LG-A8) | G-P4 | Product law — keep |
| Low | Accent | Phosphor green | System accent | VS-13 | Optional brand accent |

## Verdict
Verdict: Pass
