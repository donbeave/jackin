# 07 — Facade trait retirement inventory (console phase)

Vetted: 2026-08-19 (citation check: all citations verified; three fixes applied — ModalOutcome is NOT console-exclusive (facade-internal `operator_info.rs` consumes it), test-file count 9→14, `ready_blocking_subscription` cite disambiguated)
Questions: what exactly retires from the jackin-tui facade when the console surface migrates to upstream contracts (D22), in what compile-green order, and what stays for later phases.
Informs: roadmap `termrock-migration` console-phase sequencing; facade deletion PR split.
Method: full read of facade files; `rg` consumer sweep across all 6 workspace crates; upstream API verification at pinned checkout. jackin @ `roadmap/termrock-migration` (= main `955b2fea` sources); TermRock @ `29a16b5b`. All line refs read directly. Confidence HIGH unless marked.

Settled end-state (2026-08-19, D22): facade = `tokens` + `operator_info` only; no compat shim; retirement is per-surface.

## Findings

### Facade public surface

All in `crates/jackin-tui/src/`; crate root re-exports only `ModalOutcome` (lib.rs:20); `runtime` module declared lib.rs:17.

| Item | Location | Signature / shape |
|---|---|---|
| `SubscriptionPoll<Event>` | runtime.rs:20-27 | enum `Ready(E)/Pending/Closed` |
| `Subscription` | runtime.rs:30-36 | trait; `type Output; fn poll_next(&mut self) -> SubscriptionPoll<Output>` |
| `Dirty` | runtime.rs:40-63 | enum `Clean/Redraw`; `is_dirty()`, `merge()` |
| `NoEffect` | runtime.rs:67 | uninhabited enum |
| `UpdateResult<Effect=NoEffect>` | runtime.rs:72-125 | struct{dirty,effects}; `clean()/redraw()/with_effect()/dirty()/is_dirty()/effects()/merge()` |
| `Component<Event,Message>` | runtime.rs:128-131 | trait; `fn handle_event(&mut self,&Event)->Option<Message>` |
| `View<Model>` | runtime.rs:134-137 | trait; `fn render(&self,&Model,&mut Frame,Rect)` |
| `drive_frame` | runtime.rs:140-156 | fn over `Terminal<B>` + `View` + overlay closure → thin `Terminal::draw` wrap |
| `drive_render` | runtime.rs:159-168 | fn `Terminal::draw(render)` wrap |
| `SurfaceFocusTarget<Content>` | runtime/focus.rs:11-16 | enum `TabBar/Content(C)` |
| `SurfaceFocus<Content>` | runtime/focus.rs:20-106 | wrapper over `FocusGraph<SurfaceFocusTarget<C>>`; ctors `tab_bar/content`; `focused/focused_content/focus_tab_bar/focus_content/is_tab_bar/is_content/show_cursor_for` |
| `ModalFlow<Modal>` | runtime/modal_flow.rs:11-119 | `current/parents` + depth-only `OverlayStack`; `new/current/current_mut/parents/parents_mut/is_open/has_parent/open/open_sub/pop/clear/take_current/set_current/open_pair` |
| `ModalOutcome<T>` | modal_outcome.rs:9-16 | enum `Continue/Cancel/Commit(T)` |
| tests | runtime/tests.rs (decl runtime.rs:170-171) | removed with module at final retirement |

### Console consumers → upstream replacement

Console = `crates/jackin-console` + `crates/jackin/src/console` adapter. Upstream refs at TermRock checkout: `EventResult` interaction/event_result.rs:142, `Redraw` :16, `Propagation` :44, `FocusRequest` :72, `OverlayRequest` :99; re-exported interaction/mod.rs:22-25. `FocusGraph` focus_graph.rs:203, `FocusNode` :68 (re-exp mod.rs:26-28). `OverlayStack` overlay_stack.rs:755, `OverlaySpec` :364, `OverlaySize` :137 (re-exp mod.rs:53-57). `ReadySubscription`/`ReadySubscriptionPoll`/`ready_subscription` runtime/subscription.rs:22/9/49 (re-exp runtime/mod.rs:30).

