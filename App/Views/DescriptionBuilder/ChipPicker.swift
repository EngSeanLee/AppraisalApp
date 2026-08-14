import SwiftUI

/// Row of tappable choice chips for the common jewelry vocabulary values
/// (karats, stone shapes, cert issuers, ...) so the most frequent answers
/// need zero typing or speech at all — only the unusual case needs the
/// mic/keyboard. Selecting a chip sets `selection`; typing something else
/// into the paired field simply doesn't match any chip, which is fine.
struct ChipPicker: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection = option }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(selection == option ? Color.accentColor : Color.secondary.opacity(0.15))
                        )
                        .foregroundStyle(selection == option ? Color.white : Color.primary)
                }
            }
        }
    }
}
