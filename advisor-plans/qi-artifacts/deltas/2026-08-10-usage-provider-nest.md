# QI delta: usage-provider-nest · dark + light

## Oracle
- HTML: advisor-plans/qi-artifacts/html/usage-provider-nest-dark.png (sidebar nest under OpenAI)

## Candidate
- Unit: advisor-plans/qi-artifacts/native/usage-provider-nest-{dark,light}.png (`UsageAccountNestView`)
- Window: advisor-plans/qi-artifacts/native/usage-window-openai-dark.png sidebar column
- Dual-image review: HTML OpenAI identity + ACCOUNTS a1 57% meter / a2 0% empty; native unit + window sidebar show same IA (provider no %; multi radio; mini meters; 0% empty)

## Same (keep)
- Provider ≠ account; nest under selected provider; 57% + mini meter; **0% empty mini meter**

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Low | Mini meter hue | Severity orange on 57% | Neutral mini fill | G-U4 | Optional severity tint |

## Verdict
Verdict: Pass
