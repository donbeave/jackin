# Plan 004: Align the TUI docs with the post-bump API surface, fix the stale surface path, verify the chord-glyph mirror, and prove merge-readiness

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: MED (the full `cargo xtask ci` lane is the package's merge-readiness evidence; it can surface failures the earlier plans' narrower lanes never ran)
- **Depends on**: `plans/termrock-migration/003-*.md` (Brand compensation, background pick, snapshot re-baseline)
- **Covers**: B4 (TUI docs same-PR: three pages + the AGENTS.md path), B7 (drift-check half: the `hint.rs` mirror)
- **Guardrails**: N1 (inlined below)
- **Research basis**: `research/jackin-verification-tooling/01-gates-and-commands.md`
- **Planned at**: commit `d554dca8`, 2026-08-19

## Why this matters

The bump deletes or renames TermRock APIs that three contributor-docs pages name in prose, so after plans 002–003 land the code is correct and the documentation is actively wrong — the repository's docs-as-source-of-truth gate requires them to move in the same PR. One AGENTS.md table row already points at a directory (`src/console/tui/`) that does not exist in this workspace, sending every future TUI contributor to a dead path. One capsule comment claims to mirror an upstream convention that the head may have changed. After this plan: every API name in `docs/content/reference/tui/` matches the shipped head, the TUI surface table names real directories, the mirror claim is verified against the head (or corrected), and the full `cargo xtask ci` gate has passed on the finished diff — the evidence the operator needs to merge.

## Preconditions — run before anything else

Run from the repository root. Any failed precondition is a STOP.

- Plan 003 landed (hub row): `rg -n '^\| 003 ' plans/termrock-migration/README.md` → the Status column reads `DONE`.
- The pin is at head: `rg -n 'termrock = ' Cargo.toml` → the line contains `rev = "e1d61f4d67ea6f0f3adee578caa2c5dba642217e"`. (Planning-time value at `Cargo.toml:118` was the old pin `rev = "5ff94ee117fd4a1b72fdd0d1b1847815055a93ac"`; seeing the old rev means 002 has not landed → STOP.)
- Cheapest 003 done criterion re-run (snapshots re-blessed and green): `cargo xtask ci --only snapshots` → exit 0.
- Toolchain present: `cargo xtask ci --help` → exit 0 and prints the partition list (`lint, policy, tests, powerset, docs, snapshots, e2e`).
- Docs-site toolchain present (needed by step 8): `bun --version` → `1.3.14` (pinned in `mise.toml`; a different version is not a STOP, a missing `bun` is — run `mise install`).
- Drift check: `git diff --stat d554dca8..HEAD -- docs/content/reference/tui/ AGENTS.md crates/jackin-capsule/src/tui/components/dialog/hint.rs`
  - Expected: **no** changes under `docs/content/reference/tui/` and **none** in `AGENTS.md` (this plan owns those edits). Any change there means someone else edited this plan's territory → compare the "Starting state" excerpts against the live files; a mismatch is a STOP.
  - `crates/jackin-capsule/src/tui/components/dialog/hint.rs` **may** show changes (plan 002 migrated renamed TermRock APIs across the capsule). That is expected: re-read the live file and treat it — not the excerpt below — as the authority for step 7.

## Spec contract

The requirements this plan implements, inlined **verbatim** from the spec — the executor does not read `spec/`:

### Requirement: Dead-name docs pages updated in the bump PR

The bump PR SHALL update the three pages pinning soon-dead termrock names so every named API matches the head: `docs/content/reference/tui/visual-design.mdx` (lines 10, 24, 64, 76: `Theme::default().style(role)`, `PanelEmphasis::Focused/Normal`), `docs/content/reference/tui/dialogs.mdx` (line 174: "FocusRing + ModalStack lifecycle"), `docs/content/reference/tui/navigation.mdx` (lines 24, 26, 142, 249, 359: `FocusRing`, `PanelEmphasis`) — and SHALL re-grep all of `docs/content/reference/tui/` for remaining dead names as the closing check.

#### Scenario: No dead API names in TUI docs

- **WHEN** `rg -n "PanelEmphasis|FocusRing|ModalStack|Theme::default" docs/content/reference/tui/` runs after the docs update
- **THEN** zero hits remain (or each remaining hit is a deliberate historical reference explicitly marked as such)

### Requirement: Stale AGENTS.md surface path fixed

The bump PR SHALL fix the AGENTS.md TUI table's host-console row from the nonexistent `src/console/tui/` to the real surfaces (`crates/jackin-console/src/tui/` and `crates/jackin/src/console/`), keeping the CLAUDE.md symlink arrangement untouched.

#### Scenario: TUI table points at real directories

- **WHEN** the AGENTS.md TUI surface table is read after the fix
- **THEN** every directory it names exists in the repository

### Requirement: chord_glyph mirror drift check

The bump PR SHALL verify the comment-level convention mirror at `crates/jackin-capsule/src/tui/components/dialog/hint.rs:25` ("Mirrors the `Ctrl-` prefix convention used by `termrock::keymap::chord_glyph`") still matches the head's `chord_glyph` behavior, updating the jackin❯ hint formatting or the comment if the convention drifted.

