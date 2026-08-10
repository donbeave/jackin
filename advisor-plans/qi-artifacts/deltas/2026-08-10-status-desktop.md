# QI delta: status-desktop · dark + light

## Oracle
- HTML: advisor-plans/qi-artifacts/html/status-desktop-{dark,light}.png
- FB1-6: template mono dual-stack — never Liquid Glass chips
- System  / Control Center / clock = N/A (do not clone)

## Candidate
- Native: advisor-plans/qi-artifacts/native/status-desktop-{dark,light}.png
- Capture: `DesktopVisualSnapshotHarness` → `StatusItemRendering.icon` + `.title`
  on menu-bar **stage fill** (not clear); template icons tinted with `labelColor`;
  cell width measured from dual-stack title so `100%` stays one line.

## Dual-image (personal read post-fix)

| Theme | Readable | Icons | Dual-stack | Notes |
|-------|----------|-------|------------|-------|
| Dark | yes | sparkles / hex / waveform | 1h·12% · 3d·57% · 18h·100% | stage ~0.14 gray |
| Light | yes | same | same fixture tokens | stage ~0.90 gray; **not blank** |

| Dimension | Score | Notes |
|-----------|-------|-------|
| IA / hierarchy | Pass | Per-provider dual-stack extras |
| Color | Pass | Template mono on stage (not phosphor chips) |
| Meters | N/A | Status uses % tokens, not fill bars |
| Copy / data | Pass | Rust barLabel + compact reset |
| Affordances | Pass | Icons present beside dual stack |

## Different (Low only)
| Severity | Element | HTML | Native | Action |
|----------|---------|------|--------|--------|
| Low | Stage | Full menubar desk | Isolated strip on solid stage | Accept harness tier |
| Low | Glyphs | HTML SVG stand-ins | SF Symbol template | Accept FB1-6 native |

## Verdict
Verdict: Pass
