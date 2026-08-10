# QI delta: usage-detail-openai · dark + light

## Oracle
- HTML: advisor-plans/qi-artifacts/html/usage-detail-openai-dark.png

## Candidate
- Card: advisor-plans/qi-artifacts/native/usage-detail-openai-{dark,light}.png (`ProviderCardView`)
- Window: advisor-plans/qi-artifacts/native/usage-window-openai-{dark,light}.png detail column
- Dual-image review: HTML Session 63% / Weekly 57% orange / Spark 88% / Open usage / Status fresh; native matches heroes, meters 1:1, Limit Reset Credits, Open usage pill; window also shows sidebar nest

## Same (keep)
- Open usage page CTA; meta group; limit cards with severity; Limit Reset Credits structured; no provider glance meter on detail

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Low | Accent | Phosphor healthy | System blue healthy | VS-13 | Optional |
| Low | Weekly subline | “Runs out in…” sometimes in HTML | Only Rust layout lines | G-D1 | Show only if Rust emits |

## Verdict
Verdict: Pass
