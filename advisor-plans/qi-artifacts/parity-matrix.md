# Parity matrix — criteria 1–3

**Authority:** `advisor-plans/qi-artifacts/EVIDENCE_LEDGER.toml`  
Do not cite PNG paths that are not ledger-pass (or explicit `*.BLOCKED.txt`).

| Criterion | Status | Evidence (ledger only) |
|-----------|--------|------------------------|
| Status dual-stack template mono; no glass chips | Present | Ledger `status-desktop` harness Dark+Light (`status-desktop-{dark,light}.png` via StatusItemRendering); optional live extras row `status-desktop-live-extras` |
| Left-click full popover focused on provider | Present | Ledger `popover-openai` / `popover-anthropic` harness Dark+Light (`PopoverRoot` G-P1 craft); focus wiring `StatusPopoverFocus` + DesktopSoTParityHarness. **Not** live popover PNGs (ledger `popover-live-click` **blocked**) |
| Right-click Open Usage / Refresh / Quit enabled | Present | StatusItemMenuModel + DesktopSoTParityHarness; ledger `ctx-menu-live` **blocked** (no live PNG) |
| Usage real NSToolbar | Present | Ledger `usage-toolbar` harness (`usage-toolbar-*.png` UsageWindowController) |
| provider≠account nest; 0% empty | Present | Ledger `usage-provider-nest` + `usage-window-openai-*.png` sidebar; SoT meter fractions |
| Detail head + Limit Reset + Open usage | Present | Ledger `usage-detail-openai` harness |
| GlassFallbacks only; limits only | Present | DesktopArchitectureLint + glass-and-limits-grep |
| G-P1 sticky chrome | Present | Ledger `popover-openai` harness Dark+Light (brand · Overview\|Providers · strip) |
| G-U2 sidebar craft | Present | `usage-window-openai-*.png` Browse/logos/selection/nest |

## Blocked (ledger)

| Scene id | Reason |
|----------|--------|
| popover-live-click | `native/popover-live.BLOCKED.txt` — craft = harness only |
| ctx-menu-live | `native/ctx-menu-live-dark.BLOCKED.txt` — rows via model/harness |
