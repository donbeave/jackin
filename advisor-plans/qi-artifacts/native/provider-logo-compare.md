# provider-logo-compare (live re-verify)

| key | source | result |
|-----|--------|--------|
| codex | Commons OpenAI 2025 symbol | BYTE-identical master |
| claude | lobe-icons claude.svg | PATH-identical master |
| amp | ampcode.com/amp-mark-color.svg | BYTE-identical master; ship maxA 255 |
| grok | lobe-icons grok.svg | PATH-identical master |
| kimi | moonshot brand-guide icon-round | BYTE-identical master |
| zai | z-cdn logo.svg | PATH-identical master |
| minimax | lobe + minimax.io OG bars | path + visual match OG |

## amp.png health (skeptic gap)
maxA=255 meanA=161.7 n=13382 (PASS if maxA>=250)
PASS amp full alpha

## Amp re-snap (skeptic fix)
- amp.png maxA=255 (was 59)
- status-desktop-dark.png: Amp triple-chevron visible at full template mono next to Claude/OpenAI
- popover-amp-dark.png: purple Amp plate with white official chevron mark (selected)
- ProviderMarksHarness: amp mark maxA=255 PASS

## Multimodal read
- Status strip: Claude starburst · OpenAI Blossom · Amp chevrons — all real
- Amp popover plate: official triple chevron, not dome/arch SF stand-in
