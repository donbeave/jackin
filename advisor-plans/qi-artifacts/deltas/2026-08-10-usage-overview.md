# QI delta: usage-overview · Dark + Light (G-U5)

**Date:** 2026-08-10 · **Tip:** `bd3f3dc9`  
**Oracle HTML:** `html/usage-overview-{dark,light}.png`  
**Native:** `native/usage-overview-{dark,light}.png` (OverviewListView)

## Dual-image

| Check | HTML | Native | Match |
|-------|------|--------|-------|
| Per-account rows | Anthropic Personal 12% · OpenAI a1 57% · a2 0% · Amp 100% | same fixture rows (+ Work optional) | Yes |
| Meters | severity colors · 0% empty | same | Yes |
| OV-5 calendar | exact reset under OpenAI 57% | 15 Aug 2026, 17:02 | Yes |
| Limits only | remaining % | no prices | Yes |
| Brand | jackin❯ desktop (window) | component list (chrome separate) | IA Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Framing | Native component lacks full sidebar chrome (see usage-toolbar Light) |

## False-pass correction

QI fixture previously reversed canonical Codex/Claude catalog order and added an
Anthropic Work account absent from the frozen HTML scene. Fixture now preserves
`DESKTOP_PROVIDER_ORDER`; status burn ranking has its own array.

## Verdict
**Verdict: Pass** (Dark + Light)