#### Scenario: Mirror verified against head

- **WHEN** the head's `chord_glyph` output for a Ctrl-chord is compared with the capsule hint formatting
- **THEN** they agree, or the divergence is fixed on the jackin❯ side in the same PR

Done means these scenarios hold; the test plan below exercises them.

## Must NOT

Guardrails inlined verbatim from the must-not registry, with reasons. These override anything a step seems to imply:

- **N1**: The migration MUST NOT move any brand composition (BrandHeader, digital rain, launch animation/warp, launch progress rail, capsule brand pill) into TermRock, and MUST NOT change their visual identity — upstream 0331 declined absorption; item Decisions 2026-08-19 make ownership and look invariants.
  - **How N1 binds this plan**: the docs edits must keep the documented ownership of brand compositions intact. `docs/content/reference/tui/visual-design.mdx` today documents product-owned tokens (`BRAND_BLOCK`, `DEBUG_AMBER`, `STATUS_BLOCKED_RED`, `MENU_*`, `ACTION_ACCENT`, `DISCLOSURE_ACCENT`, `LINK_BLUE`, rain RGB) as living in `jackin-brand` / `jackin_tui::tokens`. Do **not** re-document any brand composition or brand token as a TermRock component, and do not "simplify" a product-owned row into the TermRock row while renaming the neutral API names beside it.

## Inputs to provide

- `<TERMROCK_CHECKOUT>` — a local checkout of the TermRock repository at the pinned head `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`, used **read-only** as the authority for the head's `chord_glyph` behavior. Needed by step 7.
  - On this machine it is at `/Users/donbeave/Projects/tailrocks/termrock` (verify: `git -C /Users/donbeave/Projects/tailrocks/termrock rev-parse HEAD` → `e1d61f4d67ea6f0f3adee578caa2c5dba642217e`).
  - If absent or at a different rev: clone it — `git clone https://github.com/tailrocks/termrock.git <somewhere-outside-this-repo> && git -C <somewhere-outside-this-repo> checkout e1d61f4d67ea6f0f3adee578caa2c5dba642217e` — and use that path as `<TERMROCK_CHECKOUT>`. Do NOT clone inside this repository.
  - Second fallback (no network): Cargo's own vendored checkout of the pinned rev, `~/.cargo/git/checkouts/termrock-*/e1d61f4/`. Confirm the directory exists before relying on it: `ls -d ~/.cargo/git/checkouts/termrock-*/e1d61f4`. Do NOT block waiting for either — the fallback is materialized by the build that plan 002 already ran.

Everything else is inside the repository and is referenced repo-relative.

## Starting state

All excerpts re-read at planning time (commit `d554dca8`). The repository's post-002/003 state is the authority at execution — where an excerpt below disagrees with the live file, follow the drift-check rule in the preconditions.

**Dead-name survey (`rg -n "PanelEmphasis|FocusRing|ModalStack|Theme::default" docs/content/reference/tui/`, 2026-08-19 → 10 hits across 3 files).** This is a planning-time measurement: re-run the command in step 1 and stamp the fresh count; the fresh number is the authority, not this one.

- `docs/content/reference/tui/visual-design.mdx:10` — "resolve neutral presentation with `Theme::default().style(Role::…)` so ordinary,"
- `docs/content/reference/tui/visual-design.mdx:24` — table row: "| TermRock `Role` | `Text`, `TextStrong`, `TextMuted`, `Border`, `BorderFocused`, `Accent`, `Danger`, `Warning`, `Tab*`, `Link*`, `Scroll*` | Shared presentation via `Theme::default().style(role)` |"
- `docs/content/reference/tui/visual-design.mdx:64` — "…The paint path maps `focused = true` → `PanelEmphasis::Focused` with no overflow gate."
- `docs/content/reference/tui/visual-design.mdx:76` — "TermRock `Viewport` paints border emphasis from `PanelEmphasis`. Console scrollable panels go through `scroll_block::render_scrollable_block_at`, which maps the caller's `focused` flag to `PanelEmphasis::Focused` / `Normal`. …"
- `docs/content/reference/tui/dialogs.mdx:174` — "The shared mechanism for this contract is TermRock's atomic `FocusRing` + `ModalStack` lifecycle, projected into product state by `jackin_tui::runtime::ModalFlow`. `open_sub` preserves the visible product modal while opening its matching focus scope, `pop` restores both parent and scope for Esc/cancel, and `clear` closes the whole chain after a terminal commit. Product code tests its modal transitions through `ModalFlow`; TermRock owns the primitive focus/stack conformance tests."
- `docs/content/reference/tui/navigation.mdx:24` — "1. `jackin_tui::runtime::SurfaceFocus<Target>` is the product projection over TermRock's `FocusRing` for tabbed screens. …"
- `docs/content/reference/tui/navigation.mdx:26` — "3. `PanelEmphasis` is border styling only. It is computed from screen-level or dialog-level focus state when rendering; do not store it as independent state."
- `docs/content/reference/tui/navigation.mdx:142` — "…Content blocks derive their `PanelEmphasis` from `!tab_bar_focused && scroll_focused`. …"
- `docs/content/reference/tui/navigation.mdx:249` — "TermRock `Viewport` (console `scroll_block` adapter) paints `PanelEmphasis` from the caller's `focused` flag with **no overflow gate**. …"
- `docs/content/reference/tui/navigation.mdx:359` — "…Use `focused = parent.list_names_focused` (or equivalent), never hardcoded `PanelEmphasis::Normal` when the parent owns interaction. …"

