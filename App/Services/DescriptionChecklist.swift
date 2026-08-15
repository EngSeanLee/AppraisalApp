import Foundation

/// Soft, non-blocking reminders about what a freely-typed/dictated
/// description might be missing — the "guided checklist" from earlier
/// versions of this app, demoted from a multi-field form Tony has to fill
/// in step by step to a background check that just nudges him. Nothing
/// here blocks export or forces structured entry; it only surfaces hints
/// under the description box for as long as they apply, and they
/// disappear on their own once the wording covers that ground.
///
/// Deliberately loose regex/keyword matching, not a real parser — a false
/// "you might be missing X" once in a while costs nothing (it's just a
/// caption), where a missed real appraisal detail is the thing worth
/// guarding against.
enum DescriptionChecklist {
    private static let metalPattern = try! NSRegularExpression(
        pattern: #"\b(\d{1,2}\s*(k|kt|karat)|platinum|sterling|silver|gold)\b"#,
        options: .caseInsensitive
    )
    private static let weightPattern = try! NSRegularExpression(
        pattern: #"\d+(\.\d+)?\s*(gram|gr\b|g\b|ct\b|carat)"#,
        options: .caseInsensitive
    )
    private static let stoneWordPattern = try! NSRegularExpression(
        pattern: #"\b(diamond|stone|sapphire|ruby|emerald|topaz|amethyst|zircon|pearl)\b"#,
        options: .caseInsensitive
    )
    private static let gradingPattern = try! NSRegularExpression(
        pattern: #"\b(SI\d|VS\d|VVS\d|FL|IF|I\d|[D-M]\s*color)\b"#,
        options: .caseInsensitive
    )

    /// Returns the reminders that still apply to `text`. Empty once the
    /// description is long enough and mentions the basics, or if it's
    /// still empty (nothing to nudge about yet).
    static func missingHints(for text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var hints: [String] = []
        if !matches(metalPattern, in: trimmed) {
            hints.append("Metal & karat (e.g. \"14kt white gold\")")
        }
        if !matches(weightPattern, in: trimmed) {
            hints.append("A weight — grams or carats")
        }
        if matches(stoneWordPattern, in: trimmed), !matches(gradingPattern, in: trimmed) {
            hints.append("Stone color/clarity grading, since a stone is mentioned")
        }
        return hints
    }

    private static func matches(_ regex: NSRegularExpression, in text: String) -> Bool {
        regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}
