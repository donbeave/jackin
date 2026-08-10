# QI delta: usage-overview · Dark + Light (G-U5)

**Date:** 2026-08-10 · **Tip:** goal scene-specific dual-image  
**Oracle HTML:** `html/usage-overview-*.png` (Overview inventory / all accounts)  
**Native:** `native/usage-overview-*.png` (`OverviewListView` harness)

## Dual-image (this scene only)

| Check | HTML / SoT | Native overview | Match |
|-------|------------|-----------------|-------|
| Per-account inventory | one card/row per account when multi | OpenAI a1 57% + a2 0%; Anthropic; Amp | Yes |
| Titles | Provider · account | inventory labels from helper | Yes |
| Meters | 12% / 57% / 0% / 100% severity | same fixture | Yes |
| OV-5 calendar | exact reset under selected where known | OpenAI 57% shows calendar line when present | Yes |
| Limits only | remaining % | no prices/trends | Yes |

## Different (not High)

| Severity | Element | Notes |
|----------|---------|-------|
| Low | Chrome | Native component lacks full NSToolbar frame (see usage-toolbar Light) |
| Low | Card density | HTML may use denser sidebar chrome; same inventory law |

## Verdict
**Pass** (Dark + Light) — Overview inventory per account; DATA_CONTRACT fixtures.
