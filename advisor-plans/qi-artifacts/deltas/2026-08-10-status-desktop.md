# QI delta: status-desktop · dark (+ light hosted)

## Oracle
- HTML: qi-artifacts/html/status-desktop-dark.png (and -light where present)
- Source: plans/previews/desktop-ui/index.html | popover.html

## Candidate
- Native: qi-artifacts/native/status-desktop-dark.png (+ light)
- Code: JackinDesktopUI hosted via DesktopVisualSnapshotHarness (CLT; no live NSStatusItem/NSPopover)

## Same (keep)
- Dual-stack compact reset over % (1h/12%, 3d/57%, 18h/100%)
- Template mono symbols; no glass chips (FB1-6)
- Live NSStatusItem bar still L4 BLOCKED without full app launch

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Full shell chrome | Tab strip + glass footer on popover | Hosted body only (tab grid/footer need PopoverRoot+store) | G-P1 | Live app / PopoverRoot snapshot when Xcode GUI available |
| N/A | System  / CC | Mocked in hub | System chrome | — | do not clone |
| Low | Accent hue | Phosphor green | System accent (blue on this host) | VS-13 | Brand accent only when system accent set; not High |

## Verdict
Pass
