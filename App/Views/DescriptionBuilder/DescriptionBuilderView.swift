import SwiftUI

/// Hybrid description input from the plan: guided prompts for each
/// required element assemble into one editable text box. The box is the
/// override surface — once the user types into it directly, it stops being
/// regenerated from the checklist so their edits are never clobbered.
struct DescriptionBuilderView: View {
    @Binding var elements: DescriptionElements
    @Binding var descriptionText: String
    @Binding var manuallyEdited: Bool
    @ObservedObject var speech: SpeechRecognitionService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description").font(.title3.bold())

            MetalStepView(field: $elements.metal, speech: speech)
            ItemStyleStepView(field: $elements.itemStyle, speech: speech)
            CenterStoneStepView(field: $elements.centerStone, speech: speech)
            CertificationStepView(field: $elements.certification, speech: speech)
            SideStonesStepView(field: $elements.sideStones, speech: speech)

            Divider().padding(.vertical, 4)

            HStack {
                Text("Assembled Description").font(.headline)
                Spacer()
                if manuallyEdited {
                    Button("Regenerate from checklist") {
                        descriptionText = DescriptionTemplateEngine.assemble(elements)
                        manuallyEdited = false
                    }
                    .font(.caption)
                }
            }

            TextEditor(text: $descriptionText)
                .frame(minHeight: 120)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.4)))
                .onChange(of: descriptionText) { _, newValue in
                    if newValue != DescriptionTemplateEngine.assemble(elements) {
                        manuallyEdited = true
                    }
                }
        }
        .onChange(of: elements) { _, newValue in
            guard !manuallyEdited else { return }
            descriptionText = DescriptionTemplateEngine.assemble(newValue)
        }
    }
}
