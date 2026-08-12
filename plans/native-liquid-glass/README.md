# Native Liquid Glass redesign

Status: **A1 production implementation and automated branch-head evidence complete; A08–A09 and final repository delivery proof pending**

These files are the design authority for the native jackin❯ desktop redesign. The A1 selection authorized Phase 2 audits and the smallest runnable Phase 3 proof; D-004 separately authorizes production implementation of that confirmed direction.

## Evidence and decisions

- [DRIFT_REPORT.md](DRIFT_REPORT.md) — Phase 0 implementation and preview drift
- [DecisionLog.md](DecisionLog.md) — operator decisions and their exact scope
- [ExperienceBrief.md](ExperienceBrief.md) — separate briefs for the menu-bar
  popover and Usage window
- [InformationArchitecture.md](InformationArchitecture.md) — objects,
  hierarchy, navigation, actions, and continuity
- [NativeComponentMap.md](NativeComponentMap.md) — native ownership for every
  visible region
- [LayerMap.md](LayerMap.md) — content versus functional layers and material
  ownership
- [BrandIntegration.md](BrandIntegration.md) — operator-directed synthesis of
  native hierarchy, canonical identity, and semantic phosphor color
- [Fixtures.md](Fixtures.md) — deterministic design and validation data
- [RequiredStates.md](RequiredStates.md) — required appearance, accessibility,
  interaction, sizing, and restoration states
- [Alternatives.md](Alternatives.md) — eight structural alternatives and the
  current recommendation
- [LiquidGlassAudit.md](LiquidGlassAudit.md) — Phase 2 region, mechanics,
  availability, anti-pattern, and acceptance audit
- [SwiftProjectAudit.md](SwiftProjectAudit.md) — Phase 2 project, toolchain,
  signing, test, CI, and agent-integration audit
- [ConceptMigrationPlan.md](ConceptMigrationPlan.md) — bounded migration plan
  for the runnable A1 proof
- [ConceptHandoff.md](ConceptHandoff.md) — runnable build, fixture, component,
  AppKit-boundary, and verification handoff for the A1 proof
- [ProductionPlan.md](ProductionPlan.md) — post-confirmation coverage ledger, zero-context slices, verification, recovery, and completion conditions
- [CompletionAudit.md](CompletionAudit.md) — authoritative DONE-criteria ledger and exact remaining proof

## Gate

The operator selected A1 and explicitly confirmed the runnable native concept with `I confirm the runnable A1 native concept.` Production work is authorized only when it preserves A1 plus D-002 and D-003. Publication and merge remain separately controlled.

## Product invariants

- Rust owns provider detection, provider and account ordering, labels, plan and
  status strings, quota rows, percentages, reset text, refresh results, and URLs.
- Swift presents Rust-owned data and adapts it to native macOS structure.
- Usage surfaces show subscription and quota limits only. They never show token
  prices, estimated spend, spend history, usage trends, or cost rankings.
- The current desktop provider domain is the seven-entry Rust-owned
  `DESKTOP_PROVIDER_ORDER`. OpenCode is not added by the redesign.
- SwiftUI is the primary UI framework. AppKit remains only at proven platform
  boundaries.
- Liquid Glass belongs to system-owned navigation and transient functional
  layers. Content rows, tables, forms, and quota presentations do not receive
  glass.

## Sources

The design rules are based on Apple Human Interface Guidelines and first-party
macOS behavior, including [Materials](https://developer.apple.com/design/human-interface-guidelines/materials),
[Navigation and search](https://developer.apple.com/design/human-interface-guidelines/navigation-and-search),
and [Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/).
The installed Xcode 26.6 toolchain and macOS 26.5 SDK are the API baseline for
later implementation probes.
