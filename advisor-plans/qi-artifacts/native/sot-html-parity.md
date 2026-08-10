# HTML composition vs native structure

| HTML surface | Native | Parity |
|--------------|--------|--------|
| Status dual-stack template logos | StatusItemRendering | **match** (fixture) |
| Overview\|Providers modes | PopoverTabGrid | **match** |
| mode-overview groups + multi-account + meter + refresh | PopoverOverviewTab + OverviewInventory | **match** |
| OV-5 relative + calendar | overviewResetDisplay → row.resetLabel dual line | **match** selected/glance (OpenAI: Resets in 3d + 15 Aug 2026, 17:02 in snap) |
| OV-5 unselected multi-account reset | AccountRow lacks reset DTO | **deferred** data model |
| Providers strip + detail | TabGrid + PopoverProviderTab | **match** |
| Open Usage CTA | PopoverFooter | **match** |
| Usage shell | UsageWindowRoot | **match** craft roles |

## Multimodal popover-overview-dark.png
- OpenAI selected account: "Resets in 3d" + "15 Aug 2026, 17:02"
- Unselected 0%: "Fully used" only (no invented calendar)
- Official marks; no severity dots
