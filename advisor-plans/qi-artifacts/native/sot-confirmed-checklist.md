# SoT CONFIRMED checklist — status / popover / Usage

**Tip:** plan/desktop-visual @ def678f5  
**SoT:** decisions §0 → HTML index/popover → AGENT_HANDOFF

| ID | Surface | Status | Evidence |
|----|---------|--------|----------|
| SB-1…SB-4 burn-first ≤3 compact | Status | **met** | `status_bar_provider_glance_rows` hard-cap 3; DesktopAppDelegate uses `statusBarGlanceRows` only |
| SB-6 / FB1-22 official logos | Status+plates | **met** | ProviderMarks 7/7 + maxA≥200 |
| SB-7…SB-16 dual-line time/% | Status | **met** | StatusItemRendering.title |
| SB-17 soonest-then-remaining | Status | **met** | Rust `status_bar_rank_key` + strip/status_bar_provider_glance_rows tests |
| SB-19 hide 0% on bar | Status | **met** | status_bar path filters rem==0; inventory keeps 0% (OV-7) |
| SB-20/21 weekly-first / Amp daily | Status | **met** | glance_bucket Weekly/Daily |
| SB-22 bar vs popover depth | Both | **met** | statusBarGlanceRows vs providerGlanceRows |
| SB-23…26 chip → focused popover | Status→popover | **met** | StatusPopoverFocus + SoT harness |
| SB-27/28 tall popover | Popover | **met** | PopoverRoot maxHeight |
| OV-1…4, OV-6…7 inventory IA | Overview | **met** | PopoverOverviewTab + OverviewInventory |
| OV-5 relative + calendar | Overview | **partial** | Selected/glance compose exactReset; unselected multi-account deferred (no Account DTO) |
| OV-8…10, OV-12/13 | Overview | **met** | refresh, no severity dots, cards |
| FB1-6 transparent bar | Status | **met** | template mono |
| FB1-12…22 / LG-A / UW shell | Popover+Usage | **met** | gates + component snaps |
| Limits-only / display-only | All | **met** | Parity matrix + arch tests |

## Deferred / OPEN / residual
| ID | Note |
|----|------|
| OV-5 unselected multi-account reset | AccountRow lacks reset DTO |
| LG-6 exact plate hex | interim HTML-adjacent |
| UW-O1 open control | footer + menu |
| Usage full-window glass sidebar | **BLOCKED** pixels — see `usage-window-sidebar.BLOCKED.txt`; nest/detail/overview component snaps are structural bar |
| Live NSStatusItem Screen Recording | `status-live-nsstatusitem.BLOCKED.txt` |

