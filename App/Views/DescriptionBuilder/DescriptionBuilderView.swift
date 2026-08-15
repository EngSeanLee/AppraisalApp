import SwiftUI

/// Hybrid description input from the plan: guided prompts for one or more
/// pieces assemble into one editable text box. The box is the override
/// surface — once the user types into it directly, it stops being
/// regenerated from the checklist so their edits are never clobbered.
struct DescriptionBuilderView: View {
    @Binding var pieces: [Piece]
    let valuationMode: ValuationMode
    @Binding var descriptionText: String
    @Binding var manuallyEdited: Bool
    @ObservedObject var speech: SpeechRecognitionService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Description").font(.title3.bold())

            ForEach($pieces) { $piece in
                PieceEditorView(
                    piece: $piece,
                    index: pieces.firstIndex(where: { $0.id == piece.id }) ?? 0,
                    pieceCount: pieces.count,
                    valuationMode: valuationMode,
                    speech: speech,
                    onRemove: { pieces.removeAll { $0.id == piece.id } }
                )
            }

            Button {
                pieces.append(Piece())
            } label: {
                Label("Add Another Piece", systemImage: "plus.circle")
            }
            .font(.subheadline)

            Divider().padding(.vertical, 4)

            HStack {
                Text("Assembled Description").font(.headline)
                Spacer()
                if manuallyEdited {
                    Button("Regenerate from checklist") {
                        descriptionText = DescriptionTemplateEngine.assemble(pieces)
                        manuallyEdited = false
                    }
                    .font(.caption)
                }
            }

            TextEditor(text: $descriptionText)
                .frame(minHeight: 120)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.4)))
                .onChange(of: descriptionText) { _, newValue in
                    if newValue != DescriptionTemplateEngine.assemble(pieces) {
                        manuallyEdited = true
                    }
                }
        }
        .onChange(of: pieces) { _, newValue in
            guard !manuallyEdited else { return }
            descriptionText = DescriptionTemplateEngine.assemble(newValue)
        }
    }
}
