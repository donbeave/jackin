# HTML composition vs native structure

| HTML surface | Native | Parity |
|--------------|--------|--------|
| Status dual-stack template logos | StatusItemRendering.icon + title | **match** (fixture bitmap; live NSStatusItem may BLOCK) |
| Popover brand + Overview\|Providers | PopoverTabGrid | **match** |
| mode-overview: provider groups, multi-account, %, meter, refresh | PopoverOverviewTab + OverviewInventory | **match** (rewritten; was severity-dot list) |
| mode-providers: strip + full detail | TabGrid strip + PopoverProviderTab | **match** |
| Open Usage Window glass CTA | PopoverFooter | **match** |
| Usage: glass sidebar, solid detail, nest accounts | UsageWindowRoot + nest + ProviderCard | **match** craft role |
| Meters 3-status not multi-brand | severityTint / phosphor | **match** |
| Credential = Rust string | PopoverProviderTab credentialOrigin | **match** |
| No spend/price UI | parity matrix | **match** |

## Multimodal (qi-sot/popover-overview-dark.png)
- Overview selected; Anthropic/OpenAI/Amp groups with official plates
- Multi-account OpenAI (57% + 0% Fully used)
- Per-row refresh icons; meters status-colored; Open Usage footer
- No severity dots
