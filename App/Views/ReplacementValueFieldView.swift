import SwiftUI

/// Editor for one "Replacement Value…….$X,XXX.00" figure — reused both for
/// the appraisal-wide combined value and for each piece's own value in
/// itemized mode. Amount is typed (a dollar figure isn't naturally
/// dictated the way jewelry vocabulary is), with an optional market-note
/// parenthetical, e.g. "1.08 carats ($4375/oz)".
struct ReplacementValueFieldView: View {
    @Binding var value: ReplacementValue

    @State private var amountRaw = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("$").foregroundStyle(.secondary)
                TextField("Replacement value", text: $amountRaw)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
            TextField("Market note (optional, e.g. \"1.08 carats ($4375/oz)\")", text: $value.marketNote)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
        }
        .onAppear { amountRaw = value.amount.map { String(format: "%.2f", $0) } ?? "" }
        .onChange(of: amountRaw) { _, newValue in
            value.amount = Double(newValue.replacingOccurrences(of: ",", with: ""))
        }
    }
}
