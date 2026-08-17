import SwiftUI

/// The description, as one free-typed-or-dictated box — no guided fields.
/// Earlier versions of this app broke the description into a multi-step
/// guided checklist (metal, item style, stones, certification...); in
/// practice that was way more form than Tony needed. The structure still
/// exists, just moved to `DescriptionChecklist` running quietly in the
/// background: soft reminders under the box, not fields he has to fill in.
///
/// Voice input here works differently from `TapToSpeakField`: each
/// dictation session is *appended* to whatever's already there (with a
/// space in between) rather than replacing it, since a description is
/// naturally built up over several sentences/passes, typed and spoken
/// interchangeably — unlike a short single-value field like the customer
/// name. Before appending, the raw transcript is run through
/// `DictationCleanupService` (a cloud LLM call, see its doc comment) to
/// fix run-ons and filler words — on-device dictation alone tends to
/// produce exactly the kind of comma-splice wall of text an appraisal
/// shouldn't read like.
struct DescriptionBuilderView: View {
    @Binding var descriptionText: String
    @ObservedObject var speech: SpeechRecognitionService

    @State private var fieldID = UUID()
    @State private var isCleaningUp = false

    private var isListening: Bool { speech.activeListenerID == fieldID }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Description").font(.title3.bold())

            TextEditor(text: $descriptionText)
                .frame(minHeight: 160)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.4)))

            if isListening {
                Text(speech.liveTranscript.isEmpty ? "Listening…" : speech.liveTranscript)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.08)))
            }

            if isCleaningUp {
                HStack(spacing: 6) {
                    ProgressView()
                    Text("Cleaning up…")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Button(action: toggleListening) {
                Label(isListening ? "Stop" : "Add by Voice", systemImage: isListening ? "mic.fill" : "mic")
            }
            .buttonStyle(.bordered)
            .tint(isListening ? .red : .accentColor)
            .disabled(isCleaningUp)

            let hints = DescriptionChecklist.missingHints(for: descriptionText)
            if !hints.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(hints, id: \.self) { hint in
                        Label(hint, systemImage: "lightbulb")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onChange(of: speech.activeListenerID) { oldValue, newValue in
            // Fires whether the session ended because the user tapped
            // Stop, or the recognizer auto-stopped on its own (silence,
            // error) — either way, commit whatever was captured exactly
            // once, right here.
            guard oldValue == fieldID, newValue != fieldID else { return }
            let transcript = speech.liveTranscript
            Task { await commit(transcript) }
        }
    }

    private func toggleListening() {
        if isListening {
            speech.stopListening()
        } else {
            try? speech.startListening(for: fieldID)
        }
    }

    @MainActor
    private func commit(_ transcript: String) async {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isCleaningUp = true
        let cleaned = await DictationCleanupService.cleanUp(trimmed)
        isCleaningUp = false

        if descriptionText.isEmpty || descriptionText.hasSuffix(" ") || descriptionText.hasSuffix("\n") {
            descriptionText += cleaned
        } else {
            descriptionText += " " + cleaned
        }
    }
}
