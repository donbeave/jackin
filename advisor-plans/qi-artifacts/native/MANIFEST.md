# DesktopVisualSnapshotHarness manifest

status: StatusItemRendering.icon + StatusItemRendering.title (AppKit bitmap fixture)
status_live_nsstatusitem: **BLOCKED** on CLT — see `status-live-nsstatusitem.BLOCKED.txt`
popover: PopoverRoot (TabGrid + Overview/Providers + Footer) via PresentationStore.applyQIFixture
usage_detail: ProviderCardView (content column only) — solid content path OK
usage_overview: OverviewListView (content) — solid content path OK
usage_nest: UsageAccountNestView — nest structure OK as **component** capture
usage_toolbar: UsageWindowController titlebar crop

## usage_window_* residual (honest)

`usage-window-openai-*.png` / `usage-window-overview-*.png` are **full-window**
captures. On CLT hosts, Liquid Glass sidebar often **whites out** in CGWindow /
view-bitmap fallback (see DesktopVisualSnapshotHarness comments around
CGWindowListCreateImage). Do **not** treat left sidebar nest as verified from
those full-window PNGs alone.

**Accepted structural bar for Usage shell:**
- `usage-provider-nest-*.png` (nest)
- `usage-detail-openai-*.png` (detail)
- `usage-overview-*.png` (overview list)
- `usage-toolbar-*.png` (chrome strip)

Full-window files remain useful for overall chrome silhouette only.
See `usage-window-sidebar.BLOCKED.txt`.
