import SwiftUI
import UIKit

/// Draws the appraisal letterhead background. Falls back to a drawn
/// placeholder (with corner marks + labeled slots) when the real template
/// artwork hasn't been added to Assets.xcassets yet, so the rest of the app
/// is runnable/testable before that asset exists — see plan's Open Items
/// ("Finalize the template image").
struct TemplateBackgroundView: View {
    var layout: TemplateLayout

    var body: some View {
        GeometryReader { proxy in
            if let uiImage = UIImage(named: TemplateAsset.name) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                placeholder(in: proxy.size)
            }
        }
        .aspectRatio(8.5 / 11, contentMode: .fit) // US Letter, matches print output
    }

    private func placeholder(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.secondary, lineWidth: 2)

            VStack {
                Text("TEMPLATE PLACEHOLDER")
                    .font(.caption).bold()
                    .foregroundStyle(.secondary)
                Text("Add the real letterhead to Assets.xcassets as \"\(TemplateAsset.name)\"")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer()
            }
            .padding(.top, 12)

            ForEach(labeledSlots) { slot in
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .overlay(alignment: .topLeading) {
                        Text(slot.label)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .padding(2)
                    }
                    .frame(width: slot.rect.width * size.width, height: slot.rect.height * size.height)
                    .position(
                        x: (slot.rect.minX + slot.rect.width / 2) * size.width,
                        y: (slot.rect.minY + slot.rect.height / 2) * size.height
                    )
            }
        }
    }

    private struct Slot: Identifiable {
        let label: String
        let rect: CGRect
        var id: String { label }
    }

    private var labeledSlots: [Slot] {
        [
            Slot(label: "Name", rect: layout.customerName),
            Slot(label: "Date", rect: layout.date),
            Slot(label: "Address", rect: layout.address),
            Slot(label: "Description", rect: layout.itemDescription),
            Slot(label: "Replacement Value", rect: layout.replacementValue),
            Slot(label: "Photo 1", rect: layout.photoOne),
            Slot(label: "Photo 2", rect: layout.photoTwo),
            Slot(label: "Photo 3", rect: layout.photoThree),
            Slot(label: "PER (stamp line)", rect: layout.perLine)
        ]
    }
}

#Preview {
    TemplateBackgroundView(layout: .default)
        .padding()
}
