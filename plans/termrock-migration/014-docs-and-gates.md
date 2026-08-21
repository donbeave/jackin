# Plan 014: Align the TUI docs with the modernized console machinery, run the final parity proof set, strip the planning artifacts, and prove merge-readiness

> **Executor instructions**: Follow this plan step by step. Run the
> preconditions first. Run every verification command and confirm the
> expected result before moving on. If anything in "STOP conditions"
> occurs, stop and report — do not improvise. Status flips and commit law
> are the hub's executor protocol.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: MED (the full `cargo xtask ci` lane is the package's merge-readiness evidence; the re-bless decision point is a judgment call gated on recorded reviews; the post-strip status flip crosses branches)
- **Depends on**: `plans/termrock-migration/005-*.md` through `plans/termrock-migration/013-*.md` (every console modernization plan)
- **Covers**: B14 (final byte-identity audit), B16 (final parity proof set), N4 (closing check), the docs same-PR law for the console package
- **Guardrails**: N4 (inlined below)
- **Research basis**: `research/jackin-verification-tooling/01-gates-and-commands.md`
- **Planned at**: commit `f320b51f`, 2026-08-19

## Why this matters

Plans 006–013 re-platformed the console onto upstream machinery — focus on `FocusGraph`, modals on `OverlayStack`/`DismissPolicy`, scrolling on `ScrollArea`, hints on `kbd` + `hint_bar`, keymaps on `keymap_bridge`, the runtime on `Presenter`/`FrameClock`/`ReadySubscription`, the wizard on `form_wizard`, the facade's console-exclusive items deleted — and plan 012 added the sanctioned `keyboard_help` overlay. The contributor docs under `docs/content/reference/tui/` still describe the pre-modernization machinery (`SurfaceFocus`, `ModalFlow`, `scroll_block`, `dialog_layout`, `drive_frame`), so after 006–013 the code is correct and the documentation is actively wrong; the repository's docs-as-source-of-truth gate requires the pages to move in the same PR. After this plan: every mechanism named in the TUI reference pages resolves in the shipped code, the full parity proof set (text snapshots, trparity tests, PNG baselines, BrandHeader crop, literal-RGB tests) is green in one recorded run, the merge diff carries code only (planning artifacts stripped, exactly like PR #897), the full merge-readiness gate has passed on the final tree, and the PR body tells the operator how to verify.

## Preconditions — run before anything else

Run from the repository root. Any failed precondition is a STOP.

- Branch (hub repo law, operator directive 2026-08-20): `git branch --show-current` → `roadmap/termrock-migration` (the whole package executes on this one branch; never create a new branch).
- Hub rows 005–013 all DONE: `rg -n '^\| 01[0-3] |^\| 00[5-9] ' plans/termrock-migration/README.md` → nine rows, every Status column reads `DONE`. Any other value (TODO, IN PROGRESS, BLOCKED, STALE) → STOP per the hub protocol; never build on a non-DONE row.
- Roadmap-branch ancestry (needed by step 14's flip sync): `git fetch origin roadmap/termrock-migration && git merge-base --is-ancestor origin/roadmap/termrock-migration HEAD` → exit 0. Non-zero means the artifact home moved independently of the execution branch → STOP and report; the sync route needs operator input.
- Cheapest re-verification per dependency (current-session output; cite it in the DONE flip):
  - **005 + 007** (PNG pipeline, baselines, CI lane; BrandHeader crop): the lane is plan 005's harness, not a mise task — run the compare form `cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)'` → exit 0. No `png_baselines` tests matched (nextest reports zero tests run) → STOP (plan 005's harness is missing). Then `git ls-files '*.png' | rg -ci 'brand|header'` → count ≥ 1 (plan 007's dedicated crop baseline is tracked).
  - **006** (facade retirement): `rg -n "ModalFlow|SurfaceFocus" crates/jackin-console/src crates/jackin/src/console` → no output; `rg -n "ModalFlow|ModalOutcome" crates/jackin-tui/src` → no output (console-exclusive facade items deleted; `SurfaceFocus` may survive in `jackin-tui` only for capsule/launch — the first grep must still be empty on console/adapter paths).
  - **008** (interaction core): `rg -n "ScrollArea" crates/jackin-console/src` → hits; `rg -n "wheel_steps" crates/jackin-console/src` → hits (the `.wheel_steps(1, 1)` compensation).
  - **009** (collections + modal geometry): `rg -n "CollectionState|RovingFocusGroup|VirtualList|DismissPolicy" crates/jackin-console/src` → hits.
  - **010** (dialog/form layer): `rg -n "confirm_prompt|alert_dialog|file_picker|combobox|password_input" crates/jackin-console/src` → hits.
  - **011** (layout/chrome/runtime): `cargo xtask lint arch --strict` → exit 0 (run-loop ownership and facade-remnant invariants hold).
  - **012** (recipes, wizard, keyboard_help): `rg -n "keyboard_help" crates/jackin-console/src` → hits.
  - **013** (op-picker): `rg -c "enum ModalOutcome" crates/ --type rust` → exactly one hit total (the single shared product-owned definition); `rg -n "BlockingSubscription" crates/jackin-oppicker/src` → no output.
- Toolchain present: `cargo xtask ci --help` → exit 0 and prints the partition list (`lint, policy, tests, powerset, docs, snapshots, e2e`).
- Docs-site toolchain present (needed by step 8): `bun --version` → `1.3.14` (pinned in `mise.toml`; a different version is not a STOP, a missing `bun` is — run `mise install`).
- Drift check: `git diff --stat f320b51f..HEAD -- docs/content/reference/tui/ docs/content/research/watchlist.mdx`
  - Expected: **no** changes (intermediate plans note drift; this plan owns the docs edits per the hub's same-PR docs law). Any change means someone else edited this plan's territory → compare the "Starting state" excerpts against the live files; a mismatch is a STOP.
  - `crates/` differs massively from `f320b51f` — that is the 005–013 work and is expected. All code excerpts below are planning-time snapshots; the live code is the authority.

## Spec contract

The requirements this plan implements, inlined **verbatim** from the spec — the executor does not read `spec/`:

### Requirement: UI/UX parity invariant

The console modernization SHALL preserve every console screen's current look and interaction behavior; any upstream visual or behavioral divergence from the pre-migration UX MUST be compensated — consumer configuration first, an upstream TermRock change per the misfit rule when a widget cannot reproduce the current UX — and MUST NOT be silently accepted.

Covers: F5, W2, B16 · Evidence: roadmap item §Decisions (parity invariant ruling, 2026-08-19)

#### Scenario: Text snapshot diff during modernization

- **GIVEN** a console screen has been re-platformed onto upstream components
- **WHEN** the console text snapshot suite runs
- **THEN** every existing console snapshot is byte-identical to its pre-modernization bless
- **AND** any diff is treated as a parity break: the executor STOPs for operator review and MUST NOT re-bless

#### Scenario: Parity proof set complete

- **WHEN** the console phase finishes
- **THEN** parity is proven by all of: the bump-phase text snapshots (byte-identical), the named behavioral parity tests, the zero-tolerance PNG baselines on the full console inventory, and the BrandHeader PNG crop

### Requirement: Zero-tolerance compare with bless workflow

Baseline comparison SHALL be zero-tolerance on decoded pixels (upstream `compare_png_pixels` semantics: any pixel difference fails). Blessing (writing/updating baselines) SHALL happen only via the explicit bless path (environment variable per the upstream pattern), never as a test side effect.

Covers: F7, B10 · Evidence: research/termrock-head-adoption/05-png-baseline-pipeline.md (pipeline anatomy)

#### Scenario: Unintended paint change fails

- **GIVEN** a code change that alters any rendered pixel of a baselined screen
- **WHEN** the baseline suite runs without the bless variable
- **THEN** the compare fails and names the differing screen

#### Scenario: Deliberate re-bless

- **WHEN** a look change is intentional and reviewed
- **THEN** baselines update only via the bless path, and the re-blessed PNGs are visible in the diff for review

### Requirement: Text snapshots remain the standing suite

The existing text snapshot suite SHALL remain in force unchanged; PNG baselines are additive gates and do not replace, weaken, or re-bless text snapshots. Console text snapshots stay byte-identical through the modernization per the parity rule (any diff = STOP for operator review).

Covers: B10, B16 · Evidence: roadmap item §Decisions (console-phase parity rule, 2026-08-19)

#### Scenario: Both gates run

- **WHEN** the console phase's verification runs
- **THEN** both the text snapshot suite (byte-identical) and the PNG baseline suite (zero-tolerance) execute and pass independently

Done means these scenarios hold at the end of the console phase; the test plan below exercises them.

## Must NOT

Guardrails inlined verbatim from the must-not registry, with reasons. These override anything a step seems to imply:

- **N4**: The console phase MUST NOT add operator-visible screens or overlays beyond the single sanctioned `keyboard_help` overlay, and MUST NOT change operator journeys — item D14 amended by D18: the amendment's scope is exactly one additive help overlay.
  - **How N4 binds this plan**: the docs sweep must document `keyboard_help` and nothing else as new operator-visible UI. If the sweep discovers that plans 005–013 introduced any other new screen or overlay (e.g. `notification_center`, `command_palette`), or changed an operator journey, that is an N4 violation by the plan that introduced it → STOP and report; do not document the violation into legitimacy.

## Inputs to provide

None — fully self-contained. The PNG lane command and bless path are discovered from the repository at execution time (they are plan 005's deliverables); the re-bless decision input (earlier plans' recorded STOP-reviews) is read from the execution branch's own commit history and the hub.

## Starting state

All excerpts re-read at planning time (commit `f320b51f`, branch `roadmap/termrock-migration` — the pre-modernization state). The repository's post-013 state is the authority at execution — where an excerpt below disagrees with the live file, follow the drift-check rule in the preconditions.

**Planning-time measurements carry the re-derivation rule.** Every count below is a snapshot: re-run the counting command, stamp the fresh number, note the delta — never treat a drifted planning number as a target to reproduce.

**Docs machinery survey** (`rg -n "SurfaceFocus|ModalFlow|ModalOutcome|scroll_block|render_scrollable_block_at|dialog_layout|breadcrumb_title|drive_frame|drive_render|FocusRing|ModalStack|BlockingSubscription|list_pre_render_focus_plan|focused_block_still_scrollable" docs/content/reference/tui/ docs/content/research/watchlist.mdx`, 2026-08-19 → 22 hits across 5 files: `navigation.mdx` 12, `dialogs.mdx` 5, `components.mdx` 2, `visual-design.mdx` 2, `index.mdx` 1; zero in `chrome.mdx`, `architecture.mdx`, `watchlist.mdx`). Load-bearing excerpts:

- `docs/content/reference/tui/navigation.mdx:24` — "1. `jackin_tui::runtime::SurfaceFocus<Target>` is the product projection over TermRock's `FocusGraph` for tabbed screens. …" (plan 006 retires the console-side `SurfaceFocus`; the console speaks `FocusGraph` directly).
- `docs/content/reference/tui/navigation.mdx:249` — "TermRock `Viewport` (console `scroll_block` adapter) paints `PanelChrome` from the caller's `focused` flag with **no overflow gate**. …" (plan 008 cuts the console scroll adapter to `ScrollArea`).
- `docs/content/reference/tui/dialogs.mdx:174` — "The shared mechanism for this contract is TermRock's `OverlayStack` + `FocusGraph` lifecycle, projected into product state by `jackin_tui::runtime::ModalFlow`. `open_sub` preserves the visible product modal while opening its matching focus scope, `pop` restores both parent and scope for Esc/cancel, and `clear` closes the whole chain after a terminal commit. Product code tests its modal transitions through `ModalFlow`; TermRock owns the primitive focus/stack conformance tests." (plan 006 deletes the facade `ModalFlow`; the console modal flow enum stays product-owned — plan 009 puts geometry/stacking on `OverlayStack`/`DismissPolicy`.)
- `docs/content/reference/tui/dialogs.mdx:182` — "…and the jackin❯ `ModalFlow` projection. Treat new Esc-back regressions on any surface as bugs; fix the product flow through the shared lifecycle rather than adding a new stash."
- `docs/content/reference/tui/components.mdx:34` — "Input methods return typed component outcomes (`ListOutcome`, `DetailTableOutcome`, `ModalOutcome`, or the widget's equivalent). …" (plan 006 re-homes `ModalOutcome` as product-owned code; the name may still resolve — verify against live code before touching this generic sentence).
- `docs/content/reference/tui/components.mdx:125` — "**Render primitives**: TermRock `Panel` / `render_dialog_shell` / `Viewport` / `DialogScroll` ([TermRock source](https://github.com/tailrocks/termrock)), console `scroll_block` and `dialog_layout` adapters when call shape needs them, `breadcrumb_title` (<RepoFile path="crates/jackin-console/src/tui/components/op_picker.rs">…</RepoFile>), `render_fatal` (…), TermRock filter input and list widgets — use these building blocks when composing new modals rather than hand-rolling border + layout from scratch." (plans 008/010 retire `scroll_block`/`dialog_layout`; plan 013 re-bases the breadcrumb on `widgets/breadcrumbs`.)
- `docs/content/reference/tui/index.mdx:14` — "Frame dispatch is shared, not per-loop: each surface's model-to-pixels step implements the jackin❯-owned `jackin_tui::runtime::View<Model>` contract, and production frames render through the product-owned `drive_frame` adapter — one `Terminal::draw` per tick … Production callers are the host console (`jackin` console TUI), launch progress (`jackin-launch` `RichRenderer::render` via `LaunchViewView`), and capsule compositor (`jackin-capsule` daemon compositor via `CapsuleView`). Short-lived launch dialogs and prompts use `drive_render`, …" (plan 006 inlines `View` and `drive_frame` for the console; capsule/launch keep them until their own phases — the sentence stays true for those surfaces.)
- `docs/content/reference/tui/visual-design.mdx:71` — "TermRock `Viewport` paints border emphasis from `PanelChrome`. Console scrollable panels go through `scroll_block::render_scrollable_block_at`, which maps the caller's `focused` flag to `PanelChrome::Focused` / `Normal`. …"
- `docs/content/reference/tui/architecture.mdx:53` — "2. **`crates/jackin-tui/`** — Product-specific compositions and Ratatui adapters shared by at least two jackin❯ surfaces. It may own cross-surface product update/effect, external-subscription, and one-draw adapter contracts, but cannot own a generic theme facade, neutral widgets, terminal lifecycle, surface event loops, schedulers, or external effects." (plan 006 shrinks the facade toward its end state — brand `tokens.rs` + `operator_info` — for the console; capsule/launch still consume the retained items, so the sentence's truth after 013 is a code read, not an assumption.)

**Watchlist rows** (`docs/content/research/watchlist.mdx:60-65`, verbatim at planning time — the TermRock row tracks "render fixtures … compatibility evidence", which the console phase's PNG pipeline now concretizes on the jackin❯ side):

```markdown
| Reference | Watch for | Where it informs the program |
|---|---|---|
| TermRock and jackin❯'s pinned compatibility revision | Canonical-versus-legacy public API growth, ownership drift, catalog coverage, render fixtures, terminal lifecycle, dependency changes, and compatibility evidence. | [TUI Architecture](/reference/tui/architecture/), [TUI Components](/reference/tui/components/), and the [TermRock repository](https://github.com/tailrocks/termrock). |
```

**Parity proof set inventory (planning-time):**

- 18 `.snap` fixtures: 6 console (`crates/jackin-console/src/tui/view/snapshots/`), 12 capsule (`crates/jackin-capsule/src/tui/components/dialog/snapshots/` ×10, `.../branch_context_bar/snapshots/` ×2). The console phase may legitimately change only the 6 console ones, and only via plan 012's recorded footer-hint review (the `? help` discovery hint on every stage, D24). Capsule fixtures are outside this package's territory.
- 19 `trparity_` tests: `crates/jackin-launch/src/tui/diff_scroll/tests.rs` ×7, `crates/jackin-capsule/src/tui/components/dialog/tests.rs` ×5, `crates/jackin-tui/src/runtime/tests.rs` ×5, `crates/jackin-console/src/tui/screens/editor/model/tests.rs` ×2. Plan 006 may re-home the jackin-tui ones with the prefix kept; an unexplained count drop is a STOP.
- 12 literal-RGB brand tests: `crates/jackin-console/src/tui/components/brand_header/tests.rs` ×3 (`brand_chevron_keeps_pre_bump_white` line 11, `brand_separator_keeps_pre_bump_dark_phosphor` line 21, `brand_label_keeps_pre_bump_dim_phosphor` line 30), `crates/jackin-launch/src/tui/components/header/tests.rs` ×3, `crates/jackin-launch/src/tui/components/progress_rail/tests.rs` ×4 (`rail_text_spans_keep_pre_bump_white` line 12, `rail_strong_span_keeps_pre_bump_white_bold` line 34, `rail_muted_span_keeps_pre_bump_dim_phosphor` line 41, `rail_queued_span_keeps_pre_bump_dark_phosphor` line 48), `crates/jackin-capsule/src/tui/components/chrome/tests.rs` ×2 (`brand_pill_chevron_keeps_pre_bump_white` line 187, `row0_tabs_follow_the_upstream_theme_without_compensation` line 213). Eleven names match `keeps_pre_bump`; the twelfth is the row0 test. Plan 007 keeps these as the BrandHeader value-level gate.
- No `keyboard_help` anywhere under `crates/` at planning time (plan 012 adds it); no PNG baselines tracked (plan 005 adds them).

**Artifact-strip precedent (PR #897, commit `23c9366`):** subject `chore(plans): drop planning artifacts from the merge diff`, body "plans/, roadmap/, and research/ are tailrocks session artifacts; they stay branch-side on roadmap/termrock-migration and never enter main's history.", 25 files removed spanning exactly `plans/`, `research/`, `roadmap/`; it was the last commit on `feature/termrock-head-bump` before the squash merge (main `955b2fea`). The roadmap branch (`roadmap/termrock-migration`) carries the artifacts permanently: it shares history with the execution branch up to the strip's parent and then continues artifact-side.

**Branch topology (verified at planning time):** `origin/main`'s tree contains no top-level `plans/`, `roadmap/`, or `research/`; the merge-base of `origin/main` and `roadmap/termrock-migration` is `c9be126c`, which also contains none. So after the strip, `git diff --name-only origin/main...HEAD` lists zero artifact paths — provided every artifact file added mid-branch was removed, which `git rm -rq plans/ roadmap/ research/` guarantees for those trees.

**Post-strip gate safety (verified at planning time):** the `docs` partition validates the docs-site trees, not the stripped artifact dirs — `cargo xtask roadmap audit` → `docs/content/roadmap/` and `cargo xtask research check` → `docs/content/research/` (`crates/jackin-xtask/src/docs.rs:411-452`, `DOCS_ROOT`/`ROADMAP_REL`/`RESEARCH_REL` at lines 36-39). PR #897's green post-strip CI is the end-to-end proof.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Merge-readiness gate (this package's evidence) | `cargo xtask ci` | exit 0 |
| Text snapshot suite (byte-identical gate) | `cargo xtask ci --only snapshots` | exit 0 |
| Docs partition | `cargo xtask ci --only docs` | exit 0 |
| Brand-prose gate | `cargo xtask docs brand` | exit 0 |
| Arch gate (011 re-verification) | `cargo xtask lint arch --strict` | exit 0 |
| Behavioral parity tests | `cargo nextest run --workspace --all-features --locked -E 'test(trparity_)'` | all pass; stamp fresh count |
| Literal-RGB brand tests | `cargo nextest run --workspace --all-features --locked -E 'test(/keeps_pre_bump/) + test(row0_tabs_follow_the_upstream_theme_without_compensation)'` | 12 pass (fresh count from the nextest summary) |
| PNG baseline lane | `cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)'` (plan 005's harness; no mise task is installed) | exit 0 |
| Docs-site gate (run from `docs/`, only because pages under `docs/content/` changed) | see block below | exit 0 |

