import Foundation

/// Sends a raw on-device dictation transcript (from `SpeechRecognitionService`)
/// to a small Cloudflare Worker — see `/worker` at the repo root — that
/// calls Claude to clean it into a well-formed paragraph: fixing run-on
/// sentences, filler words, and obvious mis-transcriptions of jewelry
/// terms, while leaving every number, grade, and weight untouched.
///
/// The Anthropic API key can never live in this app — a compiled app's
/// strings are trivially extractable, so embedding it would just be a
/// leaked key billed to Tony's account with no way to revoke it without
/// breaking the app for everyone. This always goes through that Worker
/// proxy instead of calling Claude directly; see `/worker/README.md` for
/// what it does and how to deploy it.
enum DictationCleanupService {
    /// Set this after deploying `/worker` (its README walks through it) —
    /// the Worker's `*.workers.dev` URL, or a custom domain if one was set
    /// up, with `/cleanup` appended.
    private static let endpoint: URL? = URL(string: "https://REPLACE-WITH-YOUR-WORKER-URL.workers.dev/cleanup")

    /// Matches the `APP_SHARED_SECRET` set on the Worker (`wrangler secret
    /// put APP_SHARED_SECRET`) — see the Worker's own doc comment for what
    /// this does and, importantly, doesn't protect against. Leave both
    /// sides unset (`nil` here, no secret configured on the Worker) if you
    /// don't want this check.
    private static let sharedSecret: String? = nil

    /// Falls back to the raw transcript on any failure — no endpoint
    /// configured yet, no network, a slow/erroring Worker. Dictation must
    /// keep working exactly as it did before this feature existed if this
    /// step can't reach the network, since the rest of the app is
    /// deliberately offline-first.
    static func cleanUp(_ rawTranscript: String) async -> String {
        guard let endpoint, let cleaned = try? await requestCleanup(rawTranscript, endpoint: endpoint) else {
            return rawTranscript
        }
        return cleaned
    }

    private static func requestCleanup(_ rawTranscript: String, endpoint: URL) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let sharedSecret {
            request.setValue(sharedSecret, forHTTPHeaderField: "X-App-Secret")
        }
        request.httpBody = try JSONEncoder().encode(CleanupRequest(transcript: rawTranscript))
        // A cleanup call is a small text request against a fast model —
        // if it hasn't come back in this long, something's wrong and the
        // raw transcript is a better outcome than leaving Tony staring at
        // a spinner.
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CleanupError.requestFailed
        }
        return try JSONDecoder().decode(CleanupResponse.self, from: data).cleaned
    }

    private struct CleanupRequest: Encodable {
        let transcript: String
    }

    private struct CleanupResponse: Decodable {
        let cleaned: String
    }

    enum CleanupError: Error {
        case requestFailed
    }
}
