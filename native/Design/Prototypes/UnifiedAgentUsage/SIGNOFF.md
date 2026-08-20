# SIGNOFF — Unified Agent Usage prototype

Prototype package: `native/Design/Prototypes/UnifiedAgentUsage/`
Launch contract: `--tr-scenario`, `--tr-appearance`, `--tr-window`,
`--tr-reduce`, `--tr-backdrop`. `default` resolves byte-for-byte to F02.
Unknown scenario names (including the F18/F19/F24 matrix headings) and
malformed sizes fail at launch with a nonzero exit.

Operator entry points from the repository root:

```sh
mise run desktop-prototype-build
mise run desktop-prototype-run -- F02 920x620 light
mise run desktop-prototype -- F02 920x620 dark
```

The combined `desktop-prototype` task builds then launches. Optional fourth and
fifth positional arguments map to the existing reduction and backdrop flags;
the executable launch contract remains unchanged. Build assembles a local
`UnifiedAgentUsageProto.app`; run opens that app through macOS, so it opens only
the prototype window, never Terminal. Re-running replaces the prior prototype.

## Design inputs (consumed revisions)

| Artifact | Path | Commit | Date |
|---|---|---|---|
| Experience brief | `native/Design/UnifiedAgentUsage/ExperienceBrief.md` | `aca543dd` | 2026-08-20 |
| Native component map | `native/Design/UnifiedAgentUsage/NativeComponentMap.md` | `e06b0243` | 2026-08-20 |
| Alternatives (A without H, selected) | `native/Design/UnifiedAgentUsage/Alternatives.md` | `aca543dd` | 2026-08-20 |
| Anti-references | `native/Design/UnifiedAgentUsage/AntiReferences.md` | `aca543dd` | 2026-08-20 |
| Fixtures F00–F24 | `native/Design/UnifiedAgentUsage/Fixtures.md` | `fc5c7d99` | 2026-08-20 |
| Legacy baseline visual QA | `native/Design/UnifiedAgentUsage/BaselineVisualQA.md` | `0b859a0a` | 2026-08-20 |
| Swift project readiness | `native/Design/UnifiedAgentUsage/SwiftProjectReadiness.md` | `b663e4b3` | 2026-08-20 |
| Swift best-practices review | `native/Design/UnifiedAgentUsage/SwiftBestPracticesReview.md` | `b663e4b3` | 2026-08-20 |

## Scenarios walked

Legend: ✅ approved live by the user · ☐ pending. Every Usage scenario runs at
760 × 500, 920 × 620, and 1200 × 760 in light and dark; popover-bearing
scenarios also run at 380 × 520 in both appearances. F18 subscenarios repeat
with `--tr-reduce` unset / `transparency` / `motion` / `transparency,motion`.

| Scenario | Sizes | Light | Dark | Popover | Result |
|---|---|---|---|---|---|
| `default` (= F02 byte-for-byte) | 3 | ☐ | ☐ | ☐ | pending |
| F00 no providers | 3 | ☐ | ☐ | — | pending |
| F01 single normal | 3 | ☐ | ☐ | ☐ | pending |
| F02 full catalog | 3 | ☐ | ☐ | ☐ | pending |
| F03 multi-account | 3 | ☐ | ☐ | ☐ | pending |
| F04 nearly exhausted | 3 | ☐ | ☐ | ☐ | pending |
| F05 exhausted | 3 | ☐ | ☐ | — | pending |
| F06 stale last-good | 3 | ☐ | ☐ | ☐ | pending |
| F07 refreshing last-good | 3 | ☐ | ☐ | ☐ | pending |
| F08 partial timeout | 3 | ☐ | ☐ | ☐ | pending |
| F09 permission denied | 3 | ☐ | ☐ | — | pending |
| F10 offline cached | 3 | ☐ | ☐ | ☐ | pending |
| F11 long labels | 3 | ☐ | ☐ | ☐ | pending |
| F12 layout envelope (42 accounts) | 3 | ☐ | ☐ | ☐ | pending |
| F13 initial loading | 3 | ☐ | ☐ | — | pending |
| F14 global bridge error | 3 | ☐ | ☐ | — | pending |
| F15 accepted preference mutation | 3 | ☐ | ☐ | ☐ | pending |
| F16 rejected preference mutation | 3 | ☐ | ☐ | ☐ | pending |
| F17 reordered mutation completion | 3 | ☐ | ☐ | ☐ | pending |
| F18-f02 × 4 reduction settings | 3 | ☐ | ☐ | ☐ | pending |
| F18-f11 × 4 reduction settings | 3 | ☐ | ☐ | ☐ | pending |
| F19-en-US (2× expansion) | 3 | ☐ | ☐ | ☐ | pending |
| F19-ar-SA (RTL) | 3 | ☐ | ☐ | ☐ | pending |
| F19-ja-JP (CJK) | 3 | ☐ | ☐ | ☐ | pending |
| F19-de-DE (German) | 3 | ☐ | ☐ | ☐ | pending |
| F20 destructive sentinel | 3 | ☐ | ☐ | ☐ | pending |
| F21 keyboard/VoiceOver sequence | live | ☐ | ☐ | ☐ | pending |
| F22 provider money cap | 3 | ☐ | ☐ | ☐ | pending |
| F23 physical display/restoration | live | ☐ | ☐ | ☐ | pending |
| F24-f02 resize sweep | live | ☐ | ☐ | ☐ | pending |
| F24-f11 resize sweep | live | ☐ | ☐ | ☐ | pending |
| F24-f12 resize sweep | live | ☐ | ☐ | ☐ | pending |

## Pending capture lane (post-signoff, `tailrocks-macos-visual-qa`)

- Baseline captures of every scenario above through the same five-flag
  launch contract, under the region policy in `Regions.md`.
- Real accessibility-settings matrix with snapshot-and-restore: Increase
  Contrast, Differentiate Without Color, Full Keyboard Access, Reduce
  Transparency, Reduce Motion — including the F18 and F24 repeats under real
  settings.
- Light/dark key-window and inactive-window transitions.

## Not proven live by this prototype

- System material adaptation under real Reduce Transparency: the macOS 26.5
  SDK accessibility environment keys are get-only, so the process-local
  `--tr-reduce transparency` flag cannot drive system materials; this design
  ships no custom material, so there is nothing SwiftUI-owned to adapt.
  Reduce Motion is honored by stripping view animations process-locally.
- VoiceOver announcement wording and full keyboard traversal (F21 is walked
  live for focus/order; the audit lane owns the recorded evidence).
- Multi-display anchoring/restoration beyond the displays present during the
  blessing walk (F23).
- The prototype renders fixture records only; no Rust bridge, credentials,
  or network path is exercised.

## Blessed

(empty — the user records approval here, with name and date, after walking
every scenario above live)

Blessed: — by —
