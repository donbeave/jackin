# Baseline Visual QA — Unified Agent Usage

Status: FAILED LEGACY BASELINE. This is evidence about the incumbent source, not
an approved visual baseline or evidence for the successor fixture tuples.

Run: 2026-08-20 against source commit `25844091bd70933df134d9daa5af68b600e3d925`.

## Environment and permissions

- macOS 26.5.2 (`25F84`), macOS SDK 26.5, Xcode 26.6 (`17F113`).
- Interactive graphical session: present.
- Display: built-in Liquid Retina XDR, 3456 × 2234 Retina, 2× backing scale.
- Screen Recording: held, proven by successful window-ID captures.
- Accessibility: held; System Events reported UI elements enabled.
- Automation for system-setting changes: held, proven by successful accessibility-setting captures and restore.
- XCTest UI automation: unavailable during this run; the runner failed before tests with `Timed out while enabling automation mode`.
- Original accessibility-display defaults were absent and were restored. A post-run read confirmed Increase Contrast, Reduce Transparency, Reduce Motion, and Differentiate Without Color were all absent.

## Build and launch proof

- `cargo xtask desktop build --version 0.6.0 --build 1`: passed.
- `cargo xtask desktop verify native/dist/JackinDesktop.app`: passed for the ad hoc development artifact.
- Every accepted image was captured from the running app by resolved window ID. No detached SwiftUI snapshot or rectangle capture is accepted as evidence.
- Accepted image and executable SHA-256 values are recorded in JSON sidecars under the ignored local evidence directory `native/.build/visual-qa/baseline/`.

## Accepted captures

| State | Fixture | Geometry | Result |
|---|---|---:|---|
| Usage window, light | Legacy F02 | 920 × 620 | Captured; readable but structurally noisy. |
| Usage window, dark | Legacy F02 | 920 × 620 | Captured; readable but structurally noisy. |
| Focused popover, dark | Legacy F03 | 406 × 546 frame | Captured; clear provider/account focus and quota hierarchy. |
| Usage window, dark, Reduce Transparency | Legacy F02 | 920 × 620 | Captured; system material became opaque and content remained stable. |
| Usage window, dark, Increase Contrast | Legacy F02 | 920 × 620 | Captured; hard failure due to collapsed table layout. |

Two later files with spaces in their names are excluded: their malformed launch arguments produced empty fixture identifiers, wrong 760 × 500 geometry, and identical image hashes. They are not evidence for F00 or F03.

The accepted files were generated from the legacy executable fixture catalog at
the named source commit. They establish incumbent structural failures only. The
prototype harness must bind `VisualQAFixtures.swift` to the canonical successor
records in `Fixtures.md` and recapture F02/F03 before any image can satisfy the
selected design's evidence matrix.

## Findings

### Hard failure — Increase Contrast destroys table relationships

At the same 920 × 620 geometry, provider group placeholders and account values concatenate across visual columns: `— — — —`, `Plus 0% —`, `Max 20× 12% —`, and `Default — 81% —`. The table no longer communicates which account, plan, remaining value, and reset belong together. This violates the required contrast, hierarchy, and non-overlap behavior and blocks release.

The enabling structural condition is visible in `OverviewListView`: Plan, Remaining, and Reset have width contracts, while Provider and Account do not, and provider group rows emit placeholders through every account-specific column. The selected prototype must prove a hierarchy that keeps provider labels out of account-only cells and preserves identity/state widths under Increased Contrast, long labels, and minimum geometry.

### Major — overview hierarchy carries avoidable placeholder noise

Default light and dark captures remain readable, but provider group rows fill account, plan, remaining, and reset columns with em dashes. Single-provider rows such as Amp also resemble data rows with missing fields. The repeated placeholders compete with canonical account rows and make scanning harder than the provider/account model requires.

### Major — account identity wraps before less important metadata contracts

The normal personal and secondary email labels wrap at 920 points while wide plan and reset columns remain reserved, including when reset data is absent. The selected design must protect provider/account identity and explicit state before secondary plan/reset metadata.

### Passed baseline observations

- The system sidebar, titlebar, traffic lights, split behavior, and native controls read as a macOS 26 application in light and dark appearances.
- The popover has a clear provider/account heading, ordered quota windows, explicit values and reset text, and stable footer actions.
- Reduce Transparency produced an opaque native result without layout drift.
- Quota values remained textual, not color-only; no token price, spend history, trend, or launch-blocking action appeared.

## Automated accessibility result

`performAccessibilityAudit` did not execute. The UI-test launch failed while enabling automation mode, before any test case ran. The ignored result bundle is `native/.build/visual-qa/baseline/accessibility.xcresult`. This is a recorded blocker, not a pass. The implementation plan must repair deterministic UI-test lifecycle and run audits for status item, popover, Usage overview/detail, Settings, every unavailable state, and Increased Contrast.

## Missing baseline states

The following remain required before final approval:

- F00, F01, and F04–F24 with valid fixture identity and requested geometry or
  task-completion evidence as defined by each fixture.
- Light/dark inactive window and key-window transitions.
- Reduce Motion and Differentiate Without Color captures.
- Full Keyboard Access and VoiceOver traversal, announcements, order, labels, values, and actions.
- Clear and tinted Liquid Glass appearance, accent colors, icon sizes, scrollbar policies, display scaling, external-display movement, varied wallpaper, and color profiles.
- Minimum 760 × 500 and wide 1200 × 760 evidence with long, right-to-left, CJK, German, and 40-account fixtures.
- Driven status-item-to-popover-to-Usage handoff and retained selection/window restoration.
- Signed, notarized, stapled, quarantined public artifact and Homebrew-installed artifact launch.

## Baseline verdict

FAIL. The incumbent native structure is a credible starting point, but the Increased Contrast table collapse is a hard failure and automated accessibility evidence is absent. No visual direction may be approved until a selected structural prototype removes the failure and passes the complete matrix.
