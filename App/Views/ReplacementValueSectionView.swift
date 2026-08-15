import SwiftUI

/// One Replacement Value per appraisal — replaces the earlier combined-vs-
/// itemized-per-piece picker (`ValuationSectionView`), which turned out to
/// be more than Tony needed in practice.
struct ReplacementValueSectionView: View {
    @Binding var value: ReplacementValue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Replacement Value").font(.title3.bold())
            ReplacementValueFieldView(value: $value)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.06)))
    }
}
