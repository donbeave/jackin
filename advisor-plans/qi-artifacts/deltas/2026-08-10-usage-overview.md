# QI delta: usage-overview · dark (+ light)

## Oracle
- HTML: qi-artifacts/html/usage-overview-dark.png

## Candidate
- Native: qi-artifacts/native/usage-overview-dark.png
- Code: `OverviewListView` + `OverviewInventory` on fixture store accounts

## Same (keep)
- Per-account rows: Anthropic · Personal 12% red; OpenAI · chainargos 57% orange; OpenAI · zhokhov 0% empty meter; Amp · Free 100%
- Titles use Provider · account pattern
- Severity-colored % + meters; 0% track empty

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Window chrome | Full Usage + glass sidebar Overview selected | Content list only | G-U2 | Full window optional |
| Low | Reset subcopy | Exact clock parentheticals | Rust resetLabel only when selected glance | G-U5 | Data limit |

## Verdict
**Pass** — inventory IA and fixture % match HTML Overview content.
