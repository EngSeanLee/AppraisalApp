import SwiftUI

/// Guided element #4: "Certification # and grading (color/clarity)."
/// Skippable for uncertified pieces.
struct CertificationStepView: View {
    @Binding var field: GuidedField<CertificationInfo>
    @ObservedObject var speech: SpeechRecognitionService

    @State private var issuer = ""
    @State private var number = ""
    @State private var color = ""
    @State private var clarity = ""

    private static let issuerOptions = ["GIA", "IGI", "AGS", "EGL", "GSI"]
    private static let colorOptions = ["D", "E", "F", "G", "H", "I", "J", "K", "L", "M"]
    private static let clarityOptions = ["FL", "IF", "VVS1", "VVS2", "VS1", "VS2", "SI1", "SI2", "I1", "I2"]

    var body: some View {
        GuidedStepContainer(title: "Certification & Grading", status: field.stepStatus, onSkip: toggleSkip) {
            VStack(alignment: .leading, spacing: 10) {
                ChipPicker(options: Self.issuerOptions, selection: $issuer)
                TapToSpeakField(title: "Issuer", text: $issuer, speech: speech)

                TapToSpeakField(title: "Certificate number", text: $number, speech: speech)

                ChipPicker(options: Self.colorOptions, selection: $color)
                TapToSpeakField(title: "Color grade", text: $color, speech: speech)

                ChipPicker(options: Self.clarityOptions, selection: $clarity)
                TapToSpeakField(title: "Clarity grade", text: $clarity, speech: speech)
            }
        }
        .onAppear(perform: loadFromField)
        .onChange(of: issuer) { _, _ in commit() }
        .onChange(of: number) { _, _ in commit() }
        .onChange(of: color) { _, _ in commit() }
        .onChange(of: clarity) { _, _ in commit() }
    }

    private func loadFromField() {
        guard case .filled(let info) = field else { return }
        issuer = info.issuer
        number = info.number
        color = info.color
        clarity = info.clarity
    }

    private func toggleSkip() {
        field = field.stepStatus == .skipped ? .notStarted : .skipped
    }

    private func commit() {
        guard !issuer.isEmpty, !number.isEmpty, !color.isEmpty, !clarity.isEmpty else { return }
        field = .filled(CertificationInfo(issuer: issuer, number: number, color: color, clarity: clarity))
    }
}
