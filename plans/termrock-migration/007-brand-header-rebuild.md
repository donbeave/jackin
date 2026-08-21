# Plan 007: Rebuild the console BrandHeader on TermRock head primitives behind a dedicated zero-tolerance PNG crop proof

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED (the proof is a pixel-exact gate riding plan 005's harness; a rebuild that cannot reproduce the render byte-identically is a STOP, not a re-bless)
- **Depends on**: `plans/termrock-migration/005-*.md` (PNG pipeline foundation: full console inventory baselines + CI lane)
- **Covers**: F8 (console BrandHeader rebuilt on new primitives, look proven by dedicated PNG crop + 12 literal-RGB tests), B11 console half (each brand composition rebuilt in its owning surface's phase), B16 (parity proof set = text snapshots + parity tests + PNG baselines + BrandHeader crop), D21 (BrandHeader proof = dedicated PNG-baseline crop + literal-RGB unit tests; template for the other brand compositions)
- **Guardrails**: N1, N4 (inlined below)
- **Research basis**: `research/termrock-head-adoption/03-theme-brand-impact.md` (brand span inventory + compensation), `research/termrock-head-adoption/04-component-adoption-candidates.md` (C18 — no upstream pairing for the brand header), `research/termrock-head-adoption/05-png-baseline-pipeline.md` (raster pipeline + consumer contract), `research/jackin-verification-tooling/01-gates-and-commands.md` (gate commands)
- **Planned at**: commit `f320b51f`, 2026-08-19

## Why this matters

The console BrandHeader is the first brand composition to be rebuilt under
the modernization program, and its proof mechanism is the template the
launch rain/warp/rail and capsule pill rebuilds copy at their own phases.
The header stays jackin❯-owned and keeps its exact current look — ownership
and look are the invariants, implementation is not. After this plan lands,
the header renders through TermRock head's sanctioned styled-line painter
instead of a raw ratatui `Paragraph`, and "renders identically" is proven by
a zero-tolerance PNG baseline cropped to the header's row — an artifact no
surrounding-screen re-bless can touch — with the bump phase's 12 literal-RGB
span tests kept as the value-level gate.

## Preconditions — run before anything else

- Plan 005 landed (hub row DONE). All three checks must hold:
  - `grep -n 'termrock-raster' Cargo.toml` → one dependency line, git source
    `https://github.com/tailrocks/termrock.git`, rev
    `29a16b5bff84ea8609854711b774e87acbc456cc` — the same rev as the
    `termrock` pin at `Cargo.toml:118` (a second, divergent rev resolves two
    termrock copies with incompatible types and is a STOP).
  - `find crates -name '*.png' | wc -l` → ≥ 25 at planning time (6 stage
    views + 19 modal baselines). Planning-time count — re-run and treat the
    fresh number as the authority; the check that matters is ≥ 1 committed
    console baseline and a green harness.
  - `grep -rln 'termrock_raster' crates --include='*.rs'` → non-empty (the
    jackin-side harness exists), and the harness package's suite is green:
    `cargo nextest run -p <HARNESS_PACKAGE> --locked` → exit 0
    (`<HARNESS_PACKAGE>` = the package owning the files the previous grep
    listed, per step 1).
- The 12 literal-RGB brand tests exist and pass **before** the rebuild:
  `grep -rn 'fn .*keeps_pre_bump\|fn .*keep_pre_bump\|fn row0_tabs_follow_the_upstream_theme_without_compensation' crates --include='*.rs' | wc -l`
  → `12`, then the per-module runs in "Commands you will need" → all pass.
- Drift check:
  `git diff --stat f320b51f..HEAD -- crates/jackin-console/src/tui/components/brand_header.rs crates/jackin-console/src/tui/components/brand_header/ crates/jackin-tui/src/tokens.rs crates/jackin-console/src/tui/view.rs crates/jackin-launch/src/tui/components/header/tests.rs crates/jackin-launch/src/tui/components/progress_rail/tests.rs crates/jackin-capsule/src/tui/components/chrome/tests.rs`
  — on any in-scope change, compare "Starting state" excerpts against live
  code; a mismatch is a STOP. (Plan 005's own additions — `termrock-raster`
  in `Cargo.toml`, its harness and baseline files — are expected drift and
  are not in this list.)

Any failed precondition is a STOP.

## Spec contract

The requirements this plan implements, inlined **verbatim** from
`plans/termrock-migration/spec/console-brand-header.md` — the executor does
not read `spec/`:

### Requirement: Rebuilt header, identical look

The console BrandHeader SHALL be re-implemented on TermRock head primitives and MUST render identically to its pre-rebuild output — same glyphs, same brand colors, same layout within its region. The header stays jackin❯-owned; it MUST NOT move into TermRock and MUST NOT change visual identity (N1).

Covers: F8 · Evidence: roadmap item §Decisions (brand rebuild allowed, look preserved; BrandHeader proof ruling), research/termrock-head-adoption/03-theme-brand-impact.md

#### Scenario: Header across console stages

- **WHEN** the rebuilt header renders on any console stage view
- **THEN** its region shows the identical brand composition as before the rebuild (PNG crop compare, zero-tolerance)

### Requirement: Brand proof is a dedicated PNG crop plus literal-RGB tests

The BrandHeader's look SHALL be proven by a zero-tolerance PNG baseline cropped to the BrandHeader region — isolated from surrounding chrome so re-blessing a surrounding screen never touches the brand baseline — and the bump phase's 12 literal-RGB span tests MUST be kept as the value-level gate. Re-blessing the brand crop follows the same deliberate-review rule as any baseline; a brand-crop diff outside an intended brand change is a parity break and a STOP.

Covers: F8, B11, B16 · Evidence: roadmap item §Decisions (BrandHeader proof ruling, 2026-08-19)

#### Scenario: Chrome churn does not touch the brand baseline

- **GIVEN** a surrounding screen's PNG baseline is re-blessed after an intended chrome change
- **WHEN** the BrandHeader crop suite runs
- **THEN** the brand crop baseline is untouched and still passes

#### Scenario: Value-level gate survives the rebuild

- **WHEN** the rebuilt header lands
- **THEN** all 12 literal-RGB span tests pass against the rebuilt implementation

### Requirement: Mechanism recorded as the brand-proof template

The crop-plus-RGB proof mechanism SHALL be recorded (in the plan that lands it) as the template the remaining brand compositions adopt at their owning surfaces' phases — launch rain/warp/rail and the capsule pill — so each later phase reuses the pattern instead of re-deriving it.

Covers: B11 · Evidence: roadmap item §Decisions (BrandHeader proof ruling: "the template for the remaining brand compositions")

#### Scenario: Template reusable

- **WHEN** the launch or capsule phase plans its brand composition rebuild
- **THEN** the console BrandHeader plan's proof mechanism (crop isolation, RGB test retention, re-bless review rule) is cited as the pattern to copy

Done means these scenarios hold; the test plan below exercises them.

## Must NOT

Guardrails inlined verbatim from the must-not registry
(`plans/termrock-migration/coverage.md`). These override anything a step
seems to imply:

- **N1**: No brand composition moves into TermRock or changes visual identity (BrandHeader, rain, launch animation/warp, rail, capsule pill) — upstream 0331 declined; ownership+look invariants.
- **N4**: No new operator-visible screens or overlays beyond keyboard_help; no journey changes — amended D14 — amendment scope is exactly one overlay.

Concretely for this plan: the rebuild never edits the brand tokens
(`jackin-tui/src/tokens.rs`), never edits the 12 literal-RGB tests, never
changes a glyph, color, modifier, or spacing of the header, and never re-blesses
a brand crop after the pre-rebuild bless in step 3.

## Inputs to provide

- `<HARNESS_PACKAGE>` — the cargo package owning plan 005's PNG baseline
  harness. Needed by every step. If absent: discover by
  `grep -rln 'termrock_raster' crates --include='*.rs'`; the package is the
  crate containing those files. No placeholder possible — a missing harness
  means precondition 1 failed and this plan STOPs.
- `<BASELINE_ROOT>` — the directory holding plan 005's committed console PNG
  baselines. Needed by step 2. If absent: discover by
  `find crates -name '*.png' | head -20` and take the common root.
- `<FULLSCREEN_BLESS_ENV>` — the env var that puts plan 005's harness in
  bless mode. Needed by step 3 (isolation proof only — this plan never
  re-blesses full screens). If absent: discover by
  `grep -rn 'BLESS' crates --include='*.rs' | grep -i png`.
- `<PALETTE>` — the `RolePalette` the harness renders with. Needed by step 2.
  If absent: read it from the harness's render call; use whatever plan 005
  uses, never a different one (the crop must be a sub-region of the same
  render).
- `<STATE_SEAM>` — the per-screen state constructors and canonical sizes plan
  005 baselined (6 stage views + 19 modals). Needed by step 2. If the harness
  does not expose them to a sibling suite: factor them into a shared
  test-support module inside the harness location — additive,
  behavior-preserving extraction only. If that extraction would require
  restructuring plan 005's harness beyond additive moves, STOP (out of
  scope).

All five are derivable from the landed plan 005 artifacts in-repo; none may
be invented. Record the discovered values in the step 1 commit message.

## Starting state

The facts, inlined:

- **The header implementation** —
  `crates/jackin-console/src/tui/components/brand_header.rs` (whole file, 50
  lines). Load-bearing excerpts:

  `brand_header.rs:22-42` — the span composition, with the bump phase's
  pinned brand constants:

  ```rust
  fn brand_header_line(label: &str) -> Line<'static> {
      let block = Style::default()
          .bg(jackin_tui::tokens::BRAND_BLOCK)
          .add_modifier(Modifier::BOLD);
      // The chevron/separator/label pin jackin❯-owned brand constants: head's
      // palette recolored the roles they used to read, and the brand look is an
      // invariant across the bump.
      Line::from(vec![
          Span::styled(" jackin", block.fg(jackin_tui::tokens::INK)),
          Span::styled("❯", block.fg(jackin_tui::tokens::BRAND_CHEVRON)),
          Span::styled(" ", block),
          Span::styled(
              " · ",
              Style::default().fg(jackin_tui::tokens::BRAND_SEPARATOR),
          ),
          Span::styled(
              label.to_owned(),
              Style::default().fg(jackin_tui::tokens::BRAND_LABEL),
          ),
      ])
  }
  ```

  `brand_header.rs:14-20` — the render path this plan replaces:

  ```rust
  impl Widget for BrandHeader<'_> {
      fn render(self, area: Rect, buffer: &mut Buffer) {
          Paragraph::new(brand_header_line(self.label))
              .alignment(Alignment::Left)
              .render(area, buffer);
      }
  }
  ```

  `brand_header.rs:44-46` — the public seam (signature MUST NOT change; three
  call sites depend on it):

  ```rust
  pub fn render_brand_header(frame: &mut ratatui::Frame<'_>, area: Rect, label: &str) {
      frame.render_widget(BrandHeader { label }, area);
  }
  ```

- **The brand tokens (untouchable)** — `crates/jackin-tui/src/tokens.rs`:
  `:27` `pub const BRAND_BLOCK: Color = color(BRAND_BLOCK_RGB);` (0,255,65),
  `:51` `pub const INK: Color = Color::Black;`,
  `:54` `pub const BRAND_CHEVRON: Color = color(WHITE_RGB);`,
  `:57` `pub const BRAND_SEPARATOR: Color = color(PHOSPHOR_DARK_RGB);`,
  `:59` `pub const BRAND_LABEL: Color = color(PHOSPHOR_DIM_RGB);`.

- **The 12 literal-RGB tests (untouchable; the value-level gate)** —
  3 console: `crates/jackin-console/src/tui/components/brand_header/tests.rs:11`
  (`brand_chevron_keeps_pre_bump_white` — fg `Rgb(255,255,255)`, bg
  `Rgb(0,255,65)`, BOLD), `:21` (`brand_separator_keeps_pre_bump_dark_phosphor`
  — fg `Rgb(0,80,18)`), `:30` (`brand_label_keeps_pre_bump_dim_phosphor` — fg
  `Rgb(0,140,30)`); 3 launch cockpit duplicate:
  `crates/jackin-launch/src/tui/components/header/tests.rs:11,21,30`; 2
  capsule pill: `crates/jackin-capsule/src/tui/components/chrome/tests.rs:187`
  (`brand_pill_chevron_keeps_pre_bump_white`) and `:213`
  (`row0_tabs_follow_the_upstream_theme_without_compensation`); 4 launch
  rail: `crates/jackin-launch/src/tui/components/progress_rail/tests.rs:12,34,41,48`.
  Only the 3 console tests exercise the code this plan rebuilds; the other 9
  guard surfaces this plan never touches — all 12 run as the gate.

- **Where the header renders** — every console stage view paints it at row 0:
  `crates/jackin-console/src/tui/view.rs:388-390` (`render_header` delegates
  to `render_brand_header`), called from `view.rs:610` (workspaces),
  `crates/jackin-console/src/tui/screens/settings/view.rs:177`,
  `crates/jackin-console/src/tui/screens/editor/view/frame.rs:107`. The
  header chunk is the frame's top rows: `view.rs:232-246`
  (`workspace_frame_areas`, `Constraint::Length(2)`),
  `settings/view.rs:84-100` and `editor/view/frame.rs:32-48`
  (`Constraint::Length(3)`); the single text line lands on row 0 in all three
  (e.g. the `list_empty_80x24` snapshot's first row is
  ` jackin❯  · workspaces`). Modal states paint `Backdrop` over row 0
  (`view.rs:626-630`), so the brand is visible only on non-modal stage views.

- **The head primitive the rebuild adopts** — termrock at the pinned rev
  `29a16b5b`, `crates/termrock/src/text/mod.rs`:
  `:466` `pub fn paint_line_overflow(buffer: &mut Buffer, area: Rect, line: &Line<'_>, style: Style, placement: LinePlacement<'_>, scratch: &mut String)`
  — doc: "Paints a styled `line` into `area`, preserving per-span styles
  across the alignment offset and the contraction boundary." Its
  `buffer.set_style(area, style)` with `Style::default()` patches nothing
  (fg/bg/modifiers all `None`), matching `Paragraph`'s default-style no-op;
  `LinePlacement::clipped("…")` (`text/mod.rs:404-411`) is
  left-aligned + `CellOverflow::Clip` (`:378-382`, the default variant) — `Paragraph`'s
  own clip behavior. The `Line` it takes is `ratatui_core::text::Line`
  (`text/mod.rs:10`); jackin pins `ratatui = "0.30"` +
  `ratatui-core = "=0.1.2"` (`Cargo.toml:111-114`) against termrock's
  `ratatui-core = "0.1.2"` — one core type in one lockfile, so
  `ratatui::text::Line` and the painter's `Line` are the same type.

- **Why not `widgets::Text`/`TextSpan`** — considered and rejected:
  `Text::resolve_style` (`crates/termrock/src/widgets/text.rs:526-556`)
  resolves styles from `Role` + emphasis through `DesignSystem` only, and its
  `preserve_bg` path actively strips backgrounds — the brand pill's literal
  bg 0,255,65 / fg black and the three pinned phosphor RGBs cannot be
  expressed. No upstream widget carries the brand look (research ch04 row
  C18: brand header is jackin-owned, no pairing). The buffer-level
  `paint_line_overflow` is the head primitive that preserves per-span literal
  styles; `paint_text` (`text/mod.rs:442`) is documented as "the sanctioned
  painter for titles, labels, and single-line values".

- **The raster API the crop rides** (plan 005 adds the dep; research ch05
  verified at the pin): `termrock_raster::render_png(&Buffer, &RolePalette)`
  and `termrock_raster::compare_png_pixels(&[u8], &[u8])` take only ratatui
  and termrock types — no lookbook types; compare decodes both PNGs and
  reports the first differing pixel with coordinates and both RGBA values at
  zero tolerance (`crates/termrock-raster/src/compare.rs:49-84`); committed
  baseline PNGs need REUSE annotations (jackin runs a REUSE lane; plan 005
  establishes the pattern this plan mirrors).

- **Convention to match** — the upstream bless/test shape this suite
  mirrors: bless mode is just an env var making the test write
  `fs::write(path, first_render)` instead of comparing
  (`crates/termrock-lookbook/tests/png_baselines.rs:26-29,48-52`), and
  in-process render-twice identity is asserted on every run with an explicit
  "PIPELINE BUG … do NOT resolve it by blessing" message
  (`png_baselines.rs:41-46`).

**Planning-time measurements carry the re-derivation rule.** The counts
stamped above — 12 RGB tests, 25 PNG baselines (6 stage + 19 modal), 6 brand
crops (one per non-modal stage view) — are planning-time snapshots: the
executor re-runs the counting command, the fresh number is the authority,
and the delta from the planned figure is stamped in the report, never
treated as a target to reproduce.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Build | `cargo check --workspace --all-targets --locked` | exit 0 |
| Console suite | `cargo nextest run -p jackin-console --locked` | all pass |
| Three-crate brand gate | `cargo nextest run -p jackin-console -p jackin-launch -p jackin-capsule --locked` | all pass, incl. the 12 RGB tests |
| Console RGB tests (3) | `cargo nextest run -p jackin-console -E 'test(/brand_header::tests/)' --locked` | 3 pass |
| Launch header RGB tests (3) | `cargo nextest run -p jackin-launch -E 'test(/header::tests/)' --locked` | 3 pass |
| Launch rail RGB tests (4) | `cargo nextest run -p jackin-launch -E 'test(/progress_rail::tests/)' --locked` | 4 pass |
| Capsule chrome tests (incl. the 2 brand rows) | `cargo nextest run -p jackin-capsule -E 'test(/chrome::tests/)' --locked` | all pass |
| Text-snapshot parity lane | `cargo xtask ci --only snapshots` | exit 0 (snapshots byte-identical) |
| Clippy | `cargo clippy -p jackin-console --all-targets -- -D warnings` | exit 0 |
| Format | `cargo fmt --check` | exit 0 |
| Merge-readiness (fast) | `cargo xtask ci --fast` | exit 0 |

(All forms proven by `research/jackin-verification-tooling/01-gates-and-commands.md`:
package and `-E 'test(/module::tests/)'` filters, the `snapshots` partition =
`cargo nextest run -p jackin-capsule -p jackin-console --locked`, per-crate
clippy, `cargo xtask ci --fast`.)

## Scope

**In scope** (the only files to create or modify):

- `crates/jackin-console/src/tui/components/brand_header.rs` — the rebuild +
  the template doc comment.
- The plan 005 harness location (`<HARNESS_PACKAGE>`), **additively**: one
  new brand-crop suite module; the shared state/render extraction
  (`<STATE_SEAM>`) only if the harness does not already expose it.
- New brand-crop baselines (planning-time: 6 PNGs) in a dedicated
  brand-crop directory the full-screen bless cannot address (step 2 fixes
  the exact location against `<BASELINE_ROOT>`).
- `REUSE.toml` — annotation for the new crop PNGs, mirroring plan 005's
  pattern for its baselines.

**Out of scope** (do NOT touch, even though related):

- `crates/jackin-tui/src/tokens.rs` — the brand constants are the look
  invariant; N1.
- The 12 literal-RGB test files (`brand_header/tests.rs`,
  launch `header/tests.rs`, `progress_rail/tests.rs`, capsule
  `chrome/tests.rs`) — they run unmodified; an edit is an N1-class look
  change.
- Plan 005's full-screen baselines and its bless flow — never re-blessed or
  restructured here; the isolation proof in step 3 must leave them
  byte-identical (`git checkout -- <paths>` if a bless rewrites them with
  identical content showing as churn — report any real diff as a STOP).
- The launch cockpit header duplicate
  (`crates/jackin-launch/src/tui/components/header.rs`) and every other
  brand composition — their surfaces' own phases (B11).
- `crates/jackin-console/src/tui/view.rs`, `layout.rs`, screens, and every
  other console chrome file — plans 006/008–013 territory; the header's
  call sites and geometry are already correct.
- Docs-site TUI pages (`docs/content/reference/tui/`) — plan 014's same-PR
  sweep.
- The TermRock checkout — read-only; an API misfit follows the hub's BLOCKED
  route, never a local edit.

The hub `plans/termrock-migration/README.md` and the roadmap item are
protocol-writable and never listed in scope.

## Git workflow

Commit boundaries for this plan (on the package's execution branch per the
hub):

1. Step 3: `test(console): add BrandHeader PNG crop suite with pre-rebuild baselines`
   — suite module + any additive `<STATE_SEAM>` extraction + blessed crops +
   `REUSE.toml` annotation. The crops are blessed from the CURRENT,
   pre-rebuild header: this commit is the parity gate.
2. Step 4: `refactor(console): rebuild BrandHeader on termrock text paint primitives`
   — `brand_header.rs` only.
3. Step 5: `docs(console): record the brand-proof template at the BrandHeader site`
   — `brand_header.rs` doc comment only.

## Steps

### Step 1: Discover and record the harness contract

Run the five discovery commands from "Inputs to provide" and record
`<HARNESS_PACKAGE>`, `<BASELINE_ROOT>`, `<FULLSCREEN_BLESS_ENV>`,
`<PALETTE>`, and whether `<STATE_SEAM>` is exposed or needs the additive
extraction. Read the harness's compare/bless flow end to end — the brand
suite mirrors its conventions (filename scheme, bless write, failure
message shape).

**Verify**: `cargo nextest run -p <HARNESS_PACKAGE> --locked` → exit 0, and
all five values are written down for the step 3 commit message.

### Step 2: Add the brand-crop suite

One new module in the harness location (e.g. a `brand_header_crop` sibling
of plan 005's baseline suite), reusing `<STATE_SEAM>` so each render is the
identical buffer the full-screen baseline came from. For every NON-modal
stage view in plan 005's inventory (planning-time: the 6 stage views —
workspaces, editor, settings at their canonical sizes; modals paint the
backdrop over row 0 and are excluded):

1. Render the full-screen buffer exactly as the harness does (same state,
   same size, same `<PALETTE>`).
2. Extract row 0 (`y = 0`, full width) into a fresh
   `Buffer::empty(Rect::new(0, 0, width, 1))`, copying each cell.
3. `termrock_raster::render_png(&row_buffer, <PALETTE>)` twice; assert the
   two renders are byte-identical (pipeline-bug guard — never resolved by
   blessing).
4. `termrock_raster::compare_png_pixels` the first render against the
   committed crop baseline at zero tolerance.

Suite rules:

- Crop baselines live in a dedicated brand-crop directory that
  `<FULLSCREEN_BLESS_ENV>` cannot address: inside `<BASELINE_ROOT>` only if
  the harness bless writes per-screen filenames it enumerates (the upstream
  pattern), otherwise a sibling of `<BASELINE_ROOT>`. Record the choice and
  its reason in the step 3 commit message.
- Blessing the crops uses a SEPARATE env var from `<FULLSCREEN_BLESS_ENV>`
  (suggested: `JACKIN_BLESS_BRAND_PNGS=1`; if the harness already provides
  per-suite bless scoping, use that and record it).
- An inventory guard asserts the crop baseline count equals the non-modal
  stage-view count in the inventory (fresh count is the authority).
- Add the `REUSE.toml` annotation for the crop directory, mirroring plan
  005's PNG pattern.

**Verify**: `cargo nextest run -p <HARNESS_PACKAGE> -E 'test(/brand/)' --locked`
→ the suite runs and FAILS reporting missing baselines (proves the compare
path executes); `git status --porcelain` → only the new suite file, the
`REUSE.toml` edit, and any `<STATE_SEAM>` extraction.

### Step 3: Bless the pre-rebuild crops and prove isolation

1. Bless from the CURRENT header:
   `JACKIN_BLESS_BRAND_PNGS=1 cargo nextest run -p <HARNESS_PACKAGE> -E 'test(/brand/)' --no-capture --locked`
   → the crop baselines are written.
2. Immediately re-run compare mode:
   `cargo nextest run -p <HARNESS_PACKAGE> -E 'test(/brand/)' --locked`
   → exit 0.
3. Isolation proof (spec scenario "Chrome churn does not touch the brand
   baseline"): run plan 005's full-screen bless
   (`<FULLSCREEN_BLESS_ENV>=1 cargo nextest run -p <HARNESS_PACKAGE> --no-capture --locked`),
   then `git status --porcelain` → NO brand-crop path appears, and any
   full-screen baseline that appears is byte-identical churn
   (`git diff --stat` empty for it after `git checkout -- <path>`); a real
   full-screen diff means the tree was dirty before the bless — STOP.
4. Re-run the brand suite → exit 0 (the full-screen bless left it
   untouched and passing).
5. Commit per "Git workflow" commit 1.

**Verify**: after the commit, `git show --stat HEAD` lists only the suite
module, the crop PNGs, the `REUSE.toml` line, and any `<STATE_SEAM>`
extraction; the brand suite passes from a clean tree.

### Step 4: Rebuild the header on the head painter

Rewrite `crates/jackin-console/src/tui/components/brand_header.rs`:

- `BrandHeader::render` calls
  `termrock::text::paint_line_overflow(buffer, area, &brand_header_line(self.label), Style::default(), LinePlacement::clipped("…"), &mut scratch)`
  where `scratch` is a local `String::new()` — replacing the
  `Paragraph::new(...).alignment(Alignment::Left).render(...)` body. The
  `Paragraph`/`Alignment` imports go; `Line`/`Span`/`Style`/`Modifier` stay.
- `brand_header_line`, the `BrandHeader` struct, and
  `render_brand_header(frame, area, label)` keep their exact current shapes
  and signatures — the three call sites (`view.rs:389`,
  `settings/view.rs:177`, `editor/view/frame.rs:107`) and the header
  geometry are untouched.
- The spans, tokens, glyphs, and modifiers are byte-for-byte the current
  ones (N1). If `paint_line_overflow` at the pinned rev cannot reproduce
  the render (any crop diff after a correct implementation), this is a
  TermRock API misfit: STOP and follow the hub's BLOCKED route with the
  concrete gap — never compensate by editing spans, tokens, tests, or
  baselines.

**Verify** (all against the UNMODIFIED gates):

- `cargo nextest run -p <HARNESS_PACKAGE> -E 'test(/brand/)' --locked` →
  exit 0, zero crop diffs, baselines untouched
  (`git status --porcelain` shows no PNG path).
- The 12 literal-RGB tests: the four per-module commands from "Commands you
  will need" → 3 + 3 + 4 + (chrome module all) pass.
- `cargo xtask ci --only snapshots` → exit 0 (text snapshots byte-identical;
  a diff is a parity break — STOP, never re-bless).
- `cargo check --workspace --all-targets --locked`,
  `cargo clippy -p jackin-console --all-targets -- -D warnings`,
  `cargo fmt --check` → exit 0.
- Commit per "Git workflow" commit 2.

### Step 5: Record the template at the site

Extend the `brand_header.rs` module doc (`//!` header) with a short
"Brand-proof template" block later phases copy:

- the proof is a zero-tolerance PNG crop of row 0 per non-modal stage view,
  baselined in the dedicated brand-crop directory, blessed only through the
  brand bless env var — never by a surrounding screen's re-bless;
- the 12 literal-RGB span tests are the standing value-level gate and are
  never edited to match new output;
- a brand-crop diff outside an intended brand change is a parity break:
  STOP for operator review, never re-bless silently;
- launch rain/warp/rail and the capsule pill copy this mechanism at their
  own phases.

**Verify**: `cargo fmt --check` and
`cargo clippy -p jackin-console --all-targets -- -D warnings` → exit 0;
commit per "Git workflow" commit 3.

### Step 6: Final gate

**Verify**: `cargo xtask ci --fast` → exit 0; `git status --porcelain` →
only protocol writes remain.

## Test plan

- The brand-crop suite (step 2) is the new test surface, in the harness
  location, modeled on plan 005's baseline suite and the upstream
  `png_baselines.rs` shape (per-artifact compare, env-var bless, render-twice
  identity guard). One spec scenario per check:
  - "Header across console stages" — one crop compare per non-modal stage
    view at its canonical size.
  - "Value-level gate survives the rebuild" — the 12 literal-RGB tests run
    unmodified (independent expected values: literal `Color::Rgb` tuples,
    never recomputed from the code under test).
  - "Chrome churn does not touch the brand baseline" — command-verified in
    step 3 (full-screen bless leaves crops untouched and passing), not a
    test.
  - "Template reusable" — the step 5 doc comment plus this plan's
    maintenance notes; verified by review, not a test.
- Edge cases covered by construction: narrow-width contraction uses
  `CellOverflow::Clip` — `Paragraph`'s own behavior — so the truncated
  render is identical; the render-twice guard catches nondeterminism; the
  inventory guard catches a silently dropped stage view.
- Expected values come from artifacts blessed BEFORE the rebuild (the
  pre-rebuild crop PNGs) and from literal RGB tuples — never from the
  rebuilt code's own output.

**Verify**: `cargo nextest run -p jackin-console -p jackin-launch -p jackin-capsule --locked`
→ all pass, including the 12 RGB tests and the crop suite (count = the
re-derived non-modal stage-view count).

## Done criteria

Machine-checkable. ALL must hold, each cited from this session's output:

- [ ] `cargo check --workspace --all-targets --locked` exits 0
- [ ] `cargo nextest run -p jackin-console -p jackin-launch -p jackin-capsule --locked`
      exits 0; the 12 literal-RGB tests pass UNMODIFIED
      (`git diff f320b51f..HEAD --stat -- <the four test files>` is empty)
- [ ] The brand-crop suite passes with zero tolerance against baselines
      blessed from the pre-rebuild header; the crop count equals the
      re-derived non-modal stage-view count
- [ ] Isolation held: the step 3 full-screen bless left every brand-crop
      baseline untouched (`git status --porcelain` showed no crop path) and
      the suite passed after it
- [ ] `cargo xtask ci --only snapshots` exits 0 (console text snapshots
      byte-identical)
- [ ] `cargo fmt --check` and
      `cargo clippy -p jackin-console --all-targets -- -D warnings` exit 0
- [ ] `git diff f320b51f..HEAD -- crates/jackin-tui/src/tokens.rs` is empty
      (N1 — tokens untouched)
- [ ] The `brand_header.rs` module doc carries the brand-proof template
      block
- [ ] `cargo xtask ci --fast` exits 0
- [ ] No files outside the in-scope list modified (`git status`) —
      excluding the protocol writes: `plans/termrock-migration/README.md`
      status rows and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails, or "Starting state" does not match reality.
- The brand-crop compare fails after the rebuild — that is a parity break:
  NEVER re-bless a crop in this plan; report the first-differing-pixel
  output and stop.
- Any of the 12 literal-RGB tests fails unmodified, or passing them seems to
  require editing them, the tokens, or the spans (N1).
- `cargo xtask ci --only snapshots` reports a text-snapshot diff (the
  package's byte-identical rule — operator review, never re-bless).
- `paint_line_overflow` (or its `LinePlacement`/`CellOverflow` family)
  differs at the pinned rev from the cited signature, or cannot reproduce
  the render byte-identically — a TermRock API misfit: follow the hub's
  BLOCKED route (`termrock API misfit — recommend upstream change: <one
  line>`), do not edit the checkout.
- Plan 005's harness is absent, red, lacks a bless path, or exposing
  `<STATE_SEAM>` needs more than additive, behavior-preserving extraction.
- The full-screen bless writes into the brand-crop set and the suite layout
  cannot be fixed additively inside the harness location.
- A step's verification fails twice after a reasonable fix attempt.
- The work requires touching an out-of-scope file or violating a Must NOT.
- The assumption "A5" (ch04-verified APIs at `e1d61f4d` persist at pin
  `29a16b5b`) turns out false for the cited text primitives.

## Maintenance notes

- **The brand-proof template (this plan's recorded mechanism — copy it for
  launch rain/warp/rail and the capsule pill at their owning phases):**
  (1) bless a dedicated zero-tolerance PNG crop of the composition's exact
  region from the PRE-rebuild render, as the first step, in a directory the
  surrounding screens' bless cannot address; (2) keep the bump phase's
  literal-RGB span tests as the unmodified value-level gate; (3) rebuild,
  then require the crop compare and the RGB tests to pass with zero changes
  to baselines, tests, or tokens; (4) any crop diff outside an intended
  brand change is a parity break — STOP for operator review, never re-bless
  silently; re-bless only as a deliberate, reviewed act like any baseline.
- **Plan interactions**: plan 014's deliberate full-screen re-bless must
  leave this crop set untouched, and its final parity proof set (B16)
  includes this suite; plans 008–013 modernize the chrome AROUND the header
  — any of them tripping a crop diff is their parity break, not a reason to
  re-bless here; the launch and capsule brand rebuilds cite this mechanism
  instead of re-deriving it (B11).
- **Reviewer scrutiny**: the crops were blessed before the rebuild (commit
  order), the RGB tests and `tokens.rs` are untouched, the isolation proof
  was run and recorded, and the rebuild diff is confined to
  `brand_header.rs`'s render path.
- **Deferred**: the launch cockpit header duplicate (`header.rs`) and every
  non-console brand composition — their surfaces' own phases (B11);
  keyboard_help PNG baselining — plan 012.
