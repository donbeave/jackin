# SoT CONFIRMED checklist — status / popover / Usage

**Tip:** plan/desktop-visual @ 97d4b053  
**SoT:** decisions §0 → HTML index/popover → AGENT_HANDOFF

| ID | Surface | Status | Evidence |
|----|---------|--------|----------|
| SB-1…SB-4 burn-first ≤3 compact | Status | **met** | StatusItemRendering; Rust stripMax |
| SB-6 / FB1-22 official logos | Status+plates | **met** | ProviderMarks 7/7 + maxA≥200 |
| SB-7…SB-16 dual-line time/% | Status | **met** | title(barLabel, resetLabel) |
| SB-17 soonest-then-remaining | Status | **met** | host compact strip tests |
| SB-19 hide 0% on bar | Status | **met** | host; Overview still shows 0% |
| SB-20/21 weekly-first / Amp daily | Status | **met** | Rust view/host |
| SB-22 bar vs popover depth | Both | **met** | compact bar + PopoverProviderTab |
| SB-23…26 chip → focused popover | Status→popover | **met** | StatusPopoverFocus + SoT harness |
| SB-27/28 tall popover | Popover | **met** | PopoverRoot maxHeight |
| OV-1…4, OV-6…7 inventory IA | Overview | **met** | PopoverOverviewTab + OverviewInventory |
| OV-5 relative + calendar | Overview | **partial** | Selected/glance: overviewResetDisplay; unselected multi-account **deferred** (no Account DTO reset) |
| OV-8 refresh control | Overview | **met** | store.refresh(surfaceId:) |
| OV-9 no global Refresh footer | Popover | **met** | PopoverFooter Open Usage only |
| OV-10 no severity dots | Overview | **met** | logos + meters |
| OV-12/13 craft hierarchy | Overview | **met** | cards, mono %, meters |
| FB1-6 transparent bar | Status | **met** | template mono |
| FB1-12 Overview no strip | Overview | **met** | strip Providers-only |
| FB1-13 Providers full detail | Providers | **met** | PopoverProviderTab |
| FB1-17 strip centered | Providers | **met** | PopoverTabGrid |
| FB1-19 dual theme | All | **met** | dark+light snaps |
| FB1-20 brand on plates only | Meters | **met** | severityTint/phosphor; brandChrome plates |
| FB1-41 full popover | Status click | **met** | PopoverRoot |
| FB1-43 Open Usage glass CTA | Footer | **met** | PopoverFooter |
| LG-A1… glass chrome | Shell | **met** | GlassFallbacks; ArchitectureLint |
| LG-5 company names | Labels | **met** | OpenAI/Anthropic/Amp |
| UW shell glass/solid | Usage | **met** | UsageWindowRoot |
| Limits-only / display-only | All | **met** | Parity matrix + arch tests |
| Credential Rust-only | Provider detail | **met** | credentialOrigin |

## Deferred / OPEN (not silent CONFIRMED)
| ID | Note |
|----|------|
| OV-5 unselected multi-account reset | AccountRow lacks reset/exact DTO |
| LG-6 exact plate hex | interim HTML-adjacent |
| UW-O1 open control placement | footer + menu exist |
| SB-5 bar chip color vs FB1-6 | bar stays mono |
| Live NSStatusItem Screen Recording | fixture StatusItemRendering + BLOCKED.txt |

