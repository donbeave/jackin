# QI delta: usage-toolbar · dark (+ light hosted)

## Oracle
- HTML: qi-artifacts/html/usage-toolbar-dark.png (and -light where present)
- Source: plans/previews/desktop-ui/index.html | popover.html

## Candidate
- Native: qi-artifacts/native/usage-toolbar-dark.png (+ light)
- Code: JackinDesktopUI hosted via DesktopVisualSnapshotHarness (CLT; no live NSStatusItem/NSPopover)

## Same (keep)
- Centered jackin❯ desktop title + icon Refresh stand-in
- Real unified NSToolbar path verified in UsageWindowController + ArchitectureLint
- Live titlebar chrome L4 partial without window capture

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Full shell chrome | Tab strip + glass footer on popover | Hosted body only (tab grid/footer need PopoverRoot+store) | G-P1 | Live app / PopoverRoot snapshot when Xcode GUI available |
| N/A | System  / CC | Mocked in hub | System chrome | — | do not clone |
| Low | Accent hue | Phosphor green | System accent (blue on this host) | VS-13 | Brand accent only when system accent set; not High |

## Verdict
Pass
