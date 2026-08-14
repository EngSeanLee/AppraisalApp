import SwiftUI

/// Guided element #3: "Center stone details (shape, carat weight, cut)."
/// Skippable — a plain band has no center stone.
struct CenterStoneStepView: View {
    @Binding var field: GuidedField<CenterStoneInfo>
    @ObservedObject var speech: SpeechRecognitionService

    @State private var cut = ""
    @State private var caratRaw = ""
    @State private var stoneType = ""

    private static let cutOptions = [
        "round brilliant cut", "princess cut", "marquise cut", "oval cut", "cushion cut",
        "pear cut", "emerald cut", "asscher cut", "radiant cut", "heart cut"
    ]
    private static let stoneOptions = ["diamond", "sapphire", "ruby", "emerald", "topaz", "amethyst"]

    var body: some View {
        GuidedStepContainer(title: "Center Stone", status: field.stepStatus, onSkip: toggleSkip) {
            VStack(alignment: .leading, spacing: 10) {
                ChipPicker(options: Self.cutOptions, selection: $cut)
                TapToSpeakField(title: "Shape / cut", text: $cut, speech: speech)

                TapToSpeakField(title: "Carat weight (e.g. \"3.05 carat\")", text: $caratRaw, speech: speech)

                ChipPicker(options: Self.stoneOptions, selection: $stoneType)
                TapToSpeakField(title: "Stone type", text: $stoneType, speech: speech)
            }
        }
        .onAppear(perform: loadFromField)
        .onChange(of: cut) { _, _ in commit() }
        .onChange(of: caratRaw) { _, _ in commit() }
        .onChange(of: stoneType) { _, _ in commit() }
    }

    private func loadFromField() {
        guard case .filled(let info) = field else { return }
        cut = info.cut
        caratRaw = info.carat.displayString
        stoneType = info.stoneType
    }

    private func toggleSkip() {
        field = field.stepStatus == .skipped ? .notStarted : .skipped
    }

    private func commit() {
        guard !cut.isEmpty, !stoneType.isEmpty else { return }
        let result = QuantityNormalizer.extractQuantity(from: caratRaw, unit: "carat")
        guard let carat = result.quantity else { return }
        field = .filled(CenterStoneInfo(carat: carat, cut: cut, stoneType: stoneType))
    }
}
