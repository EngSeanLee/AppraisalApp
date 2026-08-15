import SwiftUI

/// Guided element: every stone or stone-group on a piece, as a repeatable
/// list rather than fixed center/side-stone slots — real appraisals range
/// from zero stones to several independently-graded groups. An empty list
/// is itself the "N/A, no stones" state, so there's no separate skip
/// toggle here the way the fixed-field steps have one.
struct StonesStepView: View {
    @Binding var stones: [StoneEntry]
    @ObservedObject var speech: SpeechRecognitionService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Stones").font(.headline)
                Spacer()
                Label(stones.isEmpty ? "None" : "\(stones.count) added",
                      systemImage: stones.isEmpty ? "circle" : "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    // Explicit `Color.` on both branches: `.secondary` alone is
                    // ambiguous between `Color.secondary` and
                    // `HierarchicalShapeStyle.secondary`, and the compiler
                    // picks the latter here, which has no `.green` — a real
                    // build failure caught by CI, not just a style nit.
                    .foregroundStyle(stones.isEmpty ? Color.secondary : Color.green)
            }

            ForEach($stones) { $stone in
                StoneEntryEditorView(stone: $stone, speech: speech, onDelete: {
                    stones.removeAll { $0.id == stone.id }
                })
            }

            Button {
                // First stone added defaults to the center role (the
                // common case); anything after that defaults to accent.
                stones.append(StoneEntry(role: stones.isEmpty ? .center : .accent))
            } label: {
                Label(stones.isEmpty ? "Add a Stone" : "Add Another Stone / Group", systemImage: "plus.circle")
            }
            .font(.caption)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.06)))
    }
}
