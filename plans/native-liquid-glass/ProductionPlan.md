# Confirmed A1 production plan

Status: **P1–P4 complete**

## Authority and stop line

The operator confirmed the runnable native direction with `I confirm the runnable A1 native concept.` Production must preserve A1, the D-002 jackin❯ identity placement, and the D-003 fixed leading sidebar control. Code structure may improve; visible structure, hierarchy, material ownership, content/functional classification, and brand behavior may not silently change.

Stop and return to the operator if a required visible region needs a CUSTOM control, custom glass, a design change, a new domain semantic, a weakened gate, unavailable GUI permission, or an API unavailable on the selected macOS 26 baseline.

## Observable acceptance

- A primary provider status-item click opens one real transient `NSPopover` focused on that provider; the popover has no cross-provider tab system.
- The popover uses native account selection, readable Rust-owned metadata and limits, visible refresh/recovery, and Open Usage preserving provider/account context.
- Usage uses a two-column `NavigationSplitView`: Overview plus Rust-ordered providers in the sidebar, native `Table` Overview, native provider detail, provider-scoped account selection, system toolbar/menu commands, and no visible `Usage` title.
- Exactly one native sidebar toggle stays visible, hittable, and at the same leading toolbar coordinates before collapse, after collapse, and after reopen.
- The canonical generated `jackin❯ by tailrocks` wordmark stays noninteractive in the quiet sidebar footer. Healthy quota progress uses adaptive phosphor; warning and danger use text plus system semantic color.
- Close/reopen, provider removal, refresh success/failure, app activation, popover-to-Usage transition, selection, scrolling, and standard commands preserve valid context and fail safely.
- Every visible region remains NATIVE or NATIVE-COMPOSED and CONTENT or FUNCTIONAL. CUSTOM count, explicit `glassEffect` count, `GlassEffectContainer` count, and app-owned material count remain zero.
- The app builds only for the declared current macOS 26 baseline through the generated Xcode application target. Rust remains authoritative for provider/order/quota/account/refresh semantics and every domain string.
- Final branch-head captures and interaction evidence cover the complete [RequiredStates.md](RequiredStates.md) matrix; accessibility audits cover popover, Overview, and provider detail.
- Canonical operator, contributor, roadmap, build, and PR documentation describe the production behavior and no longer claim macOS 14, HTML pixels, custom glass, provider tabs, account pills, or concept-only authority.

## Explicit non-goals

- Apple credential provisioning, notarized publication, Homebrew release activation, or PR merge.
- Capture-gated Amp paid-plan wire parsing.
- New providers, configuration concepts, prices, spend history, trends, forecasts, analytics, or commercial actions.
- Compatibility UI or handcrafted material for pre-macOS-26 systems.
- Deferred All Accounts, Status & Sources, incident metadata, collapsible secondary metrics, or configuration-UI candidates.

## Coverage ledger at confirmation

| Area | Current evidence | Gap before production completion |
|---|---|---|
| Project baseline | `project.yml`, macOS 26 target, Swift 6 strict concurrency, generated Xcode app/UI-test targets, pinned format/lint/dead-code tools, ad-hoc build verification | Release workflow and canonical docs still state macOS 14 and stale Xcode selection; regeneration cleanliness needs branch-head proof |
| Domain ownership | `PresentationStore`, UniFFI DTOs, parity harnesses, source-confinement tests | Live surface removal can leave stale Usage selection unless explicitly normalized |
| Usage lifecycle | Real `NSWindow`, `NavigationSplitView`, native toolbar, frame autosave | app reopen currently asks for Overview instead of preserving valid destination; close/reopen continuity lacks an integration test |
| Sidebar | One fixed `.navigation` toolbar button and UI coordinate test | Preserve the same slot through production cleanup and reopen coverage |
| Overview/detail | Native `Table`, `List`, `Section`, `LabeledContent`, `ProgressView`, menu `Picker` | Add complete recovery/continuity evidence and remove concept/card-era naming and authority residue where it can mislead maintainers |
| Popover | Real `NSPopover`, native `Form`, account picker, limit rows, visible actions | Hidden shortcut-only Refresh button violates the approved component map; move the shortcut to the visible native action |
| Menus/commands | Native App/File/Edit/View/Window/Help menu and status-item context menu | Prove Command-R, Command-comma, Command-W, Usage reopen, and popover-to-Usage routing in the running host |
| Fixtures/states | Deterministic F00–F14 catalog, isolated from bridge/network/credentials | Reframe as final visual-QA fixtures, prove no destructive controls, and bind each required row to final evidence |
| Accessibility | Provider-detail `performAccessibilityAudit`, labels, identifiers | Run audits on Overview and real popover; prove long labels, focus, non-color state, and native action reachability |
| Liquid Glass | Custom-glass and material helpers deleted; architecture lint count zero | Repeat region audit after production edits and capture final system-owned material states from the real hosts |
| Runtime QA | Real concept captures with window-ID metadata and restored settings | Regenerate a complete `evidence/final/` matrix from final branch HEAD; concept screenshots cannot prove final code |
| Documentation | Approved design artifacts and concept handoff exist | Operator guide, native README, ADR, roadmap state, and PR body describe retired architecture and pending confirmation |
| Repository readiness | Focused desktop gates pass at confirmation commit | Run `mise install`, desktop gates, docs gates, `cargo xtask ci --fast`, and `cargo xtask ci` at final branch HEAD; reconcile remote checks without weakening failures |