Docs-site block (PULL_REQUESTS.md:204 superset of the PR-template block — includes `cargo xtask research check`):

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

- §Merge-readiness gates: "`--only` is a local-dev tool; merge readiness is the full `ci` (or `ci --fast` without powerset)". **Use the full `cargo xtask ci`, not `--fast`.** The powerset lane (`cargo hack check --workspace --feature-powerset --all-targets --locked`) catches feature-combination fallout from the dependency-graph changes plan 005 made (new `termrock-raster` git dependency). Partition table: lint = actionlint + `cargo fmt --check` + `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` + `cargo xtask lint --strict`; tests = `cargo check --workspace --all-targets --locked` + `cargo nextest run --workspace --all-features --locked` + `cargo test --doc --workspace --locked`; policy = `cargo audit` + `cargo deny check advisories bans licenses sources` + `cargo xtask schema-check --base origin/main` + `cargo shear --deny-warnings`; docs = `cargo xtask roadmap audit` + `cargo xtask docs repo-links` + `cargo xtask research check`; snapshots = `cargo nextest run -p jackin-capsule -p jackin-console --locked`.
- Same chapter, §Docs gate: the xtask `docs` partition is **bun-free** (exactly those three commands); the bun-side checks are the separate docs-site gate run from `docs/`, required before docs-touching PRs are merge-ready per PULL_REQUESTS.md.
- Same chapter, Dead ends: `mise run ci` is **not** equivalent — it runs only `policy`, `docs`, `snapshots`. Do not substitute it.
- Same chapter, §Partition selection / "One test / one module": the `-E 'test(<name>)'` filter form; the `+` union inside a filterset is the same nextest DSL the chapter's derived exclusion example uses.
- `cargo xtask lint arch --strict` is the arch gate's failing mode (`crates/jackin-xtask/src/main.rs:164-170`, `crates/jackin-xtask/src/arch.rs:114-125` — "`--strict` to fail on architecture violations instead of just reporting").
- `cargo xtask docs brand` is not in the xtask `ci` docs partition; it is a docs-workflow gate (`crates/jackin-xtask/src/main.rs:88`, `crates/jackin-xtask/src/docs.rs:189`). Run it here because this plan edits brand-bearing prose.
- The PNG lane has no chapter entry: it did not exist at the chapter's writing. It is plan 005's deliverable; discover, never invent — if no PNG task exists, that is a STOP (plan 005 defect), not an invitation to hand-roll a command.

