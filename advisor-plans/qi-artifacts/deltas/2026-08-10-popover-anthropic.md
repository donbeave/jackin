# QI delta: popover-anthropic · Dark + Light (multi-limit + G-P3)

**Date:** 2026-08-10 · **Tip:** G-P3 meter-last hold + dual-image re-verify  
**Oracle HTML:** `html/popover-anthropic-{dark,light}.png`  
**Native:** `native/popover-anthropic-{dark,light}.png`

## Fail → Pass trail

| Cycle | High residual | Fix |
|-------|---------------|-----|
| Fail | Sparse mini-card (Session+Weekly only) | QIFixture multi-limit expand |
| Fail | G-P3 meter under hero | detailBucketBlock meter last |
| Pass | Full multi-limit + hero→pace→reset→meter | dual-image re-read |

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Multi-limit density | Session…Extra usage | 74/12/28/35/28/100 + Extra | Yes |
| Personal/Work chips | yes | yes | Yes |
| Session order | 74% → pace → reset → meter | same | **Yes** |
| Weekly order | 12% danger → reserve → reset → meter | same | **Yes** |
| All models / Sonnet / Fable / Daily | full plate | same | Yes |
| Extra usage | spend bound limits-only | same | Yes |
| Light theme | same stack | same | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Strip count | QI 3 vs HTML 5+ |
| Low | Credential line | optional on native surface |

## Verdict
**Verdict: Pass** (Dark + Light) — multi-limit density + G-P3 anatomy.
