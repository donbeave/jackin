# SoT CONFIRMED checklist — status / popover / Usage

**Tip:** plan/desktop-visual @ (stamp after evidence commit)  
**Code:** SB-18/SB-13 @ 7bac5273 · SB-3/17/19 @ b97f2a4c  
**SoT:** decisions §0 → HTML index/popover → AGENT_HANDOFF

| ID | Surface | Status | Evidence |
|----|---------|--------|----------|
| SB-1…SB-4 burn-first ≤3 | Status | **met** | `status_bar_provider_glance_rows` + `statusBarGlanceRows` |
| SB-6 / FB1-22 logos | Status+plates | **met** | ProviderMarks 7/7 maxA≥200 |
| SB-7…SB-9 dual-line %/time | Status | **met** | StatusItemRendering.title |
| SB-10 hours-first | Status | **met** | SB-18 ladder (hours until 48h) |
| SB-11…SB-12 burn-first intent | Status | **met** | rank + dual stack |
| SB-13 dynamic bar order | Status | **met** | `statusBarOrderRequiresRebuild` + remove+recreate |
| SB-14 ≤3 hard cap | Status | **met** | STATUS_BAR_MAX_CHIPS=3 |
| SB-15/16 dual-line layout | Status | **met** | compact reset top + barLabel bottom |
| SB-17 soonest-then-remaining | Status | **met** | host `status_bar_rank_key` + tests |
| SB-18 48h duration ladder | Status | **met** | `compact_duration_label` 24–47h hours, ≥48h days (`compact_duration_sb18_tests`) |
| SB-19 hide 0% on bar | Status | **met** | bar filters rem==0; inventory keeps 0% |
| SB-20/21 weekly/daily | Status | **met** | glance_bucket |
| SB-22 bar vs popover | Both | **met** | statusBarGlanceRows vs providerGlanceRows |
| SB-23…26 focus path | Status→popover | **met** | StatusPopoverFocus |
| SB-27/28 tall popover | Popover | **met** | PopoverRoot maxHeight |
| OV-1…4, OV-6…7 | Overview | **met** | PopoverOverviewTab |
| OV-5 relative+calendar | Overview | **partial** | selected/glance exactReset; unselected deferred |
| OV-8…10, OV-12/13 | Overview | **met** | refresh, no severity dots |
| FB1 / LG / UW craft | Popover+Usage | **met** | gates + component snaps |
| Limits-only | All | **met** | Parity matrix |

## Deferred / residual
| Item | Note |
|------|------|
| OV-5 unselected multi-account reset | no Account DTO |
| LG-6 plate hex | interim |
| UW-O1 open control | footer+menu |
| Usage full-window glass sidebar | **BLOCKED** — usage-window-sidebar.BLOCKED.txt |
| Live NSStatusItem | status-live-nsstatusitem.BLOCKED.txt |

