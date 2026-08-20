# 06 — Mouse-subsystem parity matrix

Vetted: 2026-08-19 (citation check: all 19 rows + cutover verdict + open unknowns SUPPORTS; two annotation fixes applied — row 11 scope, row 14 enforcement cite)
Questions: termrock-migration Q1 — behavioral parity of the mouse subsystem ahead of the C14 cutover (console mouse machinery → `UiContext`/HitRegion + `ScrollArea` wheel/drag).
Informs: C14 gate (console-phase planning); decides proceed / compensate / blocked-on-upstream.
Method: read-only side-by-side of jackin console mouse code + tests (`crates/jackin-console/src/tui/input/mouse.rs`, `mouse/{hover,scroll_bars,scroll_pan,modal_scroll,selection}.rs`, `mouse/tests.rs`, geometry in `tui/layout.rs`, wheel plan in `tui/update.rs`, seam plan in `tui/screens/workspaces/update.rs`, split clamp in `tui/split.rs`) vs TermRock @ `29a16b5b` (`widgets/scroll_area.rs`, `context.rs`, `interaction/mod.rs`, `interaction/scene.rs`, `interaction/overlay_stack.rs`, `interaction/collection.rs`, `widgets/resizable_panel_group.rs`, `scroll/mod.rs`, `scroll/render.rs`). Confidence HIGH unless marked.

Jackin paths shorthand: `J:` = `crates/jackin-console/src/tui/`; TermRock: `T:` = `crates/termrock/src/`.

## Findings

### Parity matrix