## Scope

**In scope** (the only files to create or modify):

- `docs/content/reference/tui/navigation.mdx`
- `docs/content/reference/tui/dialogs.mdx`
- `docs/content/reference/tui/components.mdx`
- `docs/content/reference/tui/chrome.mdx`
- `docs/content/reference/tui/architecture.mdx`
- `docs/content/reference/tui/index.mdx`
- `docs/content/reference/tui/visual-design.mdx`
- `docs/content/research/watchlist.mdx` — **conditionally**, only if step 7 finds its TermRock row stale against the shipped pipeline state
- Committed PNG baseline files under whichever directory plan 005 chose — **conditionally**, only via step 9's reviewed re-bless window
- Deletions only: `plans/`, `roadmap/`, `research/` (step 11's strip commit)
- The PR body (step 13) — a GitHub artifact, not a repository file

**Out of scope** (do NOT touch, even though related):

- Any file under `crates/`. Modernization is plans 005–013's territory; if a docs sentence is wrong because the *code* is wrong, that is the owning plan's defect → STOP and report, do not fix code here.
- `*.snap` files anywhere. The text-snapshot re-bless window was plan 012's reviewed exception; any snapshot diff at this point is a parity break → STOP.
- `.snap` content, `Cargo.toml`, `Cargo.lock`, `deny.toml`, `REUSE.toml`, `.github/workflows/` — the PNG CI lane is plan 005's territory.
- Other pages under `docs/content/` unless step 6's closing grep reports a dead machinery name there — then extend only to the offending line and say so in the report.
- `AGENTS.md`, `RULES.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `PROJECT_STRUCTURE.md`.
- The capsule, launch, and small-surface modernization — later packages.

The hub `plans/termrock-migration/README.md` and the roadmap item are protocol-writable and never listed in scope; this plan's own status flip happens on `roadmap/termrock-migration` (step 14), not the execution branch.

## Git workflow

Only what is specific to this plan (the hub carries the branch, sign-off, and push-after-every-commit law; this plan instantiates the hub's artifact-strip rule):

- Commit 1 — docs sweep (steps 2–7): `docs(tui): align TUI reference pages with the modernized console machinery`
- Commit 2 — **conditional**, only if step 9 re-blesses: `chore(console): re-bless PNG baselines for the reviewed <name the look change>` (the changed PNGs must be the whole diff — `git show --stat` shows only `*.png` and any harness-adjacent metadata plan 005's bless path writes).
- Commit 3 — the artifact strip (step 11), the **last content commit** on the execution branch, mirroring PR #897's `23c9366`:

  ```text
  chore(plans): drop planning artifacts from the merge diff

  plans/, roadmap/, and research/ are tailrocks session artifacts; they stay
  branch-side on roadmap/termrock-migration and never enter main's history.
  ```

- Step 14's protocol writes (hub row 014 → DONE, item Log entry, `roadmap/README.md` row) commit on `roadmap/termrock-migration` as `docs(roadmap): record console modernization phase DONE — package goal PASS at <short SHA>` — **not** on the execution branch, whose tree no longer carries the artifacts after commit 3. Push both branches immediately (`git push` on each).

If step 9 finds no recorded look change, there is no commit 2 — record the search output in the report instead.

## Steps

### Step 1: Read the post-013 reality before writing a word of documentation

Do not edit any `.mdx` yet. Establish what the code now says:

1. Re-run the survey and record the fresh hit count (planning-time figure: 22 hits / 5 files — a different number is fine; stamp yours and note the delta):

   ```sh
   rg -n "SurfaceFocus|ModalFlow|ModalOutcome|scroll_block|render_scrollable_block_at|dialog_layout|breadcrumb_title|drive_frame|drive_render|FocusRing|ModalStack|BlockingSubscription|list_pre_render_focus_plan|focused_block_still_scrollable" docs/content/reference/tui/ docs/content/research/watchlist.mdx
   ```

2. Read the live machinery behind each docs claim. For each, write down the name the docs must use (the `use termrock::…` lines and product type names are the answer):
   - Focus: `rg -n "FocusGraph|SurfaceFocus" crates/jackin-console/src/tui/ | head -20`
   - Modal/overlay bookkeeping and the product flow enum: `rg -n "OverlayStack|DismissPolicy" crates/jackin-console/src/tui/ | head -20`; `rg -n "enum ModalOutcome|enum ConsoleModal" crates/ --type rust`
   - Scrolling: `rg -n "ScrollArea|scroll_block" crates/jackin-console/src/tui/ | head -20`
   - Footer hints: `rg -n "hint_bar|kbd::|HintSpan" crates/jackin-console/src/tui/ | head -20`
   - Keymaps: `rg -n "keymap_bridge|UiIntent" crates/jackin-console/src/tui/ | head -10`
   - Runtime: `rg -n "Presenter|FrameClock|ReadySubscription" crates/jackin-console/src crates/jackin-oppicker/src | head -10`
   - Facade remnant: `ls crates/jackin-tui/src/ crates/jackin-tui/src/operator_info/ 2>/dev/null; rg -n "^pub" crates/jackin-tui/src/lib.rs`
   - Wizard: `rg -n "form_wizard|WizardGate|WizardPhase|WizardProgress" crates/jackin-console/src | head -10`
   - keyboard_help: `rg -n "keyboard_help" crates/jackin-console/src | head -10`
   - Op-picker breadcrumb: `rg -n "breadcrumbs" crates/jackin-console/src/tui | head -10`
3. Read the docs pages end to end (all seven under `docs/content/reference/tui/`), marking every sentence that names a mechanism the greps prove is gone from the console path, and every place the pages describe console machinery without naming the adopted upstream component where naming it is the page's convention (the pages name TermRock components throughout — match that convention).

**Verify**: you can state, in one sentence each, (a) what replaced `SurfaceFocus` for console tabbed screens, (b) what the console modal flow is built on now and what the product-owned pieces are called, (c) what replaced the `scroll_block` adapter, (d) what renders footer hints now, (e) what the facade (`crates/jackin-tui`) still exports and for whom. If any of the five has no answer in the code, STOP.

### Step 2: Update `docs/content/reference/tui/navigation.mdx`

Rewrite every machinery claim that plans 006/008/009 invalidated, locating by text, not line number:

- Line 24's `SurfaceFocus<Target>` projection sentence: name what the console actually uses after 006 (step 1's answer (a)). If capsule/launch still use `SurfaceFocus`, say so explicitly — the facade item survives for them per the hub's deferral note.
- The `scroll_block` adapter sentence (line 249 area): name the `ScrollArea`-based path and keep the documented behavior rules (border emphasis derived from focus, no overflow gate, passive-scroll focusability clearing) — those behaviors are parity-preserved; only the carrier changed.
- Every `PanelChrome` sentence: still valid if the enum still exists — verify with `rg -n "PanelChrome" crates/jackin-console/src | head -5` and leave untouched if so.
- Where the page describes selection/list behavior that moved to `CollectionState`/`RovingFocusGroup`/`VirtualList` (plan 009), name the upstream machinery per the page's convention, keeping the two-level selection's product-wrapper ownership clear.

Keep every paragraph on one line (docs prose is never hard-wrapped); brand spelled per the hub's brand law; RULES.md's TUI label/keybinding/modal rules bind any label prose you touch.

**Verify**: `rg -n "SurfaceFocus|scroll_block|render_scrollable_block_at|list_pre_render_focus_plan|focused_block_still_scrollable" docs/content/reference/tui/navigation.mdx` → no output, and every new TermRock name you introduced resolves: `rg -n "<Name>" crates/jackin-console/src` finds it for each.

### Step 3: Update `docs/content/reference/tui/dialogs.mdx` and `docs/content/reference/tui/components.mdx`

- `dialogs.mdx:174` and `:182`: rewrite the modal-lifecycle mechanism from step 1's answer (b). Keep the contract sentences that are still true (`open_sub`/`pop`/`clear` semantics, Esc cascade, product code tests its transitions) — verify each against the live product flow enum's method list before keeping it; if a method was renamed, use the new name. Name `OverlayStack`/`DismissPolicy` as the geometry/stacking carrier (plan 009) and the product-owned flow enum by its live name.
- `components.mdx:34`: `ModalOutcome` survives as a product-owned type (006 re-homed it; 013 made it the single shared one). Leave the sentence if the name still resolves (`rg -n "enum ModalOutcome" crates/ --type rust` → one hit); otherwise update to the live name.
- `components.mdx:125`: replace the retired `scroll_block`/`dialog_layout` adapter references with the post-008/010 reality; update `breadcrumb_title` to the `widgets/breadcrumbs` re-base (plan 013), keeping the `op_picker.rs` RepoFile link only if the symbol still lives there (`rg -n "breadcrumb" crates/jackin-console/src/tui/components/op_picker.rs`).
- Where these pages enumerate console dialogs, add the `keyboard_help` overlay per the page's convention if the enumeration is meant to be complete (it is the one sanctioned addition — N4): opened by `?` from every console stage, content sourced from `keymap_bridge` data, dismissed by Esc with focus restored, discoverable via the footer hint per RULES.md label law.

**Verify**: `rg -n "ModalFlow|scroll_block|dialog_layout|FocusRing|ModalStack" docs/content/reference/tui/dialogs.mdx docs/content/reference/tui/components.mdx` → no output; `rg -n "breadcrumb_title" docs/content/reference/tui/components.mdx` → no output (or the surrounding sentence explicitly marks it historical).

### Step 4: Update `docs/content/reference/tui/chrome.mdx` and `docs/content/reference/tui/visual-design.mdx`

- `chrome.mdx` describes hint-bar behavior (rows 12-15, 140, 206), scroll-hover and click-to-focus rules (128, 137, 139-140), and single-consumer mouse routing (143) — the *behaviors* are parity-preserved, but any sentence naming the old carrier machinery is now wrong. Read the page; where it names mechanism, align with step 1's answers (c) and (d): hints render through `kbd` + `hint_bar` (011), mouse/wheel machinery through `UiContext`/HitRegion + `ScrollArea` (008). Behavior rules (hint bar is focus-scoped, single-consumer routing while a modal is open, scroll-transfers-focus) stay — they are the parity contract, re-verified by the modernized code.
- `visual-design.mdx:71`: replace the `scroll_block::render_scrollable_block_at` paint-path claim with the live path (step 1's answer (c)); keep the `PanelChrome` behavior description if the enum survives (verified in step 2).
- Where a stage's hint bar is described, the `? help` discovery hint (plan 012, D24) is now part of every console stage's footer — document it where the page enumerates hint content, using the full-word label RULES.md requires.

**Verify**: `rg -n "scroll_block" docs/content/reference/tui/chrome.mdx docs/content/reference/tui/visual-design.mdx` → no output; every newly named mechanism resolves in `crates/jackin-console/src`.

### Step 5: Update `docs/content/reference/tui/architecture.mdx` and `docs/content/reference/tui/index.mdx`

- `index.mdx:14`: the frame-dispatch paragraph must distinguish the surfaces: the console no longer goes through the facade `View`/`drive_frame` (006 inlined them surface-side); capsule and launch still do until their phases. Rewrite so each surface's current dispatch is named truthfully from step 1's reads (console run loop stays surface-owned per the arch gate — the precondition's `cargo xtask lint arch --strict` proves it).
- `architecture.mdx:53` (the `crates/jackin-tui/` layer row): describe the facade as it stands after 013 — its console-exclusive items retired, its remaining exports serving capsule/launch until their phases, end state brand `tokens.rs` + `operator_info`. Read `crates/jackin-tui/src/lib.rs` and state only what is there.
- Do not editorialize the roadmap into the page: describe the current state, and at most one forward sentence ("capsule/launch retain … until their modernization phases").

**Verify**: `rg -n "drive_frame|drive_render" docs/content/reference/tui/index.mdx docs/content/reference/tui/architecture.mdx` → remaining hits only where the sentence is about capsule/launch; `rg -n "ModalFlow|SurfaceFocus" docs/content/reference/tui/architecture.mdx` → no output.

### Step 6: Watchlist check + closing grep over the whole TUI docs tree

1. `docs/content/research/watchlist.mdx:63`: the TermRock row tracks "render fixtures … compatibility evidence". If the console phase's PNG pipeline makes the row stale (e.g. it implies jackin❯ has no render-fixture gate of its own, or the pinned-revision tracking note contradicts the shipped pin), update the row minimally; otherwise record "checked, still accurate" in the report and leave the file untouched.
2. Closing grep (spec scenario: no dead machinery names in docs):

   ```sh
   rg -n "SurfaceFocus|ModalFlow|scroll_block|render_scrollable_block_at|dialog_layout|breadcrumb_title|FocusRing|ModalStack|BlockingSubscription|list_pre_render_focus_plan|focused_block_still_scrollable" docs/content/reference/tui/ docs/content/research/watchlist.mdx
   ```

   **Verify**: no output. A hit is acceptable only when the surrounding sentence explicitly marks it historical (e.g. "before the 2026 console modernization this was `scroll_block`") — paste any such line into the report with its justification. A hit on a page outside this plan's listed files means the survey under-counted: fix that one line and name the file in the report.
3. Reverse check: every TermRock machinery name the docs now use resolves in the code. Collect the names you introduced (`rg -o "ScrollArea|CollectionState|RovingFocusGroup|VirtualList|DismissPolicy|hint_bar|keymap_bridge|UiIntent|Presenter|FrameClock|ReadySubscription|SpinnerState|panel_stack|resizable_panel_group|form_wizard|keyboard_help" docs/content/reference/tui/ | sort -u`) and grep each back into `crates/`. Any name with zero code hits is invented prose → fix or remove it.

### Step 7: Run the docs gates for the touched pages

The xtask docs partition (bun-free) plus the brand gate:

```sh
cargo xtask ci --only docs
cargo xtask docs brand
```

Then, because pages under `docs/content/` changed, the docs-site gate from `docs/` — the block in "Commands you will need".

**Verify**: `cargo xtask ci --only docs` exits 0, `cargo xtask docs brand` exits 0, and the `docs/` block completes with `bun run build`, `bunx tsc --noEmit`, and `bun test` all succeeding.

### Step 8: Commit the docs sweep

Commit per the git workflow (commit 1). Push.

**Verify**: `git log -1 --format=%s` → `docs(tui): align TUI reference pages with the modernized console machinery`; `git status --porcelain` → empty.

### Step 9: The re-bless decision point (spec scenario: Deliberate re-bless)

Exactly one PNG re-bless window exists in this package, here, and only when an earlier plan's STOP-review recorded an intended look change whose re-bless was deferred to this plan. Search the record:

```sh
git log --format='--- %h %s%n%b' origin/main..HEAD | rg -i -C2 "re-bless|rebless|look change|operator review|STOP.review"
rg -n -i "re-bless|look change" plans/termrock-migration/README.md
```

Decide, and act on exactly one branch:

- **A recorded, operator-reviewed look change awaits re-bless**: run the bless path plan 005 installed — `JACKIN_BLESS_PNGS=1 cargo nextest run -p jackin-console --locked -E 'test(/png_baselines/)' --no-capture` (env-var bless; never bless by hand-editing or by deleting baselines). Inspect the rendered difference before committing — the changed PNG set must correspond to the recorded look change and nothing else. Commit per the git workflow (commit 2); the re-blessed PNGs are visible in the diff for review.
- **No recorded look change**: do **not** re-bless. Record the search output in the report. Any PNG baseline failure observed anywhere in this plan is then an unintended paint change (spec scenario: Unintended paint change fails) → STOP and report the differing screen; never bless to make it pass.

**Verify**: on the re-bless branch, `git show --stat HEAD` lists only baseline PNGs (and bless-path metadata); on the no-re-bless branch, `git status --porcelain` is empty and the report carries the search output.

### Step 10: Run the final parity proof set (B16)

Run all five; paste every summary line into the report. This is the console phase's acceptance run (spec scenario: Parity proof set complete; scenario: Both gates run):

1. **Text snapshots byte-identical**: `cargo xtask ci --only snapshots` → exit 0. Then the byte-identity audit against main:

   ```sh
   git diff --name-only origin/main...HEAD -- '*.snap'
   ```

   → every listed file is under `crates/jackin-console/src/tui/view/snapshots/` and traceable to plan 012's recorded footer-hint review (find that record: `git log --format='%h %s' origin/main..HEAD -- crates/jackin-console/src/tui/view/snapshots/`). Any capsule fixture in the list, or any console fixture not traceable to 012's record, is a parity break → STOP. An empty list is acceptable only if plan 012's record explains why the `?` hint moved no snapshot.
2. **Behavioral parity tests**: `cargo nextest run --workspace --all-features --locked -E 'test(trparity_)'` → all pass; stamp the fresh count (planning-time 19). A delta is acceptable only with an earlier plan's recorded re-homing (prefix kept); an unexplained drop → STOP.
3. **PNG baseline suite zero-tolerance green**: the precondition's 005/007 run is the record — cite its exit-0 output — **unless** step 9 re-blessed, in which case re-run the lane now → exit 0.
4. **BrandHeader crop green**: covered by the same lane (the precondition's `git ls-files '*.png' | rg -ci 'brand|header'` ≥ 1 proves the crop is tracked and inside the suite). If the lane's output enumerates screens, confirm the crop appears; paste the line.
5. **Literal-RGB tests**: `cargo nextest run --workspace --all-features --locked -E 'test(/keeps_pre_bump/) + test(row0_tabs_follow_the_upstream_theme_without_compensation)'` → all pass; the nextest summary's count is the fresh authority (planning-time 12). Plan 007's rebuild keeps these as the value-level gate; a count change must be explained by 007's record, else STOP.

Also confirm no pending snapshot files: `git ls-files '*.pending-snap'` → empty; `find crates -name '*.pending-snap' | head -1` → no output.

**Verify**: all five proof lines recorded from this session; the `.snap` audit output pasted; pending-snap checks empty.

### Step 11: Strip the planning artifacts (hub repo law, instantiated)

This is the last content commit on the execution branch — everything after it is gates and protocol writes:

```sh
git rm -rq plans/ roadmap/ research/
git commit -s -m "chore(plans): drop planning artifacts from the merge diff

plans/, roadmap/, and research/ are tailrocks session artifacts; they stay
branch-side on roadmap/termrock-migration and never enter main's history."
git push
```

**Verify** (both):

```sh
git show --name-only --format='' HEAD | awk -F/ '{print $1}' | sort -u
git diff --name-only origin/main...HEAD | grep -cE '^(plans|roadmap|research)/'
```

→ the first prints exactly `plans`, `research`, `roadmap` (the strip touched nothing else); the second prints `0` (grep exits 1 on zero matches — the count `0` is the success signal, not the exit code). A non-zero count means an artifact path survives in the merge diff: find it (`git diff --name-only origin/main...HEAD | rg '^(plans|roadmap|research)/'`) and remove it in a fix-up commit with the same subject shape, then re-verify. Do not proceed with a non-zero count.

### Step 12: Run the full merge-readiness gate

```sh
cargo xtask ci
```

Run on the post-strip tree — this is the exact tree that merges. Not `--fast` (skips the powerset lane that catches feature-combination fallout from plan 005's new dependency), not `mise run ci` (only 3 of 6 partitions).

**Verify**: exit 0. Paste the final summary line into the report. On failure, apply the STOP rule for unrelated lanes below.

### Step 13: Refresh the PR body to match the final diff

The package is one PR opened from `roadmap/termrock-migration` (opened as draft after plan 005's first push per the hub, operator directive 2026-08-20); PR-body refresh happens at merge-readiness — this step — not per commit (PULL_REQUESTS.md:231).

1. Read the current body and number: `gh pr view --json number,title,body`.
2. Rewrite it against the finished diff, following `.github/PULL_REQUEST_TEMPLATE.md` and `PULL_REQUESTS.md`:
   - **What ships / Behavior changes** at feature level — no function names, no file-by-file inventory, no test lists (PULL_REQUESTS.md:125-126). Name the adopted component set at the experience level (substrate re-platformed, experience unchanged), the `keyboard_help` overlay as the one addition, and the parity proof story.
   - **Verify locally** with the `jackin-dev pr sync <PR_NUMBER>` checkout block (PULL_REQUESTS.md:42-44).
   - This is a console/TUI PR: put the console smoke first, listing the keys/clicks the operator walks (PULL_REQUESTS.md:102) — include opening `keyboard_help` with `?` and dismissing with Esc.
   - The capsule block rule: the diff touches `crates/jackin-tui/`, which is in the `jackin-capsule` dependency closure (`crates/jackin-capsule/Cargo.toml:39`), so `jackin-dev pr sync` exports a local capsule and the body needs the `### jackin-capsule smoke` block after `### User smoke` (PULL_REQUESTS.md:50-59). Confirm against the final diff first: `git diff --name-only origin/main...HEAD | rg '^crates/(jackin-capsule|jackin-tui)/'` → hits mean the block is mandatory.
   - Include the docs verification gate block (the one sanctioned mechanical check, PULL_REQUESTS.md:128).
   - No deployed-docs links, no open-PR references, no hard-wrapped paragraphs.
3. Write it to a file and apply with `gh pr edit --body-file <file>` (never `--body "…"`), then read the rendered body back (`.github/AGENTS.md`).

**Verify**: `gh pr view --json body -q .body | rg -n "jackin-dev pr sync|jackin-capsule smoke|User smoke"` → all present, the `jackin-dev pr sync` line appears before the smoke headings, and `### User smoke` appears before `### jackin-capsule smoke`.

### Step 14: Protocol writes on the roadmap branch + final goal check

Under the one-branch law (operator directive 2026-08-20), the artifact strip commit and the protocol writes both land directly on `roadmap/termrock-migration`:

1. Confirm the strip is the branch tip: `git log -1 --format=%s` → the strip subject. If anything landed after the strip, STOP and report.
2. Update the hub row 014 to DONE, citing this session's command output (the proof-set lines, the strip verification, the `cargo xtask ci` exit 0). Record "console modernization phase DONE" in the roadmap item's Log with the PR reference (draft, merge is the operator's — mirror the bump phase's Log entry shape), and update the item's `roadmap/README.md` row in the same edit. The item itself stays IN EXECUTION (capsule/launch/small phases pending — hub protocol step 7). Note: with the strip applied, `plans/` and `roadmap/` no longer exist in the worktree — restore them for these protocol writes from the strip's parent (`git checkout 'HEAD^' -- plans/ roadmap/ research/`), so the status row and item Log remain the artifact home while the merge diff still strips them. Commit and push.
3. Final act (hub protocol): `sh plans/termrock-migration/goal-check.sh` on the clean tree → paste its final line; it must start with `TAILROCKS GOAL: PASS`.

**Verify**: the goal-check final line starts with `TAILROCKS GOAL: PASS`; `git branch --show-current` → `roadmap/termrock-migration`; branch fully pushed (`git log origin/roadmap/termrock-migration..roadmap/termrock-migration --oneline` empty).

## Test plan

This plan is documentation-and-verification work; its scenarios are checked by commands, not by new Rust tests.

- **Spec scenario "Text snapshot diff during modernization" (final audit half)** — step 10.1 is the test: `cargo xtask ci --only snapshots` exit 0 plus the `git diff --name-only origin/main...HEAD -- '*.snap'` membership audit. Independent source of truth: the committed fixtures on `origin/main`, not the working tree's render.
- **Spec scenario "Parity proof set complete"** — step 10 in full: all five proof lines green in one recorded run. Independent sources of truth: committed baselines (snapshots, PNGs), the nextest runner's own counts, the lane's exit code.
- **Spec scenario "Unintended paint change fails"** — step 9's no-re-bless branch is the enforcement: any unexplained PNG failure is a STOP, never a bless. (The scenario's positive half — the compare failing on a real change — is the lane's own test, plan 005's territory.)
- **Spec scenario "Deliberate re-bless"** — step 9's re-bless branch: bless only via the discovered bless path, changed PNGs visible in the commit diff, commit whole-diff `*.png`.
- **Spec scenario "Both gates run"** — step 10.1 and 10.3 are the two gates, run and recorded independently.
- **Docs scenarios (B4-class, same shape as plan 004)** — step 6.2's closing grep (no dead names) and step 6.3's reverse-resolution check (no invented names). Independent source of truth: `crates/` via grep-back.
- **N4 closing check** — step 3's keyboard_help documentation pass plus the sweep's own observation: if the docs work surfaced any other new operator-visible UI, the plan STOPs (see STOP conditions).
- **Verify**: `cargo xtask ci` → exit 0 (step 12), which includes every lane above as a partition or a covered suite.

