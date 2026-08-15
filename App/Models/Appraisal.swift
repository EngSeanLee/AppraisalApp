import Foundation

/// The "PER" signature line. NOT hardcoded to one person — real letterheads
/// show different appraisers with different (or no) credential lines, e.g.
/// "Tony Lee" alone vs. "Christopher D. Walker" with "GIA Certified Grader"
/// underneath. `roster` seeds the picker but the fields stay freely
/// editable so anyone can appraise, not just the two people seen so far.
struct AppraiserInfo: Codable, Equatable {
    var name: String = ""
    var credential: String = ""   // optional second line, e.g. "GIA Certified Grader"

    static let roster = ["Tony Lee", "Christopher D. Walker"]
}

/// A "Replacement Value…….$X,XXX.00" line — always present on a real
/// appraisal, per appraisal-description-spec.md clause #7. `marketNote` is
/// the occasional optional parenthetical justifying part of the valuation,
/// e.g. "1.08 carats ($4375/oz)".
struct ReplacementValue: Codable, Equatable {
    var amount: Double?
    var marketNote: String = ""

    var isEmpty: Bool { amount == nil }

    /// Dot-leader style, two decimals, comma thousands separator — matches
    /// every real example in the spec exactly.
    var displayString: String {
        guard let amount else { return "" }
        let formatter = NumberFormatter()
        // Fixed to en_US regardless of device locale: this is always a US
        // dollar figure ("$X,XXX.00"), not a locale-sensitive number —
        // using the device's locale would silently swap in "." thousands
        // separators on a device set to e.g. German.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        let base = "Replacement Value…….$\(formatted)"
        let note = marketNote.trimmingCharacters(in: .whitespaces)
        return note.isEmpty ? base : "\(base) (\(note))"
    }
}

/// Whether one Replacement Value covers every piece together, or each
/// piece gets its own line — both patterns are real, per spec clause #6.
enum ValuationMode: String, Codable, CaseIterable, Identifiable, Equatable {
    case combined, itemized

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .combined: return "Combined total"
        case .itemized: return "Itemized per piece"
        }
    }
}

/// One appraisal in progress: the anchored header fields (customer, date,
/// address, appraiser, Replacement Value) plus one or more `Piece`s that
/// build the description, and the piece photo.
struct Appraisal: Codable, Equatable {
    var customerName: String = ""
    var date: Date = .now
    var address: String = ""
    var appraiser: AppraiserInfo = AppraiserInfo()

    var pieces: [Piece] = [Piece()]
    var valuationMode: ValuationMode = .combined
    var combinedReplacementValue: ReplacementValue = ReplacementValue()

    /// The description as shown/edited on screen. Starts as whatever
    /// `DescriptionTemplateEngine` assembles from `pieces`, but per the
    /// plan this is a single editable box the user can freely rewrite —
    /// once hand-edited it's no longer regenerated automatically.
    var descriptionText: String = ""
    var descriptionManuallyEdited: Bool = false

    /// Filenames of the up to 3 captured piece photos within the app's
    /// document storage (kept as filenames, not raw image data, to stay
    /// Codable/lightweight), positionally matched to
    /// `TemplateLayout.photoSlots` — index 0 is the leftmost slot, etc.
    /// Always 3 elements; a nil means that slot hasn't been captured yet.
    var photoFilenames: [String?] = [nil, nil, nil]

    init(itemType: ItemType = .ring) {
        self.pieces = [Piece(itemType: itemType)]
    }

    /// The Replacement Value line(s) to print, already formatted, one
    /// per line — a single combined line, or one per piece when itemized
    /// (skipping any piece that hasn't had a value entered yet).
    var replacementValueLines: [String] {
        switch valuationMode {
        case .combined:
            return combinedReplacementValue.isEmpty ? [] : [combinedReplacementValue.displayString]
        case .itemized:
            return pieces.compactMap { piece in
                guard !piece.replacementValue.isEmpty else { return nil }
                let label = piece.pieceLabel.trimmingCharacters(in: .whitespaces)
                let base = piece.replacementValue.displayString
                return label.isEmpty ? base : base.replacingOccurrences(of: "Replacement Value", with: "Replacement Value \(label)")
            }
        }
    }

    var isReadyToExport: Bool {
        !customerName.trimmingCharacters(in: .whitespaces).isEmpty
            && !descriptionText.trimmingCharacters(in: .whitespaces).isEmpty
            && photoFilenames.contains { $0 != nil }
    }
}
