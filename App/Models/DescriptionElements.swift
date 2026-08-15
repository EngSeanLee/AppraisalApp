import Foundation

// The building blocks `Piece` composes a description from. The type
// originally named `DescriptionElements` (a single fixed bundle of five
// required fields) is gone — appraisal-description-spec.md's "Core
// Insight" is that there's no single fixed sentence template even within
// one item type, so the model is now a composable, repeatable set of
// pieces (see `Piece.swift`) rather than one rigid struct. Kept this
// filename since these are still the shared vocabulary types used
// throughout the guided description builder.

/// Whether a guided-checklist element has been visited yet, deliberately
/// skipped ("N/A" — e.g. a plain band has no center stone), or filled with
/// a value. Kept distinct from a plain optional so the checklist UI can
/// show "not started" differently from "explicitly skipped" — the plan
/// calls for making skipped-vs-filled "visually obvious ... so nothing
/// gets missed by accident on a piece that does need it."
enum GuidedField<Value: Codable & Equatable>: Codable, Equatable {
    case notStarted
    case skipped
    case filled(Value)

    var value: Value? {
        if case .filled(let v) = self { return v }
        return nil
    }

    var isResolved: Bool {
        switch self {
        case .notStarted: return false
        case .skipped, .filled: return true
        }
    }
}

struct MetalInfo: Codable, Equatable {
    var karat: String       // e.g. "14 karat"
    var metalName: String   // e.g. "white gold"
    var totalWeight: Quantity
}

/// Element from the plan ("Item type & setting style"), e.g. spoken as
/// one utterance ("Euro shank ring with halo") but split into the two
/// pieces the description clauses need: the item-type noun phrase used
/// once, and the short setting-style noun ("halo") the accent-stones
/// clause refers back to again ("The halo also consists of..."). Either
/// half can be edited by hand if the split guesses wrong.
struct ItemStyleInfo: Codable, Equatable {
    var typePhrase: String        // e.g. "Euro shank ring"
    var settingStyle: String?     // e.g. "halo" (nil if the piece has no named setting)
}

/// Whether a diamond is disclosed as natural, lab-grown, or not yet
/// determined. Deliberately a 3-way flag the user sets explicitly, never
/// silently inferred (e.g. from an "LG"-prefixed cert number) — per
/// appraisal-description-spec.md's "Special Flags" section, guessing this
/// wrong on a real appraisal is a real liability risk. `unspecified` is the
/// default so nothing gets marked natural/lab-grown by accident.
enum StoneOrigin: String, Codable, CaseIterable, Identifiable, Equatable {
    case natural, labGrown, unspecified

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .natural: return "Natural"
        case .labGrown: return "Lab-Grown"
        case .unspecified: return "Unspecified"
        }
    }
}

/// A stone's grading-lab certificate. Attaches per stone (not once per
/// appraisal) — real examples show up to 3 independently-certified stones
/// on one piece, each with its own issuer/number.
struct StoneCertification: Codable, Equatable {
    var issuer: String = ""   // e.g. "GIA", "IGI"
    var number: String = ""

    var isEmpty: Bool {
        issuer.trimmingCharacters(in: .whitespaces).isEmpty
            && number.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// Whether a stone entry is the primary/center stone (rendered "...in the
/// center") or one of an accent group (rendered "The halo also consists
/// of...") — see appraisal-description-spec.md clauses #3 and #4.
enum StoneRole: String, Codable, CaseIterable, Identifiable, Equatable {
    case center, accent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .center: return "Center Stone"
        case .accent: return "Accent Stones"
        }
    }
}

/// One stone (or one group of identical accent stones) on a piece.
/// Replaces the old fixed `centerStone` + `certification` + `sideStones`
/// trio with a repeatable list, since real appraisals show anywhere from
/// zero stones (a plain chain) to several independently-graded groups —
/// see appraisal-description-spec.md's "Core Insight": there is no single
/// fixed sentence template, so the data model shouldn't have one either.
struct StoneEntry: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var role: StoneRole = .center
    /// Number of stones this entry describes — 1 for a typical center
    /// stone, N for an accent group ("10 round diamonds"). Occasionally
    /// >1 on a center-role entry too (rare co-equal center stones, e.g. a
    /// past/present/future 3-stone ring where none is more "center" than
    /// the others).
    var count: Int = 1
    var cut: String = ""          // shape/cut, e.g. "round brilliant cut", "marquise cut"
    var stoneType: String = "diamond"
    /// Carat weight — this stone's own weight if role == .center, or the
    /// group's total weight ("with the weight of 0.38ctw") if role == .accent.
    var carat: Quantity?
    /// Some stones (small/colored) are sized by mm instead of, or in
    /// addition to, carat — e.g. "2X4mm". Free text since it's a
    /// dimension pair, not a single number.
    var mmSize: String = ""
    var color: String = ""        // e.g. "E", or a range like "H-I"
    var clarity: String = ""      // e.g. "VS1", or a range like "SI1-SI2"
    var origin: StoneOrigin = .unspecified
    var certification: StoneCertification?

    var isEmpty: Bool {
        cut.trimmingCharacters(in: .whitespaces).isEmpty
            && color.trimmingCharacters(in: .whitespaces).isEmpty
            && clarity.trimmingCharacters(in: .whitespaces).isEmpty
            && mmSize.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// For stone-less pieces (chains, Cuban-link bracelets) — clause #5 in the
/// spec: "[style name] [item type] weighs [weight] grams [karat] [metal
/// color] gold [length] in length," with no stone clauses at all.
struct ChainInfo: Codable, Equatable {
    var styleName: String = ""    // e.g. "Miami Cuban links"
    var length: Quantity?         // e.g. 7.5 "inch"
}
