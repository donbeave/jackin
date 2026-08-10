# SoT CONFIRMED checklist — status / popover / Usage

**Branch tip:** plan/desktop-visual @ 9c4e428c (+ any later)  
**Method:** decisions §0 + surface CONFIRMED IDs vs shipped native + gates/snaps

| ID | Surface | Status | Evidence |
|----|---------|--------|----------|
| SB-1…SB-4 compact burn-first ≤3 | Status | **met** | StatusItemRendering dual-stack; stripMax/Rust |
| SB-6 / FB1-22 official logos | Status+plates | **met** | ProviderMarks 7/7 + maxA≥200 harness |
| SB-7…SB-16 dual-line time/% | Status | **met** | title(barLabel, resetLabel) compact ladder |
| SB-17 soonest-then-remaining | Status | **met** | Rust host compact strip tests |
| SB-19 hide 0% on bar | Status | **met** | host remaining==0; Overview still shows 0% |
| SB-20/21 weekly-first / Amp daily | Status | **met** | Rust view/host |
| SB-22 bar vs popover depth | Both | **met** | compact bar + full provider tab |
| SB-23…26 chip → focused popover | Status→popover | **met** | StatusPopoverFocus + SoT harness |
| SB-27/28 tall popover minimize scroll | Popover | **met** | PopoverRoot maxHeight 640 / QI expand |
| OV-1…4, OV-6…7 inventory IA | Overview | **met** | PopoverOverviewTab + OverviewInventory |
| OV-5 relative + calendar | Overview | **partial** | Selected/glance: `overviewResetDisplay`; unit+SoT assert calendar. Unselected multi-account: **deferred** (AccountRow has no reset DTO) |
| OV-8 per-surface refresh | Overview | **met** | refresh control → store.refresh(surfaceId:) |
| OV-9 no global Refresh footer | Popover | **met** | PopoverFooter Open Usage only |
| OV-10 no mystery severity dots | Overview | **met** | logos + meters only |
| OV-12/13 craft hierarchy | Overview | **met** | cards, mono %, meters |
| FB1-6 transparent bar | Status | **met** | template mono, no chip chrome |
| FB1-12 Overview without provider strip | Overview | **met** | strip only Providers mode |
| FB1-13 Providers full detail | Providers | **met** | PopoverProviderTab |
| FB1-17 strip centered | Providers | **met** | PopoverTabGrid |
| FB1-19 dual theme | All | **met** | dark+light snaps |
| FB1-20 brand on plates only | Meters | **met** | severityTint/phosphor meters; brandChrome plates |
| FB1-41 full popover not mini | Status click | **met** | PopoverRoot |
| FB1-43 Open Usage glass CTA | Footer | **met** | PopoverFooter |
| LG-A1… glass chrome only | Shell | **met** | GlassFallbacks; ArchitectureLint |
| LG-5 company display names | Labels | **met** | OpenAI / Anthropic / Amp |
| UW shell glass sidebar solid content | Usage | **met** | UsageWindowRoot / controller |
| Limits-only / display-only Swift | All | **met** | Parity matrix + ArchitectureTests |
| Credential = Rust origin only | Provider detail | **met** | PopoverProviderTab credentialOrigin |

## Deferred / OPEN (not silent CONFIRMED)
| ID | Note |
|----|------|
| OV-5 unselected multi-account reset | Needs Rust Account DTO reset/exact fields |
| LG-6 exact plate hex | Interim HTML-adjacent colors |
| UW-O1 primary open control | Footer + menu exist; exact placement OPEN |
| SB-5 urgency color on bar chips | vs FB1-6 transparent — bar stays mono |
| Live NSStatusItem Screen Recording | Fixture StatusItemRendering accepted |

