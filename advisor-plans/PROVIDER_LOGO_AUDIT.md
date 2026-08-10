# Provider logo deep audit — jackin❯ desktop

**Date:** 2026-08-10  
**Tip:** live re-verify + Amp full-alpha rebuild  
**Desktop providers (7):** `codex` · `claude` · `amp` · `grok` · `kimi` · `zai` · `minimax`  
**Host-only (no Desktop mark):** `opencode`

## Method

1. Inventory shipped marks + UI call sites (status / popover / Usage).
2. Map closed domain: Rust `HostSurfaceId::DESKTOP_PROVIDER_ORDER` (7) vs `ALL` (8).
3. Fetch **official** brand/press assets (or industry-canonical vectors).
4. Compare master vectors: SVG path `d=` equality or PNG byte identity.
5. Ship PNG health: black glyph + alpha (template). Fix weak alpha.
6. Gate: `ProviderMarksHarness` + visual harness assert 7/7.

## What we support (real providers)

| id | Product | Usage surface | Desktop mark |
|----|---------|---------------|--------------|
| `codex` | OpenAI / Codex | Yes | Yes — Blossom |
| `claude` | Anthropic Claude | Yes | Yes — Starburst |
| `amp` | Amp | Yes | Yes — press chevrons |
| `grok` | xAI Grok Build | Yes | Yes — slash-circle |
| `zai` | GLM / Z.AI | Yes | Yes — Z plate |
| `kimi` | Moonshot Kimi | Yes | Yes — brand-guide K |
| `minimax` | MiniMax | Yes | Yes — bar icon |
| `opencode` | OpenCode | Host yes | **No** (excluded from Desktop contract) |

`icon_key == surface_id` for Desktop glance rows.

## Official source table (live verify)

| Surface | Master asset | Source URL / kit | Verify result | Confidence |
|---------|--------------|------------------|---------------|------------|
| `codex` | Blossom symbol | Commons OpenAI 2025 symbol · openai.com/brand | **Byte-identical** master | **High** |
| `claude` | Starburst | lobe-icons `claude.svg` | **Path-identical** master | **High** |
| `amp` | Triple chevron | **ampcode.com/amp-mark-color.svg** (press / favicon) | **Byte-identical** master | **High** |
| `grok` | Slash-circle | lobe-icons `grok.svg` (xAI kit download gated) | **Path-identical** master | **High** geom |
| `kimi` | K + orbit | **moonshotai.github.io/Branding-Guide** icon-round PNG | **Byte-identical** master | **High** |
| `zai` | Z plate | **z-cdn.chatglm.cn/z-ai/static/logo.svg** | **Path-identical** master | **High** |
| `minimax` | Vertical bars | lobe + **minimax.io** OG/favicon dual-bar glyph | Path + visual match OG | **High** |

## Before vs after

| Provider | Before deep audit | Real? | After |
|----------|-------------------|-------|-------|
| OpenAI | Corrupted soccer-ball silhouette | No | **OpenAI Blossom** |
| Claude | Generic 8-point star | No | **Claude starburst** |
| Amp | Fake dome/arch | No | **Official Amp chevrons** |
| Amp ship PNG | maxA≈59 (invisible template) | Geometry OK | **maxA=255** full mono |
| Grok | Fake monogram | No | **Grok slash-circle** |
| Kimi | Generic K letter | Partial | **Official Kimi icon** |
| Z.ai | Generic Z | No | **Official Z plate** |
| MiniMax | Wordmark-heavy ZIP render | Partial | **Bar icon** (= OG form) |

## UI surfaces

| Surface | Loader | Fallback |
|---------|--------|----------|
| Status bar | `ProviderMarks.templateImage` → `StatusItemRendering.icon` | SF Symbol stand-in (should not hit for 7) |
| Popover plates | `ProviderMarks.swiftUIImage` | SF Symbol |
| Usage cards / head | same | SF Symbol |

## Bundle layout

`native/Sources/JackinDesktop/Resources/ProviderMarks/`

- `*.png` — black glyph, transparent (**preferred**)
- `*.pdf` — fallback
- `*.master.*` — pre-template source for re-builds
- `PROVENANCE.md` — source URLs + live verify

## Residual

- Trademark use is **referential** (usage monitor identity). Legal review is operator-owned.
- Grok: xAI brand-guidelines ZIP not re-fetched (403); geometry matches industry pack. Prefer re-seal from xAI download when available.
- When a vendor ships a newer primary mark, replace master + rebuild PNGs; code path stays the same.
- `opencode`: no official Desktop mark by design.

## Automated gate

`swift run -c release ProviderMarksHarness` — 7/7 via shipped `ProviderMarks` + `StatusItemRendering.icon`.
