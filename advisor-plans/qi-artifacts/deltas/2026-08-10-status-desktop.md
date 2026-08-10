# QI delta: status-desktop · live + StatusItemRendering

## Oracle
- HTML: qi-artifacts/html/status-desktop-dark.png
- Source: index.html system menu-bar mock with dual-stack extras

## Candidate
- Live: qi-artifacts/native/status-desktop-live-dark.png (AX-geometry screencapture of JackinDesktop menu bar 2 extras)
- API: qi-artifacts/native/status-desktop-dark.png (StatusItemRendering.icon + title bitmap)
- Launch: `{SCRATCH}/app-launch-prod.log` — JackinDesktop release binary running under Xcode 26.6
- AX inventory: status-ax-positions.tsv — OpenAI, Anthropic (`4d 4h`/`95%` dual-stack title), Amp 100%, xAI dual-stack, Kimi

## Same (keep)
- Live NSStatusItem extras present (menu bar 2), template mono icons, **no glass chips** (FB1-6)
- Dual-stack where Rust supplies reset+bar: AX titles show compact reset + % on Anthropic/xAI
- Amp single-line 100%; OpenAI/Kimi dash when no glance %
- System /CC/clock not cloned

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Fixture numbers | 12%/57%/100% mock | Live host credentials (95%/36%/…) | G-D1 | Expected — live data ≠ HTML fixture |
| Low | Density crop | Full bar mock | Crop of extras only | G-S1 | OK for extras parity |
| N/A | /CC/clock | Mocked | System | — | do not clone |

## Verdict
**Pass** — live status extras + dual-stack StatusItemRendering path; L4 launch succeeded on Xcode.app.
