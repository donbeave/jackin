# QI delta: popover-openai · dark (+ light hosted)

## Oracle
- HTML: qi-artifacts/html/popover-openai-dark.png (and -light where present)
- Source: plans/previews/desktop-ui/index.html | popover.html

## Candidate
- Native: qi-artifacts/native/popover-openai-dark.png (+ light)
- Code: JackinDesktopUI hosted via DesktopVisualSnapshotHarness (CLT; no live NSStatusItem/NSPopover)

## Same (keep)
- Hero remaining % (63/57/88/100) with severity color
- Account chips: selected filled, multi-account rail
- Bucket cards solid content layer; 1:1 meters; Limit Reset Credits present
- DATA_CONTRACT fixtures (57%, 0%, Pro 20×)

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Full shell chrome | Tab strip + glass footer on popover | Hosted body only (tab grid/footer need PopoverRoot+store) | G-P1 | Live app / PopoverRoot snapshot when Xcode GUI available |
| N/A | System  / CC | Mocked in hub | System chrome | — | do not clone |
| Low | Accent hue | Phosphor green | System accent (blue on this host) | VS-13 | Brand accent only when system accent set; not High |

## Verdict
Pass
