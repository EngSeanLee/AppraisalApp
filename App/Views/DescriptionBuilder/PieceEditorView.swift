import SwiftUI

/// One physical piece's full guided editor: item type, qualifier/custom-made,
/// metal, item style, stones, and (for stone-less pieces) chain/length —
/// plus, in itemized-valuation mode, this piece's own Replacement Value.
/// Multi-item appraisals show one of these per piece.
struct PieceEditorView: View {
    @Binding var piece: Piece
    let index: Int
    let pieceCount: Int
    let valuationMode: ValuationMode
    @ObservedObject var speech: SpeechRecognitionService
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Picker("Item Type", selection: $piece.itemType) {
                ForEach(ItemType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .bottom) {
                TapToSpeakField(title: "Qualifier (optional, e.g. \"Ladies'\")", text: $piece.qualifier, speech: speech)
                Toggle("Custom made", isOn: $piece.isCustomMade)
                    .toggleStyle(.switch)
                    .fixedSize()
                    .padding(.bottom, 8)
            }

            if valuationMode == .itemized {
                itemizedValueFields
            }

            MetalStepView(field: $piece.metal, speech: speech)
            ItemStyleStepView(field: $piece.itemStyle, speech: speech)
            StonesStepView(stones: $piece.stones, speech: speech)
            ChainStepView(field: $piece.chain, speech: speech)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.25)))
    }

    private var header: some View {
        HStack {
            Text(pieceCount > 1 ? "Piece \(index + 1)" : "Piece").font(.title3.bold())
            Spacer()
            if pieceCount > 1 {
                Button(role: .destructive, action: onRemove) {
                    Label("Remove", systemImage: "trash")
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
    }

    private var itemizedValueFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This piece's Replacement Value").font(.caption).foregroundStyle(.secondary)
            TapToSpeakField(title: "Label for this line (e.g. \"engagement ring\")", text: $piece.pieceLabel, speech: speech)
            ReplacementValueFieldView(value: $piece.replacementValue)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
    }
}
