import Foundation

/// A numeric quantity (weight, carat, etc.) that remembers whether it came
/// from a precise dictated figure or a hedged/vague one ("about half a
/// carat"), per the plan's normalization rules.
struct Quantity: Codable, Equatable {
    var value: Double
    var unit: String
    var isApproximate: Bool

    /// e.g. "approximately 0.50 carat" or "3.05 carat".
    ///
    /// NOTE: units are kept singular even when the value isn't 1, matching
    /// the plan's own example ("8.00 gram Euro shank ring") — appraisal
    /// sentences use the quantity adjectivally ("an 8.00-gram ring"), not as
    /// a standalone plural noun. The plan flags this as still fuzzy
    /// ("approximately 2.00 gram(s)") — revisit once real reference
    /// appraisals are available (see plan's Open Items).
    var displayString: String {
        let formatted = String(format: "%.2f", value)
        return isApproximate ? "approximately \(formatted) \(unit)" : "\(formatted) \(unit)"
    }
}
