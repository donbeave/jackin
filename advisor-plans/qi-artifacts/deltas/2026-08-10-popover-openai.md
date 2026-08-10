# QI delta: popover-openai · Dark + Light (G-P3 bucket anatomy)

**Date:** 2026-08-10 · **Tip:** G-P3 meter-last hold + dual-image re-verify  
**Oracle HTML:** `html/popover-openai-{dark,light}.png`  
**Native:** `native/popover-openai-{dark,light}.png`

## Fail → Pass trail

| Cycle | High residual | Fix |
|-------|---------------|-----|
| Fail | G-P3 order hero→**meter**→pace→reset | `PopoverProviderTab.detailBucketBlock` meter before pace |
| Pass | hero→pace→reset→**meter** matches HTML | recapture dual-image |

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Brand | jackin❯ desktop | same | Yes |
| Footer CTA | centered phosphor glyph + label | same; no trailing chevron | Yes |
| Session order | 63% → On pace → Resets 2h 14m → meter | same | **Yes** |
| Weekly order | 57% → 13% deficit → Resets 3d → meter | same | **Yes** |
| Spark / LRC | multi-limit plate | same | Yes |
| Meters 1:1 | fills match % | same | Yes |
| 0% account chip | empty track | zhokhov 0% | Yes |
| Light theme | same IA | same | Yes |
| Limits only | no prices | no prices | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Strip count | QI fixture 3 vs HTML 5+ |
| Low | Exact wall-clock | Native compact Rust segments |

## Verdict
**Verdict: Pass** (Dark + Light) — G-P3 meter-last anatomy matches popover.html.
