# HTML composition vs native structure

| HTML surface | Native | Parity |
|--------------|--------|--------|
| Status dual-stack ≤3 burn-first | statusBarGlanceRows + StatusItemRendering | **match** (fixture; live BLOCKED) |
| Brand + Overview\|Providers | PopoverTabGrid | **match** |
| mode-overview inventory | PopoverOverviewTab | **match** |
| OV-5 calendar when known | overviewResetDisplay | **match** selected/glance |
| Providers strip + detail | TabGrid + PopoverProviderTab | **match** |
| Open Usage CTA | PopoverFooter | **match** |
| Usage glass sidebar + solid detail | UsageWindowRoot | **craft roles match**; full-window PNG sidebar often **whites out** (residual) |
| Meters 3-status | severityTint | **match** |
| No spend/price UI | parity matrix | **match** |

## Token map
`--jk` → Color.jackinPhosphor · `--glass` → GlassFallbacks · status bands → severityTint

## Residual honesty
- `usage-window-sidebar.BLOCKED.txt` — do not claim full-window sidebar+detail OK
- Structural Usage bar: usage-provider-nest / usage-detail / usage-overview / usage-toolbar snaps
