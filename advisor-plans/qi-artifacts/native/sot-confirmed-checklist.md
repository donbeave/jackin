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
| OV-1…4, OV-6…7 | Overview | **met** | PopoverOverviewTab + OverviewInventory |
| OV-5 relative + calendar when known | Overview | **partial** | Selected/glance: `overviewResetDisplay(resetLabel,exactReset)` → dual line. Unit + SoT harness PASS calendar text. Unselected multi-account: **deferred** — `AccountRow` has no reset/exact DTO from Rust (not invented). |
| OV-8 per-account refresh | Overview | **met** | refresh → store.refresh(surfaceId:) (surface scope; per-account when DTO allows) |
| OV-9 no global Refresh footer | Popover | **met** | PopoverFooter Open Usage only |
| OV-10 no mystery severity dots | Overview | **met** | logos + meters |
| OV-12/13 craft bar | Overview | **met** | cards + hierarchy + mono % |
| FB1-6 transparent bar | Status | **met** | template mono |
| FB1-12 no Overview strip | Overview | **met** | strip only Providers mode |
| FB1-13 Providers full detail | Providers | **met** | PopoverProviderTab |
| FB1-17 strip centered | Providers | **met** | PopoverTabGrid |
| FB1-19 dual theme | All | **met** | dark+light snaps |
| FB1-20 brand on plates only | Meters | **met** | phosphor/severityTint meters |
| FB1-41 full popover | Status click | **met** | PopoverRoot |
| FB1-43 Open Usage glass CTA | Footer | **met** | PopoverFooter |
| LG-A1… glass chrome | Shell | **met** | GlassFallbacks only |
| LG-5 provider company names | Labels | **met** | OpenAI/Anthropic/Amp |
| UW-* shell | Usage | **met** | UsageWindowController |
| Limits-only | All | **met** | Parity matrix |

## Deferred / OPEN
| ID | Note |
|----|------|
| OV-5 unselected multi-account calendar | Needs Rust Account DTO reset fields |
| LG-6 exact hex palette | interim HTML-adjacent plate colors |
| UW-O1 open control placement | Open Usage footer + menu |
| Live NSStatusItem Screen Recording | fixture StatusItemRendering accepted |

## Gates
- DesktopSoTParityHarness 18/18 (includes OV-5 exactReset asserts)
- OverviewInventoryTests 5/5
- ProviderMarksHarness, ParityMatrix, ArchitectureLint (see desktop-gates.log)
