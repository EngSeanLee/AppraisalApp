import Foundation

/// Assembles one or more `Piece`s into the appraisal's description text.
///
/// This is a composable clause system, not a fixed sentence-per-item-type
/// template — see appraisal-description-spec.md's "Core Insight": a plain
/// band, a 3-stone ring, and a stone-less Cuban link bracelet share almost
/// no structure, derived from 12 of Tony's real past appraisals. Which
/// clauses appear is driven entirely by what data is actually present on
/// each piece (a metal clause, an optional center-stone clause, zero or
/// more accent-stone-group clauses, per-stone certification sentences, or
/// — for stone-less pieces — a chain/length clause instead), always
/// assembled in the same standardized voice/order regardless of item type.
/// Multiple pieces (a wedding + engagement ring pair) just contribute their
/// clauses one after another into the same description.
///
/// Every stone carries its own grading (color/clarity) and, optionally,
/// its own lab certification — real appraisals show up to 3 independently
/// certified stones on one piece. The spec explicitly allows a cert number
/// either inline in the stone's clause or as its own sentence; this engine
/// always uses a separate sentence, so every generated description reads
/// in one consistent voice no matter how the elements were spoken.
enum DescriptionTemplateEngine {

    static func assemble(_ pieces: [Piece]) -> String {
        var sentences: [String] = []

        for piece in pieces {
            if piece.hasAnyStones {
                if let opening = openingClause(piece) {
                    sentences.append(opening)
                }
                for stone in piece.centerStones {
                    if let cert = certificationSentence(stone) {
                        sentences.append(cert)
                    }
                }
                for stone in piece.accentStoneGroups {
                    sentences.append(contentsOf: accentSentences(stone, piece: piece))
                    if let cert = certificationSentence(stone) {
                        sentences.append(cert)
                    }
                }
            } else if let chain = chainClause(piece) {
                sentences.append(chain)
            } else if let opening = openingClause(piece) {
                // Metal/style filled in, but no stones and no chain info
                // yet — still worth showing what's there so far.
                sentences.append(opening)
            }
        }

        return sentences.joined(separator: " ")
    }

    // Convenience overload for the common single-piece case (used by the
    // guided builder's live preview while editing one piece).
    static func assemble(_ piece: Piece) -> String { assemble([piece]) }

    // MARK: - Opening clause (metal/weight + item style + center stone)

    /// "[Ladies'] [custom made] [14 karat white gold, 8.00 gram] [Euro
    /// shank ring with halo][, set with a 3.05 carat marquise cut diamond,
    /// SI1, I color, in the center]." Order of the qualifier/custom-made
    /// prefix, metal, and style pieces matches the spec's real examples,
    /// which show weight-before-karat and karat-before-weight both in use
    /// — kept fixed here as one consistent order per piece rather than
    /// trying to reproduce the speaker's original phrasing order.
    ///
    /// Loose (unmounted) stones (`itemType == .looseStone`) skip the
    /// metal/setting wrapper entirely — the stone itself is the subject,
    /// with no "in the center" framing, since there's no setting for it
    /// to be centered in.
    private static func openingClause(_ piece: Piece) -> String? {
        let prefixWords = [piece.qualifier, piece.isCustomMade ? "custom made" : ""]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let centerStones = piece.centerStones

        if piece.itemType == .looseStone, let first = centerStones.first {
            let subject = centerStoneSubject(first) + (gradingPhrase(clarity: first.clarity, color: first.color).map { ", \($0)" } ?? "")
            return (prefixWords + [subject]).joined(separator: " ").finishedAsSentence()
        }

        var parts: [String] = []
        if let metal = piece.metal.value {
            parts.append("\(metal.karat) \(metal.metalName), \(metal.totalWeight.displayString)")
        }
        if let style = piece.itemStyle.value {
            var phrase = style.typePhrase
            if let setting = style.settingStyle, !setting.trimmingCharacters(in: .whitespaces).isEmpty {
                phrase += " with \(setting)"
            }
            parts.append(phrase)
        }

        guard !parts.isEmpty || !centerStones.isEmpty else { return nil }

        var clause = (prefixWords + parts).joined(separator: " ")

        if let first = centerStones.first {
            let grading = gradingPhrase(clarity: first.clarity, color: first.color).map { ", \($0)" } ?? ""
            let firstSubject = centerStoneSubject(first) + grading
            let extraSubjects = centerStones.dropFirst().map(centerStoneSubject)
            let joinedSubjects = ([firstSubject] + extraSubjects).joined(separator: " and ")

            clause = clause.isEmpty
                ? "Set with \(joinedSubjects) in the center"
                : "\(clause), set with \(joinedSubjects) in the center"
        }

        return clause.finishedAsSentence()
    }

    /// "a 3.05 carat marquise cut diamond" (singular) or "2 round diamonds"
    /// (a center-role entry with count > 1 — rare co-equal center stones,
    /// e.g. a past/present/future 3-stone ring). Assumes `cut`/`stoneType`
    /// are non-empty, which the guided stone editor already enforces
    /// before a stone is added.
    private static func centerStoneSubject(_ stone: StoneEntry) -> String {
        let sizedCut = [sizePhrase(for: stone), stone.cut]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return stone.count > 1
            ? "\(stone.count) \(sizedCut) \(stone.stoneType)"
            : "a \(sizedCut) \(stone.stoneType)"
    }