| # | Jackin rule (file:line) | Upstream behavior (file:line) | Verdict | Risk / compensation |
|---|---|---|---|---|
| 1 | Wheel axis/modifier classification: native L/R, Shift+vertical→horizontal, caller step — `J:update.rs:437-470` | Same helper `mouse_scroll_delta_with_step` — `T:scroll/mod.rs:487-522` | MATCH (already upstream) | none |
| 2 | Wheel step = 1 line/col both axes — `J:layout.rs:14-15`, consumed `J:mouse.rs:183-194`, `modal_scroll.rs:32` | `ScrollAreaState` defaults step_y=3, step_x=4 — `T:widgets/scroll_area.rs:165-166`; `DEFAULT_HORIZONTAL_SCROLL_STEP=4` — `T:scroll/mod.rs:175` | DIFFERS | LOW — consumer config `.wheel_steps(1,1)` (`T:widgets/scroll_area.rs:189-193`, min-clamped at 1) |
| 3 | Shift+wheel: horizontal first, vertical fallback when horizontal can't move — `J:update.rs:455-467`, `J:mouse.rs:183-187`; test `J:update/tests.rs:345-351` | No carrier: Capture→`Ignored` at edge; NestedPreferChild→`ChainToParent`, never vertical retry — `T:widgets/scroll_area.rs:626-641` | DIFFERS | MED — consumer: on `ScrollOutcome::Ignored` (public, `T:widgets/scroll_area.rs:56-86`) retry with vertical-only axes; or upstream change |
| 4 | Wheel hover-routed to block under pointer, focus re-derived per event — `J:scroll_pan.rs:150,238-242,342`; tests `mouse/tests.rs:1183,1235` | `ScrollAreaState::handle_mouse` ignores `event.position` — `T:widgets/scroll_area.rs:602-613`; routing carrier = `InteractionScene::hit_test` last-registered-topmost — `T:interaction/scene.rs:441-447` / `HitRegion` — `T:interaction/mod.rs:68-73` | NO-UPSTREAM-CARRIER in ScrollArea; MATCH-by-composition | MED — consumer hit-tests position → dispatches to that block's state; registration order must mirror paint z-order |
| 5 | Click in pane sets scroll focus + clears tab-bar focus — `J:scroll_pan.rs:18-127` (focus transfer 100-106, 119-121); tests 1134-1183, 1942 | `InteractionScene::handle_mouse` Down(Left) on focusable hit → `FocusChanged` — `T:interaction/scene.rs:603-619` | MATCH | LOW — register content blocks `focusable(true)` |
| 6 | Hit geometry: half-open rect `point_in_rect` — `J:layout.rs:215-220` | `Rect::contains` in `hit_test`/`HoverState` — `T:interaction/scene.rs:445`, `T:interaction/mod.rs:108` | MATCH | none |
| 7 | Global routing precedence chain: container-info copy → container scroll → picker modal → file-browser modal → tabs → focus → scrollbar drags → wheel → row select → URL → seam/list — `J:mouse.rs:118-261` | No single carrier; mechanism = scene `hit_test` rev-order + `OverlayStack::route_pointer` top/Lower/OutsideTop — `T:interaction/overlay_stack.rs:954-968` | MATCH-by-composition | MED — chain stays consumer code; upstream supplies z-ordered hit + overlay routing primitives |
| 8 | Modal wheel captures before background, including at scroll edge — `J:mouse.rs:140-146`; tests 375-471, 1765 | `OverlayPolicy.wheel_captures` + `wheel_captured(position)` — `T:interaction/overlay_stack.rs:191-192,877-879`; `ScrollChain::Capture` default — `T:widgets/scroll_area.rs:44-46,626-628` | MATCH | LOW — set policy + keep Capture default |
| 9 | Modal wheel = vertical-only step-1, moves picker *selection* saturating (no wrap); keyboard wraps — `J:modal_scroll.rs:20-33`, `J:components/file_browser/state.rs:121-146` | `CollectionState` wrap policy configurable, `move_by` — `T:interaction/collection.rs:139-143,254`; ScrollArea moves offset, not selection | MATCH-via-config (selection model) | MED — picker selection stays consumer `ListState` or migrates to `CollectionState` w/ `.wrap(false)`; outside ScrollArea scope |
| 10 | Scrollbar drag: pointer in track → absolute offset jump (no grab-delta), per-stage targets, modal suppresses — `J:scroll_bars.rs:14-263`, math `J:layout.rs:111-169`; tests 1532, 1799, 1823 | Math primitives already consumed (`scrollbar_offset_for_track_position` `T:scroll/render.rs:158`, area fns) — but `ScrollAreaState::handle_mouse` drops Down/Drag (helper returns None) — `T:widgets/scroll_area.rs:609-613` | NO-UPSTREAM-CARRIER (drag policy) | MED — stays consumer-side post-C14, or upstream adds drag handling to ScrollAreaState |
| 11 | Scrollbar drag also sets scroll focus to dragged block (horizontal drag arms; vertical drag sets no focus) — `J:scroll_bars.rs:36-41,50-55,66-70,100-107` | none | NO-UPSTREAM-CARRIER | LOW — consumer composes focus set with drag |
| 12 | Horizontal-only blocks ignore vertical wheel — `J:scroll_pan.rs:267-269`; test 1206 | `.axes(vertical, horizontal)` gate — `T:widgets/scroll_area.rs:174-178` | MATCH-via-config | none |
| 13 | Background inert while any modal open (wheel, drag, clicks) — `J:scroll_pan.rs:147-149,197-199,235-237,279-281,328-330,339-341`; `scroll_bars.rs:22,75,111,148,197,212`; tests 1556, 1799, 1823 | Overlay layer `owns_input` + `route_pointer` OutsideTop policy — `T:interaction/overlay_stack.rs:954-968`; layer model `T:interaction/scene.rs:307-345` | MATCH-by-composition | LOW |
| 14 | Seam drag: Down within ±1 col of seam starts; anchor-relative pct delta; clamp 20-80%; terminal width <40 disables all mouse (threshold const `J:layout.rs:13`, enforcement `J:mouse.rs:106-108`); Up ends — `J:layout.rs:13,17-18,35-39,96-108`, `J:split.rs:16-26`, `J:screens/workspaces/update.rs:933-969`, `J:mouse.rs:106-108`; tests 227-333, 494 | `ResizablePanelGroup::handle_mouse` — `T:widgets/resizable_panel_group.rs:802-870`: exact 1-cell handle hit (`hit_handle` 258-262), absolute (non-anchor) positioning, per-panel min-size clamp, no width gate | DIFFERS | MED — keep consumer seam code in C14, or upstream change (hit slack + anchor-relative drag option); pct↔min-size clamp mapping unverified |
| 15 | Hover (Moved) sets/clears tab/list-row/mount/trust/copy-row hover, cleared off-area or modal open — `J:mouse.rs:110-116`, `hover.rs:59-161`, `selection.rs:33-52`; tests 610-804 | `HoverState<Id>` consumer-owned over painted `HitRegion`s, clears on miss — `T:interaction/mod.rs:75-118` | MATCH-by-composition | LOW — styling remains consumer; note HoverState takes first-registered (mod.rs:106-108) vs scene hit_test last-registered — pick one convention |
| 16 | `clickable_at` pointer-shape cue facts — `J:mouse.rs:271-321`, `J:run.rs:301-330` | none (regions give geometry only) | NO-UPSTREAM-CARRIER | LOW — consumer derives cue from same hit-test used for dispatch |
| 17 | Container-info dialog dual-axis wheel via `DialogScroll` + `dialog_scroll_axes` — `J:mouse.rs:124-138` | Same API — `T:scroll/mod.rs:214-224,331-345` | MATCH (already upstream) | none |
| 18 | Click on non-row in Trust block deselects via `usize::MAX` sentinel — `J:selection.rs:90-92` | Scene outside-click = layer dismiss policy only — `T:interaction/scene.rs:621-630` | NO-UPSTREAM-CARRIER | LOW — consumer |
| 19 | Telemetry privacy: raw mouse coords never leave process (wire conformance) — `J:mouse/tests.rs:39-156` | N/A — upstream emits no coordinate telemetry | MATCH (constraint preserved) | none — keep test post-cutover |

