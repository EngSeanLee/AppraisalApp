import Foundation
import Speech
import AVFoundation

/// On-device, tap-field-then-talk speech recognition (plan: "not
/// continuous/parsed dictation" — one field is armed at a time, reliability
/// over flexibility for a non-technical user). Recognition never leaves the
/// device: `requiresOnDeviceRecognition = true` keeps customer/item data
/// local and lets the app work fully offline.
@MainActor
final class SpeechRecognitionService: NSObject, ObservableObject {

    enum State: Equatable {
        case idle
        case listening
        case unavailable(reason: String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var liveTranscript: String = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Call once (e.g. app launch) to prompt for mic + speech permission
    /// up front, rather than surprising a non-technical user mid-task.
    func requestAuthorization() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            state = .unavailable(reason: "Speech recognition permission was not granted.")
            return false
        }

        // AVAudioSession's permission API (not AVAudioApplication's) —
        // simpler, and still fully supported at this deployment target.
        let micGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard micGranted else {
            state = .unavailable(reason: "Microphone permission was not granted.")
            return false
        }

        guard recognizer?.isAvailable == true else {
            state = .unavailable(reason: "Speech recognition is not available on this device right now.")
            return false
        }

        return true
    }

    /// Starts listening for the field that was just tapped. Any previous
    /// session is torn down first so only one field is ever "armed."
    func startListening() throws {
        stopListening()

        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable(reason: "Speech recognition is not available right now.")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // On-device only — see type doc comment.
        request.requiresOnDeviceRecognition = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        liveTranscript = ""
        state = .listening

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.liveTranscript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.stopListening()
                }
            }
        }
    }

    /// Ends the current listening session. Whatever was last transcribed
    /// stays in `liveTranscript` for the caller to commit into the field.
    func stopListening() {
        guard state == .listening || audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        state = .idle
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
