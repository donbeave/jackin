# SoT CONFIRMED checklist — status / popover / Usage (2026-08-10)

| ID | Surface | Status | Evidence |
|----|---------|--------|----------|
| SB-1…SB-4, SB-7…SB-16, SB-18 | Status dual-stack | **met** | StatusItemRendering; harness status snaps |
| SB-3/14 ≤3 | Status | **met** | Rust strip max; PresentationStore.stripMax |
| SB-6 / FB1-22 logos | Status+plates | **met** | ProviderMarks 7/7 + maxA gate |
| SB-17 rank soonest-then-remaining | Status | **met** | Rust host compact strip tests |
| SB-19 hide 0% on bar | Status | **met** | host remaining==0 path; Overview still shows 0% (OV-7) |
| SB-20/21 weekly-first / Amp daily | Status | **met** | Rust view/host |
| SB-22 bar vs popover depth | Both | **met** | compact bar + full PopoverProviderTab |
| SB-23…26 focus path | Status→popover | **met** | StatusPopoverFocusTests + DesktopSoTParity |
| SB-27/28 taller popover | Popover | **met** | PopoverRoot maxHeight 640 / QI 1600 |
| OV-1…7 inventory | Overview | **met** | PopoverOverviewTab + OverviewInventory (rewrite this session) |
| OV-8 per-account refresh | Overview | **met** | refresh button → store.refresh(surfaceId:) |
| OV-9 no global Refresh footer | Popover | **met** | PopoverFooter Open Usage only |
| OV-10 no mystery severity dots | Overview | **met** | Circle dots removed; logos + meters |
| OV-12/13 craft bar | Overview | **met** | cards + hierarchy + mono % |
| FB1-6 transparent bar | Status | **met** | template mono, no chip chrome |
| FB1-12 no Overview strip | Overview | **met** | strip only Providers mode |
| FB1-13 Providers full detail | Providers | **met** | PopoverProviderTab buckets |
| FB1-17 strip centered | Providers | **met** | PopoverTabGrid |
| FB1-19 dual theme | All | **met** | dark+light snaps |
| FB1-20 brand on plates only | Meters | **met** | phosphor/severityTint meters; brandChrome plates |
| FB1-41 full popover not mini | Status click | **met** | PopoverRoot |
| FB1-43 Open Usage glass CTA | Footer | **met** | PopoverFooter |
| LG-A1… glass chrome | Shell | **met** | GlassFallbacks only (arch lint) |
| LG-5 provider company names | Labels | **met** | OpenAI/Anthropic/Amp display labels |
| UW-* shell | Usage | **met** | UsageWindowController glass sidebar + solid content |
| Limits-only | All | **met** | Parity matrix + arch tests |
| Product law display-only Swift | Bridge | **met** | ArchitectureTests / ParityMatrix |

## Deferred / OPEN (not silently implemented)
| ID | Note |
|----|------|
| LG-6 exact hex palette | CONFIRMED intent; exact hex OPEN — plates use HTML-adjacent interim colors |
| UW-O1 primary open control placement | OPEN — Open Usage footer + menu exist |
| SB-5 color urgency on bar chips | OPEN vs FB1-6 transparent — bar stays mono template |
| Live NSStatusItem Screen Recording | env BLOCKED; fixture StatusItemRendering accepted |

## Gates
- ProviderMarksHarness ALL PASS (maxA≥200)
- DesktopSoTParityHarness 15/15
- DesktopParityMatrixHarness ALL PASS
- DesktopArchitectureLint ALL PASS
- JackinUsageBridgeTests 44/44
