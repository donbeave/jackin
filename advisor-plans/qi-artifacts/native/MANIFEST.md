# DesktopVisualSnapshotHarness manifest
out: ../advisor-plans/qi-artifacts/native
popover: PopoverRoot (TabGrid + ProviderTab + Footer) via PresentationStore.applyQIFixture
status: StatusItemRendering.icon + StatusItemRendering.title (AppKit bitmap)
status_live_nsstatusitem: prefer live screencapture when JackinDesktop is running (see VISUAL_QA_LOG)
usage_window: UsageWindowController CGWindow full (sidebar nest + detail) — not blank NSHostingView split
usage_detail: ProviderCardView (+ window detail column)
usage_overview: OverviewListView (+ window overview)
usage_nest: UsageAccountNestView (+ window sidebar when CGWindow OK)
usage_window_openai_dark: BLOCKED
usage_window_overview_dark: OK
usage_window_openai_light: OK
usage_window_overview_light: OK
usage_toolbar_dark: BLOCKED
usage_toolbar_light: UsageWindowController titlebar crop