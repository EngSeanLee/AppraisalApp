import SwiftUI

/// Guided element #1: "Metal type, karat/purity & total weight."
struct MetalStepView: View {
    @Binding var field: GuidedField<MetalInfo>
    @ObservedObject var speech: SpeechRecognitionService

    @State private var karat = ""
    @State private var metalName = ""
    @State private var weightRaw = ""

    private static let karatOptions = ["10 karat", "14 karat", "18 karat", "22 karat", "platinum", "sterling silver"]
    private static let metalOptions = ["white gold", "yellow gold", "rose gold", "platinum", "silver"]

    var body: some View {
        GuidedStepContainer(title: "Metal & Weight", status: field.stepStatus, onSkip: toggleSkip) {
            VStack(alignment: .leading, spacing: 10) {
                ChipPicker(options: Self.karatOptions, selection: $karat)
                TapToSpeakField(title: "Karat / purity", text: $karat, speech: speech)

                ChipPicker(options: Self.metalOptions, selection: $metalName)
                TapToSpeakField(title: "Metal", text: $metalName, speech: speech)

                TapToSpeakField(title: "Total weight (e.g. \"8 grams\")", text: $weightRaw, speech: speech)
            }
        }
        .onAppear(perform: loadFromField)
        .onChange(of: karat) { _, _ in commit() }
        .onChange(of: metalName) { _, _ in commit() }
        .onChange(of: weightRaw) { _, _ in commit() }
    }

    private func loadFromField() {
        guard case .filled(let info) = field else { return }
        karat = info.karat
        metalName = info.metalName
        weightRaw = info.totalWeight.displayString
    }

    private func toggleSkip() {
        field = field.stepStatus == .skipped ? .notStarted : .skipped
    }

    private func commit() {
        guard !karat.isEmpty, !metalName.isEmpty else { return }
        let result = QuantityNormalizer.extractQuantity(from: weightRaw, unit: "gram")
        guard let weight = result.quantity else { return }
        field = .filled(MetalInfo(karat: karat, metalName: metalName, totalWeight: weight))
    }
}
