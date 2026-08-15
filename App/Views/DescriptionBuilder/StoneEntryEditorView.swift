import SwiftUI

/// One stone (or accent-stone group) editor row within `StonesStepView`.
/// Unlike the fixed-field steps, `StoneEntry` is a plain struct in a
/// repeatable array — no notStarted/skipped wrapping needed, so most
/// fields bind directly. Only `carat` needs the usual raw-text +
/// `QuantityNormalizer` dance since it's a structured `Quantity`, not a
/// bare string.
struct StoneEntryEditorView: View {
    @Binding var stone: StoneEntry
    @ObservedObject var speech: SpeechRecognitionService
    var onDelete: () -> Void

    @State private var caratRaw = ""

    private static let cutOptions = [
        "round brilliant cut", "princess cut", "marquise cut", "oval cut", "cushion cut",
        "pear cut", "emerald cut", "asscher cut", "radiant cut", "heart cut"
    ]
    private static let stoneOptions = ["diamond", "diamonds", "sapphire", "ruby", "emerald", "topaz", "amethyst", "zircon"]
    private static let colorOptions = ["D", "E", "F", "G", "H", "I", "J", "K", "L", "M"]
    private static let clarityOptions = ["FL", "IF", "VVS1", "VVS2", "VS1", "VS2", "SI1", "SI2", "I1", "I2"]
    private static let issuerOptions = ["GIA", "IGI", "AGS", "EGL", "GSI"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Picker("Role", selection: $stone.role) {
                    ForEach(StoneRole.allCases) { role in
                        Text(role.displayName).tag(role)
                    }
                }
                .pickerStyle(.segmented)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            if stone.role == .accent {
                Stepper("Count: \(stone.count)", value: $stone.count, in: 1...200)
                    .font(.subheadline)
            }

            ChipPicker(options: Self.cutOptions, selection: $stone.cut)
            TapToSpeakField(title: "Shape / cut", text: $stone.cut, speech: speech)

            ChipPicker(options: Self.stoneOptions, selection: $stone.stoneType)
            TapToSpeakField(title: "Stone type", text: $stone.stoneType, speech: speech)

            TapToSpeakField(title: "Carat weight (optional — e.g. \"3.05 carat\")", text: $caratRaw, speech: speech)
            TapToSpeakField(title: "mm size (optional — e.g. \"2X4mm\", for stones sized by dimension)", text: $stone.mmSize, speech: speech)

            ChipPicker(options: Self.clarityOptions, selection: $stone.clarity)
            TapToSpeakField(title: "Clarity grade (optional)", text: $stone.clarity, speech: speech)

            ChipPicker(options: Self.colorOptions, selection: $stone.color)
            TapToSpeakField(title: "Color grade (optional)", text: $stone.color, speech: speech)

            originPicker

            certificationFields
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
        .onAppear { caratRaw = stone.carat?.displayString ?? "" }
        .onChange(of: caratRaw) { _, newValue in
            guard !newValue.isEmpty else { stone.carat = nil; return }
            stone.carat = QuantityNormalizer.extractQuantity(from: newValue, unit: "carat").quantity
        }
    }

    /// Explicit 3-way toggle, defaulting to Unspecified — never inferred
    /// from a cert number's "LG" prefix even though that prefix is a
    /// strong signal. Per appraisal-description-spec.md's "Special Flags"
    /// section, guessing this wrong is a real liability risk, so the app
    /// never guesses.
    private var originPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Natural / lab-grown").font(.caption).foregroundStyle(.secondary)
            Picker("Origin", selection: $stone.origin) {
                ForEach(StoneOrigin.allCases) { origin in
                    Text(origin.displayName).tag(origin)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    /// Optional — attaches at the stone level, so each stone/group can
    /// carry its own certificate independently of any other stone on the
    /// same piece.
    private var certificationFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Certification (optional)").font(.caption).foregroundStyle(.secondary)
            ChipPicker(options: Self.issuerOptions, selection: issuerBinding)
            TapToSpeakField(title: "Issuer", text: issuerBinding, speech: speech)
            TapToSpeakField(title: "Certificate number", text: numberBinding, speech: speech)
        }
    }

    private var issuerBinding: Binding<String> {
        Binding(
            get: { stone.certification?.issuer ?? "" },
            set: { newValue in
                var cert = stone.certification ?? StoneCertification()
                cert.issuer = newValue
                stone.certification = cert.isEmpty ? nil : cert
            }
        )
    }

    private var numberBinding: Binding<String> {
        Binding(
            get: { stone.certification?.number ?? "" },
            set: { newValue in
                var cert = stone.certification ?? StoneCertification()
                cert.number = newValue
                stone.certification = cert.isEmpty ? nil : cert
            }
        )
    }
}
