# Plan 001: Status left-click focuses that provider in the glance popover

> **Executor instructions**: Follow step by step. Run every verification before the next step. If a STOP condition hits, stop and report — do not improvise. Update status in `advisor-plans/README.md` when done.
>
> **Drift check (run first)**:
> `git diff --stat 1531495c..HEAD -- native/Sources/JackinDesktop/DesktopAppDelegate.swift native/Sources/JackinDesktop/PopoverRoot.swift native/Sources/JackinUsageBridge/PresentationStore.swift`
> If those files diverged, re-read live code before applying steps.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `1531495c`, 2026-08-10

## Why this matters

HTML SoT (`plans/previews/desktop-ui/index.html`) loads  
`popover.html?embed=1&mode=providers&provider=…` on status left-click.  
Native today only **toggles** the popover and does **not** set `store.popoverSelection` to the surface id of the clicked `NSStatusItem`, so operators often land on Overview or a stale tab — wrong IA and wrong glance account.

## Current state

- `StatusBarController` (in `DesktopAppDelegate.swift`) owns `providerItems: [String: NSStatusItem]` keyed by `surfaceId`.
- `handleClick` → `togglePopover(sender)` with no surface id resolution.
- `PopoverRoot` shows `PopoverProviderTab` when `store.popoverSelection` matches a glance row; else Overview.

Excerpt pattern today (`DesktopAppDelegate.swift` ~157–181):

```swift
@objc private func handleClick(_ sender: NSStatusBarButton) {
    if NSApp.currentEvent?.type == .rightMouseUp { /* menu */ return }
    togglePopover(sender)
}
private func togglePopover(_ sender: NSStatusBarButton) {
    // show/hide only — no store.popoverSelection = surfaceId
    popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
}
```

Conventions: MainActor UI; store mutations only through `PresentationStore`; no invented strings.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Structural SoT | `python3 plans/previews/desktop-ui/check_usage_liquid_glass.py` | `PASS: …` |
| Search | `rg -n "popoverSelection" native/Sources` | shows store field + PopoverRoot |
| Diff scope | `git status` / `git diff --stat` | only in-scope files |

## Scope

**In scope:**
- `native/Sources/JackinDesktop/DesktopAppDelegate.swift` (`StatusBarController` only for this plan)
- Optional tiny helper in same file if needed to map button → surfaceId
- Test: `native/Tests/…` **or** a pure function unit if you extract mapping — prefer architecture-style string assertion only if no XCTest harness for AppKit clicks

**Out of scope:**
- Popover visual redesign (plan 002)
- Usage window
- Changing `StatusItemRendering` dual-stack layout
- `AppMainMenu` / activation policy

## Git workflow

- Branch: stay on `plan/desktop-visual` (or operator’s active feature branch).
- Commit: `fix(desktop): focus popover on status-item provider` with `git commit -s`
- Push immediately after commit.

## Steps

### Step 1: Map status button → surfaceId

In `StatusBarController`, when handling left-click:

1. Resolve `surfaceId` by finding which `providerItems[id]?.button === sender` (identity compare).
2. If found: `store.popoverSelection = surfaceId` **before** showing the popover.
3. If fallback item (no provider): `store.popoverSelection = nil` (Overview).
4. Keep right-click path unchanged (context menu only).

Target shape:

```swift
private func surfaceId(for button: NSStatusBarButton) -> String? {
    for (id, item) in providerItems where item.button === button {
        return id
    }
    return nil
}

// in left-click path before show:
store.popoverSelection = surfaceId(for: sender)
// fallback item → nil
```

**Verify**: `rg -n "popoverSelection\\s*=" native/Sources/JackinDesktop/DesktopAppDelegate.swift` shows assignment from click path.

### Step 2: Toggle semantics

When closing popover (same button), clear selection only if product wants Overview next time — **prefer keep last selection** so re-open shows same provider (matches re-click UX). Do **not** force nil on close.

When opening a **different** status item while open: set new `popoverSelection` and re-anchor (already closes/reopens).

**Verify**: code review path for “same button closes” still works; no crash if `providerItems` empty.

### Step 3: Commit

```sh
git add native/Sources/JackinDesktop/DesktopAppDelegate.swift
git commit -s -m "fix(desktop): focus popover on clicked status provider"
git push
```

**Verify**: `git log -1 --oneline` shows the commit; remote tracking updated.

## Test plan

- Manual (required if no AppKit test): with ≥2 providers, left-click Anthropic item → popover tab/body is Anthropic; left-click OpenAI → OpenAI.
- If adding a pure helper `surfaceId(for:)` extracted for testability, unit-test mapping with fake dictionary — optional.

## Done criteria

- [ ] Left-click on provider status item sets `store.popoverSelection` to that `surfaceId` before show
- [ ] Fallback item opens Overview (`nil` selection)
- [ ] Right-click menu still works (Open Usage / Refresh / Quit)
- [ ] No files outside scope modified
- [ ] `check_usage_liquid_glass.py` still PASS
- [ ] README row 001 → DONE

## STOP conditions

- `popoverSelection` is not a published store field or is renamed — re-read `PresentationStore` and adapt.
- Click sender is not the `NSStatusBarButton` on the item (AppKit event change) — stop and report.
- Fix requires changing PopoverRoot data model — defer to plan 002, only set selection here.

## Maintenance notes

- Any new multi-status-item UI must keep button→id map (do not rely on title string matching).
- Reviewer: confirm no activation policy change in this commit.
