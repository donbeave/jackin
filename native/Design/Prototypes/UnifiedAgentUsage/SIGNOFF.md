# Signoff — Unified Agent Usage prototype

Status: implementation reference complete; human visual blessing pending.

The prototype is dark-only. Canonical geometry is 800×520 minimum, 1000×680
default, 1200×760 wide, and 380×520 popover. Launch contract:
`--tr-scenario`, `--tr-appearance dark`, `--tr-window`, `--tr-reduce`, and
`--tr-backdrop`; `--tr-increase-contrast` is the deterministic contrast lane.

Build and test:

```sh
rtk mise run desktop-prototype-build
rtk swift test --package-path native/Design/Prototypes/UnifiedAgentUsage
```

## Automated contract

- dark-only parsing and exact window bounds;
- default/F02 equivalence and unknown-fixture rejection seam;
- account-only multi-account navigation and direct single-account navigation;
- keyboard destination order and valid selection persistence;
- explicit unavailable/stale quota truth;
- semantic quota category order with stable order inside a category;
- reduction flag parsing.

## Human signoff matrix

No row below is inferred from builds, screenshots, or agent review.

| Matrix | Status |
|---|---|
| F00–F29 at 800×520, 1000×680, and 1200×760 | pending |
| Popover-bearing fixtures at 380×520 | pending |
| Sidebar expanded/collapsed, provider/account selection, meters | pending |
| Hover, keyboard focus, VoiceOver, Voice Control, Full Keyboard Access | pending |
| Reduce Motion and Reduce Transparency using real system settings | pending |
| Increase Contrast and Differentiate Without Color using real system settings | pending |
| Active/inactive window, resize/full screen, scale and color profiles | pending |
| Secondary-display and rightmost-menu-bar popover anchoring | pending |
| Digital-rain worst-frame motion review | pending |

Blessed: _pending human operator_

Production adaptation follows [PRODUCTION_MAPPING.md](PRODUCTION_MAPPING.md).
Prototype harness/store/fixtures are never production source.
