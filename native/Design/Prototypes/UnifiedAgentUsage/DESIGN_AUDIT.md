# Design audit — Unified Agent Usage prototype

Date: 2026-08-20. Live baseline and revised pass: F02, F04, F05, F25, and
F29 at 920 × 620 in Light and Dark. Review used the running executable and
the in-app Scenario menu; no screenshots were captured.

## A. Color system

Baseline: phosphor endpoints were adaptive, but wash alpha, severity colors,
meter track, card ground, stage, separator, and shadow escaped the token table.
System red/orange also gave no stable small-text contrast contract. Revised:
`JackinBrand` names every authored color. Phosphor, warning, and danger resolve
to explicit Light/Dark endpoints; wash and track alpha resolve dynamically in
the token. Native stage/card/separator colors remain system semantic tokens.
The decorative shadow was removed, leaving surface separation to the native
grounds and separator.

WCAG contrast against the resolved native card ground (small status text):

| Token | Light | Dark |
|---|---:|---:|
| Phosphor | 5.58:1 | 11.27:1 |
| Warning | 7.41:1 | 10.34:1 |
| Danger | 6.57:1 | 6.61:1 |

Verdict: AA passes. State remains paired with a symbol or label.

## B. Typography

Baseline: the hierarchy read correctly, but the 26-point hero was an isolated
literal and metadata used scattered font calls. Revised: the authored ramp is
named (`heroMetric`, `metadata`, `tertiary`); the hero is 28-point rounded
semibold. Percent, quota, sidebar, and reset numerals use monospaced digits.
First-baseline alignment remains on identity/hero pairs. F11 and F19 fixtures
retain middle truncation for account identifiers and multiline error/reset text.

## C. Spatial rhythm

Baseline: major gutters were close to a four-point rhythm, but 6, 10, and 14
point authored gaps weakened repetition. Revised: authored layout consumes the
documented 4/8/12/16/20/24 scale. Native controls keep system-owned metrics.

## D. Hierarchy and scanning

Provider mark/name remains first; the larger metric is next; the four-point
meter anchors it; reset metadata closes the scan. Healthy rows stay silent.
Warning/depleted labels remain visible but subordinate to the metric.

## E. Signature moments

One signature remains per surface: phosphor mark well in content, wordmark in
the sidebar structural plane, and the single prominent Open Usage action in the
popover. The refresh glyph/spinner swap remains system-owned and Reduce Motion
suppresses view animations. No additional ornament or glass was introduced.

## F. Multi-account

F25's five accounts retain one provider card with separated account blocks and
one expanded sidebar group. Shared spacing tokens calm repeated rows; account
identity truncates in the middle, and each row retains its numeric summary.

## G. Dark appearance

Dark phosphor remains #5CF07A. The quieter 10% adaptive well avoids a halo;
the card shadow is gone; track opacity rises slightly for separation. F02,
F04, F05, F25, and F29 remained launch-stable after the revised pass.

## Liquid Glass and native-component decision

No exception. Glass remains confined to native toolbar/popover controls.
Sidebar, List, Form, LabeledContent, Picker, Toggle, and system menu patterns
remain native. Overview quota cards are content, use no glass or blur, and use
the minimal custom boundary required for the scannable adaptive grid signature.

## Render-stability sweep

After the revision, all 36 supported fixture names (F00–F29 plus the named
F18, F19, and F24 variants) remained alive after initial render at 760 × 500,
920 × 620, and 1200 × 760 in Light and Dark: 216 launches. F18-f02 and
F18-f11 also passed at 920 × 620 in both appearances with reduction unset,
Transparency, Motion, and Transparency + Motion: 16 additional launches.
This proves launch/render stability; visual blessing and real system
accessibility-setting verification remain the operator-owned SIGNOFF lane.
