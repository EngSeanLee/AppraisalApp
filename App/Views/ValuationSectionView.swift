import SwiftUI

/// Combined-total vs. itemized-per-piece valuation (spec clause #6) — both
/// patterns are real, so the user picks per appraisal rather than the app
/// guessing. In itemized mode, each piece's own value is entered inline on
/// that piece's card in `DescriptionBuilderView`, not here.
struct ValuationSectionView: View {
    @Binding var valuationMode: ValuationMode
    @Binding var combinedValue: ReplacementValue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Valuation").font(.title3.bold())
            Picker("Valuation Mode", selection: $valuationMode) {
                ForEach(ValuationMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if valuationMode == .combined {
                ReplacementValueFieldView(value: $combinedValue)
            } else {
                Text("Enter each piece's Replacement Value on its own card below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.06)))
    }
}
