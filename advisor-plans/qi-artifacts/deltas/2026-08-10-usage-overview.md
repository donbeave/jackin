# QI delta: usage-overview · Dark + Light (G-U5)

**Date:** 2026-08-10
**Oracle HTML:** `html/usage-overview-{dark,light}.png`  
**Native:** `native/usage-overview-{dark,light}.png` (OverviewListView)

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Page identity | 36 pt jackin❯ mark · Overview · inventory subtitle | same | Yes |
| Per-account rows | Anthropic Personal 12% · OpenAI a1 57% · a2 0% · Amp 100% | same four fixture rows; canonical provider order | Yes |
| Inventory anatomy | one inset list · divided rows · reset before meter | same | Yes |
| Meters | severity colors · 0% empty | same | Yes |
| OV-5 calendar | exact reset under OpenAI 57% | 15 Aug 2026, 17:02 | Yes |
| Limits only | remaining % | no prices | Yes |
| Brand | jackin❯ desktop (window) | component list (chrome separate) | IA Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Order | HTML frozen scene ranks Anthropic first; native preserves canonical provider catalog order |

## False-pass correction

QI fixture previously reversed canonical Codex/Claude catalog order and added an
Anthropic Work account absent from the frozen HTML scene. Fixture now preserves
`DESKTOP_PROVIDER_ORDER`; status burn ranking has its own array.

Second audit found native’s earlier “Pass” still lacked oracle page identity and
rendered every account as a separate floating card. Native now owns one page head,
one bordered inventory list, divided rows, 13/12/22 pt typography, and meter-last
anatomy. Architecture lint bans regression to per-row cards.

## Verdict
**Verdict: Pass** (Dark + Light)