**Two stale repository paths on the same in-scope pages** (same defect class as the AGENTS.md row; neither directory exists — this workspace has no root `src/`):

- `docs/content/reference/tui/dialogs.mdx:164` — "**Applies to every TUI surface jackin❯ renders — host console (`src/console/`) and the in-container multiplexer (`crates/jackin-capsule/`).**"
- `docs/content/reference/tui/navigation.mdx:196` — "- Every root-console modal widget such as `src/console/tui/op_picker/` must expose a `footer_items` function (or equivalent) and remove its internal hint row."

**AGENTS.md TUI surface table** (`AGENTS.md:91-96`, verbatim):

```markdown
| Surface | Directory |
|---|---|
| Shared components | [TermRock](https://github.com/tailrocks/termrock) |
| Capsule | `crates/jackin-capsule/src/tui/` |
| Host console | `src/console/tui/` |
| Lookbook | [TermRock catalog](https://github.com/tailrocks/termrock/tree/main/docs) |
```

Line 95 is the defect. Real host-console surfaces, both verified present at planning time: `crates/jackin-console/src/tui/` (contains `auth.rs`, `components.rs`, `console.rs`, `debug.rs`, …) and `crates/jackin/src/console/` (contains `adapter.rs`, `effects.rs`, `services.rs`, …). `CLAUDE.md` is a symlink to `AGENTS.md` (`CLAUDE.md -> AGENTS.md`, 9 bytes) — edit `AGENTS.md` in place; never delete/recreate either file.

**The capsule mirror comment** (`crates/jackin-capsule/src/tui/components/dialog/hint.rs:23-34`, verbatim at planning time):

```rust
/// Derive a display glyph for a raw palette-key byte.
///
/// Mirrors the `Ctrl-` prefix convention used by [`termrock::keymap::chord_glyph`]
/// so the hint bar is visually consistent regardless of which key the operator
/// configured via `JACKIN_PALETTE_KEY`.
fn format_key_glyph(byte: u8) -> String {
    match byte {
        0x01..=0x1A => format!("Ctrl-{}", (b'@' + byte) as char),
        0x1C => "Ctrl-\\".to_owned(),
        _ => format!("0x{byte:02X}"),
    }
}
```

Its existing tests live at `crates/jackin-capsule/src/tui/components/dialog/hint/tests.rs:164-172`: `format_key_glyph_ctrl_backslash` asserts `format_key_glyph(0x1C) == "Ctrl-\\"`, `format_key_glyph_ctrl_e` asserts `format_key_glyph(0x05) == "Ctrl-E"`. Hint text also appears in assertions higher in that file (e.g. `hint.contains("Ctrl-\\ menu")` at lines 28 and 85, `"Ctrl-Q quit"` at line 108).

**The head's `chord_glyph`** (`<TERMROCK_CHECKOUT>/crates/termrock/src/keymap.rs:585-606`, read at planning time from the checkout at `e1d61f4d`):

```rust
/// Derive the hint-bar key glyph from a chord.
///
/// Reproduces the exact glyphs already in use across the codebase so output is
/// byte-identical to hand-written hints. Callers that need a *grouped* glyph
/// (e.g. `"↑↓"` for a pair of bindings) should set [`KeyBinding::glyph`]
/// instead of relying on this function.
///
/// Returns `""` when `chord` is `None`. Returns `"?"` for Char values not in
/// the common-shortcut set — callers must supply an explicit `glyph` for those.
#[must_use]
pub fn chord_glyph(chord: Option<KeyChord>) -> &'static str {
    let Some(chord) = chord else { return "" };
    match chord.key {
        KeyCode::Char(c) if chord.mods.contains(KeyModifiers::CONTROL) => {
            match c.to_ascii_lowercase() {
                'q' => "Ctrl-Q",
                'c' => "Ctrl-C",
                'l' => "Ctrl-L",
                'h' => "Ctrl-H",
                _ => "Ctrl-?",
            }
        }
```

So at the head the Ctrl-chord convention is `Ctrl-` + the uppercased key, with an explicit `"Ctrl-?"` fallback for chars outside the known set, and the documented expectation that callers supply their own glyph for those. Step 7 turns this reading into an executed comparison.

**Planning-time observations about the head's replacement names** — snapshots only, **not** targets to reproduce. The authority for what the docs must say is the post-002 jackin❯ code, which the executor reads in step 1:

