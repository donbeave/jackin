// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// Popover footer: one Refresh control on a **glass** capsule (LG-A8).
/// Spinner reflects `refreshInProgress`. No other actions.
public struct PopoverFooter: View {
    public let refreshInProgress: Bool
    public let onRefresh: () -> Void

    public init(refreshInProgress: Bool, onRefresh: @escaping () -> Void) {
        self.refreshInProgress = refreshInProgress
        self.onRefresh = onRefresh
    }

    public var body: some View {
        Button(action: onRefresh) {
            HStack(spacing: 6) {
                if refreshInProgress {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text("Refresh")
                Spacer()
                Text("⌘R")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .keyboardShortcut("r", modifiers: [.command])
        .background {
            // Glass control island — chrome only, not a content card.
            GlassFallbacks.floatingChromeIsland()
        }
        .clipShape(RoundedRectangle(cornerRadius: GlassFallbacks.chromeTileCornerRadius, style: .continuous))
    }
}
