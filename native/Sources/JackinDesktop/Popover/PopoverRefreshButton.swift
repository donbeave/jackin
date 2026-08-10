// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// Shared 28 pt phosphor refresh control matching `popover.html` `.btn-icon`.
struct PopoverRefreshButton: View {
    let label: String
    var inProgress = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if inProgress {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                }
            }
            .foregroundStyle(Color.jackinPhosphor)
            .frame(width: 28, height: 28)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.jackinPhosphor.opacity(0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.jackinPhosphor.opacity(0.28), lineWidth: 0.5)
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}
