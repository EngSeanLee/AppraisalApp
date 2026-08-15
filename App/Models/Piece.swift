import Foundation

/// One physical item within an appraisal. Most appraisals have exactly
/// one; multi-item appraisals (a wedding + engagement ring pair, a
/// 3-ring stack) have several — see appraisal-description-spec.md clause
/// #6 "Multi-item combination." Each piece gets its own metal/style/stone
/// clauses; `DescriptionTemplateEngine` concatenates all pieces' clauses
/// into the appraisal's single description text box.
struct Piece: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var itemType: ItemType = .ring

    /// Short name for this piece, used only when `Appraisal.valuationMode
    /// == .itemized` to label its Replacement Value line (e.g.
    /// "engagement ring", "the band" — matches real examples like
    /// "Replacement Value engagement ring……$6,950.00"). Ignored in
    /// combined-valuation mode.
    var pieceLabel: String = ""

    /// Gender/qualifier prefix, e.g. "Ladies'", "Men's" — real examples
    /// show this varies and is sometimes omitted entirely.
    var qualifier: String = ""
    var isCustomMade: Bool = false

    var metal: GuidedField<MetalInfo> = .notStarted
    var itemStyle: GuidedField<ItemStyleInfo> = .notStarted

    /// Every stone or stone-group on this piece, in the order they should
    /// appear in the description (center stone(s) first, then each accent
    /// group). Empty means either no stones yet, or — combined with a
    /// filled `chain` — a genuinely stone-less piece like a plain chain.
    var stones: [StoneEntry] = []

    /// For stone-less pieces (chains, Cuban-link bracelets): clause #5,
    /// used instead of the stone clauses when `stones` is empty.
    var chain: GuidedField<ChainInfo> = .notStarted

    /// This piece's own Replacement Value — only meaningful/shown when
    /// the appraisal uses itemized valuation; combined valuation uses
    /// `Appraisal.combinedReplacementValue` instead.
    var replacementValue: ReplacementValue = ReplacementValue()

    var hasAnyStones: Bool { !stones.isEmpty }

    var centerStones: [StoneEntry] { stones.filter { $0.role == .center } }
    var accentStoneGroups: [StoneEntry] { stones.filter { $0.role == .accent } }
}