## Execution record

- **P1 complete:** visible popover Refresh owns Command-R; Usage retains valid provider/account/sidebar/frame state; removed providers normalize at the state owner; local/global Retry stays native; production names replace concept/card-era names; model and real-host tests cover continuity, commands, scrolling, context routing, menu order, destructive-action absence, and all three accessibility surfaces.
- **P2 complete:** the release lane uses macOS 26 and Xcode 26.6; the Xcode project regenerates cleanly; operator and contributor docs describe the focused popover, two-column Usage window, fixed leading sidebar control, limits-only contract, and current platform floor; roadmap state retains only external release and capture-gated work.
- **P3 complete:** source `c69a237b0b80c62164df34a39edd6578d78d81c9` has 36 core and eight accessibility real-host captures, exact provenance, byte-identical setting restoration, 15/15 real-host tests with zero runtime warnings, all three accessibility audits, and a hard-failure-free design review. Source `7c8fca3fcbfa02f50e80ec1364475bd396173b98` adds operator-confirmed A08 Clear and A09 Tinted evidence for both native surfaces.
- **P4 complete:** DCO repair, main synchronization, evidence documentation, complete branch-head repository/docs gates, original Clear preference restoration, clean-tree proof, and final draft-PR reconciliation are complete. [`CompletionAudit.md`](CompletionAudit.md) is the authoritative DONE-criteria ledger.

## Slice P1 — Production state and interaction correctness

Owned files: native presentation/store models, app/window/popover hosts, Usage views, unit tests, UI tests, architecture/parity harnesses.

Work:

1. Remove the hidden shortcut-only popover button and bind Command-R to the visible native Refresh action.
2. Preserve the current valid Usage destination when reopening the retained window; keep explicit Overview/provider entry paths distinct.
3. Normalize a selected provider that disappears or becomes disabled to Overview at the state owner, not as a view-only illusion.
4. Keep local/global recovery actions visible and native without clearing last-good data.
5. Replace concept-only or HTML-authority wording/names that would make the final architecture ambiguous; keep deterministic fixture launch support explicit and isolated.
6. Add focused model and real-host tests for provider removal, close/reopen, account continuity, popover-to-Usage routing, standard commands, scrolling, no destructive action, and all three accessibility surfaces.

Verification: `mise run desktop-format-check`; `mise run desktop-lint`; focused Swift/Xcode tests; `mise run desktop-test`; `mise run desktop-test-ui`; `mise run desktop-deadcode`.

Done: every P1 acceptance path passes without a second control path, stale selection, custom component, custom glass, or fixture bridge mutation.

Recovery: revert the complete P1 commit if native lifecycle or bridge ownership regresses. Do not retain a view-only fallback while the store still owns an invalid selection.

## Slice P2 — Shipping baseline and documentation truth

Owned files: release workflow baseline, shared task declarations, native README, operator guide, ADR, roadmap item/status view, design artifacts, generated brand documentation when touched.

Work:

1. Align release build environment and Xcode selection with macOS 26.0 and Xcode 26.6; use canonical desktop tasks where the workflow has a macOS GUI/toolchain boundary.
2. Regenerate the Xcode project twice and prove no unexplained tracked diff.
3. Rewrite operator documentation around the focused popover, native two-column Usage window, fixed sidebar toggle, native picker/table/list behavior, current platform floor, and limits-only contract.
4. Rewrite contributor architecture around current SwiftUI/AppKit boundaries and remove HTML/CSS, provider-tab, card, pill, fallback-glass, and concept-gate claims.
5. Advance the roadmap current-state boundary while leaving genuinely external release activation and capture-gated Amp work open.

Verification: workflow lint through repository gates; `bun install --frozen-lockfile`; `bun run build`; `cargo xtask docs repo-links`; `cargo xtask roadmap audit`; `cargo xtask research check`; `bunx tsc --noEmit`; `bun test`.

Done: code, release configuration, published docs, roadmap, and design artifacts describe one current production architecture.

Recovery: revert baseline/docs slice together if workflow and documented build contract cannot stay identical. Do not restore a pre-26 visual lane.

## Slice P3 — Final material, visual, accessibility, and design acceptance

Owned files: QA scripts, final capture evidence and metadata, state/fixture coverage ledger, final audit records.

Work:

1. Re-audit every visible region against [NativeComponentMap.md](NativeComponentMap.md) and [LayerMap.md](LayerMap.md); reject content glass, nested glass, custom material, hidden controls, card-era navigation, and unapproved CUSTOM regions.
2. Build the exact branch-head app and run atomic kill-launch-drive-window-ID capture across all required appearance, active/inactive, accessibility, size, content, recovery, scrolling, and sidebar states.
3. Exercise keyboard, pointer, menu, focus, VoiceOver/accessibility-tree, close/reopen, status-item, popover, Usage, selection, refresh, and recovery paths.
4. Restore every modified macOS setting on success, failure, and interruption; record receipts and host/runtime/toolchain metadata.
5. Review final captures only against A1, D-002, D-003, D-004, component/layer maps, brand contract, and actual native behavior. Correct every hard failure and repeat until stable.

Verification: final capture manifest completeness; all UI/accessibility tests; architecture lint; no forbidden-source scans; manual clear/tinted Liquid Glass preference evidence remains operator-owned because macOS has no public read API.

Done: every required-state row points to branch-head evidence or an explicitly operator-owned manual preference observation; no hard design failure remains.

Recovery: delete and regenerate incomplete final evidence. Never relabel concept screenshots as final evidence.

## Slice P4 — Completion, full gates, and PR reconciliation

Owned files: plan statuses, required-state ledger, PR title/body, final test record, working tree and branch state.

Work:

1. Fetch current `main`; merge normally if behind; never rebase or force-push.
2. Re-run all done criteria after any merge and reset stale evidence honestly.
3. Run `mise install`, all desktop gates, `cargo xtask ci --fast`, `cargo xtask ci`, and every docs gate at final branch HEAD.
4. Inspect failures to root cause; never weaken tests, expected output, architecture policy, accessibility, or design acceptance.
5. Reconcile the one draft PR body with objective, both operator approvals, before/after real captures, component/layer maps, AppKit boundaries, baseline changes, exact results, final QA matrix, accessibility result, limitations, and deferred external work.
6. Keep the PR open, draft or ready according to actual evidence, and unmerged unless the operator separately authorizes merge.

Done: every objective criterion is proven, tree is clean, commits are conventional/signed/co-authored/pushed, branch is current, exactly one PR contains complete evidence, and no required plan row remains pending.

## Exact final command set

```sh
mise install
mise run desktop-generate
mise run desktop-format-check
mise run desktop-lint
mise run desktop-deadcode
mise run desktop-test
mise run desktop-test-ui
mise run desktop-build
mise run desktop-verify
cargo xtask ci --fast
cargo xtask ci
```

```sh
cd docs
bun install --frozen-lockfile
bun run build
cargo xtask docs repo-links
cargo xtask roadmap audit
cargo xtask research check
bunx tsc --noEmit
bun test
```

## Completion condition

Production is complete only when all four slices are done and every original DONE criterion has current authoritative evidence. Green concept-era checks, screenshots, or draft-PR metadata cannot substitute for final branch-head proof.
