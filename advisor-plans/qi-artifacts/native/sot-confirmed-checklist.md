# SoT CONFIRMED checklist — status / popover / Usage

**Tip:** plan/desktop-visual @ 3accf797 (SB-5 partial + OV-11 met + structural tests)
**Code:** SB-18/SB-13 @ 7bac5273 · SB-3/17/19 @ b97f2a4c  
**SoT:** decisions §0 → HTML index/popover → AGENT_HANDOFF

| ID | Surface | Status | Evidence |
|----|---------|--------|----------|
| SB-1…SB-4 burn-first ≤3 | Status | **met** | `status_bar_provider_glance_rows` + `statusBarGlanceRows` |
| SB-5 urgency color on bar | Status | **partial / deferred** | Priority via rank order (SB-13/17), not colored chip fills. **FB1-6** locks template mono bar (no severity tint) — `StatusItemLabel.swift` LG-A1/FB1-6. **SB-P4** (color on chip chrome) still OPEN. Do not invent colored bar chrome until grill. |
| SB-6 / FB1-22 logos | Status+plates | **met** | ProviderMarks 7/7 maxA≥200 |
| SB-7…SB-9 dual-line %/time | Status | **met** | StatusItemRendering.title |
| SB-10 hours-first | Status | **met** | SB-18 ladder (hours until 48h) |
| SB-11…SB-12 burn-first intent | Status | **met** | rank + dual stack |
| SB-13 dynamic bar order | Status | **met** | `statusBarOrderRequiresRebuild` + remove+recreate |
| SB-14 ≤3 hard cap | Status | **met** | STATUS_BAR_MAX_CHIPS=3 |
| SB-15/16 dual-line layout | Status | **met** | compact reset top + barLabel bottom |
| SB-17 soonest-then-remaining | Status | **met** | host `status_bar_rank_key` + tests |
| SB-18 48h duration ladder | Status | **met** | `compact_duration_label` 24–47h hours, ≥48h days |
| SB-19 hide 0% on bar | Status | **met** | bar filters rem==0; inventory keeps 0% |
| SB-20/21 weekly/daily | Status | **met** | glance_bucket |
| SB-22 bar vs popover | Both | **met** | statusBarGlanceRows vs providerGlanceRows |
| SB-23…26 focus path | Status→popover | **met** | StatusPopoverFocus |
| SB-27/28 tall popover | Popover | **met** | PopoverRoot maxHeight |
| OV-1…4, OV-6…7 | Overview | **met** | PopoverOverviewTab |
| OV-5 relative+calendar | Overview | **partial** | selected/glance exactReset; unselected deferred |
| OV-8 per-surface refresh | Overview | **met** | refresh control → `store.refresh(surfaceId:)` |
| OV-9 no global Refresh footer | Overview/popover | **met** | PopoverFooter Open Usage only |
| OV-10 no mystery severity dots | Overview | **met** | logos + account meters only |
| OV-11 no Overview-level progress | Overview | **met** | No `ProgressView` / orphan Overview loading bar in `PopoverOverviewTab.swift`; meters are **per-account** only. Snap: `popover-overview-dark.png` — no Overview-wide progress chrome. `{SCRATCH}/ov11-structure.log` |
| OV-12/13 craft hierarchy | Overview | **met** | cards, mono %, meters |
| FB1 / LG / UW craft | Popover+Usage | **met** | gates + component snaps |
| Limits-only | All | **met** | Parity matrix |

## Deferred / residual
| Item | Note |
|------|------|
| SB-5 bar urgency color | **partial** — rank carries focus; colored bar chrome deferred (FB1-6 vs SB-P4 OPEN) |
| OV-5 unselected multi-account reset | no Account DTO |
| LG-6 plate hex | interim |
| UW-O1 open control | footer+menu |
| Usage full-window glass sidebar | **BLOCKED** active state — Dark/Light window-ID captures inactive |
| Live NSStatusItem | status-live-nsstatusitem.BLOCKED.txt |
