import Foundation

/// The kinds of piece an appraisal can describe. Each case has its own
/// fixed sentence skeleton in `DescriptionTemplateEngine`, per the plan's
/// "Fixed template per item type" requirement.
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
