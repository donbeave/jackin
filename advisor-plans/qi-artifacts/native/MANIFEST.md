# DesktopVisualSnapshotHarness manifest (craft artifacts)

status: StatusItemRendering dual-stack + template icons on menu-bar stage
popover: PopoverRoot (TabGrid + body + Footer) via applyQIFixture
usage_detail / overview / nest: shipped SwiftUI roots via NSHostingView
usage_window / toolbar: UsageWindowController — prefer CGWindow non-blank;
  harness rejects pure-black CGImage; falls back to screencapture -l then view bitmap
  (view bitmap may white-out glass sidebar — prefer CGWindow craft when available)

Pixel proof (agent): usage-toolbar + usage-window dark/light non-blank; status light non-blank.
