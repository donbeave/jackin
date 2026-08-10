# Provider logo deep audit — jackin❯ desktop

**Date:** 2026-08-10  
**Tip:** post official-mark rebuild  
**Desktop providers:** `codex` · `claude` · `amp` · `grok` · `kimi` · `zai` · `minimax`

## Method

1. Inventory shipped marks + UI call sites (status / popover / Usage).
2. Fetch **official** brand/press assets and industry-faithful vectors.
3. Visual dual-image compare (shipped vs master).
4. Replace failings with verified masters → template mono PNG (+ PDF fallback).
5. Re-snap status, popover, Usage detail.

## Official source table

| Surface | Product | Master asset | Source URL / kit | Confidence |
|---------|---------|--------------|------------------|------------|
| `codex` | OpenAI / Codex | Blossom symbol | openai.com/brand · Commons OpenAI_logo_2025_(symbol).svg | **High** — official Blossom |
| `claude` | Anthropic Claude | Starburst | lobe-icons `claude.svg` (Claude app mark geometry) | **High** — matches Claude product icon |
| `amp` | Amp | Triple chevron mark | **ampcode.com/amp-mark-color.svg** (press kit) | **High** — vendor press |
| `grok` | xAI Grok | Slash-circle | lobe-icons `grok.svg` | **High** — Grok product mark family |
| `kimi` | Moonshot Kimi | K + orbit icon | **moonshotai.github.io/Branding-Guide** icon-round PNG | **High** — vendor brand guide |
| `zai` | Z.ai | Z plate | **z-cdn.chatglm.cn/z-ai/static/logo.svg** | **High** — vendor CDN |
| `minimax` | MiniMax | Waveform icon | MiniMax logo ZIP family + lobe-icons geometry | **High** — icon form of official mark |

## Before vs after

| Provider | Before deep audit | Real? | After |
|----------|-------------------|-------|-------|
| OpenAI | Corrupted soccer-ball silhouette | No | **OpenAI Blossom** |
| Claude | Generic 8-point star | No | **Claude starburst** |
| Amp | Fake dome/arch | No | **Official Amp chevrons** |
| Grok | Fake monogram | No | **Grok slash-circle** |
| Kimi | Generic K letter | Partial | **Official Kimi icon** |
| Z.ai | Generic Z | No | **Official Z plate** |
| MiniMax | Wordmark-heavy ZIP render | Partial | **Waveform icon** |

## UI proof (re-snapped)

- Status dual-stack: Blossom · Claude starburst · Amp chevrons visible as template mono.
- Popover provider plates: same marks on brand-colored tiles (white glyph).
- Usage detail head: OpenAI Blossom on plate.

## Bundle layout

`native/Sources/JackinDesktop/Resources/ProviderMarks/`

- `*.png` — black glyph, transparent (preferred for template + plates)
- `*.pdf` — fallback
- `*.master.*` — pre-template source for re-builds
- `PROVENANCE.md` — source URLs

## Residual

- Trademark use is **referential** (usage monitor identity). Legal review is operator-owned.
- When a vendor ships a newer primary mark, replace master + rebuild PNGs; code path stays the same.
