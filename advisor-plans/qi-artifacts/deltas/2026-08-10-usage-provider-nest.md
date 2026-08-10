# QI delta: usage-provider-nest · dark (+ light)

## Oracle
- HTML: qi-artifacts/html/usage-provider-nest-dark.png (sidebar nest under OpenAI)

## Candidate
- Native: qi-artifacts/native/usage-provider-nest-dark.png
- Code: `UsageAccountNestView` + `UsageAccountMiniMeter` (same mini meter as `UsageWindowRoot`)

## Same (keep)
- Provider identity “OpenAI” + “2 accounts” — no provider %
- Multi radio: selected a1 57% + mini meter fill; a2 0% empty mini meter
- Plan labels Pro 20× / Plus

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Context | Nested under full sidebar with other providers | Isolated nest strip | G-U4 | OK for nest unit; full sidebar in live UsageWindowRoot |
| Low | Meter color | Severity orange on 57% | Neutral mini meter fill | G-U4 | Optional severity tint on mini |

## Verdict
**Pass** — provider≠account + nest meters (incl. 0% empty) match High IA for G-U3/G-U4.
