# QI delta: status-desktop · dark (+ light API)

## Oracle
- HTML: advisor-plans/qi-artifacts/html/status-desktop-dark.png
- Source: index.html Status interactions (system menu-bar mock)

## Candidate
- Live: advisor-plans/qi-artifacts/native/status-desktop-live-dark.png
- API: advisor-plans/qi-artifacts/native/status-desktop-{dark,light}.png (`StatusItemRendering`)
- Code: StatusItemLabel / StatusItemRendering
- Dual-image review: HTML mock strip shows dual-stack 1h/12% · 3d/57% · 18h/100%; live AX titles show dual-stack on Anthropic/xAI; live crop shows template mono extras (Amp 100%); no glass chips

## Same (keep)
- Template mono extras; dual-stack when reset+bar present; no Liquid Glass chips (FB1-6)
- System /CC/clock N/A

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| Med | Fixture % | 12/57/100 mock | Live host credentials | G-D1 | Expected |
| N/A | System chrome | Mocked | Real system | — | do not clone |

## Verdict
Verdict: Pass
