# QI delta: usage-toolbar · dark + light

## Oracle
- HTML: advisor-plans/qi-artifacts/html/usage-toolbar-dark.png

## Candidate
- Native: advisor-plans/qi-artifacts/native/usage-toolbar-{dark,light}.png
- Source: crop of real `UsageWindowController` CGWindow (unified titlebar + toolbar)
- Dual-image review: HTML centered jackin❯ desktop + refresh; native real traffic lights + jackin❯ desktop + Refresh icon on unified toolbar (not custom floating strip)

## Same (keep)
- Real NSToolbar / unified titlebar host; brand title; Refresh control

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Title position | Centered | Leading (system unified) | G-U1 | Native OK |
| Low | Extra controls | Refresh only | Sidebar toggle + Refresh | G-U1 | System NavigationSplitView |

## Verdict
Verdict: Pass
