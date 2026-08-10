# QI delta: usage-detail-openai · Dark + Light (G-U6 / G-U7)

**Date:** 2026-08-10 · **Tip:** goal scene-specific dual-image  
**Oracle HTML:** `html/usage-detail-openai-*.png` (detail column: Open usage + buckets)  
**Native:** `native/usage-detail-openai-*.png` (`ProviderCardView` + fixture detail)

## Dual-image (this scene only)

| Check | HTML detail | Native detail | Match |
|-------|-------------|---------------|-------|
| Head | OpenAI · account · Pro 20x | same | Yes |
| Open usage page | CTA + external affordance | green pill + ↗ | Yes |
| Meta | Status fresh · Updated · Auth OAuth | same mechanical rows | Yes |
| Session | **63% left** green meter | same | Yes |
| Weekly | **57% left** orange · 13% deficit | same | Yes |
| Codex Spark 5-hour | **88% left** | same | Yes |
| Codex Spark Weekly | **100% left** (native) | full track | Yes |
| Limit Reset Credits | present in HTML lower plate | LRC card at bottom (may clip in crop) | Yes (struct) |
| Limits only | no prices | no prices/trends | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Sidebar | HTML full-window includes nest; native detail-only snap |
| Low | Exact calendar clock on heroes | Native compact “Resets in 3d” from Rust segments |
| Med | Full-window sidebar whiteout | Separate BLOCKED path; not this component Pass |

## Verdict
**Pass** (Dark + Light) — mechanical Rust rows; meters; Open usage; limits only.
