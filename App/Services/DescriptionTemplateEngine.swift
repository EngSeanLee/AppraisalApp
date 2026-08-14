import Foundation

/// Assembles `DescriptionElements` into the fixed, per-item-type sentence
/// the plan calls for, so every appraisal of the same item type reads with
/// identical structure regardless of how the elements were spoken.
///
/// Only the ring template is filled in from the plan's worked example.
/// Necklace/bracelet/earrings/loose-stone reuse the same clause shapes as a
/// reasonable starting point — per the plan's Open Items, these still need
/// their own templates defined against real reference appraisals.
enum DescriptionTemplateEngine {

    static func assemble(_ elements: DescriptionElements) -> String {
        var sentences: [String] = []

        if let opening = openingClause(elements) {
            sentences.append(opening)
        }
        if let cert = certificationClause(elements) {
            sentences.append(cert)
        }
        if let side = sideStonesClause(elements) {
            sentences.append(side)
        }

        return sentences.joined(separator: " ")
    }

    // MARK: - Clause builders
    // These are independent so a partially-filled checklist (some
    // elements skipped as N/A) still produces a grammatical, if shorter,
    // description — nothing is required to be present except each
    // sentence's own subject.

    /// "14 karat white gold, 8.00 gram Euro shank ring with halo[, set with
    /// a 3.05 carat marquise cut diamond in the center]."
    private static func openingClause(_ elements: DescriptionElements) -> String? {
        var parts: [String] = []

        if let metal = elements.metal.value {
            parts.append("\(metal.karat) \(metal.metalName), \(metal.totalWeight.displayString)")
        }

        if let style = elements.itemStyle.value {
            var phrase = style.typePhrase
            if let setting = style.settingStyle {
                phrase += " with \(setting)"
            }
            parts.append(parts.isEmpty ? phrase.capitalizingFirstLetter() : phrase)
        }

        guard !parts.isEmpty else { return nil }
        var clause = parts.joined(separator: " ")

        if let center = elements.centerStone.value {
            clause += ", set with a \(center.carat.displayString) \(center.cut) \(center.stoneType) in the center"
        }

        return clause.finishedAsSentence()
    }

    /// "The marquise diamond is certified by IGI #764659900, E, VS1." —
    /// refers back to the center stone by its shape adjective + stone type,
    /// matching the plan's worked example, not just the bare stone type.
    private static func certificationClause(_ elements: DescriptionElements) -> String? {
        guard let cert = elements.certification.value else { return nil }
        let stoneNoun = elements.centerStone.value.map(stoneAdjectivePhrase) ?? "center stone"
        return "The \(stoneNoun) is certified by \(cert.issuer) #\(cert.number), \(cert.color), \(cert.clarity)."
    }

    /// "marquise cut" + "diamond" -> "marquise diamond".
    private static func stoneAdjectivePhrase(_ center: CenterStoneInfo) -> String {
        let shapeAdjective = center.cut.hasSuffix(" cut") ? String(center.cut.dropLast(4)) : center.cut
        return "\(shapeAdjective) \(center.stoneType)"
    }

    /// "The halo consists of diamonds with a total weight of 0.53 carat."
    /// Falls back to "The accent stones..." if no named setting style was
    /// captured (e.g. side stones on a plain style with no halo/pavé term).
    private static func sideStonesClause(_ elements: DescriptionElements) -> String? {
        guard let side = elements.sideStones.value else { return nil }
        let settingNoun = elements.itemStyle.value?.settingStyle ?? "accent stones"
        let subject = settingNoun == "accent stones" ? "The accent stones consist" : "The \(settingNoun) consists"
        return "\(subject) of \(side.stoneType) with a total weight of \(side.totalWeight.displayString)."
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }

    /// Capitalizes the first letter and ensures the clause ends with a period.
    func finishedAsSentence() -> String {
        var s = capitalizingFirstLetter()
        if !s.hasSuffix(".") { s += "." }
        return s
    }
}