- `PanelEmphasis` is gone; the head's sole chrome enum is `PanelChrome`, re-exported from `style::tokens` (`<TERMROCK_CHECKOUT>/crates/termrock/src/style/mod.rs:58-62`) and consumed by `widgets/panel.rs:26,490,519,632,639,722`. `crates/termrock/src/lib.rs:139-140` asserts "PanelEmphasis must be PanelChrome only".
- `FocusRing` and `ModalStack` still exist but are **crate-private** at the head — `interaction/mod.rs:38-41` ("FocusRing remains crate-private (pre-1.0 M3). Public focus graph is FocusGraph." / "Overlay authority is OverlayStack only (Break D / M4). ModalStack is crate-private.") and `interaction/mod.rs:50`. The public surface is `FocusGraph` (`interaction/mod.rs:27`), `OverlayStack` (`interaction/mod.rs:55`), and `InteractionScene` (`interaction/mod.rs:59`); `lib.rs:58-67,166-167` enforces both privacy rules.
- The `Role` enum survives (`style/mod.rs:120`, resolved by a `RolePalette`), but there is no public `Theme` type at the head — `style/mod.rs:58-62` exports `DesignSystem`, `ThemePackage`, `PanelChrome`, `FocusEmphasis`, etc. So `Theme::default().style(Role::…)` is a dead spelling even where `Role` is still correct.
- Pre-bump, `crates/jackin-tui/src/runtime/modal_flow.rs:6` imported `termrock::interaction::{FocusRing, ModalStack}` and `crates/jackin-tui/src/runtime/focus.rs:6` imported `termrock::interaction::FocusRing`; the public product API was `ModalFlow` (`open`, `open_sub`, `pop`, `clear`, `current`, `parents`, …) and `SurfaceFocus` / `SurfaceFocusTarget` (`crates/jackin-tui/src/runtime.rs:12-16`). Plan 002 re-hosted these internals on the head's public primitives while preserving that product-facing contract — step 1 confirms what it actually produced.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Merge-readiness gate (this package's evidence) | `cargo xtask ci` | exit 0 |
| Docs partition alone (inner loop) | `cargo xtask ci --only docs` | exit 0 |
| Repo-path link gate | `cargo xtask docs repo-links` | exit 0 |
| Brand-prose gate | `cargo xtask docs brand` | exit 0 |
| Capsule hint tests | `cargo nextest run -p jackin-capsule -E 'test(/hint::tests/)'` | all pass |
| Snapshot lane (regression check after any hint change) | `cargo xtask ci --only snapshots` | exit 0 |
| Docs-site gate (run from `docs/`, only when a page under `docs/content/` changed) | see block below | exit 0 |

Docs-site block, copy-pasted from `.github/PULL_REQUEST_TEMPLATE.md:183-193` (the extra `cargo xtask research check` line comes from `PULL_REQUESTS.md:204`; the template block omits it):

```sh
(
  cd docs
  bun install --frozen-lockfile
  bun run build
  cargo xtask docs repo-links
  cargo xtask roadmap audit
  cargo xtask research check
  bunx tsc --noEmit
  bun test
)
```

Command provenance (research `research/jackin-verification-tooling/01-gates-and-commands.md`):

- §Merge-readiness gates: `cargo xtask ci --help` prints "`--only` is a local-dev tool; merge readiness is the full `ci` (or `ci --fast` without powerset)". **Use the full `cargo xtask ci`, not `--fast`.** `--fast` skips the `powerset` partition (`cargo hack check --workspace --feature-powerset --all-targets --locked`), and this PR moved a workspace-wide dependency pin — feature-combination fallout is exactly what that lane catches. The chapter's partition table: lint = actionlint + `cargo fmt --check` + `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` + `cargo xtask lint --strict`; tests = `cargo check --workspace --all-targets --locked` + `cargo nextest run --workspace --all-features --locked` + `cargo test --doc --workspace --locked`; policy = `cargo audit` + `cargo deny check advisories bans licenses sources` + `cargo xtask schema-check --base origin/main` + `cargo shear --deny-warnings`; powerset = the `cargo hack` line above; docs = `cargo xtask roadmap audit` + `cargo xtask docs repo-links` + `cargo xtask research check`; snapshots = `cargo nextest run -p jackin-capsule -p jackin-console --locked`.
- Same chapter, §Docs gate: the xtask `docs` partition is **bun-free** (exactly those three commands); the bun-side checks are a separate docs-site gate run from `docs/`, required before docs-touching PRs are merge-ready per PULL_REQUESTS.md:38 and :128.
- Same chapter, Dead ends: `mise run ci` is **not** equivalent — it runs only `policy`, `docs`, `snapshots`. Do not substitute it.
- `cargo xtask docs brand` is not in the xtask `ci` docs partition; it is a docs-workflow gate (`crates/jackin-xtask/src/docs.rs:189-196`; `.github/workflows/docs.yml:257-259`). Run it here because this plan edits brand-bearing prose.

## Scope

**In scope** (the only files to create or modify):

- `docs/content/reference/tui/visual-design.mdx`
- `docs/content/reference/tui/navigation.mdx`
- `docs/content/reference/tui/dialogs.mdx`
- `AGENTS.md` — the single TUI-surface table row at line 95 (splitting it into a console row `crates/jackin-console/src/tui/` and an adapter row `crates/jackin/src/console/` is the expected shape; touch no other table row)
- `crates/jackin-capsule/src/tui/components/dialog/hint.rs` — **comment text only**, unless step 7 proves a real convention divergence, in which case the `format_key_glyph` body may change too
- `crates/jackin-capsule/src/tui/components/dialog/hint/tests.rs` — **conditionally**, only to update assertions that a step-7 output change invalidates
- The PR body (step 9) — a GitHub artifact, not a repository file

