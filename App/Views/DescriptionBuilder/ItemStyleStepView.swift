import SwiftUI

/// Guided element #2: "Item type & setting style," e.g. "Euro shank ring
/// with halo." Captured as two pieces so `DescriptionTemplateEngine` can
/// reuse the setting-style noun later in the side-stones sentence — see
/// `ItemStyleInfo` doc comment.
struct ItemStyleStepView: View {
    @Binding var field: GuidedField<ItemStyleInfo>
    @ObservedObject var speech: SpeechRecognitionService

    @State private var typePhrase = ""
    @State private var settingStyle = ""

    private static let settingOptions = ["halo", "solitaire", "pavé", "channel", "bezel", "prong", "tension", "none"]

    var body: some View {
        GuidedStepContainer(title: "Item Type & Setting Style", status: field.stepStatus, onSkip: toggleSkip) {
            VStack(alignment: .leading, spacing: 10) {
                TapToSpeakField(title: "Item type (e.g. \"Euro shank ring\")", text: $typePhrase, speech: speech)

                ChipPicker(options: Self.settingOptions, selection: $settingStyle)
                TapToSpeakField(title: "Setting style (optional)", text: $settingStyle, speech: speech)
            }
        }
        .onAppear(perform: loadFromField)
        .onChange(of: typePhrase) { _, _ in commit() }
        .onChange(of: settingStyle) { _, _ in commit() }
    }

    private func loadFromField() {
        guard case .filled(let info) = field else { return }
        typePhrase = info.typePhrase
        settingStyle = info.settingStyle ?? ""
    }

    private func toggleSkip() {
        field = field.stepStatus == .skipped ? .notStarted : .skipped
    }

    private func commit() {
        guard !typePhrase.isEmpty else { return }
        let setting = (settingStyle.isEmpty || settingStyle == "none") ? nil : settingStyle
        field = .filled(ItemStyleInfo(typePhrase: typePhrase, settingStyle: setting))
    }
}
