# QI delta: usage-toolbar · dark (+ light)

## Oracle
- HTML: qi-artifacts/html/usage-toolbar-dark.png
- Source: Usage window titlebar mock — centered jackin❯ desktop + refresh

## Candidate
- Native: qi-artifacts/native/usage-toolbar-dark.png
- Code: **real** `UsageWindowController` → `NSWindow` `toolbarStyle = .unified` + `NSHostingController` + SwiftUI `.toolbar` Refresh
- Capture: CGWindow full window, crop top band (not fake HStack)

## Same (keep)
- Real system traffic lights + window title **jackin❯ desktop**
- Icon-only Refresh control present on unified titlebar/toolbar
- Not a custom floating HTML strip

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Title position | Centered in titlebar | Leading (system unified + sidebar affordance) | G-U1 | Native macOS layout OK |
| Low | Extra controls | Refresh only | Sidebar toggle + Refresh | G-U1 | System NavigationSplitView chrome |

## Verdict
**Pass** — real NSToolbar host path evidenced by window capture; IA matches Usage chrome roles.
