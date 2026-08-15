import SwiftUI

/// Guided element for stone-less pieces (chains, Cuban-link bracelets):
/// style name + length, used instead of any stone clause — see clause #5
/// in appraisal-description-spec.md. Skippable, same as the fixed-field
/// steps, since most pieces do have stones and won't need this at all.
struct ChainStepView: View {
    @Binding var field: GuidedField<ChainInfo>
    @ObservedObject var speech: SpeechRecognitionService

    @State private var styleName = ""
    @State private var lengthRaw = ""

    var body: some View {
        GuidedStepContainer(title: "Chain / Length (stone-less pieces)", status: field.stepStatus, onSkip: toggleSkip) {
            VStack(alignment: .leading, spacing: 10) {
                TapToSpeakField(title: "Style name (optional, e.g. \"Miami Cuban links\")", text: $styleName, speech: speech)
                TapToSpeakField(title: "Length (e.g. \"7.5 inch\")", text: $lengthRaw, speech: speech)
            }
        }
        .onAppear(perform: loadFromField)
        .onChange(of: styleName) { _, _ in commit() }
        .onChange(of: lengthRaw) { _, _ in commit() }
    }

    private func loadFromField() {
        guard case .filled(let info) = field else { return }
        styleName = info.styleName
        lengthRaw = info.length?.displayString ?? ""
    }

    private func toggleSkip() {
        field = field.stepStatus == .skipped ? .notStarted : .skipped
    }

    private func commit() {
        let result = QuantityNormalizer.extractQuantity(from: lengthRaw, unit: "inch")
        guard result.quantity != nil || !styleName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        field = .filled(ChainInfo(styleName: styleName, length: result.quantity))
    }
}
