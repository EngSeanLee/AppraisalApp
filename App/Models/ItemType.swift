import Foundation

/// The kinds of piece an appraisal can describe. `DescriptionTemplateEngine`
/// doesn't use a fixed sentence skeleton per case — per
/// appraisal-description-spec.md, which clauses appear is driven by what
/// data is actually present on the piece (stones vs. a stone-less chain,
/// a loose stone with no setting at all). `itemType` still matters as the
/// noun used in generated text (e.g. "The ring also consists of...") and
/// to trigger the loose-stone-specific clause shape.
// Hashable (which subsumes Equatable) is required because ItemType is used
// as a SwiftUI Picker selection value and .tag(_:).
enum ItemType: String, CaseIterable, Identifiable, Codable, Hashable {
    case ring
    case necklace
    case bracelet
    case earrings
    case looseStone = "loose_stone"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ring: return "Ring"
        case .necklace: return "Necklace"
        case .bracelet: return "Bracelet"
        case .earrings: return "Earrings"
        case .looseStone: return "Loose Stone"
        }
    }
}
