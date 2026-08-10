# Plan 002: Popover craft + data path matches popover.html / Rust presentation

> **Executor instructions**: Self-contained plan. Drift-check first. STOP rather than invent %.
>
> **Drift check**:  
> `git diff --stat 1531495c..HEAD -- native/Sources/JackinDesktop/Popover native/Sources/JackinDesktop/PopoverRoot.swift native/Sources/JackinDesktop/GlassFallbacks.swift native/Sources/JackinDesktop/GlassPopoverHostingController.swift`

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: `001-status-left-click-focuses-provider.md`
- **Category**: tech-debt / correctness
- **Planned at**: commit `1531495c`, 2026-08-10

## Why this matters

Glance popover is the primary status interaction. HTML `popover.html` is craft SoT (FB1-41: never mini-pop). Native `PopoverProviderTab` still renders a **generic** list of `surface.buckets` segments with solid-tint account chips, fixed width 340, and no official “Open usage page”. That diverges from SoT hierarchy, multi-account chrome, and Codex Limit Reset detail.

## Current state

**SoT:** `plans/previews/desktop-ui/popover.html`  
- Sticky chrome + Overview/Providers strip  
- Left H-scroll accounts (secondary system)  
- Full bucket heroes + pace/reset  
- Glass footer dock Refresh  
- Soft scroll edges  

**Native:**
- `PopoverRoot.swift` — glass panel, SoftScrollEdges, footer, width **340**, maxHeight 480  
- `PopoverTabGrid` — Overview + providers with mini meters from `glanceRemainingPercent`  
- `PopoverProviderTab` — uses `surface.buckets` + `displaySegments`; account chips `Capsule().fill(accent)`; header opens Usage  
- `GlassPopoverHostingController` — clear host (good)  
- `PopoverFooter` — glass island Refresh (good)

**Data available but underused on popover:**
- `SurfaceRow.detailPresentation: UsageDetailPresentation` — Usage window already renders this; popover does not.

## Commands

| Purpose | Command | Expected |
|---------|---------|----------|
| SoT check | `python3 plans/previews/desktop-ui/check_usage_liquid_glass.py` | PASS |
| Grep glass gate | `rg -n "glassEffect|#available\\(macOS 26" native/Sources/JackinDesktop --glob '!**/GlassFallbacks.swift'` | no matches outside GlassFallbacks |
| Architecture | run `DesktopArchitectureLint` / XCTest if available | pass |

## Scope

**In scope:**
- `native/Sources/JackinDesktop/PopoverRoot.swift`
- `native/Sources/JackinDesktop/Popover/PopoverProviderTab.swift`
- `native/Sources/JackinDesktop/Popover/PopoverOverviewTab.swift` (only if needed for IA)
- `native/Sources/JackinDesktop/Popover/PopoverTabGrid.swift` (selection chrome polish only)
- `native/Sources/JackinDesktop/Popover/PopoverFooter.swift` (only if Open Usage CTA shared — prefer keep single Refresh; Open usage goes on provider body)
- Possibly reuse helpers from `UsageWindow/ProviderCardView.swift` (extract shared bucket row view **only if** DRY without cross-layer mess — prefer private duplication first if extraction is large)

**Out of scope:**
- Status dual-stack rendering
- Usage sidebar nest (plan 003)
- Changing Rust UniFFI schemas
- GlassFallbacks API redesign (extend only if missing a needed chrome helper)

## Git workflow

- Branch: active feature branch (`plan/desktop-visual`)
- Commits: `feat(desktop): …` / `fix(desktop): …` with `-s`, push each logical commit

## Steps

### Step 1: Size + shell parity baseline

- Set popover content width toward SoT (~**400–424** pt), keep max height reasonable for screen.
- Confirm clear host still applied after show (already in `togglePopover`).
- Confirm soft scroll + glass footer remain.

**Verify**: width constant ≥ 400 in `PopoverRoot`; no new `glassEffect` outside `GlassFallbacks`.

### Step 2: Account switcher = secondary system

Replace solid accent-filled capsules with SoT secondary pattern:
- Multi-account only (`accounts.count > 1`)
- Left-aligned strip
- Selected = phosphor **tint** stroke/fill low opacity (like Usage chips / FB1-48), not solid green slab / white text
- Show optional `remainingPercent` from `AccountRow` as mono trailing % (Rust only)

**Verify**: no `Color.accentColor.opacity(0.90)` solid fill selection in `PopoverProviderTab`.

### Step 3: Bucket list from presentation model

Prefer one of these (pick A if possible):

**A (preferred):** Render `surface.detailPresentation.rows` for buckets (`kind == .bucket`) and minimal meta needed for glance (status/updated/error), reusing layout_lines leading/trailing rules from `ProviderCardView` (reset trailing).

**B (fallback):** Keep `surface.buckets` but:
- Use `meterPercent` 1:1 with **0 = empty** (no min width hack)
- Split segments so reset labels can be secondary
- Special-case label `"Limit Reset Credits"` with Available / Next expires layout (mirror `ProviderCardView.limitResetCreditsCard`)

Do **not** invent segment text.

**Verify**: `rg -n "surface\\.buckets" native/Sources/JackinDesktop/Popover` — either gone (A) or only with documented fallback (B). Meter path has no `max(3,`.

### Step 4: Open usage page control

Add a content-layer control (not glass slab) that opens `ProviderUsageLinks.usagePageURL(surfaceId:)` via `NSWorkspace.shared.open`, same copy as Usage: `ProviderUsageLinks.openUsagePageTitle`.

**Verify**: `rg -n "ProviderUsageLinks" native/Sources/JackinDesktop/Popover` hits; all seven surface ids covered by existing map (do not invent URLs — edit `ProviderUsageLinks` + `OFFICIAL_USAGE_URLS.md` together only if a URL is wrong).

### Step 5: Header → Open Usage Window

Keep header/detail affordance that calls `onOpenUsageWindow(surfaceId)` (opens full Usage window). Do not remove it when adding browser “Open usage page”.

**Verify**: both paths exist: browser URL + in-app Usage window.

### Step 6: Visual pass vs popover.html

Manual checklist (operator or screenshot):
- [ ] Light + dark
- [ ] Glass shell translucent on desktop
- [ ] Overview tab + provider tabs
- [ ] Multi-account OpenAI fixture if available
- [ ] Refresh footer glass

**Verify**: document checklist in commit body; no limits-only violations (`$/token`, spend charts).

## Test plan

- Extend `ArchitectureTests` or Parity harness:
  - PopoverProviderTab must not contain banned invent-string tokens
  - Prefer assert `detailPresentation` consumption if path A
- `StatusItemChipHarness` unchanged

## Done criteria

- [ ] Popover width aligns with SoT (~400+)
- [ ] Account multi-select chrome is secondary (not solid primary slab)
- [ ] Buckets render Rust presentation segments/meters 1:1; 0% empty
- [ ] Limit Reset Credits structured when present
- [ ] Open usage page works per surface_id map
- [ ] `glassEffect` only in GlassFallbacks
- [ ] `check_usage_liquid_glass.py` PASS
- [ ] README 002 → DONE

## STOP conditions

- `detailPresentation` empty while `buckets` full for live providers — report; use path B and file follow-up for bridge fill.
- UniFFI missing fields for layout_lines — stop; do not parse displayLabel in Swift beyond existing bridge types.
- Design asks for glass on bucket cards — refuse (LG-A2).

## Maintenance notes

- Keep popover and Usage detail rendering patterns aligned when either changes.
- Reviewer: watch for second glass stack inside content list.
