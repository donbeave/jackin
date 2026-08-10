# ProviderMarks provenance (deep audit 2026-08-10)

Template monochrome PDFs for `NSStatusItem` (`isTemplate = true`) and UI plates.
**Critical rule:** only ship marks verified against official brand / press assets.

| Surface id | Product | Mark | Official source | Verification |
|------------|---------|------|-----------------|--------------|
| `codex` | OpenAI / Codex | **Blossom** logomark | [openai.com/brand](https://openai.com/brand/) · Commons `OpenAI_logo_2025_(symbol).svg` | Visual match: interlocking ribbon knot (current OpenAI symbol) |
| `claude` | Anthropic Claude | **Starburst** logomark | Claude app icon geometry via [lobe-icons claude.svg](https://github.com/lobehub/lobe-icons) (sourced from Claude brand usage) | Visual match: multi-ray Claude starburst (not generic 8-point star) |
| `amp` | Amp | **Amp mark** (triple chevron) | **Official** [ampcode.com/amp-mark-color.svg](https://ampcode.com/amp-mark-color.svg) + [press-kit](https://ampcode.com/press-kit) | Visual match: official red chevron mark (mono template) |
| `grok` | xAI Grok | Grok symbol | [lobe-icons grok.svg](https://github.com/lobehub/lobe-icons) (industry Grok mark) | Visual match: circle with diagonal slash (Grok app mark family) |
| `kimi` | Moonshot Kimi | **K + orbit icon** | **Official** [KIMI Brand Guidelines](https://moonshotai.github.io/Branding-Guide/) `scenarios/03-icon-without-kimi/kimi-icon-round.png` | Visual match: official K with blue accent / orbital texture |
| `zai` | Z.ai | **Z plate** | **Official** [z-cdn.chatglm.cn/z-ai/static/logo.svg](https://z-cdn.chatglm.cn/z-ai/static/logo.svg) | Visual match: rounded square Z logomark |
| `minimax` | MiniMax | Waveform icon | Official MiniMax logo family + lobe-icons minimax (icon geometry) | Visual match: MiniMax waveform mark (icon-only; not full wordmark on bar) |
| fallback | jackin❯ | JackinMark.pdf | repo | Done |

## Rejected / previous stand-ins (do not reintroduce)

| Was | Why wrong |
|-----|-----------|
| SF Symbols (`sparkles`, `hexagongrid`, `waveform`) | Not brand marks |
| Generic 8-point star (claude) | Not Claude starburst proportions |
| Arch/dome glyph (amp) | Not Amp press mark |
| Generic “K” / “Z” / “G” monograms | Not official icon assets |
| Corrupted OpenAI soccer-ball silhouette | Bad conversion of classic mark |

## Render law

- Status bar: template mono only (LG-P2 / FB1-6).
- Popover/Usage: same mark on brand-tinted plate with template glyph.
- Prefer icon-only marks on menu bar (no wordmarks).

## Masters

`*.master.svg` / `kimi.master.png` are the pre-template source files used for the PDF build.
