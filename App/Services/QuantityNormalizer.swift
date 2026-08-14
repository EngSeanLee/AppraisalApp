import Foundation

/// Turns spoken quantity phrases into a normalized `Quantity`, preserving
/// whether the speaker was precise or hedging — per the plan's
/// "Vague quantities auto-normalize, with a qualifier when appropriate"
/// rule:
///   "about half a carat"  -> approximately 0.50 carat
///   "a couple grams"      -> approximately 2.00 gram
///   "three point oh five carat" -> 3.05 carat (no qualifier)
///
/// This is a first pass built from the plan's own examples. It is NOT yet
/// tuned against real transcripts — see plan's Open Items ("gather past
/// appraisal writeups ... iterate the parser"). Treat the phrase tables
/// below as seed data to expand once real dictation samples exist.
enum QuantityNormalizer {

    /// Hedge phrases that mark a quantity as approximate, in longest-match-first order.
    private static let hedgePhrases: [String] = [
        "approximately", "roughly", "around", "about", "give or take"
    ]

    /// Vague quantity phrases mapped to a numeric value they stand in for.
    /// Order matters: longer/more specific phrases must be checked first.
    private static let vagueQuantityWords: [(phrase: String, value: Double)] = [
        ("a quarter of a", 0.25),
        ("quarter of a", 0.25),
        ("a quarter", 0.25),
        ("half a", 0.5),
        ("a half", 0.5),
        ("half", 0.5),
        ("a couple of", 2),
        ("a couple", 2),
        ("couple of", 2),
        ("couple", 2),
        ("a few", 3),
        ("few", 3),
        ("several", 4)
    ]

    /// Spelled-out digits/words used when speech-to-text hasn't already
    /// converted numbers (falls back to this if no digit is found).
    private static let numberWords: [String: Int] = [
        "zero": 0, "oh": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10
    ]

    struct Result {
        var quantity: Quantity?
        /// Leftover text with the matched quantity phrase removed, trimmed.
        var remainder: String
    }

    /// Attempts to find and normalize the first quantity+unit phrase in
    /// `text` for the given unit word (e.g. "carat", "gram"). Returns nil
    /// quantity if nothing matched, along with the original text untouched.
    static func extractQuantity(from text: String, unit: String) -> Result {
        let lower = text.lowercased()

        // 1) Exact numeric form: "<number> <unit>", optionally hedged.
        if let match = firstNumericMatch(in: lower, unit: unit) {
            let isApproximate = hasHedge(before: match.range, in: lower)
            let quantity = Quantity(value: match.value, unit: unit, isApproximate: isApproximate)
            var remainder = lower
            remainder.removeSubrange(match.range)
            return Result(quantity: quantity, remainder: cleanedRemainder(remainder, removingHedgesFrom: lower))
        }

        // 2) Vague word form: "about half a <unit>", "a couple <unit>s", etc.
        for (phrase, value) in vagueQuantityWords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: phrase))\\s+\(NSRegularExpression.escapedPattern(for: unit))s?\\b"
            if let range = lower.range(of: pattern, options: .regularExpression) {
                // Vague phrasing is always approximate, whether or not an
                // explicit hedge word ("about") also preceded it.
                let quantity = Quantity(value: value, unit: unit, isApproximate: true)
                var remainder = lower
                remainder.removeSubrange(range)
                return Result(quantity: quantity, remainder: cleanedRemainder(remainder, removingHedgesFrom: lower))
            }
        }

        return Result(quantity: nil, remainder: text)
    }

    // MARK: - Numeric matching

    private struct NumericMatch {
        var value: Double
        var range: Range<String.Index>
    }

    private static func firstNumericMatch(in lower: String, unit: String) -> NumericMatch? {
        // Digits already present, e.g. "3.05 carat" or "8 grams".
        let digitPattern = "\\b(\\d+(?:\\.\\d+)?)\\s*\(NSRegularExpression.escapedPattern(for: unit))s?\\b"
        if let range = lower.range(of: digitPattern, options: .regularExpression) {
            let matched = String(lower[range])
            let numberPart = matched.trimmingCharacters(in: CharacterSet.letters.union(.whitespaces))
            if let value = Double(numberPart) {
                return NumericMatch(value: value, range: range)
            }
        }

        // Spelled-out digits, e.g. "three point oh five carat".
        let spokenPattern = "\\b((?:(?:zero|oh|one|two|three|four|five|six|seven|eight|nine|ten)\\s+)+(?:point\\s+(?:(?:zero|oh|one|two|three|four|five|six|seven|eight|nine)\\s+)+)?)\(NSRegularExpression.escapedPattern(for: unit))s?\\b"
        if let range = lower.range(of: spokenPattern, options: .regularExpression) {
            let matched = String(lower[range])
            let numberWordsPart = matched.replacingOccurrences(of: unit, with: "")
                .replacingOccurrences(of: "\(unit)s", with: "")
            if let value = parseSpokenNumber(numberWordsPart) {
                return NumericMatch(value: value, range: range)
            }
        }

        return nil
    }

    /// Parses things like "three point oh five" -> 3.05, "eight" -> 8.
    private static func parseSpokenNumber(_ text: String) -> Double? {
        let tokens = text.split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return nil }

        guard let pointIndex = tokens.firstIndex(of: "point") else {
            // Whole number spoken digit-by-digit doesn't really occur for
            // small jewelry weights, so treat the run as a single digit.
            guard tokens.count == 1, let digit = numberWords[tokens[0]] else { return nil }
            return Double(digit)
        }

        let wholePart = tokens[..<pointIndex].compactMap { numberWords[$0] }
        let fractionPart = tokens[(pointIndex + 1)...].compactMap { numberWords[$0] }
        guard !fractionPart.isEmpty else { return nil }

        let whole = wholePart.map(String.init).joined()
        let fraction = fractionPart.map(String.init).joined()
        return Double("\(whole.isEmpty ? "0" : whole).\(fraction)")
    }

    // MARK: - Hedge detection

    private static func hasHedge(before range: Range<String.Index>, in text: String) -> Bool {
        let prefix = text[text.startIndex..<range.lowerBound]
        return hedgePhrases.contains { prefix.contains($0) }
    }

    private static func cleanedRemainder(_ remainder: String, removingHedgesFrom original: String) -> String {
        var result = remainder
        for hedge in hedgePhrases {
            result = result.replacingOccurrences(of: hedge, with: "")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
