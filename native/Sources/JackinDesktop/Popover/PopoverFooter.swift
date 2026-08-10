// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// Popover sticky footer dock — **Open Usage Window** glass capsule (FB1-43 / LG-A8).
///
/// One primary CTA (not a competing Refresh slab). Global refresh remains via
/// View menu / ⌘R on the app; OV-9 rejected a second global Refresh footer.
public struct PopoverFooter: View {
    public let title: String
    public let onOpenUsage: () -> Void

    public init(
        title: String = "Open Usage Window",
        onOpenUsage: @escaping () -> Void
    ) {
        self.title = title
        self.onOpenUsage = onOpenUsage
    }

    public var body: some View {
        Button(action: onOpenUsage) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.split.2x1")
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.body.weight(.semibold))
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(Color.primary)
            .contentShape(Rectangle())
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
        .background {
            // Glass capsule + phosphor hairline (FB1-43) — not a solid green slab.
            GlassFallbacks.floatingChromeIsland()
                .overlay {
                    RoundedRectangle(
                        cornerRadius: GlassFallbacks.chromeTileCornerRadius,
                        style: .continuous
                    )
                    .strokeBorder(Color.accentColor.opacity(0.45), lineWidth: 1)
                }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: GlassFallbacks.chromeTileCornerRadius,
                style: .continuous
            )
        )
        .accessibilityLabel(title)
    }
}
