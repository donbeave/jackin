# Regions — Unified Agent Usage prototype

Region contract for the post-signoff baseline that `tailrocks-macos-visual-qa`
freezes from this package. Derived from
[NativeComponentMap.md](../../UnifiedAgentUsage/NativeComponentMap.md): the
selected design declares **zero CUSTOM regions**, so no region is pixel-gated.
Rects are recorded at the typical 920 × 620 Usage geometry (popover at its
fixed 380 × 520), from the top-left of the owning surface, in points; for
structural regions the rect is informational, not a gate.

| Region | Class | Rect (pt, from top-left) | Mode | Budget |
|---|---|---|---|---|
| Status items (per committed `statusBarGlanceRows`) | NATIVE | menu bar, trailing | structural | — |
| Popover shell (`NSPopover`, transient) | NATIVE | 0,0 → 380,520, anchored to clicked item | structural | — |
| Popover identity header (product row, provider, account, summary) | NATIVE-COMPOSED | 0,0 → 380,~110 | structural | — |
| Popover quota-window list | NATIVE | 0,~110 → 380,~420 | structural | — |
| Popover state band (stale/error + Retry, conditional) | NATIVE-COMPOSED | 0,~420 → 380,~478 | structural | — |
| Popover footer (Refresh, Open Usage, account menu) | NATIVE-COMPOSED | 0,~478 → 380,520 | structural | — |
| Status-item right-click menu (explicit `NSMenu`) | NATIVE | below clicked item | structural | — |
| Usage window chrome + unified toolbar (`.toggleSidebar`) | NATIVE | 0,0 → 920,~52 | structural | — |
| Detail top accessory (centered product identity, trailing Refresh) | NATIVE-COMPOSED | 190,52 → 920,92 | structural | — |
| Sidebar (Overview + provider destinations, 190–280 pt) | NATIVE | 0,52 → 190,620 | structural | — |
| Overview grouped Table (provider group rows, account children) | NATIVE | 190,92 → 920,620 | structural | — |
| Provider detail Form (identity, State, Limits) | NATIVE | 190,92 → 920,620 | structural | — |
| Empty / loading / global-error content region | NATIVE | 190,92 → 920,620 | structural | — |
| Settings window Form | NATIVE | 0,0 → 440,260 own window | structural | — |

Notes:

- Structural mode = component present, in the right region, correct role,
  label, and state, checked through the accessibility tree.
- No region is drawn by the design itself; there is nothing to budget.
  If a CUSTOM region is ever introduced, it enters this table with a point
  rect and an explicit changed-pixel budget in the same change.
- The `--tr-backdrop` window is harness-owned and excluded from every region.
- Window title text is chrome; any future pixel region excludes the title bar.
- Hover/pressed states, motion, VoiceOver traversal, keyboard paths, and the
  real accessibility-settings matrix are not provable by static captures;
  SIGNOFF.md names where each landed.
