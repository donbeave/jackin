# Native Liquid Glass redesign

Status: **Phase 1 draft — operator selection required**

These files are the design authority proposed for the native jackin❯ desktop
redesign. They do not authorize implementation. Production Swift remains
unchanged until the operator selects a structural direction.

## Evidence and decisions

- [DRIFT_REPORT.md](DRIFT_REPORT.md) — Phase 0 implementation and preview drift
- [ExperienceBrief.md](ExperienceBrief.md) — separate briefs for the menu-bar
  popover and Usage window
- [InformationArchitecture.md](InformationArchitecture.md) — objects,
  hierarchy, navigation, actions, and continuity
- [NativeComponentMap.md](NativeComponentMap.md) — native ownership for every
  visible region
- [LayerMap.md](LayerMap.md) — content versus functional layers and material
  ownership
- [Fixtures.md](Fixtures.md) — deterministic design and validation data
- [RequiredStates.md](RequiredStates.md) — required appearance, accessibility,
  interaction, sizing, and restoration states
- [Alternatives.md](Alternatives.md) — eight structural alternatives and the
  current recommendation

## Gate

The operator must select one alternative, reject all alternatives, or request a
remix. After that decision, the selected structure is recorded and Phase 2 can
begin. No alternative is implicitly approved by this document set.

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