### Cutover verdict

**Proceed, with compensations — no hard upstream blocker.** Every wheel/click/hover rule has either a direct upstream carrier (rows 1, 5-8, 12, 13, 15, 17) or a cheap consumer config (rows 2, 9). Compensation list for C14:

1. `.wheel_steps(1, 1)` on every `ScrollAreaState` (row 2).
2. Shift+wheel vertical-fallback retry in consumer dispatch on `ScrollOutcome::Ignored` (row 3).
3. Scrollbar **drag** stays consumer-side (jackin `apply_scrollbar_drag` + focus-set) — upstream `ScrollAreaState` has no drag lane (rows 10-11). Optional pre-C14 upstream change: drag support in `ScrollAreaState::handle_mouse`.
4. Seam drag stays consumer-side; `ResizablePanelGroup` is not parity (hit slack 0 vs ±1, absolute vs anchor-relative, min-size vs pct clamp, no width gate) (row 14). Optional upstream change: slack + anchor option.
5. Precedence chain and deselect sentinel remain consumer routing over `hit_test`/`route_pointer` (rows 7, 16, 18).

Parity risk concentrates in rows 3, 10, 14 (all MED) — each has a consumer route, so cutover is **not blocked-on-upstream**; upstream changes are optional hardening, not prerequisites.

## Dead ends and contradictions

- Rows 4, 10, 11, 16, 18 are the no-carrier inventory: upstream supplies primitives (hit_test, route_pointer, drag math) but no widget-level carrier for those rules today; they remain consumer code or become upstream changes per the misfit rule.
- Row 14 contradicts a naive "C17 = resizable_panel_group, done" reading: the widget exists but is not behavior-parity for seam drag; adoption requires compensation (upstream slack + anchor-relative option) or a recorded consumer carve-out.
- No contradictions found between jackin tests and upstream sources.

## Open unknowns

- Whether C14 scope migrates picker modal selection to `CollectionState` (row 9) or keeps jackin `ListState`; saturating-wheel vs wrapping-keyboard split must be preserved either way.
- `move_handle` per-panel min-size semantics (`T:widgets/resizable_panel_group.rs:1070`) unread — exact mapping to jackin's 20-80% clamp unverified (row 14).
- Per-frame re-registration cost of console's full rect set into `InteractionScene`; upstream test `many_frames_are_cheap` (`T:context.rs:639-658`) suggests fine, unmeasured for console.
- Capsule (`jackin-capsule`) mouse paths were out of scope; C14 console-phase only.
