import Foundation

/// One appraisal in progress: the four anchored fields from the plan's
/// Core Flow (Customer Name, Date, Address, Item Description) plus the
/// guided elements that build the description, and the piece photo.
struct Appraisal: Codable, Equatable {
    var customerName: String = ""
    var date: Date = .now
    var address: String = ""

    /// Structured elements used to assemble the description sentence.
    var descriptionElements: DescriptionElements

    /// The description as shown/edited on screen. Starts as whatever
    /// `DescriptionTemplateEngine` assembles from `descriptionElements`,
    /// but per the plan this is a single editable box the user can freely
    /// rewrite — once hand-edited it's no longer regenerated automatically.
    var descriptionText: String = ""
    var descriptionManuallyEdited: Bool = false

    /// Filename of the captured photo within the app's document storage
    /// (kept as a filename, not raw image data, to stay Codable/lightweight).
    var photoFilename: String?

    init(itemType: ItemType = .ring) {
        self.descriptionElements = DescriptionElements(itemType: itemType)
    }

    var isReadyToExport: Bool {
        !customerName.trimmingCharacters(in: .whitespaces).isEmpty
            && !descriptionText.trimmingCharacters(in: .whitespaces).isEmpty
            && photoFilename != nil
    }
}
