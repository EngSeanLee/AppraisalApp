import SwiftUI

/// The "look at old appraisals" screen — every appraisal `AppraisalStore`
/// has on disk, most recently edited first. Tapping one hands it back to
/// `AppraisalFormView` to reopen for viewing/editing; swiping deletes it
/// (and its photos) for good.
struct SavedAppraisalsView: View {
    var onSelect: (Appraisal) -> Void

    @State private var appraisals: [Appraisal] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if appraisals.isEmpty {
                    ContentUnavailableView(
                        "No Saved Appraisals",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Appraisals save automatically as you fill them in.")
                    )
                } else {
                    List {
                        ForEach(appraisals, id: \.id) { appraisal in
                            Button {
                                onSelect(appraisal)
                            } label: {
                                row(for: appraisal)
                            }
                            .tint(.primary)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Past Appraisals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { appraisals = AppraisalStore.loadAll() }
        }
    }

    private func row(for appraisal: Appraisal) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(appraisal.customerName.isEmpty ? "Untitled" : appraisal.customerName)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(appraisal.date.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !appraisal.descriptionText.isEmpty {
                Text(appraisal.descriptionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            AppraisalStore.delete(appraisals[index])
        }
        appraisals.remove(atOffsets: offsets)
    }
}

#Preview {
    SavedAppraisalsView(onSelect: { _ in })
}
