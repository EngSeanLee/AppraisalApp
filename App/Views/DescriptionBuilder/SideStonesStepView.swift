import SwiftUI

/// Guided element #5: "Side/accent stone total weight," e.g. "the halo
/// consists of diamonds with a total weight of 0.53 carat." Skippable for
/// pieces with no accent stones.
struct SideStonesStepView: View {
    @Binding var field: GuidedField<SideStonesInfo>
    @ObservedObject var speech: SpeechRecognitionService

    @State private var stoneType = ""
    @State private var weightRaw = ""

    private static let stoneOptions = ["diamonds", "sapphires", "rubies", "emeralds", "mixed stones"]

    var body: some View {
        GuidedStepContainer(title: "Side / Accent Stones", status: field.stepStatus, onSkip: toggleSkip) {
            VStack(alignment: .leading, spacing: 10) {
                ChipPicker(options: Self.stoneOptions, selection: $stoneType)
                TapToSpeakField(title: "Stone type", text: $stoneType, speech: speech)

                TapToSpeakField(title: "Total weight (e.g. \"0.53 carat\")", text: $weightRaw, speech: speech)
            }
        }
        .onAppear(perform: loadFromField)
        .onChange(of: stoneType) { _, _ in commit() }
        .onChange(of: weightRaw) { _, _ in commit() }
    }

    private func loadFromField() {
        guard case .filled(let info) = field else { return }
        stoneType = info.stoneType
        weightRaw = info.totalWeight.displayString
    }

    private func toggleSkip() {
        field = field.stepStatus == .skipped ? .notStarted : .skipped
    }

    private func commit() {
        guard !stoneType.isEmpty else { return }
        let result = QuantityNormalizer.extractQuantity(from: weightRaw, unit: "carat")
        guard let weight = result.quantity else { return }
        field = .filled(SideStonesInfo(stoneType: stoneType, totalWeight: weight))
    }
}
