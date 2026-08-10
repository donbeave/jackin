# QI delta: popover-openai · dark (+ light host)

## Oracle
- HTML: qi-artifacts/html/popover-openai-dark.png
- Source: popover.html OpenAI provider body + hub embed

## Candidate
- Native: qi-artifacts/native/popover-openai-dark.png
- Code: `PopoverRoot` ← `PopoverTabGrid` + `PopoverProviderTab` + `PopoverFooter`
- Store: `PresentationStore.applyQIFixture` (DATA_CONTRACT fixtures)

## Same (keep)
- Full shell: Overview + provider strip with selection on OpenAI, body, glass Refresh footer (not mini-pop body-only)
- Hero remaining: Session 63%, Weekly 57% (warn orange), Spark buckets; 1:1 meters
- Multi-account chips: selected alexey@chainargos.com 57%, unselected zhokhov 0%
- Open usage page control; header meta with account · plan · updated
- Fixture numbers match DATA_CONTRACT (57/63/88/100)

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Chrome chrome IA | Segmented Overview/Providers + brand `j❯ jackin❯ desktop` top | Horizontal Overview+providers tabs (no separate Providers mode) | G-P1 | SoT native path is tab grid — acceptable if product law keeps it; optional brand strip |
| Med | Footer CTA | Green “Open Usage Window” pill | Glass **Refresh** + ⌘R (FB1 / LG-A8) | G-P4 | Keep Refresh — product law; header chevron opens Usage |
| Low | Accent | Phosphor green | System accent blue | VS-13 | Brand accent when app sets phosphor |
| Low | Account meta card | Separate ACCOUNT status/auth card before heroes | Heroes first after chips | G-P3 | Optional density polish |

## Verdict
**Pass** — full shipped PopoverRoot shell + provider body IA/meters match SoT roles; residual Med are chrome variants under product law, not High IA fails.
