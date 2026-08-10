# Final goal parity matrix — UI_PARITY_MASTER §6

**Tip:** plan/desktop-visual (see VISUAL_QA_LOG)  
**Oracle:** index.html + popover.html Dark+Light  
**Capture:** DesktopVisualSnapshotHarness + HTML baselines  

## §6.1 Status bar
| Check | Dark | Light | Notes |
|-------|------|-------|-------|
| Dual stack | Pass | Pass | status-desktop-*.png |
| Template mono | Pass | Pass | official ProviderMarks |
| No glass chips | Pass | Pass | FB1-6 |
| Focus | Pass | Pass | SoT harness (not visual) |

## §6.2 Popover
| Check | Dark | Light | Notes |
|-------|------|-------|-------|
| Density / IA | Pass | Pass | popover-openai/anthropic/overview |
| Shell glass | Pass | Pass | G-P5 |
| Tabs + strip | Pass | Pass | G-P1 |
| Accounts secondary | Pass | Pass | G-P2 |
| Buckets meters | Pass | Pass | Session/Weekly fill+track |
| Footer CTA | Pass | Pass | Open Usage Window |
| Open usage | Pass | Pass | Open usage page |

## §6.3 Usage
| Check | Dark | Light | Notes |
|-------|------|-------|-------|
| Toolbar | Pass | Pass | usage-toolbar-*.png |
| Sidebar nest craft | Pass* | Pass* | *component nest snap; full-window BLOCKED |
| Provider identity | Pass | Pass | G-U3 |
| Account nest | Pass | Pass | usage-provider-nest |
| Overview inventory | Pass | Pass | usage-overview |
| Detail limits | Pass | Pass | usage-detail-openai |

## High residual craft
**None** (live 2 BLOCKED honest).

## Live
| Scene | Verdict |
|-------|---------|
| popover-live | BLOCKED |
| ctx-menu-live | BLOCKED |