## Done criteria

Machine-checkable. ALL must hold, each checked against command output from this session:

- [ ] `cargo xtask ci` exits 0 (full gate, run on the post-strip tree — after the last repository change on the execution branch)
- [ ] `cargo xtask ci --only docs` exits 0 and `cargo xtask docs brand` exits 0
- [ ] The `docs/` bun block (`bun run build`, `bunx tsc --noEmit`, `bun test`) completes successfully
- [ ] Step 6.2's closing grep prints nothing (or every remaining hit is an explicitly-marked historical reference quoted in the report), and step 6.3's reverse-resolution check finds every introduced name in `crates/`
- [ ] Final parity proof set recorded from this session: snapshot lane exit 0; `.snap` audit lists only plan-012-traceable console fixtures; `trparity_` all-pass with fresh count stamped; PNG lane exit 0 (precondition run, or re-run after a step-9 re-bless); BrandHeader crop tracked and inside the suite; literal-RGB filter all-pass with fresh count stamped
- [ ] Step 9's decision recorded: either "no recorded look change — no re-bless" with the search output, or the re-bless commit showing only baseline PNGs
- [ ] The strip commit is the execution branch's last content commit: `git show --name-only --format='' HEAD | awk -F/ '{print $1}' | sort -u` → exactly `plans`, `research`, `roadmap`; `git diff --name-only origin/main...HEAD | grep -cE '^(plans|roadmap|research)/'` prints `0`
- [ ] The PR body carries the `jackin-dev pr sync` checkout block before `### User smoke`, and `### jackin-capsule smoke` after it (capsule-closure rule confirmed against the final diff)
- [ ] `sh plans/termrock-migration/goal-check.sh` on the roadmap branch prints a final line starting with `TAILROCKS GOAL: PASS`
- [ ] No files outside the in-scope list modified on the execution branch (`git status`) — excluding the strip's deletions
- [ ] `plans/termrock-migration/README.md` status row for 014 updated to DONE — on `roadmap/termrock-migration`, committed and pushed; item Log entry and `roadmap/README.md` row in the same commit