| Facade item | Console consumer sites | Replacement (confidence) |
|---|---|---|
| `View<ConsoleState>` | impl jackin-console/src/tui/runtime.rs:25-35; consumed via `drive_frame` jackin/src/console/adapter/run.rs:371 | none upstream; inline as plain fn + `Terminal::draw` (what `drive_frame` wraps, runtime.rs:152-155). TermRock `runner::run` (runtime/runner.rs:58) owns whole loop — not a drop-in. HIGH |
| `drive_frame` | jackin/src/console/adapter/run.rs:371 | direct `terminal.draw` with overlay closure inline. HIGH |
| `Subscription`/`SubscriptionPoll` | impl runtime.rs:43-53 (`BlockingSubscription`); poll sites: state/manager.rs:648-678+, components/file_browser/git_prompt.rs:69-76, screens/editor/model/state_impl/pending.rs:98,148,193,236 (fn-local imports :95,145,190,233), screens/settings/model/auth_impls.rs:266-269; rx fields tui/subscriptions.rs:158,178,212,245 | `ReadySubscription` covers Ready/Closed one-shot only — **no upstream `Pending`** (subscription.rs:9-14). Console keeps product-owned `BlockingSubscription` + local poll enum; upstream usable only for ready-once arms. MED (mapping), HIGH (sites) |
| `UpdateResult` | alias tui/update.rs:13-15 (`ConsoleUpdate<E>`), state/update.rs:83 (`ManagerUpdate`); ctor `ManagerUpdate::redraw()` state/update.rs:307; **all results discarded** (`drop`/`let _unused`): input/dispatch.rs:202-447, jackin/src/console/adapter/run.rs:556-889; `ManagerEffect` channel dead (no `with_effect` anywhere) | `termrock::interaction::Redraw` (event_result.rs:16) or `EventResult<M>`; realistically `()` since discarded. HIGH |
| `Dirty` | none direct (only via `UpdateResult`) | `Redraw::needs_paint()` (event_result.rs:36). HIGH |
| `Component` | none (doc mention only, tui/runtime.rs:6-7) | n/a — nothing to migrate in console. HIGH |
| `SurfaceFocus`/`SurfaceFocusTarget` | state.rs:23; state/manager.rs:159; settings/model.rs:45,157-206,435; screens/editor/model.rs:14; editor/.../navigation.rs:5,87,120-126,231,271-310; tests state/update/tests.rs:12, editor model/tests.rs:1846,1871 | `FocusGraph` + `FocusNode` direct (focus_graph.rs:203,68) with console-owned identity enum; port zero-rect register-per-mutation pattern (focus.rs:46-58). HIGH |
| `ModalFlow` | settings/model.rs:1105,1131,1350 (fields/ctor), 1164-1214 (`clear/open_sub/pop/is_open`); auth_impls.rs:41, env_impls.rs:28,60; reads view.rs:565-704, file_browser.rs:417-827, input/global_mounts.rs:202-606 (`take_current` :566) | `OverlayStack` direct (overlay_stack.rs:755) + product-owned `current/parents`; stack half is depth-only zero-geometry (modal_flow.rs:111-118) — near-vestigial. HIGH |
| `ModalOutcome` | components: agent_choice.rs:9, confirm_save.rs:20, dialogs.rs:8, github_picker.rs:14, mount_dst_choice.rs:21, role_picker.rs:7, scope_picker.rs:8, source_picker.rs:8, workdir_pick.rs:10; planners model/create_prelude.rs:175-256, update.rs:602-816, run.rs:233-239; input/editor.rs:1054; screens/settings/update.rs:21, screens/workspaces/update.rs:13 (+14 console test files) — **plus facade-internal consumer `operator_info.rs:15` (`use crate::ModalOutcome;`), whose public API returns `ModalOutcome<()>` (`handle_key`, operator_info.rs:203,241)** | **no upstream analog** (TermRock outcomes are per-widget: `CollectionOutcome` mod.rs:17, `OverlayOutcome`, `DismissDecision`; none Commit/Cancel/Continue). Canonical enum homes in jackin-oppicker (cycle-free: console already depends on oppicker); precedent: oppicker already owns an identical local enum (adapters.rs:6). HIGH |

