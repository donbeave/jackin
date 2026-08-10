# QI delta: popover-openai · hosted PopoverRoot + live open

## Oracle
- HTML: qi-artifacts/html/popover-openai-dark.png

## Candidate
- Hosted: qi-artifacts/native/popover-openai-dark.png — full `PopoverRoot` (TabGrid+body+Footer)
- Live: qi-artifacts/native/popover-live-openai-dark.png — left-click OpenAI status item (production app)

## Same (keep)
- **Full glance popover** (not mini-pop): Overview + providers strip, selected OpenAI, body, glass Refresh footer
- Live left-click focuses **OpenAI** tab (G-S2)
- Multi-account chips with remaining %; Open usage page; hero remaining cards + meters
- Hosted fixture: Session 63% / Weekly 57% / DATA_CONTRACT

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Top chrome | Overview/Providers segmented + brand mark | Tab grid only | G-P1 | Product native path |
| Med | Footer | Open Usage Window green CTA | Refresh dock (FB1/LG-A8) | G-P4 | Keep |
| Low | Accent | Phosphor green | System accent | VS-13 | Brand accent optional |
| Low | Live numbers | Fixture 57% | Live account % | G-D1 | Live data |

## Verdict
**Pass** — full shell + live focus match SoT IA/roles.
