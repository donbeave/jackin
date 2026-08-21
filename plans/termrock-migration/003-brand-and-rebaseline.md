# Plan 003: Compensate the brand spans, land the operator's background pick, re-bless the TUI snapshots

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/termrock-migration/002-*.md (must be DONE)
- **Covers**: F3 (bump half), B3, B6, B9, D8, D10, D11, D13 — spec requirements
  "Brand spans render identically across the bump", "Capsule row-0 split
  honored", "Deliberate snapshot re-baseline", "Background variant decided
  from a side-by-side render"
- **Guardrails**: N1, N2 (inlined under "Must NOT")
- **Research basis**: research/termrock-head-adoption/03-theme-brand-impact.md,
  research/jackin-verification-tooling/01-gates-and-commands.md
- **Planned at**: commit `d554dca8`, 2026-08-19

## Why this matters

Plan 002 moved the TermRock pin to head `e1d61f4d`. The head's palette
recolors three roles the jackin❯ brand headers read (`Text`, `ScrollTrack`,
`TextMuted`), so the brand renders differently even though no brand code
changed. This plan pins those spans back to jackin❯-owned constants so the
brand looks identical across the bump, pauses for the operator to pick the
surface-background variant from a real side-by-side render, and then
re-baselines the TUI snapshots exactly once — after the pick — as the
deliberate acceptance of the upstream look. After this plan, the bump PR's
only remaining work is docs (plan 004), and the brand looks the same before
and after the bump while everything else adopts head's visuals.

## Preconditions — run before anything else

Run all of these from the repository root. Any failure is a STOP.

