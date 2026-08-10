# QI delta: usage-detail-openai · Dark + Light (G-U6/G-U7)

**Date:** 2026-08-10 · **Tip:** `44bdc3e8` + audited worktree  
**Oracle HTML:** `html/usage-detail-openai-{dark,light}.png`  
**Native:** `native/usage-detail-openai-{dark,light}.png` (ProviderCardView)

## Dual-image

| Check | HTML detail | Native detail | Match |
|-------|-------------|---------------|-------|
| Head | OpenAI · account · Pro 20× | same | Yes |
| Open usage page | quiet tinted hairline + external | same; no solid phosphor slab | Yes |
| Meta | Status fresh · Updated · Auth | same | Yes |
| Limit container | one inset list + row dividers | same | Yes |
| Session | **63% left** green | same | Yes |
| Weekly | **57% left** orange · 13% deficit | same | Yes |
| Spark 5-hour | **88% left** | same | Yes |
| Spark Weekly | present in native | **100% left** | Yes |
| LRC | structured final list row | same | Yes |
| Light theme | same meters | same | Yes |
| Limits only | no prices | no prices | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Sidebar | HTML full window includes nest; native detail-only snap |
| Low | Exact calendar | Native compact Rust segments |

## False-pass correction

Earlier evidence marked the detail anatomy Pass while native rendered every
Rust bucket as a separate floating card. The root cause was container ownership
inside `bucketCard`: repetition duplicated the card shell. Native now has one
`limitList` shell; bucket helpers render rows only. Architecture lint guards
that ownership boundary.

Second audit fixed three visual/data false-passes: metadata values now align to
the oracle’s trailing edge; provider head uses vendor brand chrome; Weekly keeps
both Rust pace segments (`13% in deficit` and `Runs out in 2d 17h`). Limit Reset
Credits now carries its count in the row header. Oracle-only reset-window history
was removed because provider presentation does not expose it.

## Verdict
**Verdict: Pass** (Dark + Light)