**Out of scope** (do NOT touch, even though related):

- Any other source file. Plan 002 owns the API migration; plan 003 owns brand compensation and the background pick. If a docs sentence is wrong because the *code* is wrong, that is a 002/003 defect → STOP and report, do not fix the code here.
- `*.snap` files anywhere. Re-baselining is plan 003's territory; if a step-7 change moves rendered hint output into a snapshot diff, that is a STOP (see STOP conditions).
- `Cargo.toml`, `Cargo.lock`, `deny.toml`, `.cargo/audit.toml` — plan 002's territory.
- Other pages under `docs/content/` (including `docs/content/reference/tui/components.mdx` and `architecture.mdx`) unless the closing grep in step 5 reports a dead name there — then extend only to the offending line and say so in the report.
- `CLAUDE.md` (the symlink), `RULES.md`, `PROJECT_STRUCTURE.md`, roadmap item content beyond the protocol writes.

The hub `plans/termrock-migration/README.md` and the roadmap item are protocol-writable and never listed in scope.

## Git workflow

Only what is specific to this plan (the hub carries the branch, sign-off, and push-after-every-commit law):

- Commit 1 — docs + surface path (steps 2–6): `docs(tui): align TUI reference pages with the TermRock head`
- Commit 2 — only if step 7 changes anything: comment-only fix → `docs(capsule): correct the chord-glyph mirror note`; formatting fix → `fix(capsule): match the head chord-glyph convention in dialog hints`
- Commit 3 — the hub status flip for row 004, committed together with the work it records per the hub protocol.

If step 7 finds no divergence, there is no commit 2 — record the comparison output in the report instead.

## Steps

### Step 1: Read the post-002 reality before writing a word of documentation

Do not edit any `.mdx` yet. Establish what the code now says:

1. Re-run the survey and record the fresh hit count (planning-time figure: 10 hits / 3 files — a different number is fine; stamp yours and note the delta):

   ```sh
   rg -n "PanelEmphasis|FocusRing|ModalStack|Theme::default" docs/content/reference/tui/
   ```

2. Read the post-002 re-host: `crates/jackin-tui/src/runtime.rs`, `crates/jackin-tui/src/runtime/modal_flow.rs`, `crates/jackin-tui/src/runtime/focus.rs`. Write down, for your own use in steps 2–4: which TermRock types `ModalFlow` and `SurfaceFocus` are now built on (the `use termrock::…` lines are the answer), and whether the product-facing methods (`open`, `open_sub`, `pop`, `clear`; `SurfaceFocus::tab_bar`/`content`/`focused`/`is_content`) still exist with the same names.
3. Find the head's replacement for the border-emphasis enum as *this workspace uses it*: `rg -n "PanelChrome|PanelEmphasis" crates/ --type rust | head -40`, plus the console adapter the docs name: `rg -n "fn render_scrollable_block_at" -A 20 crates/jackin-console/src/tui/`.
4. Find how this workspace now resolves a neutral role style (the replacement for `Theme::default().style(Role::…)`): `rg -n "Role::" crates/jackin-console/src/tui/ crates/jackin-capsule/src/tui/ | head -20` and `rg -n "use termrock::style::" crates/ --type rust | head -20`.

**Verify**: all four commands ran and you can name, in one sentence each, (a) the type that replaced `PanelEmphasis` in this workspace, (b) the call shape that replaced `Theme::default().style(role)`, (c) what `ModalFlow` is built on now. If any of the three has no answer in the code, STOP (see STOP conditions).

### Step 2: Rewrite the dead names in `docs/content/reference/tui/visual-design.mdx`

Update lines 10, 24, 64, and 76 (line numbers from the starting state; locate by text, not by number) so every named API is the one step 1 found in the code:

- Line 10 prose and the line-24 table cell: replace the `Theme::default().style(Role::…)` / `Theme::default().style(role)` spelling with the real resolution path. Keep the row's meaning — TermRock owns neutral presentation via semantic roles — and keep the `Role` variant list accurate against `<TERMROCK_CHECKOUT>/crates/termrock/src/style/mod.rs` (the `Role` enum): drop or rename any variant the head no longer has.
- Lines 64 and 76: replace `PanelEmphasis::Focused` / `PanelEmphasis::Normal` / bare `PanelEmphasis` with the chrome type step 1 identified, keeping the documented behavior (focused ⇒ bright border, no overflow gate; passive blocks clear focus when content fits).
- **N1 check**: leave the product-token row (line 25) and the `jackin-brand` / `jackin_tui::tokens` ownership sentences (lines 12-20) exactly as they are — this step renames TermRock APIs only.

Keep every paragraph on one line (docs prose is never hard-wrapped) and keep the brand spelled as the hub's brand law requires.

