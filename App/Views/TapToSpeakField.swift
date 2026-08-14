import SwiftUI

/// The plan's core input control: tap the mic, speak, the field fills.
/// A keyboard toggle sits next to the mic at all times (not just as an
/// error-correction fallback) since names are a known dictation failure
/// point and a non-technical user needs a same-navigation way to type
/// instead of or on top of what was heard.
struct TapToSpeakField: View {
    let title: String
    @Binding var text: String
    @ObservedObject var speech: SpeechRecognitionService

    @State private var isTypingMode = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                if isTypingMode {
                    TextField(title, text: $text)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .onAppear { isFocused = true }
                } else {
                    Text(displayText)
                        .foregroundStyle(text.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.4)))
                }

                Button(action: toggleListening) {
                    Image(systemName: isListening ? "mic.fill" : "mic")
                        .foregroundStyle(isListening ? .red : .accentColor)
                        .imageScale(.large)
                }
                .disabled(isTypingMode)

                Button(action: { isTypingMode.toggle() }) {
                    Image(systemName: isTypingMode ? "checkmark.circle" : "keyboard")
                        .imageScale(.large)
                }
            }
        }
        .onChange(of: speech.liveTranscript) { _, newValue in
            guard isListening else { return }
            text = newValue
        }
    }

    private var isListening: Bool {
        speech.state == .listening
    }

    private var displayText: String {
        if isListening { return speech.liveTranscript.isEmpty ? "Listening…" : speech.liveTranscript }
        return text.isEmpty ? "Tap the mic and speak" : text
    }

    private func toggleListening() {
        if isListening {
            speech.stopListening()
        } else {
            do {
                try speech.startListening()
            } catch {
                // Surfacing a full error UI is unnecessary for a first pass —
                // the mic simply won't start; the keyboard toggle remains
                // the reliable fallback for a non-technical user either way.
            }
        }
    }
}
