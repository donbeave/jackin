# QI delta: popover-openai · Dark + Light (G-P1–P3)

**Date:** 2026-08-10 · **Tip:** `bd3f3dc9`  
**Oracle HTML:** `html/popover-openai-{dark,light}.png`  
**Native:** `native/popover-openai-{dark,light}.png` (PopoverRoot + QI fixture)

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Brand | jackin❯ desktop | same | Yes |
| Tabs | Overview \| Providers | Providers selected | Yes |
| Strip | OpenAI selected + meters | OpenAI selected (fixture 3 providers) | Yes |
| Account chips | multi emails | chainargos 57% · zhokhov 0% | Yes |
| ACCOUNT | Pro 20× · fresh · OAuth | same | Yes |
| Session | **63% left** green | same · On pace · Resets 2h 14m | Yes |
| Weekly | **57% left** orange | same · 13% in deficit · Resets 3d | Yes |
| Spark 5-hour | **88% left** | same | Yes |
| Spark Weekly | **100% left** | same | Yes |
| LRC | 3 manual resets | same | Yes |
| Footer | Open Usage Window | same | Yes |
| Light theme | same IA | same | Yes |
| Limits only | no prices | no prices | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Strip count | QI fixture 3 vs HTML 5+ providers |
| Low | Exact wall-clock | Native compact Rust segments vs HTML “15 Aug…” |
| Low | Open usage page link | Native shows in-body link + footer Open Usage Window |

## Verdict
**Verdict: Pass** (Dark + Light)
