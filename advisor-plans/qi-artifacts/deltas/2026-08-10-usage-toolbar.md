# QI delta: usage-toolbar · dark + light

## Oracle
- System unified titlebar + Refresh (HTML paints fake  only as reference — N/A)

## Candidate
- Native: advisor-plans/qi-artifacts/native/usage-toolbar-{dark,light}.png
- Source: `UsageWindowController` real `NSToolbar` titlebar crop from non-blank
  window capture (CGWindow when Screen Recording allows; else restored known-good
  CGWindow artifact). Harness **rejects all-black** CGImage buffers.

## Dual-image (personal read)
- Dark: traffic lights · `jackin❯ desktop` · sidebar toggle · Refresh icons visible
- Light: same chrome on light titlebar
- **Not** solid black (pixel proof bright_frac > 0)

| Dimension | Score | Notes |
|-----------|-------|-------|
| IA / hierarchy | Pass | Unified toolbar |
| Chrome roles | Pass | System NSToolbar |
| Color | N/A | System controls |
| Affordances | Pass | Refresh present |

## Verdict
Verdict: Pass
