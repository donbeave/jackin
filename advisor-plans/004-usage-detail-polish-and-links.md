# Plan 004: Usage detail polish — Limit Reset, Open usage, meta de-dupe

> **Drift check**:  
> `git diff --stat 1531495c..HEAD -- native/Sources/JackinDesktop/UsageWindow/ProviderCardView.swift native/Sources/JackinUsageBridge/ProviderUsageLinks.swift plans/previews/desktop-ui/OFFICIAL_USAGE_URLS.md`

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: `003-usage-account-nest-and-overview.md` (IA first)
- **Category**: tech-debt
- **Planned at**: commit `1531495c`, 2026-08-10

## Why this matters

Detail pane already has Open usage page + Limit Reset card + meta filter, but needs hardening so executors don’t regress: URL table completeness, Limit Reset labeling without inventing values, and mechanical `usage_detail_presentation` rendering.

## Current state

- `ProviderCardView` filters meta ids: focused/header/provider/account/username/plan
- Bucket cards use meter 1:1 with empty at 0
- `limitResetCreditsCard` labels Available / Next expires from layout lines
- `ProviderUsageLinks` maps seven surface_ids

## Scope

**In scope:**
- `ProviderCardView.swift`
- `ProviderUsageLinks.swift` + `OFFICIAL_USAGE_URLS.md` (keep in sync if URL fix needed)
- Architecture/parity tests asserting URL table keys match DESKTOP order

**Out of scope:**
- Sidebar nest (003)
- Popover (002)
- Rust reset_credits fetch logic

## Steps

### Step 1: Audit detailPresentation rendering

Confirm Usage path uses `content.detail.rows` only (no `surface.buckets` in ProviderCardView).

**Verify**: `rg -n "buckets" native/Sources/JackinDesktop/UsageWindow/ProviderCardView.swift` → no raw bucket list.

### Step 2: Limit Reset Credits

When `row.label == "Limit Reset Credits"`:
- Keep structured card
- Values only from `layoutLines` / `displayLabel` segments
- Do not add “Scope: Session + weekly” unless Rust emits it (HTML fixture may show extra — native must not invent)

**Verify**: no hard-coded “3 manual resets” strings in Swift.

### Step 3: Open usage page

- Button remains primary content control at top of detail
- Map completeness: codex, claude, amp, grok, zai, kimi, minimax
- Cross-check `OFFICIAL_USAGE_URLS.md` table

**Verify**: unit-level test or lint that each key has non-nil URL string.

### Step 4: Meta de-dupe

Keep filtering sidebar-duplicated meta. Ensure Auth (`credential_origin`) and Status/Updated still show.

**Verify**: Auth row still possible when Rust sends `auth` row_id.

## Test plan

- ArchitectureTests: `ProviderUsageLinks.usagePageString` non-nil for seven ids
- Optional: snapshot-free test that Limit Reset card uses displayLabel

## Done criteria

- [ ] Seven official URLs present and documented
- [ ] No invented Limit Reset copy in Swift
- [ ] Detail still mechanical presentation rows
- [ ] README 004 → DONE

## STOP conditions

- Official provider moved URL and unknown — update OFFICIAL_USAGE_URLS.md with evidence, do not guess.

## Maintenance notes

- URL rot is expected; treat OFFICIAL_USAGE_URLS.md as the evidence log.
