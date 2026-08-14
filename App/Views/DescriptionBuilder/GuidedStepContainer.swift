import SwiftUI

/// Shared chrome for one guided-checklist row: title, a status badge that
/// makes filled-vs-skipped-vs-not-started obvious at a glance (plan
/// requirement), a Skip/Un-skip button, and whatever step-specific content
/// the caller provides.
struct GuidedStepContainer<Content: View>: View {
    let title: String
    let status: GuidedStepStatus
    let onSkip: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                statusBadge
                Button(status.isSkipped ? "Un-skip" : "N/A") { onSkip() }
                    .font(.caption)
                    .buttonStyle(.bordered)
            }

            if !status.isSkipped {
                content()
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.06)))
    }

    private var statusBadge: some View {
        Label(status.label, systemImage: status.systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(status.color)
    }
}

enum GuidedStepStatus {
    case notStarted, skipped, filled

    var isSkipped: Bool { self == .skipped }

    var label: String {
        switch self {
        case .notStarted: return "Not started"
        case .skipped: return "N/A"
        case .filled: return "Filled"
        }
    }

    var systemImage: String {
        switch self {
        case .notStarted: return "circle"
        case .skipped: return "minus.circle"
        case .filled: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .secondary
        case .skipped: return .orange
        case .filled: return .green
        }
    }
}

extension GuidedField {
    var stepStatus: GuidedStepStatus {
        switch self {
        case .notStarted: return .notStarted
        case .skipped: return .skipped
        case .filled: return .filled
        }
    }
}