### Stays-until-later-phase set

| Item | Blocking surface | Sites |
|---|---|---|
| `Component` | capsule | jackin-capsule/src/tui/runtime.rs:34 |
| `View` | capsule, launch | capsule runtime.rs:17; jackin-launch/src/tui/model.rs:115 |
| `drive_frame` | capsule, launch | capsule daemon/compositor.rs:394; launch run.rs:451 |
| `drive_render` | launch | launch run.rs:520,559,606,644,663,739,805,919,1125 |
| `UpdateResult` (+`Dirty` member) | launch | launch update.rs:7,14,193 |
| `NoEffect` | launch | launch effect.rs:10 |
| `Subscription`/`SubscriptionPoll` | oppicker (and console consumes oppicker type) | jackin-oppicker adapters.rs:2, load.rs:7; console op_picker/load.rs:6,28 uses `jackin_oppicker::BlockingSubscription` |
| `SurfaceFocus`/`SurfaceFocusTarget` | capsule | capsule view.rs:12, daemon/compositor.rs:151-155 (+5 test sites) |

Note: oppicker's `ModalOutcome` is crate-local (adapters.rs:6), does **not** block facade `ModalOutcome` deletion.

### Retirement mechanics notes

- **Deletable this phase:** `ModalFlow` (runtime/modal_flow.rs + runtime.rs:13,16) — console-exclusive. `ModalOutcome` (modal_outcome.rs + lib.rs:15,20) — deletable ONLY AFTER `operator_info` migrates off it: `operator_info.rs` (part of the settled end-state facade) consumes `crate::ModalOutcome` in its public API (:15, :203, :241), and jackin-tui cannot depend on the enum's new home (layering). Sequence: migrate operator_info to its own outcome type (or an equivalent small contract) first, then delete the facade enum. All other items: console migrates off, item stays until blocking surface's phase; `runtime` module + runtime/tests.rs survive to final phase.
- **Atomicity:** no shim → each item's console migration lands in one commit with all its call sites. `View`+`drive_frame` must change in the same PR across two crates (impl in jackin-console, call in jackin adapter/run.rs:371); workspace CI compiles both.
- **`update_manager` return-type change** (state/update.rs:93) ripples to ~15 discard sites (dispatch.rs, adapter/run.rs, state/update.rs:972-1014) — mechanical, all `drop`/`let _unused`.
- **Focus semantics to preserve:** `focused()` fallback to `TabBar` when graph empty (focus.rs:61-66); zero-area registration keeps graph keyboard-only (focus.rs:48-57).
- **ModalFlow `OverlayStack` coupling is fake-depth** (id `modal-{depth}`, zero rect/spec, modal_flow.rs:112-118): migration can drop the stack entirely or hold a real `OverlayStack` — decision needed in-phase; upstream `OverlayStack` requires real geometry to be useful (overlay_stack.rs:755, `OverlaySpec` :364).
- **Subscription gap:** facade tri-state vs upstream bi-state means console's `BlockingSubscription` becomes product-owned code in jackin-console, not an upstream adoption; only ready-once producers (`ready_blocking_subscription`, jackin-console/src/tui/runtime.rs:55-59) map cleanly to `ready_subscription` (subscription.rs:49).

## Dead ends and contradictions

- `Component` has no console consumers (doc mention only) — nothing to migrate there this phase.
- `ModalOutcome` has no upstream analog (per-widget outcomes only) — no-carrier; moves into jackin-console, oppicker precedent.
- TermRock `runner::run` owns the whole loop — rejected as a `View`/`drive_frame` replacement (arch gate keeps run loops surface-owned).
- Embedded instructions in sources: none found (doc comments descriptive only). Secrets: none observed.

## Open unknowns

- Subscription `Pending` mapping gap (MED): whether any console blocking arm can be reframed ready-once, or all stay product-owned — resolved in-phase per call site.
- ModalFlow migration shape (drop fake-depth stack vs hold real `OverlayStack`) — decided in-phase per the console modal geometry work.
