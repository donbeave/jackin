# Plan 005: Activation, NSToolbar host, and harness guards

> **Drift check**:  
> `git diff --stat 1531495c..HEAD -- native/Sources/JackinDesktop/UsageWindowController.swift native/Sources/JackinDesktop/AppMainMenu.swift native/Sources/JackinDesktop/DesktopAppDelegate.swift native/Tools native/Tests`

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED (activation policy is finicky on macOS)
- **Depends on**: 001, 002 (behavior stable first)
- **Category**: tests / dx
- **Planned at**: commit `1531495c`, 2026-08-10

## Why this matters

SoT + FB1-65/66 require: accessory agent by default; **regular** when Usage/Settings visible; real **NSToolbar** via `NSHostingController`; main menu installed. Without harness guards, future agents reintroduce `NSHostingView`-only windows (toolbar dies) or break activation.

## Current state

- `JackinDesktopApp` / delegate: `.accessory` at launch
- `AppActivation.presentWindows()` / `resignToAccessoryIfNeeded()`
- `UsageWindowController`: hosting controller + `toolbarStyle = .unified`
- `AppMainMenu.install()` at launch
- Tools: ArchitectureLint, ParityMatrix, StatusItemChipHarness
- HTML: `check_usage_liquid_glass.py` for craft markers

## Scope

**In scope:**
- `UsageWindowController.swift`, `AppMainMenu.swift`, `DesktopAppDelegate.swift` (edge fixes only)
- `native/Tools/DesktopArchitectureLint` and/or `DesktopParityMatrixHarness` and/or XCTest architecture tests
- Optional: `plans/previews/desktop-ui/check_usage_liquid_glass.py` only if adding **native-path** checks is wrong place — prefer Swift harness for Swift facts

**Out of scope:**
- Redesigning main menu items
- HTML desktop scene redesign

## Steps

### Step 1: Activation edge cases

Verify/fix:
1. Open Usage → `.regular` + key window
2. Close Usage with no Settings → `.accessory`
3. Open Settings then Usage → stay regular until **both** closed
4. Dock reopen (`applicationShouldHandleReopen`) shows Usage

Watch for: closing sheet counting as titled window; status item windows.

**Verify**: manual script checklist in PR; code paths call `AppActivation` consistently (no bare `setActivationPolicy` outside `AppActivation` except launch).

**Code rule:** migrate any remaining direct `NSApp.setActivationPolicy` in desktop sources (except bootstrap) into `AppActivation` helpers.

### Step 2: NSToolbar host guard

Add architecture assertion:

- `UsageWindowController.swift` contains `NSHostingController` and `contentViewController`
- Does **not** assign `contentView = NSHostingView` for Usage root
- Contains `toolbarStyle = .unified`

**Verify**: harness/test fails if hosting controller removed.

### Step 3: Main menu guard

Assert `AppMainMenu` / `mainMenu.install` referenced from `DesktopAppDelegate` applicationDidFinishLaunching.

**Verify**: string presence check in ArchitectureTests or Parity harness.

### Step 4: Status interaction guards

Assert:
- Status items use `isTemplate = true` path (`StatusItemRendering`)
- Left-click sets `popoverSelection` (from plan 001)
- Context menu model still three rows (Open Usage, Refresh, Quit)

**Verify**: `StatusItemMenuModel.rows.count == 3` test already may exist — extend if needed.

### Step 5: Document run commands in native README (short)

Add “SoT parity checks” bullets pointing to advisor-plans + HTML checker — **only if** native README is the operator entry (keep short).

## Test plan

- ArchitectureTests / DesktopArchitectureLint new checks
- Manual activation sequence once on a Mac

## Done criteria

- [ ] Activation enter/exit regular documented and implemented without leaks to regular forever
- [ ] Harness prevents NSHostingView-only Usage window regression
- [ ] Status template + menu model guarded
- [ ] `check_usage_liquid_glass.py` PASS
- [ ] README 005 → DONE

## STOP conditions

- Activation thrashing (Dock flicker) — stop; research delay pattern (sleep before policy flip) and report rather than shipping flaky loops.
- Full Xcode unavailable — land source + pure string harnesses; mark manual UI verification BLOCKED for operator.

## Maintenance notes

- Reviewer: policy flips are the highest regression risk — test on Tahoe.
- HTML MACOS_CHROME_REFERENCES.md remains the interaction diagram; native must not draw fake system menu bars inside windows.
