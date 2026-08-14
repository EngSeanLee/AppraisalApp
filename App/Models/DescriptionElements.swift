import Foundation

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

/// Element #2 from the plan ("Item type & setting style"), e.g. spoken as
/// one utterance ("Euro shank ring with halo") but split into the two
/// pieces the fixed sentence template needs: the item-type noun phrase
/// used once, and the short setting-style noun ("halo") the template
/// refers back to again in the side-stones clause ("The halo consists
/// of..."). `DescriptionTemplateEngine` does the splitting; either half
/// can be edited by hand if the split guesses wrong.
struct ItemStyleInfo: Codable, Equatable {
    var typePhrase: String        // e.g. "Euro shank ring"
    var settingStyle: String?     // e.g. "halo" (nil if the piece has no named setting)
}

struct CenterStoneInfo: Codable, Equatable {
    var carat: Quantity
    var cut: String          // e.g. "marquise cut"
    var stoneType: String    // e.g. "diamond"
}

struct CertificationInfo: Codable, Equatable {
    var issuer: String   // e.g. "IGI"
    var number: String   // e.g. "764659900"
    var color: String    // e.g. "E"
    var clarity: String  // e.g. "VS1"
}

struct SideStonesInfo: Codable, Equatable {
    var stoneType: String    // e.g. "diamonds"
    var totalWeight: Quantity
}

/// The five required elements from the plan's "Description — Minimum
/// Required Elements" section, one `GuidedField` per element so the guided
/// checklist can track fill/skip state independently of the free-text
/// override the user sees and can edit at any point.
struct DescriptionElements: Codable, Equatable {
    var itemType: ItemType
    var metal: GuidedField<MetalInfo> = .notStarted
    var itemStyle: GuidedField<ItemStyleInfo> = .notStarted    // e.g. "Euro shank ring with halo"
    var centerStone: GuidedField<CenterStoneInfo> = .notStarted
    var certification: GuidedField<CertificationInfo> = .notStarted
    var sideStones: GuidedField<SideStonesInfo> = .notStarted

    /// All five, in the guided-prompt order from the plan
    /// (metal → weight → item/setting → center stone → cert/grading → side stones).
    var allFieldsResolved: Bool {
        [metal.isResolved, itemStyle.isResolved, centerStone.isResolved,
         certification.isResolved, sideStones.isResolved].allSatisfy { $0 }
    }
}