## STOP conditions

Stop and report back (do not improvise) if:

- Any precondition fails — in particular any hub row 005–013 not `DONE`, a facade-remnant grep with output, the arch gate failing, no PNG lane registered, or the roadmap-branch ancestry check failing.
- **A docs sentence is wrong because the *code* is wrong** — e.g. the console still calls `ModalFlow` after 006, or the `?` trigger is not wired on some stage. That is the owning plan's defect; name the plan, the file, and what you observed. Do not paper over it with invented prose, and do not fix code.
- **The docs sweep discovers an N4 violation**: any new operator-visible screen or overlay beyond `keyboard_help`, or a changed operator journey, introduced by plans 005–013.
- **Any `.snap` diff beyond the plan-012-traceable console set**, any capsule fixture in the audit list, or any `*.pending-snap` file — a parity break; re-blessing text snapshots is never this plan's move.
- **A PNG baseline failure with no recorded, operator-reviewed look change** — an unintended paint change; never bless to make it pass. Likewise, a step-9 search that finds a recorded look change whose re-blessed diff does not correspond to it.
- **The full `cargo xtask ci` fails on a lane unrelated to this package's changes** (e.g. a `policy` advisory, an unrelated crate's test): report the partition name and the first error verbatim, and stop. Do not chase unrelated failures into out-of-scope files.
- **The strip verification prints a non-zero count**, or anything other than the strip landed on the execution branch after the strip commit.
- **The roadmap-branch fast-forward fails** in step 14, or `git merge-base --is-ancestor` flips mid-run.
- The `trparity_` or literal-RGB counts drift without an explaining record from the plan that caused it.
- Any step's verification fails twice after a reasonable fix attempt.

## Maintenance notes

- The capsule surface's finalization and plan round come next (hub protocol step 7); its closing plan will mirror this one's shape — docs sweep, final proof set, artifact strip, merge-readiness — against the capsule package's own proof inventory. Whatever vocabulary this plan lands in the TUI reference pages is the baseline that round edits.
- A reviewer should scrutinize three things: (1) every machinery name introduced in the `.mdx` files greps back into `crates/` (step 6.3's list), (2) the strip commit contains exactly the three artifact trees and nothing else, (3) the step-9 record — the re-bless branch's PNG-only diff, or the no-re-bless branch's search output.
- Deferred on purpose: any broader docs sweep outside the seven TUI reference pages and the watchlist (step 6.2 extends only to dead-name hits, one line each, named in the report); the capsule/launch facade-item documentation end state (their own phases retire those items; this plan describes them as retained-for-those-surfaces).
- `cargo xtask docs brand` and the bun docs-site gate are not part of `cargo xtask ci`; they run here because this plan edits published prose. The next docs-touching plan must run them explicitly too.
- The execution branch is handed to the operator for merge after step 14; the hub's merge-is-the-operator's law binds — this plan never marks the PR ready, never merges.