1. **On the execution branch** (the hub's branch law):
   `git branch --show-current` → `feature/termrock-head-bump`
2. **Plan 002 landed — pin flipped**:
   `grep -n 'termrock' Cargo.toml` → the `termrock = { … }` line pins
   `rev = "e1d61f4d67ea6f0f3adee578caa2c5dba642217e"`.
   (At planning time `Cargo.toml:118` still read
   `rev = "5ff94ee117fd4a1b72fdd0d1b1847815055a93ac"` — that is the pre-002
   state and means 002 is not done.)
3. **Plan 002 landed — workspace compiles at head**:
   `cargo check --workspace --all-targets --locked` → exit 0
4. **Plan 002 landed — the old type name is gone** (N2: no shims/aliases):
   `rg -n 'termrock::Theme|use termrock::Theme' crates | wc -l` → `0`
5. **Snapshot state is untouched by 002** — the re-baseline must not have
   happened yet:
   `git diff --name-only origin/main...HEAD -- '**/*.snap' | wc -l` → `0`.
   Any non-zero count means snapshots were re-blessed before the background
   pick → STOP (spec forbids re-baselining before the pick).
6. **Toolchain**: `cargo nextest --version` → `cargo-nextest 0.9.140`;
   `cargo insta --version` → **fails** with "no such command: `insta`" (this
   is expected — see "Commands you will need"; do NOT install it).
7. **Drift check against the planning snapshot** (this plan edits
   pre-existing code):
   `git diff --stat d554dca8..HEAD -- crates/jackin-console/src/tui/components/brand_header.rs crates/jackin-launch/src/tui/components/header.rs crates/jackin-launch/src/tui/components/progress_rail.rs crates/jackin-capsule/src/tui/components/chrome.rs crates/jackin-tui/src/tokens.rs`
   Changes here are **expected** (002 renamed the palette type). Open each
   file and compare against the "Starting state" excerpts below: the span
   *structure* (which role feeds which span) must still match. If a span's
   role source changed, or a span disappeared, that is a STOP.

## Spec contract

The requirements this plan implements, inlined **verbatim** from the spec —
the executor does not read `spec/`.

### Requirement: Brand spans render identically across the bump

The following spans SHALL render with byte-identical colors/attributes before and after the bump, via consumer-code compensation (pinning to jackin-brand constants or explicit styles — mechanism is plan/executor choice): the BrandHeader line in console (`crates/jackin-console/src/tui/components/brand_header.rs:22-48`: chevron was `Role::Text` white, separator was `Role::ScrollTrack` 0,80,18, label was `Role::TextMuted` 0,140,30) and its launch duplicate (`crates/jackin-launch/src/tui/components/header.rs:15-41`), the capsule brand pill's chevron (`crates/jackin-capsule/src/tui/components/chrome.rs:144-158`, was `Role::Text` white), and the launch progress rail's theme-fed spans whose roles changed value at head — the rail is brand (D11) and is `Theme::default()`-fed, not hard-coded (`crates/jackin-launch/src/tui/components/progress_rail.rs:43`; `Role::Text` arms at `:125,:145`, `Role::TextStrong` at `:235`, `Role::TextMuted` at `:247` all shift; its `Role::Danger`/`Role::Accent` spans are value-unchanged at head and stay untouched). Already-immune elements (pill block/word, digital rain, warp animation, CLI rain, menu backgrounds, the launch header ripple's hard-coded lerps at `header.rs:106-117`) SHALL NOT be touched.

#### Scenario: Compensated spans match pre-bump values

- **GIVEN** the pre-bump rendered colors of the four affected brand span groups (white 255,255,255 chevron; 0,80,18 separator; 0,140,30 label; the rail's Text/TextStrong/TextMuted spans at their pre-bump values)
- **WHEN** the compensated code renders after the bump
- **THEN** a color-asserting test (not a glyph-only snapshot) proves each span's fg/bg/attributes equal the pre-bump values

#### Scenario: Immune brand code untouched

- **WHEN** `git diff` of the bump PR is filtered to `crates/jackin-brand/`, rain, warp/animation, and CLI brand-output files
- **THEN** no changes exist beyond renamed upstream symbols forced by compilation (expected: none — these files are termrock-free)

### Requirement: Capsule row-0 split honored

Within capsule status-bar row 0, ONLY the brand pill (block + word + chevron) SHALL be compensated; tabs, underline, menu foreground, and tab fills SHALL adopt the upstream look (fills vanish for non-hovered tabs at head) without compensation.

#### Scenario: Row-0 product chrome follows the theme

- **WHEN** the capsule status bar renders after the bump
- **THEN** tab foregrounds/fills/underline/menu use the new theme values with no compensation code attached to them
- **AND** the pill's chevron matches its pre-bump white

### Requirement: Deliberate snapshot re-baseline

All 18 `.snap` fixtures (6 console `crates/jackin-console/src/tui/view/snapshots/`, 10 capsule dialog, 2 capsule branch-context-bar) SHALL be re-baselined exactly once for the bump, after the background variant lands, via the repo-documented `INSTA_UPDATE=new cargo nextest run …` re-bless per crate (`crates/jackin-console/src/tui/view/tests.rs:565-568`; cargo-insta is not installed and ad-hoc tool installs are forbidden) — never by hand-editing `.snap` files — and the diff SHALL be reviewed wholesale as the deliberate acceptance of upstream visuals under TESTING.md's snapshot gate.

#### Scenario: Snapshot suite green after re-bless

- **GIVEN** the bump and the chosen background variant applied
- **WHEN** the snapshot partition runs after the re-bless
- **THEN** it exits 0 with no pending snapshots

#### Scenario: No hand-edited snapshots

- **WHEN** the re-baseline commit is reviewed
- **THEN** every `.snap` change came from the insta workflow (no manual `.snap` edits; TESTING.md hand-edit policy holds)

### Requirement: Background variant decided from a side-by-side render

Before snapshot re-baselining, the bump PR SHALL produce a side-by-side render of the same screens under (a) the head default obsidian surface ladder (`RolePalette::tailrocks_phosphor()`) and (b) `RolePalette::terminal_native()`, present both to the operator, and STOP for the operator's pick; the chosen variant lands inside the bump PR before merge and the re-baseline reflects it.

#### Scenario: Operator pick gates the re-baseline

- **GIVEN** side-by-side renders of representative screens under both variants
- **WHEN** the executor reaches the re-baseline step without a recorded operator pick
- **THEN** the executor stops (by-design pause) and does not re-baseline

#### Scenario: Chosen variant is what ships

- **GIVEN** the operator picked a variant
- **WHEN** the bump PR is merge-ready
- **THEN** the palette construction in jackin❯ code matches the pick and the 18 snapshots were re-blessed after it landed

Done means these scenarios hold; the test plan below exercises them.

## Must NOT

Guardrails inlined verbatim from the must-not registry, with reasons. These
override anything a step seems to imply:

- **N1**: The migration MUST NOT move any brand composition (BrandHeader,
  digital rain, launch animation/warp, launch progress rail, capsule brand
  pill) into TermRock, and MUST NOT change their visual identity — upstream
  0331 declined absorption; item Decisions 2026-08-19 make ownership and
  look invariants.
- **N2**: The migration MUST NOT introduce compatibility facades, aliases,
  or shim layers over renamed TermRock APIs — repository latest-only law;
  upstream migration directive ("No deprecated aliases are provided. This is
  a hard break.", 0061).

Additional hard boundaries for this plan:

- **Never hand-edit a `.snap` file.** TESTING.md:181 (verbatim): "Changed
  `.snap` files are enumerated in CI against the PR merge-base with
  `origin/main` (step summary + job log). Reviewers must acknowledge each
  listed snapshot; hand-edited snapshots that merely match buggy output are
  rejected in review. Pending files (`*.pending-snap`) still fail CI. Prefer
  `cargo insta review` / `cargo insta accept` over hand-editing `.snap`
  bodies." `cargo-insta` is not installed and ad-hoc installs are forbidden,
  so the executable path is the `INSTA_UPDATE=new` form in "Commands".
- **Never re-baseline before the operator's pick is recorded.** The pause in
  step 3 is by design.
- **Never install a tool** to work around a missing binary (TESTING.md:13 /
  crates/AGENTS.md forbid ad-hoc `cargo install`).

## Inputs to provide

- `OPERATOR_BACKGROUND_PICK` — the operator's choice of surface-background
  variant, one of exactly two values: `obsidian` (head default,
  `RolePalette::tailrocks_phosphor()`, which is also `RolePalette::default()`)
  or `terminal-native` (`RolePalette::terminal_native()`). Needed by step 4
  (landing the pick) and therefore by step 5 (the re-baseline).
  - **If absent: STOP.** There is no placeholder and no proceed-anyway path.
    The spec scenario "Operator pick gates the re-baseline" states that
    reaching the re-baseline step without a recorded pick means the executor
    stops and does not re-baseline. Set the hub row to
    `BLOCKED — awaiting OPERATOR_BACKGROUND_PICK (by design)` and report the
    step-3 artifacts. This BLOCKED state is the **correct outcome** of a
    first pass, not a failure: steps 1–3 are complete work, and the operator
    resumes the plan at step 4 once they answer. Do not guess a default, do
    not pick "whatever needs no code change", and do not re-bless snapshots
    "provisionally".

- `PREVIEW_DIR` — a writable directory outside the repository for step 3's
  render artifacts (they are never committed).
  - If absent: derive one with `PREVIEW_DIR="$(mktemp -d)"`, print its
    absolute path, and use that path in the operator report. Do NOT block.

- `<TERMROCK_CHECKOUT>` — a TermRock checkout at rev
  `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`, used only to READ the head
  palette sources cited below (`crates/termrock/src/style/mod.rs` —
  `RolePalette` :355, `terminal_native()` :443-456, `roles()` :828,
  `style()` :834, `Default` :839-842). On this machine:
  `/Users/donbeave/Projects/tailrocks/termrock`. Replacement: after plan 002,
  the cargo git checkout `~/.cargo/git/checkouts/termrock-*/e1d61f4/` is a
  full repo tree and serves the same reads; or
  `git clone https://github.com/tailrocks/termrock.git && git checkout e1d61f4d…`.
  Never blocks: all load-bearing values from those files are inlined in this
  plan; the checkout is for verification reads only.

Every other path below is repo-relative; `crates/termrock/src/…` cites mean
`<TERMROCK_CHECKOUT>/crates/termrock/src/…` (termrock is an external git
dependency — no `crates/termrock/` exists in this repository).

## Starting state

### The four brand span groups (the compensation targets; rail added by verifier correction — see Step 2a)

Excerpts are from the tree at the planned-at commit `d554dca8`, i.e. **before**
plan 002. Plan 002 performs the mechanical rename of the palette type
(`termrock::Theme` no longer exists at head; the head type is
`termrock::style::RolePalette`, `crates/termrock/src/style/mod.rs:355`, with
`impl Default` = `tailrocks_phosphor()` at `style/mod.rs:839-842` and the
lookup accessor `pub const fn style(&self, role: Role) -> Style` at
`style/mod.rs:834`). Read the live files and match whatever construction
expression 002 landed; the *structure* below is what must still hold.

**1. Console BrandHeader** — `crates/jackin-console/src/tui/components/brand_header.rs:22-48`:

```rust
fn brand_header_line(label: &str) -> Line<'static> {
    let block = Style::default()
        .bg(jackin_tui::tokens::BRAND_BLOCK)
        .add_modifier(Modifier::BOLD);
    Line::from(vec![
        Span::styled(" jackin", block.fg(jackin_tui::tokens::INK)),
        Span::styled(
            "❯",
            block.fg(termrock::Theme::default()
                .style(termrock::style::Role::Text)
                .fg
                .unwrap_or_default()),
        ),
        Span::styled(" ", block),
        Span::styled(
            " · ",
            Style::default().fg(termrock::Theme::default()
                .style(termrock::style::Role::ScrollTrack)
                .fg
                .unwrap_or_default()),
        ),
        Span::styled(
            label.to_owned(),
            termrock::Theme::default().style(termrock::style::Role::TextMuted),
        ),
    ])
}
```

The file declares no test module today (`grep -n 'mod tests' …` → no match)
and there is no `brand_header/` directory.

**2. Launch cockpit header** — `crates/jackin-launch/src/tui/components/header.rs:15-41`
is a **textually identical duplicate** of that function body (verified
side-by-side; the file's own comment at `header.rs:43-48` claims the pill
"stays in sync … without a separate code path", which research 03 records as
aspirational — it is a copy, not a shared import). **Both copies must be
compensated.** This file also declares no test module and has no `header/`
directory.

**3. Capsule brand pill** — `crates/jackin-capsule/src/tui/components/chrome.rs:144-158`:

```rust
        // Row 0: brand pill — green block, black word, white chevron.
        let pill = Style::default()
            .bg(jackin_tui::tokens::BRAND_BLOCK)
            .add_modifier(Modifier::BOLD);
        buf.set_string(area.x, area.y, " jackin", pill.fg(Color::Black));
        buf.set_string(
            area.x.saturating_add(7),
            area.y,
            "❯",
            pill.fg(Theme::default()
                .style(termrock::style::Role::Text)
                .fg
                .unwrap_or_default()),
        );
        buf.set_string(area.x.saturating_add(8), area.y, " ", pill);
```

`chrome.rs:433` declares `mod tests;`; the suite is
`crates/jackin-capsule/src/tui/components/chrome/tests.rs`.

### Exact old → new RGB values (research 03, "Theme value delta" + "Brand composition color sources")

| Span | Source role | Pre-bump RGB (5ff94ee) | Post-bump RGB (head e1d61f4d) | Action |
|---|---|---|---|---|
| Console/launch chevron `❯` | `Role::Text` fg | 255,255,255 | 214,224,214 | **compensate** to 255,255,255 |
| Console/launch separator `" · "` | `Role::ScrollTrack` fg | 0,80,18 (dark phosphor green) | 22,27,22 (near-black gray) | **compensate** to 0,80,18 |
| Console/launch label | `Role::TextMuted` (full style) | fg 0,140,30 (phosphor dim green) | fg 122,138,122 (gray-green) | **compensate** to fg 0,140,30 |
| Capsule pill chevron `❯` | `Role::Text` fg | 255,255,255 | 214,224,214 | **compensate** to 255,255,255 |
| Capsule pill block bg / `" jackin"` word | `jackin_tui::tokens::BRAND_BLOCK` / `Color::Black` | 0,255,65 / black | unchanged | immune — do not touch |

The three needed values already exist as jackin❯-owned constants in the
termrock-free T0 crate `jackin-brand` (`crates/jackin-brand/src/lib.rs:34-43`,
`:56-57`):

- `pub const WHITE: Rgb = Rgb::new(255, 255, 255);` (line 43)
- `pub const PHOSPHOR_DARK: Rgb = Rgb::new(0, 80, 18);` (line 39)
- `pub const PHOSPHOR_DIM: Rgb = Rgb::new(0, 140, 30);` (line 37)
- `pub const PHOSPHOR_GREEN: Rgb = Rgb::new(0, 255, 65);` (line 35), aliased
  `pub const BRAND_BLOCK: Rgb = PHOSPHOR_GREEN;` (line 57)

`crates/jackin-tui/src/tokens.rs` is the Ratatui adapter over those RGBs:
`pub const fn color(rgb: Rgb) -> Color` (line 21) plus named `Color`
constants (`BRAND_BLOCK` line 26, `INK` line 50, etc.). It does **not** yet
export chevron/separator/label tokens.

### Row-0 elements that must NOT be compensated (D13 — capsule product chrome)

These follow the upstream look. Adding compensation to any of them is a
requirement violation:

- **Tab cells** — `crates/jackin-capsule/src/tui/components/chrome.rs:61-89`
  (`tab_cell_style`): fg `Role::Text`; bg from
  `Role::TabActive/TabInactive/TabActiveHovered/TabInactiveHovered` via
  `.bg.unwrap_or_default()`. At head the non-hovered tab roles carry **no
  bg**, so `unwrap_or_default()` yields `Color::Reset` and the 42,42,42 /
  30,30,30 fills disappear; hovered fills become 26,34,28. This is expected
  and accepted.
- **Idle-tab glyph** — `chrome.rs:115-123`, `Role::Accent` (0,255,65,
  unchanged either way).
- **Menu button** — `chrome.rs:166-194`: backgrounds from
  `jackin_tui::tokens::MENU_*` (immune constants); Idle-mode fg `Role::Text`
  **shifts and stays shifted**.
- **Overflow indicator** — `chrome.rs:198-208`, `Role::TextMuted` — shifts,
  stays shifted.
- **Active-tab underline** — `chrome.rs:216-226`: `Role::Accent` when
  focused (unchanged), `Role::Text` when unfocused — shifts, stays shifted.

### Immune files — touching any of them is a STOP

Research 03 establishes these are termrock-free (sourced from `jackin-brand`
constants or literal `Color` values) and therefore unaffected by the bump:

- `crates/jackin-brand/` (whole crate — T0, deps = owo-colors only)
- `crates/jackin-launch/src/tui/components/rain.rs` (digital rain,
  `age_to_color` lines 75-85, `render_rain` lines 222-233)
- `crates/jackin-launch/src/animation.rs` (warp intro/outro, lines 16-21,
  154-165)
- `crates/jackin/src/brand_output.rs` (CLI rain, lines 221-229)
- The launch header's animated "Loading <role> in <path>" ripple
  (`crates/jackin-launch/src/tui/components/header.rs:106-117`)

CORRECTION (verifier finding, 2026-08-19): the launch progress rail is NOT
immune — `progress_rail.rs` is `Theme::default()`-fed (`:43`) with
`Role::Text` (`:125,:145`), `Role::TextStrong` (`:235`), and
`Role::TextMuted` (`:247`) spans that all shift at head, and the rail is
brand (D11) with the invariant binding from this PR (D8). It is in the
compensation set (spec contract above) and in scope; see Step 2a.

### Explicitly NOT compensated (shifts, and that is accepted)

The spec's compensation list is exhaustive. Research 03 records two further
`Role::Text` consumers that shift white → 214,224,214; the spec does **not**
list them, so they adopt the upstream look and get no compensation code:

- `crates/jackin-launch/src/tui/components/header.rs:63-72` — the
  "Preparing launch..." fallback line.
- `crates/jackin-launch/src/tui/components/footer.rs:190-198` — the white
  status-bar background built from `Role::Text` fg.

### The 18 snapshot fixtures

`find crates -name '*.snap' | wc -l` → 18 at planning time, in three
directories (re-run the count; the fresh number is the authority — stamp it
and note any delta):

- 6 — `crates/jackin-console/src/tui/view/snapshots/`
  (`…__editor_auth_tab_90x20`, `…__editor_general_90x20`,
  `…__editor_mounts_tab_90x20`, `…__global_mounts_110x30`,
  `…__list_empty_80x24`, `…__settings_general_90x20`)
- 10 — `crates/jackin-capsule/src/tui/components/dialog/snapshots/`
  (usage dialog: amp_wide, anthropic, kimi, medium_overview, minimax,
  narrow, openai, wide, xai, zai)
- 2 — `crates/jackin-capsule/src/tui/components/branch_context_bar/snapshots/`
  (`…__branch_context_bar_no_pr_80x24`,
  `…__branch_context_bar_with_pr_120x24`)

All 18 are insta **plain-text** snapshots that encode glyphs only — no
style, color, or ANSI (research 03, "Snapshot styling encoding"). Console
snapshots join `buf[(x, y)].symbol()` per cell
(`crates/jackin-console/src/tui/view/tests.rs:579-595`); the capsule dialog
does the same (`…/dialog/tests.rs:1320-1350`); the branch bar reads row 23
(`…/branch_context_bar/tests.rs:47`). **Consequence**: color changes alone
cannot move a snapshot. What moves them is head's layout/glyph changes and,
for the background variant, nothing at all. So the changed-file count after
the re-bless may legitimately be **fewer than 18** — see step 5.

### Conventions to match

- **Tests in own file (hard rule, crates/AGENTS.md)**: no inline
  `#[cfg(test)] mod tests { … }`. `foo.rs` declares exactly
  `#[cfg(test)] mod tests;` and the tests live in `foo/tests.rs`. Exemplar:
  `crates/jackin-capsule/src/tui/components/chrome.rs:433` +
  `crates/jackin-capsule/src/tui/components/chrome/tests.rs`.
- **Test-file header**: SPDX two-line header then a `//! Tests for \`<mod>\`.`
  doc comment — exemplar `crates/jackin-capsule/src/tui/components/chrome/tests.rs:1-5`.
- **Literal-RGB color assertion exemplar**:
  `crates/jackin-capsule/src/tui/view/tests.rs:108-131`
  (`debug_run_id_chip_renders_danger_red_on_the_bar_row`) asserts
  `buf[(x, y)].bg == ratatui::style::Color::Rgb(255, 94, 122)`.
- **Buffer-rendering exemplar**:
  `crates/jackin-capsule/src/tui/components/chrome/tests.rs:12-35` renders a
  widget through `ratatui::Terminal::new(TestBackend::new(w, h))` and reads
  `terminal.backend().buffer()`.
- **Palette-tracking anti-pattern to avoid**:
  `crates/jackin-console/src/tui/view/tests.rs:661-668` compares a cell's fg
  against a live `…::default().style(Role::BorderFocused).fg` lookup. Such a
  test tracks the palette and proves nothing about the pre-bump value. The
  new tests in this plan must assert **literals**.

### Planning-time measurements — re-derivation rule

Every count below is a planning-time snapshot at `d554dca8`. Re-run the
counting command, stamp the fresh number in your report, note the delta, and
never treat a drifted planning number as a target to reproduce.

- `find crates -name '*.snap' | wc -l` → 18
- `rg -n 'Theme::default' crates | wc -l` → 352 lines across 53 files
  (research 03 measured 351 on 2026-08-19 — already drifted by 1). After
  plan 002 the equivalent count is over the renamed type; derive the live
  figure with `rg -n 'RolePalette::default\(\)' crates | wc -l`.

## Commands you will need

All commands run from the repository root. Proven by
research/jackin-verification-tooling/01-gates-and-commands.md unless noted.

| Purpose | Command | Expected on success |
|---|---|---|
| Compile check | `cargo check --workspace --all-targets --locked` | exit 0 (ch01 "tests partition", ci.rs:185-189) |
| One crate's tests | `cargo nextest run -p <crate>` | exit 0 (ch01 "One package", TESTING.md:161,184) |
| One test / module | `cargo nextest run -E 'test(<name>)'` | exit 0 (ch01 "One test / one module", TESTING.md:22-32) |
| Re-bless console snapshots | `INSTA_UPDATE=new cargo nextest run -p jackin-console -E 'test(view::tests)' --no-capture` | exit 0; `.snap` files rewritten (ch01 "Re-bless via env var"; verbatim from `crates/jackin-console/src/tui/view/tests.rs:565-568`) |
| Re-bless capsule snapshots | `INSTA_UPDATE=new cargo nextest run -p jackin-capsule --no-capture` | exit 0; `.snap` files rewritten (same mechanism, package-scoped — the capsule's two snapshot suites are `components::dialog::tests` and `components::branch_context_bar::tests`) |
| Snapshot partition | `cargo xtask ci --only snapshots` | exit 0; = `cargo nextest run -p jackin-capsule -p jackin-console --locked` (ch01 "ONLY snapshot lane", ci.rs:258-272) |
| Full suite | `cargo nextest run --workspace --all-features --locked` | exit 0 (ch01 "Whole suite", ci.rs:190-200) |
| Format | `cargo fmt` then `cargo fmt --check` | exit 0 (ch01 "Lint/format/deny", ci.rs:166) |
| Clippy (one crate) | `cargo clippy -p <crate> --all-targets -- -D warnings` | exit 0 (TESTING.md:161) |
| Pending-snapshot check | `find crates -name '*.pending-snap'` | no output (ch01 "Snapshot workflow"; pending files fail CI) |

**`cargo-insta` is NOT installed and NOT pinned in `mise.toml`** (ch01,
"`cargo insta` binary is NOT installed"), and ad-hoc `cargo install` is
forbidden. `INSTA_UPDATE=new` is the executable re-bless path. Do not try
`cargo insta review` / `cargo insta accept`.

## Suggested executor toolkit

- Read `crates/AGENTS.md` before adding the new `tests.rs` files — the
  "Tests in own file" and "no `mod.rs`" rules are hard and CI-enforced.
- Read `TESTING.md` §"Snapshot review policy" (line 179-181) before step 5.

## Scope

**In scope** (the only files to create or modify):

- `crates/jackin-console/src/tui/components/brand_header.rs` — compensate
  three spans; add `#[cfg(test)] mod tests;`
- `crates/jackin-console/src/tui/components/brand_header/tests.rs` — **new**
- `crates/jackin-launch/src/tui/components/header.rs` — compensate the same
  three spans in the duplicate; add `#[cfg(test)] mod tests;`
- `crates/jackin-launch/src/tui/components/header/tests.rs` — **new**
- `crates/jackin-capsule/src/tui/components/chrome.rs` — compensate the pill
  chevron only
- `crates/jackin-capsule/src/tui/components/chrome/tests.rs` — add the
  chevron + row-0-product-chrome tests
- `crates/jackin-launch/src/tui/components/progress_rail.rs` — compensate the
  rail's shifted role spans (Text `:125,:145`, TextStrong `:235`, TextMuted
  `:247`); leave the Danger/Accent spans (`:117,:130,:138,:234,:238,:250,:254`
  region) untouched — their role values are unchanged at head
- `crates/jackin-launch/src/tui/components/progress_rail/tests.rs` — **new**;
  rail color-asserting tests (same pattern as the other span tests)
- `crates/jackin-tui/src/tokens.rs` (+ `crates/jackin-tui/src/tokens/tests.rs`
  if you add tokens there) — **optional**, only if you choose the shared-token
  mechanism (see step 1)
- The palette-construction call sites — **only if**
  `OPERATOR_BACKGROUND_PICK` = `terminal-native` (step 4)
- The 18 `.snap` files listed above — **via `INSTA_UPDATE` re-bless only**

**Out of scope** (do NOT touch, even though related):

- All docs, including `docs/content/reference/tui/`, `AGENTS.md`, and any
  TUI reference page — **plan 004 owns them**.
- `deny.toml`, `Cargo.lock`, `Cargo.toml` pin — **plan 002 owns them** and
  must already be DONE.
- Rebuilding any brand composition on head's new primitives — deferred to
  the owning surface's modernization phase (this is exactly the N1 pressure
  point: the bump PR compensates colors, it does not re-platform brand).
- Every file in the "Immune files" list — rain, warp/animation, CLI rain,
  `crates/jackin-brand/`. **Touching one is a STOP.** (The progress rail is
  NOT immune — see the correction note and Step 2a; only its Danger/Accent
  spans stay untouched.)
- The two "Explicitly NOT compensated" launch surfaces (header fallback line,
  footer status bar).
- The capsule row-0 product chrome (tabs, fills, underline, menu, overflow).

The hub `plans/termrock-migration/README.md` and the roadmap item are
protocol-writable and never listed in scope.

## Git workflow

This plan's commits ride the package's single branch `feature/termrock-head-bump`
(hub repo law). Commit boundaries and subjects:

1. After step 2 (compensation + its tests, green):
   `fix(tui): pin jackin❯ brand spans to brand constants across the bump`
2. After step 4, **only if** the pick is `terminal-native`:
   `feat(tui): adopt the terminal-native surface palette`
   (if the pick is `obsidian`, there is no code change and no commit — record
   the decision in the report and in the step-6 hub status line instead)
2a. After step 2a (rail compensation + its tests, green):
   `fix(tui): pin launch progress-rail brand spans across the bump`
3. After step 5 (re-bless):
   `test(tui): re-bless TUI snapshots for the TermRock head bump`
   — this commit contains `.snap` files and nothing else.

Step 3's render artifacts are **never committed**; they live under
`PREVIEW_DIR` outside the repository, and the throwaway capture code is
reverted before commit 1 or 2 lands.

## Steps

### Step 1: Choose the compensation mechanism and pin the three console/launch spans

Read the live `crates/jackin-console/src/tui/components/brand_header.rs` and
confirm the three role-fed spans from "Starting state" are still there.

Pick one mechanism and apply it consistently across all three files:

- **(a) Shared tokens** — add three `Color` constants to
  `crates/jackin-tui/src/tokens.rs` next to the existing `BRAND_BLOCK`/`INK`,
  built with the existing `color()` helper over `jackin-brand` RGBs:
  `BRAND_CHEVRON = color(jackin_brand::WHITE)`,
  `BRAND_SEPARATOR = color(jackin_brand::PHOSPHOR_DARK)`,
  `BRAND_LABEL = color(jackin_brand::PHOSPHOR_DIM)`. Note `jackin-tui`'s crate
  rule: it may hold product brand tokens but **must not** gain "a generic
  theme facade" — three named brand colors are tokens, not a facade. Keep it
  to constants; add no palette selector, no role mapper.
- **(b) Per-surface explicit styles** — reference
  `jackin_tui::tokens::color(jackin_brand::WHITE)` (etc.) inline at each of
  the three call sites.

Either satisfies the spec ("pinning to jackin-brand constants or explicit
styles — mechanism is plan/executor choice"). (a) is preferred because the
console and launch copies are textually identical duplicates and a shared
token keeps them from drifting apart further.

Then in **both** `crates/jackin-console/src/tui/components/brand_header.rs`
and `crates/jackin-launch/src/tui/components/header.rs`, replace the three
palette lookups inside `brand_header_line` so that:

- the `"❯"` span keeps `block` (BRAND_BLOCK bg + BOLD) and takes fg
  255,255,255;
- the `" · "` span takes fg 0,80,18 on a default (no-bg) style;
- the label span takes fg 0,140,30 — note the label currently applies the
  **whole** `Role::TextMuted` style, so replace it with an explicit
  `Style::default().fg(<0,140,30>)`; the old `TextMuted` style carried fg
  only (research 03 delta table: `TextMuted` = fg 0,140,30, no bg, no
  modifier), so an fg-only style reproduces it exactly.

Leave the ` jackin` word span (`jackin_tui::tokens::INK` on `block`)
untouched — it is immune.

Add `#[cfg(test)] mod tests;` to each of the two files (no `#[path]`, no
alias, no intervening attribute) and create the two empty-for-now sibling
`tests.rs` files with the SPDX + `//! Tests for …` header.

**Verify**:
`cargo check -p jackin-console -p jackin-launch -p jackin-tui --all-targets --locked` → exit 0
and two mechanical checks:
`rg -n 'Role::Text\b|Role::ScrollTrack|Role::TextMuted' crates/jackin-console/src/tui/components/brand_header.rs` → **no output** (the whole file is the brand header), and
`rg -n 'Role::Text\b|Role::ScrollTrack|Role::TextMuted' crates/jackin-launch/src/tui/components/header.rs` → hits **only** at the "Preparing launch..." fallback (the lines around 63-72 in the pre-edit file), which stays uncompensated by design — stamp the observed line numbers.

### Step 2: Compensate the capsule pill chevron and write the color-asserting tests

In `crates/jackin-capsule/src/tui/components/chrome.rs:144-158`, change
**only** the `"❯"` `set_string` call's fg to the 255,255,255 compensation.
Do not touch `tab_cell_style` (lines 61-89), `tab_glyph_style` (101-126), the
menu button (166-194), the overflow indicator (198-208), or the underline
(216-226).

Now write the color-asserting tests. Every expected value is a **literal**
`ratatui::style::Color::Rgb(…)` — never a live palette lookup, and never the
compensation constant itself (a test that reads the same constant the code
reads proves nothing). Model the render harness on
`crates/jackin-capsule/src/tui/components/chrome/tests.rs:12-35` and the
literal assertion style on `crates/jackin-capsule/src/tui/view/tests.rs:108-131`.

- `crates/jackin-console/src/tui/components/brand_header/tests.rs`
  - `brand_chevron_keeps_pre_bump_white` — render `brand_header_line("x")`
    (or `render_brand_header` into a `TestBackend` buffer); assert the `❯`
    span's fg == `Color::Rgb(255, 255, 255)`, its bg == `Color::Rgb(0, 255, 65)`,
    and that it carries `Modifier::BOLD`.
  - `brand_separator_keeps_pre_bump_dark_phosphor` — assert the `" · "` fg ==
    `Color::Rgb(0, 80, 18)`.
  - `brand_label_keeps_pre_bump_dim_phosphor` — assert the label fg ==
    `Color::Rgb(0, 140, 30)`.
- `crates/jackin-launch/src/tui/components/header/tests.rs` — the same three
  tests against the launch duplicate's `brand_header_line`. Name them
  distinctly (e.g. `cockpit_brand_chevron_keeps_pre_bump_white`).
- `crates/jackin-capsule/src/tui/components/chrome/tests.rs` — add:
  - `brand_pill_chevron_keeps_pre_bump_white` — render `StatusBarWidget` as
    the existing tests do; the pill occupies columns 0..=8 with `❯` at
    `area.x + 7`; assert that cell's fg == `Color::Rgb(255, 255, 255)`, bg ==
    `Color::Rgb(0, 255, 65)`.
  - `row0_tabs_follow_the_upstream_theme_without_compensation` (D13) — render
    with at least two tabs, none hovered; assert a non-hovered tab cell's bg
    == `Color::Reset` (head clears the non-hovered tab fills) and that its fg
    is **not** `Color::Rgb(255, 255, 255)` — i.e. no compensation is attached
    to product chrome. If the live head value differs from the research
    prediction, stamp the observed value and use it as the authority.

**Verify**:
`cargo nextest run -p jackin-console -p jackin-launch -p jackin-capsule` → exit 0 with the new tests present and passing (the pre-existing snapshot tests in `jackin-console`/`jackin-capsule` may still fail here — that is the by-design red window; note which fail and continue), and
`cargo clippy -p jackin-console -p jackin-launch -p jackin-capsule -p jackin-tui --all-targets -- -D warnings` → exit 0, and
`cargo fmt --check` → exit 0.

Commit 1 now (`fix(tui): pin jackin❯ brand spans to brand constants across the bump`), then push.

### Step 2a: Compensate the launch progress rail's shifted spans

Rail starting-state facts (verify at the cited lines before editing; drift
is a STOP per precondition 7): `progress_rail.rs:43` binds
`let theme = termrock::Theme::default();` feeding the termrock `Progress`
widget construction at `:44-48`; the rail's own text spans use
`Role::Text` at `:125` and `:145`, `Role::TextStrong` at `:235`,
`Role::TextMuted` at `:247`; its `Role::Accent` spans sit at
`:117,:130,:238,:254` and `Role::Danger` at `:138,:234,:250`. Pre-bump
values to preserve: Text fg 255,255,255; TextStrong fg 255,255,255 bold;
TextMuted fg 0,140,30 (fg-only). Head values they would otherwise shift to:
214,224,214 / 240,245,240 bold / 122,138,122. Token guidance under
mechanism (a): Text and TextStrong pin to the existing `WHITE`-backed token
(TextStrong keeps its BOLD modifier at the call site), TextMuted pins to the
`PHOSPHOR_DIM`-backed token — no new token names are needed beyond step 1's.
Test fixture exemplar: the TestBackend harness at
`crates/jackin-launch/src/tui/tests.rs:27-65`.

The rail is brand (D11) and theme-fed, not hard-coded. In
`crates/jackin-launch/src/tui/components/progress_rail.rs`, apply the same
compensation mechanism chosen in step 1 to the spans whose role values
changed at head:

- `Role::Text` arms at `:125` and `:145` — pre-bump fg 255,255,255
  (`jackin_brand::WHITE`).
- `Role::TextStrong` at `:235` — pre-bump fg 255,255,255 bold (pin fg to
  `WHITE`, keep the BOLD modifier).
- `Role::TextMuted` at `:247` — pre-bump fg 0,140,30
  (`jackin_brand::PHOSPHOR_DIM`).

Leave untouched: every `Role::Danger` and `Role::Accent` span
(`:117, :130, :138, :234, :238, :250, :254` region) — those role values are
unchanged at head — and the termrock `Progress` widget construction at
`:44-48` (its bar paints via the theme; the bar itself is not a
compensated brand span — only the rail's text/label spans are).

Add `crates/jackin-launch/src/tui/components/progress_rail/tests.rs` (new,
plus the `#[cfg(test)] mod tests;` declaration) with color-asserting tests
per compensated span, same independent-source-of-truth pattern as step 2:
expected values are the `jackin_brand` constants / literal RGB above, never
a recomputed theme lookup.

**Verify**:
`cargo nextest run -p jackin-launch` → exit 0 including the new
`progress_rail` tests.

This step always lands as its own commit
`fix(tui): pin launch progress-rail brand spans across the bump` (step 2's
commit 1 has already landed by plan order); push after committing.

### Step 3: Render the two background variants side-by-side and STOP for the operator

Produce, for the **same** screens, one capture under (a) the head default
obsidian surface ladder (`RolePalette::tailrocks_phosphor()`, which is what
`RolePalette::default()` already resolves to — no code change needed) and one
under (b) `RolePalette::terminal_native()`. Head's `terminal_native()`
(`crates/termrock/src/style/mod.rs:443-456`) starts from `tailrocks_phosphor()`,
clears the backgrounds of `Role::{Canvas, Surface, Raised, Elevated, Sunken}`,
and sets `Role::StatusBar` to fg WHITE — it restores the old background-free
surface behavior but keeps head's new text/hint/tab/scroll values.

Mechanism — **must leave no trace in the final tree**:

1. `PREVIEW_DIR="$(mktemp -d)"; echo "$PREVIEW_DIR"` (or use the provided
   `PREVIEW_DIR` input).
2. Append a throwaway `#[test] fn palette_preview_capture()` to the existing
   suites that already own render helpers —
   `crates/jackin-console/src/tui/view/tests.rs` (helper
   `render_manager_buffer`, lines 597+) and
   `crates/jackin-capsule/src/tui/components/chrome/tests.rs` — that walks the
   rendered `Buffer` and writes one truecolor-ANSI file per screen into the
   directory named by an env var. Run it with
   `PREVIEW_OUT="$PREVIEW_DIR/a-obsidian" cargo nextest run -E 'test(palette_preview_capture)' --no-capture`.
3. Mechanically flip the palette construction to variant (b) — replace
   `RolePalette::default()` with `RolePalette::terminal_native()` across
   `crates/` (derive the site count first: `rg -c 'RolePalette::default\(\)' crates`)
   — and re-run the capture with `PREVIEW_OUT="$PREVIEW_DIR/b-terminal-native"`.
4. Revert **everything** from steps 2–3: `git checkout -- crates` (verify with
   `git status --short` → clean, and `git diff --stat` → empty).

Cover at minimum: the console manager list screen (the one behind
`list_empty_80x24`, whose row 0 is the BrandHeader), one console editor
screen, the capsule status bar rows 0–1, and one capsule usage dialog.

Also emit a paste-able delta table: iterate `RolePalette::roles()` (head `crates/termrock/src/style/mod.rs:828`) and list
every role whose resolved `Style` differs between `tailrocks_phosphor()` and
`terminal_native()` (expected: the five surface roles lose their bg, and
`StatusBar` changes). This is the exact, colorless statement of the choice.

**Then STOP.** Report to the operator:

- the absolute `PREVIEW_DIR` and the exact `cat` commands to view each
  capture pair in a terminal (the ANSI colors only render there);
- the delta table inline;
- the explicit question: **"OPERATOR_BACKGROUND_PICK required — `obsidian`
  (head default surface ladder) or `terminal-native`?"**

Set the hub row for plan 003 to
`BLOCKED — awaiting OPERATOR_BACKGROUND_PICK (by design)` and stop the loop.
**This is the correct outcome of a first pass, not a failure.** Do not
continue to step 4 without a recorded pick.

**Verify**: `git status --short` → clean (no throwaway capture code left,
no artifact inside the repository), and both
`"$PREVIEW_DIR"/a-obsidian*` and `"$PREVIEW_DIR"/b-terminal-native*` exist
and are non-empty.

### Step 4: Land the operator's pick

Requires `OPERATOR_BACKGROUND_PICK`. If it is not recorded, go back to step 3's
STOP.

- **`obsidian`** — no code change: `RolePalette::default()` already resolves
  to `tailrocks_phosphor()` (`crates/termrock/src/style/mod.rs:839-842`).
  Record the decision in your report; there is no commit for this step.
- **`terminal-native`** — apply the same mechanical substitution you rehearsed
  in step 3 (`RolePalette::default()` → `RolePalette::terminal_native()`)
  across the palette-construction call sites in `crates/`, then
  `cargo fmt`. Stamp the fresh site count from
  `rg -c 'RolePalette::terminal_native\(\)' crates`. Commit 2
  (`feat(tui): adopt the terminal-native surface palette`) and push.

**Verify**:
`cargo check --workspace --all-targets --locked` → exit 0, and
`cargo fmt --check` → exit 0, and — for `terminal-native` only —
`rg -n 'RolePalette::default\(\)' crates --glob '!**/tests.rs' --glob '!**/tests/**' | wc -l` → `0` (production render paths only; test code may keep live-palette lookups — the anti-pattern note in the test plan governs the NEW tests, not pre-existing ones).

### Step 5: Re-bless the snapshots wholesale and review the diff

Only now, with the pick landed. Re-run the fixture count first
(`find crates -name '*.snap' | wc -l`) and stamp it.

Per crate, using the repo-documented env-var workflow:

```sh
INSTA_UPDATE=new cargo nextest run -p jackin-console -E 'test(view::tests)' --no-capture
INSTA_UPDATE=new cargo nextest run -p jackin-capsule --no-capture
```

Then:

1. `find crates -name '*.pending-snap'` → no output. If any `.pending-snap`
   file exists, the re-bless did not complete — re-run; do not rename or
   hand-edit it.
2. `git status --short -- '**/*.snap'` — stamp the number of changed files
   and note the delta from 18. **Fewer than 18 is legitimate**: all 18 are
   glyph-only text snapshots (research 03), so a fixture whose glyphs did not
   move is correctly left alone. Zero changed is also legitimate *provided*
   precondition 5 held and the snapshot partition was failing before this
   step — record which it was.
3. Review `git diff -- '**/*.snap'` **wholesale** and write the acceptance
   note into your report: for each changed fixture, one line naming what
   moved (glyph/layout change from head's widget overhaul). This is the
   deliberate acceptance the spec and TESTING.md's snapshot gate require, and
   it is what the reviewer will be asked to acknowledge.
4. Confirm no `.snap` was hand-edited: every changed `.snap` must have been
   written by the two commands above and nothing else. Do not open a `.snap`
   in an editor.

Commit 3 (`test(tui): re-bless TUI snapshots for the TermRock head bump`)
containing **only** `.snap` files, then push.

**Verify**:
`cargo xtask ci --only snapshots` → exit 0, and
`find crates -name '*.pending-snap'` → no output, and
`git show --stat HEAD` → the commit touches only `*.snap` paths.

### Step 6: Full suite green

**Verify**:
`cargo nextest run --workspace --all-features --locked` → exit 0, and
`cargo xtask ci --only snapshots` → exit 0, and
`git status --short` → only the protocol writes (hub status row, roadmap
item) remain uncommitted, if any.

Then flip the hub row to DONE per the hub's executor protocol, citing this
session's command output.

## Test plan

New tests, all with **literal** expected values (independent of the code's
own constants and of any live palette lookup):

| File | Test | Spec scenario |
|---|---|---|
| `crates/jackin-console/src/tui/components/brand_header/tests.rs` | `brand_chevron_keeps_pre_bump_white` — fg `Color::Rgb(255,255,255)`, bg `Color::Rgb(0,255,65)`, `Modifier::BOLD` | Compensated spans match pre-bump values |
| same | `brand_separator_keeps_pre_bump_dark_phosphor` — fg `Color::Rgb(0,80,18)` | same |
| same | `brand_label_keeps_pre_bump_dim_phosphor` — fg `Color::Rgb(0,140,30)` | same |
| `crates/jackin-launch/src/tui/components/header/tests.rs` | the same three against the launch duplicate | same (the duplicate is named explicitly in the requirement) |
| `crates/jackin-capsule/src/tui/components/chrome/tests.rs` | `brand_pill_chevron_keeps_pre_bump_white` | Row-0 product chrome follows the theme — "AND the pill's chevron matches its pre-bump white" |
| same | `row0_tabs_follow_the_upstream_theme_without_compensation` — non-hovered tab bg `Color::Reset`, tab fg not the compensated white | Row-0 product chrome follows the theme |
| `crates/jackin-launch/src/tui/components/progress_rail/tests.rs` | `rail_text_spans_keep_pre_bump_white` — fg `Color::Rgb(255,255,255)` | Compensated spans match pre-bump values (rail, step 2a) |
| same | `rail_strong_span_keeps_pre_bump_white_bold` — fg `Color::Rgb(255,255,255)` + `Modifier::BOLD` | same |
| same | `rail_muted_span_keeps_pre_bump_dim_phosphor` — fg `Color::Rgb(0,140,30)`, no bg, no modifier | same |

Edge cases to cover explicitly:

- The chevron assertion must check **bg and modifier too**, not just fg — the
  requirement says "byte-identical colors/attributes".
- The label assertion must confirm the span carries **no bg and no modifier**
  (the old `Role::TextMuted` was fg-only).

Scenario "Immune brand code untouched" is verified by command, not by a test:
`git diff --name-only origin/main...HEAD -- crates/jackin-brand/ crates/jackin-launch/src/tui/components/rain.rs crates/jackin-launch/src/animation.rs crates/jackin/src/brand_output.rs`
→ **no output**.

Scenarios "Snapshot suite green after re-bless" / "No hand-edited snapshots"
are verified by step 5's commands and the commit-content check.

**Verify**: `cargo nextest run -p jackin-console -p jackin-launch -p jackin-capsule`
→ exit 0, including the 11 new tests (8 from step 2 + 3 rail tests from step 2a).

## Done criteria

Machine-checkable. ALL must hold, each cited from this session's output:

- [ ] `cargo check --workspace --all-targets --locked` exits 0
- [ ] `cargo nextest run --workspace --all-features --locked` exits 0
- [ ] `cargo xtask ci --only snapshots` exits 0
- [ ] `cargo fmt --check` exits 0 and `cargo clippy -p jackin-console -p jackin-launch -p jackin-capsule -p jackin-tui --all-targets -- -D warnings` exits 0
- [ ] The 11 new color-asserting tests exist and pass (8 span-group + 3 rail); each asserts a literal
      `Color::Rgb(…)` (grep the new test files for
      `Theme::default\(|RolePalette::default\(|DesignSystem::default\(` → no
      palette lookup in an expected value; `Style::default()`/harness code is
      fine)
- [ ] `find crates -name '*.pending-snap'` produces no output
- [ ] `OPERATOR_BACKGROUND_PICK` is recorded in the report, and the tree
      matches it: `obsidian` → `rg -n 'RolePalette::terminal_native\(\)' crates`
      finds no production call site; `terminal-native` →
      `rg -n 'RolePalette::default\(\)' crates | wc -l` is `0`
- [ ] The snapshot re-bless commit touches only `*.snap` paths
      (`git show --stat <sha>`)
- [ ] `git diff --name-only origin/main...HEAD -- crates/jackin-brand/ crates/jackin-launch/src/tui/components/rain.rs crates/jackin-launch/src/animation.rs crates/jackin/src/brand_output.rs` produces no output
- [ ] No files outside the in-scope list modified (`git status`) — excluding
      the protocol writes: `plans/termrock-migration/README.md` status rows
      and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails, or "Starting state" does not match reality after
  accounting for plan 002's mechanical rename.
- A compensated span's test cannot reproduce the pre-bump value
  (255,255,255 / 0,80,18 / 0,140,30) — that means the span's structure or
  source changed and the compensation target is wrong.
- The snapshot diff shows a change in a file the "Immune files" list says
  cannot change, or the work would require editing one of those files.
- `OPERATOR_BACKGROUND_PICK` is absent when step 4 is reached — this is the
  **by-design BLOCKED** outcome, the correct result of a first pass, not a
  failure. Record it as such.
- You are tempted to hand-edit a `.snap` file, rename a `.pending-snap`, or
  install `cargo-insta`. All three are forbidden.
- The re-bless changes a `.snap` in a way you cannot explain in one line
  during the step-5 wholesale review.
- Precondition 5 fails (snapshots already re-blessed on the branch) — the
  re-baseline would then happen twice, which the spec forbids.

## Maintenance notes

- **Interacts with plan 004**: 004 updates the TUI docs pages and runs the
  merge-readiness gate; it needs the full suite (snapshots included) green,
  which is this plan's step 6. If the operator's pick is `terminal-native`,
  004's docs pass should reflect the surface-background behavior.
- **Reviewer focus**: (1) that the four brand span groups assert *literal*
  RGBs and not a live palette lookup — a palette-tracking assertion silently
  passes forever and proves nothing; (2) that no compensation leaked into
  capsule row-0 product chrome (D13); (3) that the `.snap` commit is
  snapshot-only and its wholesale-review note names what moved per fixture.
- **Deferred on purpose**: rebuilding the brand compositions on head's new
  primitives (ledger B11 rebuild half) belongs to each surface's
  modernization phase, not the bump PR — N1 is the pressure point here, and
  a compensation is the *minimum* change that keeps the look invariant.
- **Known duplication**: the console and launch `brand_header_line` bodies
  are textually identical copies. This plan compensates both rather than
  deduplicating them; the launch file's comment claiming automatic sync stays
  aspirational. Deduplication is a modernization-phase decision.