**Verify**: `rg -n "PanelEmphasis|Theme::default" docs/content/reference/tui/visual-design.mdx` → no output.

### Step 3: Rewrite the dead names in `docs/content/reference/tui/navigation.mdx`

- Line 24: `SurfaceFocus<Target>` is "the product projection over TermRock's `FocusRing`" — replace `FocusRing` with whatever `crates/jackin-tui/src/runtime/focus.rs` actually builds on after 002. If 002 made the projection sit on a public head primitive, name that primitive; if the product type is now self-contained, say that instead. Do not invent a name that does not appear in the code.
- Lines 26, 142, 249, 359: replace `PanelEmphasis` / `PanelEmphasis::Normal` with the step-1 chrome type, preserving each sentence's rule (border styling is derived, never stored; content blocks derive it from focus; the viewport paints it with no overflow gate; inline pickers inherit the parent's focus).
- Line 196: replace the nonexistent `src/console/tui/op_picker/` with the real path. Verify before writing: `ls -d crates/jackin-console/src/tui/op_picker 2>/dev/null || rg -ln "op_picker" crates/jackin-console/src crates/jackin/src | head`. Keep it a plain code span with a trailing `/` — `cargo xtask docs repo-links` only demands a link component for paths that resolve to a **file** (`crates/jackin-xtask/src/docs.rs:964-992`, `existing_repo_file` ends in `is_file()`), so a directory path stays a code span.

**Verify**: `rg -n "PanelEmphasis|FocusRing|src/console" docs/content/reference/tui/navigation.mdx` → no output.

### Step 4: Rewrite `docs/content/reference/tui/dialogs.mdx:174` to describe the post-002 hosting truthfully

Line 174 currently claims the mechanism is "TermRock's atomic `FocusRing` + `ModalStack` lifecycle, projected into product state by `jackin_tui::runtime::ModalFlow`". Rewrite it from what step 1 read in `crates/jackin-tui/src/runtime/modal_flow.rs`:

- Name the primitives `ModalFlow` is *actually* built on now.
- Keep the product contract sentences that are still true: `open_sub` preserves the visible parent while opening its child scope, `pop` restores parent and scope for Esc/cancel, `clear` closes the chain after a terminal commit, product code tests transitions through `ModalFlow`, TermRock owns the primitive conformance tests. Verify each against the live method list before keeping it — if 002 renamed a method, use the new name.
- Also fix line 164's stale `src/console/` to the real host-console surface (same correction as step 6's table row: `crates/jackin-console/src/tui/` and/or `crates/jackin/src/console/`). Same code-span rule as step 3.
- Line 170 must ALSO be updated: `termrock::interaction::classify_click` is `pub(crate)` at head (`interaction/modal.rs:135`; only `render_backdrop` is re-exported from `modal` — `interaction/mod.rs:52`), so post-bump it is a dead public spelling. Describe what plan 002's re-host actually calls instead (read the post-002 code — e.g. `OverlayStack::handle_outside_click` or the jackin-side geometry predicates). Lines 176-182: leave alone unless they name a symbol that no longer exists.

