# QI delta: usage-overview · dark + light

## Oracle
- HTML: advisor-plans/qi-artifacts/html/usage-overview-dark.png

## Candidate
- Content: advisor-plans/qi-artifacts/native/usage-overview-{dark,light}.png (`OverviewListView`)
- Window: advisor-plans/qi-artifacts/native/usage-window-overview-{dark,light}.png (`UsageWindowController` CGWindow)
- Dual-image review: HTML inventory Anthropic 12% red / OpenAI 57% orange / OpenAI 0% empty / Amp 100%; native matches titles Provider · account, severity colors, 0% empty meter; full window shows Overview selected + sidebar providers

## Same (keep)
- Per-account inventory; meters 1:1; 0% empty; DATA_CONTRACT fixture %

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Low | Reset clocks | Exact parentheticals | Rust resetLabel only | G-U5 | Data limit |
| Low | Accent | Phosphor 100% | System blue 100% | VS-13 | Optional |

## Verdict
Verdict: Pass
