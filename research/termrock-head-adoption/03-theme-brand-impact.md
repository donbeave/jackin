# 03 — Theme swap impact on brand compositions

Vetted: 2026-08-19

Questions: Does the bump alone shift brand-composition rendering? Which theme values change; what do brand comps consume; do text snapshots pin styling?
Informs: termrock-migration
Method: codebase read — termrock (https://github.com/tailrocks/termrock, HEAD `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`; old rev `5ff94ee117fd4a1b72fdd0d1b1847815055a93ac` read via `git show`, no checkout), jackin @ working tree (main, clean; pins termrock `rev = "5ff94ee117fd4a1b72fdd0d1b1847815055a93ac"` at `/Users/donbeave/Projects/jackin-project/jackin/Cargo.toml:118`).

All quoted file content below is data read from the two repositories; no embedded instructions were found in any file read for this chapter. No secrets encountered.

## Findings

### Precondition: "jackin code untouched" cannot compile at HEAD — HIGH

- Old rev exports `pub struct Theme` with `Theme::default() == Theme::tailrocks_phosphor()` (`git show 5ff94ee…:crates/termrock/src/style/mod.rs`, lines 250-252, 400-404).
- HEAD deletes `Theme` entirely; the palette type is `pub struct RolePalette` (`/Users/donbeave/Projects/tailrocks/termrock/crates/termrock/src/style/mod.rs:355`) with `Default` = `tailrocks_phosphor()` (`style/mod.rs:839-842`). A guard test enforces the deletion: `lib.rs:117-129` (`dual_paint_types_are_gone`: "Theme must be RolePalette (Break B)"). A repo-wide grep for `pub type Theme` / `pub use … Theme` finds no alias.
- jackin calls `termrock::Theme::default()` widely — 351 matching lines (counted with `rg -n 'Theme::default' crates | wc -l`, 2026-08-19); e.g. `crates/jackin-capsule/src/tui/view.rs:112`, `crates/jackin-console/src/tui/components/brand_header.rs:30`. Therefore the bump alone is a compile break; the color analysis below assumes the minimal mechanical rename `Theme` → `RolePalette` (both defaults resolve to `tailrocks_phosphor()`), which is the closest realizable form of "code untouched".

### Theme value delta 5ff94ee → HEAD (default `tailrocks_phosphor`) — HIGH

Method: old values from `git show 5ff94ee…:crates/termrock/src/style/mod.rs` (theme body lines 257-300) + `git show 5ff94ee…:crates/termrock/src/style/palette.rs` (RGB constants); new values from `/Users/donbeave/Projects/tailrocks/termrock/crates/termrock/src/style/mod.rs:362-436` + `crates/termrock/src/style/palette.rs:68-107` at HEAD. Old theme = 38 roles; HEAD = 63 roles (`ROLE_COUNT`, `style/mod.rs:251`). Of the 38 old roles: **2 removed, 7 value-identical, 29 changed.**

Removed roles: `TabUnderlineFocused` (was fg 0,255,65) and `TabUnderlineUnfocused` (was fg 255,255,255) — absent from the HEAD `Role` enum (`style/mod.rs:120-248`).

Unchanged roles (same resolved style both revisions): `BorderFocused` (fg 0,255,65), `Selection` (bg 0,255,65 / fg ANSI Black), `Accent` (fg 0,255,65), `Warning` (fg 255,216,94), `Danger` (fg 255,94,122 bold), `Info` (fg 0,180,180), `DiffRemoved` (fg 255,94,122 / bg 60,20,20).

Changed roles (old → new, RGB):

| Role | 5ff94ee | HEAD e1d61f4d |
|---|---|---|
| Canvas | (empty) | bg 10,12,10 |
| Surface | (empty) | bg 18,22,18 |
| Elevated | (empty) | bg 30,38,32 |
| Backdrop | (empty) | fg 58,68,58 |
| Text | fg 255,255,255 | fg 214,224,214 |
| TextStrong | fg 255,255,255 bold | fg 240,245,240 bold |
| TextMuted | fg 0,140,30 (phosphor dim green) | fg 122,138,122 (gray-green) |
| TextDisabled | fg 80,80,80 | fg 82,96,82 |
| Border | fg 80,80,80 | fg 48,58,50 |
| Focus | fg 0,255,65 | fg 51,255,106 |
| Success | fg 0,255,65 | fg 93,255,160 |
| Link | fg 0,200,200 | fg 94,200,255 |
| LinkHover | fg 130,240,240 | fg 143,216,255 |
| Input | bg 20,24,22 | bg 13,16,13 |
| InputInvalid | bg 20,24,22 / fg 255,94,122 | bg 13,16,13 / fg 255,94,122 |
| ScrollTrack | fg 0,80,18 (dark phosphor green) | fg 22,27,22 (near-black gray) |
| ScrollThumb | fg 0,255,65 | fg 48,58,50 |
| TabActive | fg 255,255,255 / bg 42,42,42 | fg 240,245,240 bold / **no bg** |
| TabInactive | fg 255,255,255 / bg 30,30,30 | fg 122,138,122 / **no bg** |
| TabActiveHovered | fg 255,255,255 / bg 58,58,58 | fg 240,245,240 bold / bg 26,34,28 |
| TabInactiveHovered | fg 255,255,255 / bg 48,48,48 | fg 122,138,122 / bg 26,34,28 |
| HintKey | fg 255,255,255 bold | fg 240,245,240 bold |
| HintText | fg 0,255,65 | fg 122,138,122 |
| HintDim | fg 0,140,30 | fg 82,96,82 |
| HintSeparator | fg 80,80,80 | fg 48,58,50 |
| ActionFocused | REVERSED modifier only | fg ANSI Black / bg 0,255,65 bold |
| ActionDisabled | DIM modifier only | fg 82,96,82 |
| StatusBar | (empty) | fg 214,224,214 / bg 18,22,18 |
| DiffAdded | fg 0,255,65 / bg 20,50,20 | fg 93,255,160 / bg 20,50,20 |

Related fact: HEAD adds `RolePalette::terminal_native()` (`style/mod.rs:443-456`), which starts from `tailrocks_phosphor()` and clears Canvas/Surface/Raised/Elevated/Sunken backgrounds and sets StatusBar to fg 255,255,255 — it restores the old background-free surface behavior but not the old text/hint/tab/scroll values.

### Brand composition color sources — HIGH

**1. BrandHeader (console manager)** — `crates/jackin-console/src/tui/components/brand_header.rs:22-48`. Mixed sources:
- Pill bg: `jackin_tui::tokens::BRAND_BLOCK` (line 24) — fixed. `jackin-tui` derives it from `jackin_brand::BRAND_BLOCK` = 0,255,65 (`crates/jackin-tui/src/tokens.rs:26`, `crates/jackin-brand/src/lib.rs:57`). Immune.
- " jackin" word fg: `jackin_tui::tokens::INK` = `Color::Black` (`brand_header.rs:27`, `tokens.rs:50`). Immune.
- "❯" chevron fg: `Theme::default().style(Role::Text).fg` (`brand_header.rs:30-33`) — **shifts 255,255,255 → 214,224,214**.
- " · " separator fg: `Role::ScrollTrack` fg (`brand_header.rs:38-41`) — **shifts 0,80,18 (dark green) → 22,27,22 (near-black gray)**; the phosphor-green tint disappears.
- Label: full `Role::TextMuted` style (`brand_header.rs:43-46`) — **shifts 0,140,30 (green) → 122,138,122 (gray-green)**.

**2. Launch cockpit header** — `crates/jackin-launch/src/tui/components/header.rs:15-41` is a duplicate of the same `brand_header_line` (same three role-dependent spans at lines 23-26, 31-34, 38) — same three shifts. The animated "Loading <role> in <path>" ripple uses hard-coded `Color::Rgb` lerps (green 0,140,30→120,255,120 band; white 170→255) at `header.rs:106-117` — immune. The "Preparing launch..." fallback uses `Role::Text` fg (`header.rs:67-70`) — **shifts white → 214,224,214**.

**3. Digital rain (launch cockpit)** — `crates/jackin-launch/src/tui/components/rain.rs`. `age_to_color` (lines 75-85) maps ages to `jackin_brand::{RAIN_HEAD, RAIN_FRESH, RAIN_BODY, RAIN_MID, RAIN_DIM, RAIN_DARK}`; `render_rain` paints those RGBs through a per-channel `dim()` transform (`Color::Rgb(dim(r), dim(g), dim(b))`, lines 222-233) — still fully derived from the fixed constants, no theme input. `jackin-brand` is a T0 crate with no termrock dependency and hard-coded constants (`crates/jackin-brand/src/lib.rs:35-55`, `crates/jackin-brand/Cargo.toml` deps = owo-colors only). **Immune.**

**4. Launch/warp intro-outro animation** — `crates/jackin-launch/src/tui/run.rs` consumers aside, the animation module `crates/jackin-launch/src/animation.rs:16-21` imports only `jackin_brand::{BRAND_BLOCK, RAIN_*, Rgb, WHITE}` and renders via owo-colors; its rain ramp (`animation.rs:154-165`) and phrase colors use those constants. CLI-side rain in `crates/jackin/src/brand_output.rs:221-229` likewise uses `jackin_brand::RAIN_*`. **Immune.**

**5. Brand-adjacent chrome: capsule status bar row 0** — `crates/jackin-capsule/src/tui/components/chrome.rs`:
- Brand pill (lines 144-158): bg `jackin_tui::tokens::BRAND_BLOCK` (fixed), " jackin" fg `Color::Black` (fixed), "❯" fg `Role::Text` — **chevron shifts white → 214,224,214**; pill block itself immune.
- Tab cells (lines 61-89): fg `Role::Text` (**shifts**); bg from `Role::TabActive/TabInactive/…` via `.bg.unwrap_or_default()` — at HEAD non-hovered tab roles carry **no bg**, so `unwrap_or_default()` yields `Color::Reset`: the gray tab fills (42,42,42 / 30,30,30) **disappear**, hovered fills become 26,34,28.
- Idle-tab glyph fg `Role::Accent` (lines 115-123) — unchanged (0,255,65).
- Active-tab underline (lines 216-226): `Role::Accent` when focused (unchanged), `Role::Text` when unfocused (**shifts**).
- Menu button (lines 166-194): bgs from `jackin_brand` MENU_* constants (immune); Idle-mode fg `Role::Text` (**shifts**).
- Launch cockpit footer status bar (`crates/jackin-launch/src/tui/components/footer.rs:190-198`): white bar bg built from `Role::Text` fg — **shifts pure white → 214,224,214**.

Summary: rendering shifts on bump (after the forced mechanical rename) for **BrandHeader (console), launch cockpit header, and the capsule status-bar row 0 chrome** — driver roles: `Text` (255,255,255→214,224,214), `ScrollTrack` (0,80,18→22,27,22), `TextMuted` (0,140,30→122,138,122), `TabActive/TabInactive` bg (fill → none). **Immune**: digital rain, warp intro/outro animation, CLI brand rain, the brand pill block/word itself, and menu-button backgrounds — all sourced from the termrock-free `jackin-brand` T0 crate or literal `Color` values. The old default → new default is **not** value-identical for the roles the brand headers consume; only the `Accent`-based elements (0,255,65) survive unchanged.

### Snapshot styling encoding — HIGH

18 `.snap` files exist (`find crates -name '*.snap' | wc -l` = 18) across the three listed directories. All are insta **plain-text** snapshots; none encode style, color, or ANSI:

- Console (6 files, `crates/jackin-console/src/tui/view/snapshots/`): built by `render_manager_state` joining `buf[(x, y)].symbol()` per cell — glyphs only (`crates/jackin-console/src/tui/view/tests.rs:579-595`). The `list_empty_80x24` snapshot's first row is the BrandHeader text (` jackin❯  · workspaces`) — glyphs pinned, colors not.
- Capsule usage-dialog (10 files, `crates/jackin-capsule/src/tui/components/dialog/snapshots/`): `render_usage_dialog_snapshot_for_view` joins `buf[(x, y)]` symbols the same way (`crates/jackin-capsule/src/tui/components/dialog/tests.rs:1320-1350`).
- Capsule branch-context-bar (2 files, `.../branch_context_bar/snapshots/`): row text from `buf[(x, 23)].symbol()` (`crates/jackin-capsule/src/tui/components/branch_context_bar/tests.rs:47`); snapshot header `expression: text`, single text line verified by reading the `.snap` file.

So the bump's color changes cannot fail any of the 18 snapshots. Colors are asserted only in non-snapshot unit tests that compare cell fg against the same `Theme::default()` lookup at runtime (e.g. `crates/jackin-console/src/tui/view/tests.rs:665-667`), which track the palette rather than pin old values.

## Dead ends and contradictions

- Searched HEAD termrock for a `Theme` compatibility alias (`pub type Theme`, `pub use … as Theme`): none exists; the only match is the guard test asserting its absence (`crates/termrock/src/lib.rs:123`). Consistent with the repo's stated latest-only policy — no contradiction found.
- `crates/jackin-launch/src/tui/components/header.rs` comment (line 46-48) claims the pill styling "stays in sync with the console manager … without a separate code path", but the file carries a textually identical copy of `brand_header_line`'s body (verified by side-by-side read), not a shared import — the sync claim is aspirational, though both copies shift identically here.

## Open unknowns

- Whether any jackin surface will adopt HEAD's `RolePalette::terminal_native()` (which restores background-free surfaces but keeps the new text/hint values) is a migration decision outside this chapter's scope.
- The visual delta above is computed from source values, not from a rendered side-by-side capture; a lookbook/screenshot comparison after the mechanical rename would confirm perceived severity (LOW effort, not performed — jackin does not currently compile against HEAD).
- `git show 5ff94ee…` reads assume jackin's lockfile matches the Cargo.toml rev pin; `Cargo.toml:118` pins `rev = 5ff94ee…` explicitly, so drift is unlikely but the lockfile hash was not cross-checked.
