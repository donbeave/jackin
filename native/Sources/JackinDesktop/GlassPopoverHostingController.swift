// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import SwiftUI

/// Hosts the glance popover SwiftUI root on a **clear** window so Liquid Glass
/// (`GlassFallbacks.panelSurfaceBackground`) can refract the desktop.
///
/// Without clearing the `NSPopover` window, system chrome paints opaque and
/// glass looks like a solid card (fights LG-A1 translucency).
public final class GlassPopoverHostingController<Content: View>: NSHostingController<Content> {
    public override func viewDidLoad() {
        super.viewDidLoad()
        applyClearChrome()
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        applyClearChrome()
    }

    private func applyClearChrome() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        // NSHostingView draws an opaque backdrop unless told otherwise.
        if let hosting = view as? NSHostingView<Content> {
            hosting.layer?.backgroundColor = NSColor.clear.cgColor
        }
        guard let window = view.window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        // Let the glass panel own the soft shadow (avoid double window shadow).
        window.hasShadow = false
    }
}
