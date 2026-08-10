# Plan 003: Usage account nest meters + Overview per-account inventory

> **Drift check**:  
> `git diff --stat 1531495c..HEAD -- native/Sources/JackinDesktop/UsageWindow native/Sources/JackinUsageBridge/UsageWindowModel.swift native/Sources/JackinUsageBridge/PresentationStore.swift`

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: none (can parallel 001)
- **Category**: direction / tech-debt
- **Planned at**: commit `1531495c`, 2026-08-10

## Why this matters

HTML Usage SoT nests accounts under the selected provider with **glance % + mini meter**, multi-account radio well, and Overview as **one row per account**. Native Usage sidebar has nest + % text only (no meter) and Overview is still **per-provider** glance cards — wrong information architecture for multi-account operators.

## Current state

**SoT:** `plans/previews/desktop-ui/index.html` (Usage section) + FB1-48/66 + DATA_CONTRACT multi-account.

**Native:**
- `UsageWindowRoot.providerSidebarRow` — name + “N accounts” only (good: no provider meter)
- `accountSidebarRow` — radio multi, plan, **% only** — missing mini meter
- `OverviewListView` — `ForEach(model.sidebar)` provider cards with `barLabel` (provider-centric)

**Data:**
- `AccountRow.remainingPercent: UInt8?` from `list_accounts`
- Glance rows remain selected-account-aware for bar

## Commands

| Purpose | Command | Expected |
|---------|---------|----------|
| SoT | `python3 plans/previews/desktop-ui/check_usage_liquid_glass.py` | PASS |
| Model tests | run `UsageWindowModelTests` if XCTest available | pass |

## Scope

**In scope:**
- `native/Sources/JackinDesktop/UsageWindow/UsageWindowRoot.swift`
- `native/Sources/JackinDesktop/UsageWindow/OverviewListView.swift`
- Possibly `UsageWindowModel.swift` if Overview needs a pure projection of accounts × glance (prefer pure function in bridge)
- Tests under `native/Tests/JackinUsageBridgeTests/` for any pure model helper

**Out of scope:**
- Popover (plan 002)
- ProviderUsageLinks URLs
- Changing list_accounts Rust API (use existing fields only)
- Re-adding detail account chip strip

## Git workflow

- Active branch; `feat(desktop): …` / `fix(desktop): …` + `-s` + push

## Steps

### Step 1: Account nest mini meter

In `accountSidebarRow` (and fallback row), keep trailing % and add a **3pt-tall** capsule meter width = `remainingPercent/100` of fixed ~32pt track.

Rules:
- `nil` remaining → no meter (or empty track only if SoT shows dash — prefer hide meter)
- `0` → **empty fill** (no min sliver)
- Color: secondary/primary opacity or existing `severityTint` **only if** severity is Rust-owned for that row — AccountRow has `statusWord` not severity; **do not invent severity bands from % in Swift**. Use neutral fill (accent at low opacity or primary.opacity) for the bar.

Match HTML class roles: trail column with pct + meter.

**Verify**: `rg -n "remainingPercent" native/Sources/JackinDesktop/UsageWindow/UsageWindowRoot.swift` used for both Text and frame width; no `max(3,` width.

### Step 2: Multi-account inset well (visual)

Optional polish: wrap nested accounts in a subtle inset background (content layer, not glass) when multi, matching HTML `.acct-rail`. Single-account: no radio, still show progress.

**Verify**: no `glassEffect` in UsageWindowRoot; selection still radio for multi only.

### Step 3: Overview = per-account inventory

Change Overview content to list **accounts** (or account-aware rows), not one card per provider only:

Preferred data approach:
1. Build rows from `store.accounts` joined with provider `displayLabel` from glance/surfaces.
2. Each row shows: `Provider · accountLabel`, glance % (`remainingPercent` or matching glance), reset if available without inventing.
3. Tap → `selectUsageSurface(surfaceId)` + `setSelectedAccount` if multi.

If `accounts` empty but glance rows exist, fall back to current glance list (credential edge case).

**Verify**: Overview no longer the only path that shows provider `barLabel` without account identity when multi-account data exists.

### Step 4: Empty state

Keep `UsageWindowModel.emptyHint` (`"no agent credentials found"`) when no glance rows.

**Verify**: empty string unchanged (ArchitectureTests may assert it).

## Test plan

- `UsageWindowModelTests`: if you add pure `OverviewInventoryRow` builder, unit-test multi-account expansion order stable.
- Manual: OpenAI two accounts — Overview shows two OpenAI lines; select provider shows both under nest with meters.

## Done criteria

- [ ] Account nest shows % + 1:1 meter; 0% empty
- [ ] Multi radio / single quiet behavior preserved
- [ ] Overview lists per-account when accounts available
- [ ] No provider-row glance meter reintroduced
- [ ] No detail chip strip reintroduced
- [ ] `check_usage_liquid_glass.py` PASS
- [ ] README 003 → DONE

## STOP conditions

- `list_accounts` does not populate `remainingPercent` in production — report; show % only when non-nil, do not fake.
- Overview requires new UniFFI endpoint — stop; fall back to glance rows and document.

## Maintenance notes

- Bar remains selected-account-aware; Overview is inventory of all accounts — do not force bar to “worst of all” without Rust.
