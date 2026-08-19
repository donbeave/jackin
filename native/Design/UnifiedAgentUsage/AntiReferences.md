# Anti-Reference Corpus — Unified Agent Usage

Status: PRESELECTION CORPUS

This corpus records rejected states, why they failed, the correction, and the
rule that must survive implementation. Eligible alternatives A, B, and G and the
optional H popover remix remain pending human selection; none is rejected here.
After selection, every unselected eligible direction is appended with the human
decision rationale rather than retroactively inferred by an agent.

## Rejected structural directions

| Anti-reference | Status | Why rejected | Required correction | Learned rule |
|---|---|---|---|---|
| Alternative C — canonical-account table first | Rejected and ineligible this round | Removes the settled persistent provider sidebar, makes provider order a filter/sort concern, and replaces the retained two-pane hierarchy at minimum width. | Retain Overview plus provider destinations in the sidebar; keep canonical accounts subordinate to providers and keep Rust ordering immutable. | A dense table is not automatically clearer when it erases the product object hierarchy. |
| Alternative D — three-column drilldown | Rejected and ineligible this round | Adds a third permanent region for a seven-provider inventory, fails the 760-point envelope, and changes account navigation into a different control below 900 points. | Keep one sidebar and one detail region; use a native account picker inside provider detail when needed. | Do not add a split merely to keep every relationship simultaneously visible. |
| Alternative E — native inspector | Rejected and ineligible this round | Treats primary quota windows as incidental metadata, adds a third region, and permits narrow-width overlay over the comparison surface. | Keep quota windows in primary detail content reached by stable provider/account selection. | Inspectors are for secondary properties, not the main reason the window exists. |
| Alternative F — provider workspace with nested account source list | Rejected and ineligible this round | Creates a split inside a split, wastes space for single-account providers, and introduces two layouts plus a second account-selection model. | Keep one canonical account-selection owner and one provider-detail composition across window sizes. | Responsive substitution must not duplicate navigation state or create two interaction models. |

## Rejected incumbent states

| Anti-reference | Status | Why rejected | Required correction | Learned rule |
|---|---|---|---|---|
| Increased Contrast overview collapse | Hard failure in the legacy running baseline | Provider labels, account values, plan, percentage, and reset text concatenate because provider/account identity lacks protective width behavior and provider group rows populate account-only columns with placeholders. | Group rows span hierarchy; identity/state survive before plan/reset; minimum-width and Increased Contrast fixtures prove zero overlap. | Accessibility appearance changes are layout inputs, not a cosmetic afterthought. |
| Placeholder-filled provider rows | Rejected legacy hierarchy | Repeated em dashes make provider groups resemble broken account records and compete with real values. | Use native group/disclosure semantics and leave account-only columns structurally absent on provider rows. | Missing data and non-applicable structure are different states; do not render both as placeholder noise. |
| Early account-label wrapping | Rejected legacy contraction order | Canonical account identity wraps while secondary plan/reset columns retain unnecessary width. | Contract optional metadata before provider/account identity and explicit state; expose complete accessibility text. | Protect object identity before descriptive metadata. |

## Rejected generic Mac directions

| Anti-reference | Status | Why rejected | Required correction | Learned rule |
|---|---|---|---|---|
| Card-grid usage dashboard | Rejected | Flattens provider/account/window hierarchy, adds equal visual weight, and encourages trend/spend decoration forbidden by the limits-only contract. | Native list/table hierarchy for inventory and native form/list detail for quota windows. | Monitoring work needs selection and comparison structure, not a wall of metric cards. |
| Custom-painted glass, blur, pills, window chrome, or sidebar | Rejected | Duplicates system-owned macOS 26 material and forfeits automatic contrast, transparency, focus, metric, and future-platform behavior. | Standard AppKit/SwiftUI structure and controls; no custom material while native components satisfy the job. | Do not draw what the operating system owns. |
| Fixed-canvas desktop layout | Rejected | Pretends the Mac window cannot resize and hides failures at the 760 × 500 minimum, long text, display scaling, and toolbar overflow. | Continuous native resizing across minimum, typical, and wide sizes with stable focus and selection. | A Mac design is a behavior envelope, not one screenshot size. |

## Evidence

- [Structural alternatives](Alternatives.md) — complete direction descriptions,
  strengths, risks, and eligibility.
- [Legacy baseline visual QA](BaselineVisualQA.md) — running-app failure evidence.
- [Experience brief](ExperienceBrief.md) — archetype, hierarchy, density, and
  out-of-scope boundaries.
- [Native component map](NativeComponentMap.md) — system-owned replacements and
  forbidden customizations.
- [Apple-native research](../../../research/agent-usage-platform/02-apple-native-design.md)
  — primary-source component and material constraints.