    /// Prefers carat weight; falls back to mm dimensions for small/colored
    /// stones sized that way instead (spec: "2X4mm", "5.7x4.3mm").
    private static func sizePhrase(for stone: StoneEntry) -> String {
        if let carat = stone.carat { return carat.displayString }
        return stone.mmSize.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Accent stone group clauses

    /// "The halo also consists of 10 round diamonds. These diamonds are
    /// SI1-SI2, H-I in color with the weight of 0.38ctw." — the setting
    /// name (if any) is reused as the subject, per the spec; falls back to
    /// the item type ("The ring also consists of...") when no setting
    /// style was captured.
    private static func accentSentences(_ stone: StoneEntry, piece: Piece) -> [String] {
        let settingName = piece.itemStyle.value?.settingStyle?.trimmingCharacters(in: .whitespaces)
        let subjectNoun = (settingName?.isEmpty == false ? settingName : nil) ?? piece.itemType.displayName.lowercased()

        var sentences = [
            "The \(subjectNoun) also consists of \(stone.count) \(stone.cut) \(stone.stoneType).".finishedAsSentence()
        ]

        let grading = gradingPhrase(clarity: stone.clarity, color: stone.color)
        switch (grading, stone.carat) {
        case let (.some(g), .some(carat)):
            sentences.append("These \(stone.stoneType) are \(g) with the weight of \(carat.displayString).".finishedAsSentence())
        case let (.some(g), nil):
            sentences.append("These \(stone.stoneType) are \(g).".finishedAsSentence())
        case let (nil, .some(carat)):
            sentences.append("These \(stone.stoneType) have a total weight of \(carat.displayString).".finishedAsSentence())
        case (nil, nil):
            break
        }

        return sentences
    }

    // MARK: - Certification

    /// "This marquise diamond is certified by GIA #6542519109." for a
    /// center stone, or "These diamonds are certified by IGI #LG648473332."
    /// for an accent group — grading isn't repeated here since it's
    /// already stated in the stone's own clause.
    private static func certificationSentence(_ stone: StoneEntry) -> String? {
        guard let cert = stone.certification, !cert.isEmpty else { return nil }
        switch stone.role {
        case .center:
            return "This \(stoneAdjectivePhrase(stone)) is certified by \(cert.issuer) #\(cert.number).".finishedAsSentence()
        case .accent:
            return "These \(stone.stoneType) are certified by \(cert.issuer) #\(cert.number).".finishedAsSentence()
        }
    }

    /// "marquise cut" + "diamond" -> "marquise diamond".
    private static func stoneAdjectivePhrase(_ stone: StoneEntry) -> String {
        let shape = stone.cut.hasSuffix(" cut") ? String(stone.cut.dropLast(4)) : stone.cut
        let trimmed = shape.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? stone.stoneType : "\(trimmed) \(stone.stoneType)"
    }

    /// "SI1, I color" (both), "SI1" (clarity only), or "I color" (color
    /// only) — nil when neither was captured, so callers can decide
    /// whether to omit the grading mention entirely.
    private static func gradingPhrase(clarity: String, color: String) -> String? {
        let c = clarity.trimmingCharacters(in: .whitespaces)
        let col = color.trimmingCharacters(in: .whitespaces)
        switch (c.isEmpty, col.isEmpty) {
        case (false, false): return "\(c), \(col) in color"
        case (false, true): return c
        case (true, false): return "\(col) color"
        case (true, true): return nil
        }
    }

    // MARK: - Chain/length clause (stone-less pieces)

    /// "Miami Cuban links bracelet weighs 32.0 grams 14 karat yellow gold
    /// 7.5 in length." — clause #5, used instead of any stone clause when
    /// the piece has no stones at all.
    private static func chainClause(_ piece: Piece) -> String? {
        guard let chain = piece.chain.value, let metal = piece.metal.value else { return nil }

        let style = chain.styleName.trimmingCharacters(in: .whitespaces)
        let subject = style.isEmpty ? piece.itemType.displayName.lowercased() : "\(style) \(piece.itemType.displayName.lowercased())"

        var clause = "\(subject) weighs \(metal.totalWeight.displayString) \(metal.karat) \(metal.metalName)"
        if let length = chain.length {
            clause += " \(trimmedNumber(length.value)) in length"
        }

        return clause.finishedAsSentence()
    }

    /// 7.50 -> "7.5", 32.00 -> "32" — a bare number for clauses (like
    /// chain length) that don't use `Quantity.displayString`'s fixed
    /// 2-decimal-plus-unit-word form.
    private static func trimmedNumber(_ value: Double) -> String {
        var formatted = String(format: "%.2f", value)
        while formatted.hasSuffix("0") { formatted.removeLast() }
        if formatted.hasSuffix(".") { formatted.removeLast() }
        return formatted
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