**Verify**: `rg -n "FocusRing|ModalStack|classify_click" docs/content/reference/tui/dialogs.mdx` → no output, and `rg -n "src/console/" docs/content/reference/tui/dialogs.mdx` prints only lines whose full path is `crates/jackin/src/console/…` or `crates/jackin-console/src/…` (line 164's replacement must be one of those two real directories — never a bare `src/console/`).

### Step 5: Closing grep over the whole TUI docs tree (spec scenario 1)

```sh
rg -n "PanelEmphasis|FocusRing|ModalStack|Theme::default" docs/content/reference/tui/
```

**Verify**: no output. If a hit remains, it is only acceptable when the surrounding sentence explicitly marks it as a historical reference (e.g. "before the 2026 TermRock bump this was `PanelEmphasis`"); paste any such line into the report with its justification. A hit on a page outside this plan's three files means the survey under-counted — fix that one line and name the file in the report.

### Step 6: Fix the AGENTS.md TUI surface table row (spec scenario 2)

In `AGENTS.md`, replace the host-console row (line 95, `| Host console | \`src/console/tui/\` |`) so it names the directories that exist. Both real surfaces must be reachable from the table — either as one row listing both paths, or as two rows. Suggested shape (adapt to what actually exists):

```markdown
| Host console (TUI) | `crates/jackin-console/src/tui/` |
| Host console (adapter/effects) | `crates/jackin/src/console/` |
```

Do not touch the Capsule, Shared components, or Lookbook rows. Do not run any command that deletes or recreates `CLAUDE.md` — it is a symlink to this file and must stay one.

**Verify**, both of these:

```sh
rg -n '^\| (Capsule|Host console)' AGENTS.md
awk '/^\| Surface \| Directory \|/,/^$/' AGENTS.md | rg -o '`[a-z0-9./_-]+/`' | tr -d '`' | sort -u | while read -r d; do test -d "$d" || echo "MISSING: $d"; done
test -L CLAUDE.md && readlink CLAUDE.md
```

→ the loop prints nothing (it scans only the TUI-surface table block, so every path it sees must exist; a `MISSING:` line is a failure), and `readlink CLAUDE.md` prints `AGENTS.md`.

### Step 7: Execute the `chord_glyph` mirror comparison (spec scenario 3)

The claim under test is at `crates/jackin-capsule/src/tui/components/dialog/hint.rs:25` (re-read the live file first — 002 may have moved the line).

1. Read the head's implementation and its doc comment:

   ```sh
   rg -n "pub fn chord_glyph" -A 30 -B 12 <TERMROCK_CHECKOUT>/crates/termrock/src/keymap.rs
   ```

2. Compare its Ctrl-chord output convention against `format_key_glyph`:
   - Head (planning-time read): `Ctrl-` + the uppercased letter for the known set (`Ctrl-Q`, `Ctrl-C`, `Ctrl-L`, `Ctrl-H`), `"Ctrl-?"` for any other Ctrl-char, and a documented instruction that callers supply an explicit glyph for chars outside that set.
   - jackin❯: `Ctrl-{letter}` for bytes `0x01..=0x1A`, the literal `"Ctrl-\\"` for `0x1C`, hex fallback otherwise.
3. Decide, and act on exactly one branch:
   - **Convention holds** (head still spells Ctrl chords `Ctrl-<UPPER>` and still expects callers to supply their own glyph for unusual chars): the mirror is intact. Optionally sharpen the comment to state which part is mirrored (the prefix convention) and which part is deliberately caller-supplied — comment text only. Paste both excerpts into the report as the evidence for scenario 3.
   - **Convention drifted** (the head now spells Ctrl chords differently, or `chord_glyph` moved/was renamed): fix the jackin❯ side. Prefer the comment when only the path/name changed (update the `[`termrock::keymap::chord_glyph`]` intra-doc link to the head's real path). Change `format_key_glyph`'s output only when the head's spelling genuinely differs — and then update the assertions in `crates/jackin-capsule/src/tui/components/dialog/hint/tests.rs` that named the old output (lines 28, 85, 100-108, 146-172 in the planning-time file).

**Verify**:

```sh
cargo nextest run -p jackin-capsule -E 'test(/hint::tests/)'
```

→ all pass. If you changed `format_key_glyph`'s output, also run `cargo xtask ci --only snapshots` → exit 0; a snapshot diff here is a STOP.

### Step 8: Run the docs gates for the touched pages

The xtask docs partition (bun-free) plus the brand gate:

```sh
cargo xtask ci --only docs
cargo xtask docs brand
```

Then, because pages under `docs/content/` changed, the docs-site gate from `docs/` — the block reproduced in "Commands you will need".

**Verify**: `cargo xtask ci --only docs` exits 0, `cargo xtask docs brand` exits 0, and the `docs/` block completes with `bun run build`, `bunx tsc --noEmit`, and `bun test` all succeeding.

### Step 9: Refresh the PR body to match the final diff

The package is one PR (`feature/termrock-head-bump`), and PR-body refresh happens at merge-readiness — this step — not per commit (`PULL_REQUESTS.md:231`).

1. Read the current body: `gh pr view --json number,title,body`.
2. Rewrite it against the finished diff, following `.github/PULL_REQUEST_TEMPLATE.md` and `PULL_REQUESTS.md`:
   - **What ships / Behavior changes** at feature level — no function names, no file-by-file inventory, no test lists (`PULL_REQUESTS.md:125-126`).
   - **Verify locally** with the `jackin-dev pr sync <PR_NUMBER>` checkout block, `JACKIN_CONFIG_DIR` / `JACKIN_HOME_DIR` set (`PULL_REQUESTS.md:114`).
   - **This PR touches `crates/jackin-capsule/`**, so the capsule rules are mandatory: the Checkout block builds and exports the capsule binary and is sourced **before** any `jackin` smoke command, and a dedicated `### jackin-capsule smoke` block follows `### User smoke` (`PULL_REQUESTS.md:48-59`).
   - Include the docs verification gate block (the one sanctioned mechanical check, `PULL_REQUESTS.md:128`).
   - No deployed-docs links, no open-PR references, no hard-wrapped paragraphs.
3. Write it to a file and apply with `gh pr edit --body-file <file>` (never `--body "…"`), then read the rendered body back (`.github/AGENTS.md:8`).

**Verify**: `gh pr view --json body -q .body | rg -n "jackin-dev pr sync|jackin-capsule smoke"` → both present, and the `jackin-dev pr sync` line appears **before** the capsule smoke heading.

### Step 10: Run the full merge-readiness gate

```sh
cargo xtask ci
```

This is the package's merge-readiness evidence. Not `--fast` (skips the powerset lane that catches feature-combination fallout from the bump), not `mise run ci` (only 3 of 6 partitions).

**Verify**: exit 0. Paste the final summary line into the report. On failure, apply the STOP rule for unrelated lanes below.

## Test plan

This plan is documentation-and-verification work; its scenarios are checked by commands, not by new Rust tests. One test file may change, conditionally.

- **Spec scenario 1 (no dead API names)** — step 5's grep is the test: `rg -n "PanelEmphasis|FocusRing|ModalStack|Theme::default" docs/content/reference/tui/` → no output. Independent source of truth: the post-002 code read in step 1, not the docs themselves.
- **Spec scenario 2 (table points at real directories)** — step 6's directory-existence loop is the test; the filesystem is the independent source of truth. Expected: no `MISSING:` line for any path on the TUI table.
- **Spec scenario 3 (mirror verified)** — step 7's side-by-side read of `<TERMROCK_CHECKOUT>/crates/termrock/src/keymap.rs` against `hint.rs` is the test; the upstream source at the pinned rev is the independent source of truth. Regression cover is the existing suite `crates/jackin-capsule/src/tui/components/dialog/hint/tests.rs` (`format_key_glyph_ctrl_backslash`, `format_key_glyph_ctrl_e`, plus the `Ctrl-\\ menu` / `Ctrl-Q quit` hint assertions).
  - **Only if step 7 changes `format_key_glyph`'s output**: update those assertions to the new expected strings, taken from the head's `chord_glyph` behavior (not from re-running the changed function). Add no new test module; the file already covers both the letter and the non-letter branch. Structural pattern to match: the existing `format_key_glyph_ctrl_e` test.
- **Verify**: `cargo nextest run -p jackin-capsule -E 'test(/hint::tests/)'` → all pass; then step 10's `cargo xtask ci` → exit 0.

## Done criteria

Machine-checkable. ALL must hold, each checked against command output from this session:

- [ ] `cargo xtask ci` exits 0 (full gate, run after the last repository change)
- [ ] `cargo xtask ci --only docs` exits 0 and `cargo xtask docs brand` exits 0
- [ ] The `docs/` bun block (`bun run build`, `bunx tsc --noEmit`, `bun test`) completes successfully
- [ ] `rg -n "PanelEmphasis|FocusRing|ModalStack|Theme::default" docs/content/reference/tui/` → no output, or every remaining hit is an explicitly-marked historical reference quoted in the report
- [ ] Every directory path on the AGENTS.md TUI surface table exists (step 6's loop prints no `MISSING:` for those paths); `readlink CLAUDE.md` → `AGENTS.md`
- [ ] The `chord_glyph` comparison is executed and its outcome recorded: either "convention holds" with both excerpts pasted, or the jackin❯-side fix landed and `cargo nextest run -p jackin-capsule -E 'test(/hint::tests/)'` passes
- [ ] The PR body carries the capsule checkout block before the `### jackin-capsule smoke` block
- [ ] No files outside the in-scope list modified (`git status`) — excluding the protocol writes: `plans/termrock-migration/README.md` status rows and the roadmap item + index
- [ ] `plans/termrock-migration/README.md` status row for 004 updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails — in particular a hub row 003 that is not `DONE`, or a `Cargo.toml` still on the old pin.
- **The post-002 re-host cannot be documented truthfully**: `crates/jackin-tui/src/runtime/` contradicts the spec's premise that the product-facing contract (`ModalFlow` with `open`/`open_sub`/`pop`/`clear`, `SurfaceFocus`/`SurfaceFocusTarget`) was preserved — e.g. `ModalFlow` no longer exists, or the docs' described lifecycle semantics no longer hold. Report it as a **spec defect**, name the file and what you observed, and do not paper over it with invented prose.
- **The full `cargo xtask ci` fails on a lane unrelated to this package's changes** (e.g. a `policy` advisory, a `lint` actionlint finding on an untouched workflow, an unrelated crate's test): report the partition name and the first error verbatim, and stop. Do not chase unrelated failures into out-of-scope files.
- A step-7 fix would change rendered hint output that feeds an insta snapshot (a `*.snap` or `*.pending-snap` diff appears): stop — snapshot re-baselining is plan 003's territory.
- `AGENTS.md` or `CLAUDE.md` symlink integrity breaks (`readlink CLAUDE.md` no longer prints `AGENTS.md`, or `CLAUDE.md` becomes a regular file).
- A docs sentence is wrong because the *code* is wrong (a 002/003 defect), or fixing a page would require editing an out-of-scope source file.
- Any step's verification fails twice after a reasonable fix attempt.

## Maintenance notes

- The modernization phases (console → capsule → launch → small surfaces) will re-platform surfaces onto the head's component set; each of those rounds re-touches these same three pages. Whatever vocabulary this plan lands becomes the baseline they edit — prefer the names the code uses over invented umbrella terms.
- A reviewer should scrutinize two things: that every replacement API name in the `.mdx` files was copied from live code (grep each one back into `crates/`), and that the N1 ownership sentences in `visual-design.mdx` (product tokens in `jackin-brand` / `jackin_tui::tokens`) survived the rename pass untouched.
- Deferred on purpose: a broader sweep of stale `src/…` paths across all of `docs/content/` — only the two on this plan's in-scope pages plus the AGENTS.md row are fixed here. If step 5 or the repo-links gate reveals more, file them as a follow-up rather than widening this plan.
- `cargo xtask docs brand` and the bun docs-site gate are not part of `cargo xtask ci`; they only run here because this plan edits published prose. A future docs-touching plan must run them explicitly too.
