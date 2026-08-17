import Foundation

/// A "Replacement Value…….$X,XXX.00" line — always present on a real
/// appraisal, per appraisal-description-spec.md clause #7. `marketNote` is
/// the occasional optional parenthetical justifying part of the valuation,
/// e.g. "1.08 carats ($4375/oz)".
///
/// One value per appraisal — the spec's itemized-per-piece pattern (a
/// separate line per piece) turned out not to be worth the complexity in
/// practice; Tony always prices the appraisal as a whole.
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

/// One appraisal in progress: the anchored header fields (customer, date,
/// address), a single free-typed-or-dictated description, its Replacement
/// Value, and the piece photos. The appraiser line ("PER") is a fixed
/// printed label on the template itself, not app data — see
/// `TemplateLayout.perLine` / `PDFExportService` — since it's always Tony,
/// signed/stamped by hand after printing.
struct Appraisal: Codable, Equatable {
    /// Stable identity for `AppraisalStore` — generated once when the
    /// appraisal is created and unaffected by edits, so saving the same
    /// appraisal again overwrites its own file instead of creating a new
    /// one, and `SavedAppraisalsView` can reopen the right one.
    var id: UUID = UUID()

    var customerName: String = ""
    var date: Date = .now
    var address: String = ""

    /// What Tony types or dictates, freely, in his own words — no guided
    /// fields behind it. `DescriptionChecklist` scans this text to surface
    /// soft, non-blocking reminders (missing metal, missing weight, ...)
    /// rather than forcing structured entry.
    var descriptionText: String = ""

    var replacementValue: ReplacementValue = ReplacementValue()

    /// Filenames of the up to 3 captured piece photos within the app's
    /// document storage (kept as filenames, not raw image data, to stay
    /// Codable/lightweight), positionally matched to
    /// `TemplateLayout.photoSlots` — index 0 is the leftmost slot, etc.
    /// Always 3 elements; a nil means that slot hasn't been captured yet.
    var photoFilenames: [String?] = [nil, nil, nil]

    var isReadyToExport: Bool {
        !customerName.trimmingCharacters(in: .whitespaces).isEmpty
            && !descriptionText.trimmingCharacters(in: .whitespaces).isEmpty
            && photoFilenames.contains { $0 != nil }
    }

    /// True for an appraisal nobody has touched yet — the state
    /// `AppraisalViewModel.startNew()` produces. `AppraisalStore` skips
    /// saving these so starting fresh (or just launching the app) doesn't
    /// leave empty entries cluttering the saved-appraisals list.
    var isBlank: Bool {
        customerName.trimmingCharacters(in: .whitespaces).isEmpty
            && address.trimmingCharacters(in: .whitespaces).isEmpty
            && descriptionText.trimmingCharacters(in: .whitespaces).isEmpty
            && replacementValue.isEmpty
            && !photoFilenames.contains { $0 != nil }
    }
}
