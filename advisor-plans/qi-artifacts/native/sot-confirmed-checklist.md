# SoT CONFIRMED checklist — status / popover / Usage

**Tip:** plan/desktop-visual @ 3b2db3d2 (this evidence pack; code SB bar @ b97f2a4c)
**SoT:** decisions §0 → HTML index/popover → AGENT_HANDOFF

| ID | Surface | Status | Evidence |
|----|---------|--------|----------|
| SB-1…SB-4 burn-first ≤3 | Status | **met** | `status_bar_provider_glance_rows` + DesktopAppDelegate `statusBarGlanceRows` |
| SB-6 / FB1-22 official logos | Status+plates | **met** | ProviderMarks 7/7 maxA≥200 |
| SB-7…SB-16 dual-line | Status | **met** | StatusItemRendering.title |
| SB-17 soonest-then-remaining | Status | **met** | host `status_bar_rank_key` + strip/status_bar tests |
| SB-19 hide 0% on bar | Status | **met** | bar filters rem==0; inventory keeps 0% (OV-7) |
| SB-20/21 weekly/daily glance | Status | **met** | glance_bucket Weekly/Daily |
| SB-22 bar vs popover | Both | **met** | statusBarGlanceRows vs providerGlanceRows |
| SB-23…26 focus path | Status→popover | **met** | StatusPopoverFocus + SoT harness |
| SB-27/28 tall popover | Popover | **met** | PopoverRoot maxHeight |
| OV-1…4, OV-6…7 inventory | Overview | **met** | PopoverOverviewTab + OverviewInventory |
| OV-5 relative+calendar | Overview | **partial** | overviewResetDisplay; unselected multi-account deferred |
| OV-8…10, OV-12/13 | Overview | **met** | refresh, no severity dots |
| FB1-6 transparent bar | Status | **met** | template mono |
| FB1-12…22 / LG / UW craft | Popover+Usage | **met** | gates + component snaps |
| Limits-only | All | **met** | Parity matrix |

## Deferred / residual
| Item | Note |
|------|------|
| OV-5 unselected multi-account reset | no Account DTO |
| LG-6 plate hex | interim |
| UW-O1 open control | footer+menu |
| Usage full-window glass sidebar | **BLOCKED** — usage-window-sidebar.BLOCKED.txt; structural: nest/detail/overview/toolbar |
| Live NSStatusItem | status-live-nsstatusitem.BLOCKED.txt |

