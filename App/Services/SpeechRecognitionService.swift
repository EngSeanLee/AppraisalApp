import Foundation
import Speech
import AVFoundation

/// On-device, tap-field-then-talk speech recognition (plan: "not
/// continuous/parsed dictation" — one field is armed at a time, reliability
/// over flexibility for a non-technical user). Recognition never leaves the
/// device: `requiresOnDeviceRecognition = true` keeps customer/item data
/// local and lets the app work fully offline.
///
/// `SFSpeechRecognitionTask` has an internal, undocumented time limit —
/// on-device recognition finalizes on its own after roughly a minute even
/// though the caller never asked it to stop. Left alone, that reads as
/// dictation "capping out" mid-description with no obvious explanation.
/// This chains a fresh recognition task onto the same still-open
/// microphone tap whenever a sub-session finalizes on its own (as opposed
/// to the caller calling `stopListening()`), so from the caller's side one
/// tap-to-talk session reads as continuous no matter how long it runs.
@MainActor
final class SpeechRecognitionService: NSObject, ObservableObject {

    enum State: Equatable {
        case idle
        case listening
        case unavailable(reason: String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var liveTranscript: String = ""
    /// Which caller (identified by its own UUID) is currently armed.
    /// `state`/`liveTranscript` are necessarily shared — there's one
    /// underlying recognizer — but every mic-enabled field owns its own ID
    /// and only treats itself as "listening" when this matches. Without
    /// this, every mounted field would think *it* was the one listening
    /// the moment any single field started (they'd all key off the same
    /// shared `state == .listening`), and all of them would copy in
    /// whatever was just said — a real bug, not hypothetical.
    @Published private(set) var activeListenerID: UUID?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    /// Plain (non-actor) box holding whichever request the *current*
    /// sub-session is using. The audio tap below runs on a real-time
    /// CoreAudio thread — it reads this box directly, with no `@MainActor`
    /// hop per buffer, so swapping `box.request` when chaining a new
    /// sub-session redirects the still-running tap without reinstalling
    /// it or touching the audio engine.
    private final class RequestBox: @unchecked Sendable {
        var request: SFSpeechAudioBufferRecognitionRequest?
    }
    private let requestBox = RequestBox()
    private var task: SFSpeechRecognitionTask?

    /// Set right before a caller-requested stop, so a sub-session
    /// finalizing as a *result* of that teardown isn't mistaken for
    /// Apple's internal time limit and chained into a new one.
    private var isStoppingIntentionally = false
    /// Finished sub-sessions' text from earlier in this same listening
    /// run, so `liveTranscript` keeps reading as one continuous transcript
    /// across however many internal sub-sessions get chained together.
    private var committedPrefix = ""

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
    /// `listenerID` is the caller's own stable identity (see
    /// `activeListenerID`) — pass a `UUID` you keep in `@State` for the
    /// lifetime of that mic-enabled control.
    func startListening(for listenerID: UUID) throws {
        stopListening()

        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable(reason: "Speech recognition is not available right now.")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Installed once for the whole listening run — chaining a new
        // sub-session below only swaps `requestBox.request`/`self.task`,
        // never touches the audio engine or this tap, so the mic stays
        // open continuously with no audible gap or re-prompt. Reads
        // `requestBox` directly (no `@MainActor` hop) since this closure
        // runs on CoreAudio's real-time thread, not the main thread.
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [requestBox] buffer, _ in
            requestBox.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        liveTranscript = ""
        committedPrefix = ""
        isStoppingIntentionally = false
        activeListenerID = listenerID
        state = .listening

        beginRecognitionSubSession()
    }

    /// Reads `self.recognizer` directly rather than taking it as a
    /// parameter — it's already a stored property, and re-reading it here
    /// avoids carrying a captured reference across the `Task { @MainActor
    /// in ... }` hop in the completion handler below.
    private func beginRecognitionSubSession() {
        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable(reason: "Speech recognition is not available right now.")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // On-device only — see type doc comment.
        request.requiresOnDeviceRecognition = true
        requestBox.request = request

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                guard self.state == .listening else { return } // stale callback after a real stop
                if let result {
                    self.liveTranscript = self.committedPrefix + result.bestTranscription.formattedString
                }
                guard error != nil || result?.isFinal == true else { return }
                guard !self.isStoppingIntentionally else { return } // stopListening() already tore everything down
                self.chainToNewSubSession()
            }
        }
    }

    /// Apple's internal session-length limit ended this sub-session on its
    /// own — fold its text into `committedPrefix` and start a fresh
    /// sub-session on the same still-open mic tap, so the caller never
    /// sees a gap.
    private func chainToNewSubSession() {
        var prefix = liveTranscript
        if !prefix.isEmpty, !prefix.hasSuffix(" ") { prefix += " " }
        committedPrefix = prefix

        requestBox.request?.endAudio()
        task?.cancel()
        requestBox.request = nil
        task = nil

        beginRecognitionSubSession()
    }

    /// Ends the current listening session. Whatever was last transcribed
    /// stays in `liveTranscript` for the caller to commit into the field.
    func stopListening() {
        guard state == .listening || audioEngine.isRunning else { return }
        isStoppingIntentionally = true
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        requestBox.request?.endAudio()
        task?.cancel()
        requestBox.request = nil
        task = nil
        state = .idle
        activeListenerID = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
