# Final A1 native evidence

Status: **provisional; regenerate from the final clean pushed branch head before acceptance**

The files here prove the real-host capture workflow and required state coverage, but current source corrections postdate their recorded source commit and application hash. They are not final branch-head evidence. The fail-closed capture matrix now refuses dirty desktop inputs, rebuilds the canonical application, verifies it, and records fresh provenance before these files may be accepted.

The host was macOS 26.5.2 (`25F84`) with Xcode 26.6 (`17F113`) and the macOS 26.5 SDK. All 36 PNGs came from the real `JackinDesktop.app`: Usage evidence resolves the real layer-0 `NSWindow`; popover evidence resolves the real layer-25 `NSPopover`. Each JSON sidecar records fixture, requested appearance and size, window identity, layer, geometry, active state, app path and hash, image hash, source commit, runtime, toolchain, SDK, timestamp, and accessibility-setting values.

## Principal review views

- [Light Usage](usage-light-active-F02.png)
- [Dark Usage](usage-dark-active-F02.png)
- [Light inactive Usage](usage-light-inactive-F02.png)
- [Dark inactive Usage](usage-dark-inactive-F02.png)
- [Sidebar collapsed](usage-light-collapsed-F02.png)
- [Minimum Usage](usage-light-min-F12.png)
- [Expanded Usage](usage-light-expanded-F12.png)
- [Light provider popover](popover-light-active-F02.png)
- [Dark provider popover](popover-dark-active-F02.png)
- [Maximum-content popover](popover-light-maximum-F12.png)

## Content-state coverage

| Fixture | Usage | Popover |
|---|---|---|
| F00 no providers | [capture](usage-light-empty-F00.png) | [capture](popover-light-empty-F00.png) |
| F01 single provider | [capture](usage-light-single-F01.png) | [capture](popover-light-single-F01.png) |
| F02 catalog normal | [capture](usage-light-active-F02.png) | [capture](popover-light-active-F02.png) |
| F03 multiple accounts | [capture](usage-light-multiaccount-F03.png) | [capture](popover-light-multiaccount-F03.png) |
| F04 nearly exhausted | [capture](usage-light-nearly-exhausted-F04.png) | [capture](popover-light-nearly-exhausted-F04.png) |
| F05 exhausted | [capture](usage-light-exhausted-F05.png) | [capture](popover-light-exhausted-F05.png) |
| F06 stale last-good | [capture](usage-light-stale-F06.png) | [capture](popover-light-stale-F06.png) |
| F07 refreshing | [capture](usage-light-refreshing-F07.png) | [capture](popover-light-refreshing-F07.png) |
| F08 partial failure | [capture](usage-light-partial-F08.png) | [capture](popover-light-partial-F08.png) |
| F09 permission denied | [capture](usage-light-permission-F09.png) | [capture](popover-light-permission-F09.png) |
| F10 offline cached | [capture](usage-light-offline-F10.png) | [capture](popover-light-offline-F10.png) |
| F11 long strings | [capture](usage-light-long-F11.png) | [capture](popover-light-long-F11.png) |
| F12 layout envelope | [minimum](usage-light-min-F12.png) / [expanded](usage-light-expanded-F12.png) | [capture](popover-light-maximum-F12.png) |
| F13 initial loading | [capture](usage-light-loading-F13.png) | [capture](popover-light-loading-F13.png) |
| F14 global bridge error | [capture](usage-light-error-F14.png) | [capture](popover-light-error-F14.png) |

F15 is intentionally not a visual fixture because the product has no destructive action. `VisualQAFixturesTests.testA1SourcesExposeNoDestructiveAction` scans every action-bearing A1 view for delete, revoke, reset-credit consumption, and sign-out controls.

The F08 OpenAI popover is intentionally byte-identical to F02: the partial failure belongs to Kimi and must not disturb a healthy provider's focused popover. The F08 Usage capture shows the Kimi-local error while preserving every healthy row.

## Interaction and accessibility proof

Real-host UI tests cover provider navigation, the fixed sidebar control and stable coordinates, native account picker behavior, distinct empty/loading/error states, real popover hosting, provider-context routing into Usage, retained-window continuity, minimum-size Usage scrolling, constrained popover scrolling, Command-R, Command-comma, Command-W, Control-Command-S, and accessibility audits for Overview, provider detail, and popover. [Native focus and dismissal evidence](focus-and-dismissal-log.md) separately proves keyboard reachability and Escape behavior with macOS Keyboard Navigation enabled. Pure model tests cover provider removal, account fallback, menu order, status-item focus, all F00–F14 fixtures, long labels, non-color status text, nonfocused accessible refresh progress, and absence of destructive controls.

Earlier real-host suites and all three accessibility audits passed against their recorded application sources. The final complete suite must pass again against the final pushed branch head with zero runtime warnings; earlier results cannot substitute.

## Host-setting restoration

[`settings-before.txt`](settings-before.txt) is the captured baseline. An initial outer-shell trap failed to restore Reduce Transparency; [`settings-after-failed-attempt.txt`](settings-after-failed-attempt.txt) detected the retained value immediately. Explicit restoration produced [`settings-after-recovery.txt`](settings-after-recovery.txt), byte-identical to the baseline. The repository-owned `state.sh with` wrapper was then exercised with a failing child command and produced [`settings-after-trap-test.txt`](settings-after-trap-test.txt), also byte-identical. [`settings-current.txt`](settings-current.txt) independently confirms no tested accessibility or appearance setting remains changed.

Reduce Transparency, Increase Contrast, Reduce Motion, and Differentiate Without Color have provisional real-host captures under [`accessibility/`](accessibility/) with byte-identical before/after setting receipts. [The historical blocker record](blocked-accessibility-captures.md) explains the earlier host failure. Clear/tinted Liquid Glass preference observations remain operator-owned. No placeholder or offscreen renderer is accepted as native material proof.
