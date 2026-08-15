import SwiftUI

/// The "PER" line — name plus an optional credential/title line
/// underneath. Seeded from `AppraiserInfo.roster` but always freely
/// editable, since real letterheads show different appraisers with
/// different (or no) credentials, not just one hardcoded person.
struct AppraiserFieldView: View {
    @Binding var appraiser: AppraiserInfo
    @ObservedObject var speech: SpeechRecognitionService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appraiser (PER)").font(.title3.bold())
            ChipPicker(options: AppraiserInfo.roster, selection: $appraiser.name)
            TapToSpeakField(title: "Name", text: $appraiser.name, speech: speech)
            TapToSpeakField(title: "Credential / title (optional, e.g. \"GIA Certified Grader\")", text: $appraiser.credential, speech: speech)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.06)))
    }
}
