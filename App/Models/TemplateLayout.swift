import CoreGraphics
import Foundation

/// Where each anchored region sits on the background template image, as
/// fractions (0–1) of the image's width/height — so layout survives the
/// image being scaled to fit different screen/print sizes.
///
/// Tuned against the real letterhead (`Tony's Jewelry Template.pdf` →
/// `AppraisalTemplate` in Assets.xcassets): a decorative silver border with
/// the "Tony's Jewelry & Custom Design" logo block in the upper-left, and
/// nothing else pre-printed — Tony's paper form has no ruled field lines to
/// match, so these positions are a layout choice, not a measurement. Only
/// constraints: stay inside the border (~5% margin) and below the logo
/// (bottom edge ~23% down). Eyeballed, not pixel-measured — nudge these if
/// the real printed/exported page looks off once someone can view it on an
/// actual device or printer.
enum TemplateAsset {
    /// Name of the letterhead image in Assets.xcassets. Both the on-screen
    /// preview (`TemplateBackgroundView`) and the PDF export
    /// (`PDFExportService`) read this same constant, so swapping in the
    /// real artwork is a one-place change.
    static let name = "AppraisalTemplate"
}

struct TemplateLayout: Codable, Equatable {
    var customerName: CGRect
    var date: CGRect
    var address: CGRect
    var itemDescription: CGRect
    /// Three equal, roughly square photo slots side by side, spanning the
    /// same width the other fields do (0.09–0.91) — multiple angles of the
    /// piece, sized to actually be usable rather than thumbnails.
    var photoOne: CGRect
    var photoTwo: CGRect
    var photoThree: CGRect
    /// The "Replacement Value…….$X,XXX.00" line(s), immediately after the
    /// description rather than pinned to the bottom of the page — stacked
    /// top-to-bottom when the appraisal is itemized per piece.
    var replacementValue: CGRect

    // Note: there is deliberately no `appraiser` region here anymore.
    // Appraisal.appraiser (the "PER" line) is still collected in the app
    // via AppraiserFieldView — it's just not drawn onto the printed
    // template right now. See PDFExportService if/when it needs a spot.

    /// The three photo slots in left-to-right order, for callers that want
    /// to iterate (the on-screen preview, PDF export) rather than name
    /// each one individually.
    var photoSlots: [CGRect] { [photoOne, photoTwo, photoThree] }

    static let `default` = TemplateLayout(
        customerName: CGRect(x: 0.09, y: 0.27, width: 0.52, height: 0.035),
        date: CGRect(x: 0.66, y: 0.27, width: 0.25, height: 0.035),
        address: CGRect(x: 0.09, y: 0.32, width: 0.82, height: 0.035),
        // Moved up now that the appraiser row above it is gone, and
        // shrunk another 15% on top of the prior 25% cut
        // (0.30 -> 0.225 -> ~0.191), so there's room for the Replacement
        // Value line right underneath and the photo row below that,
        // without crowding the bottom border.
        itemDescription: CGRect(x: 0.09, y: 0.37, width: 0.82, height: 0.19125),
        // Immediately after the description (not pinned to the page
        // bottom, which put it right up against the border).
        replacementValue: CGRect(x: 0.09, y: 0.57, width: 0.82, height: 0.04),
        // Full content width (0.09–0.91, matching every other field) split
        // into 3 equal slots with 0.02 gaps: 3×0.26 + 2×0.02 = 0.82. Height
        // is width × (page width ÷ page height) = 0.26 × (8.5/11) ≈ 0.20,
        // so each slot renders as an actual square on the US-Letter page,
        // not a portrait-cropped rectangle.
        photoOne: CGRect(x: 0.09, y: 0.65, width: 0.26, height: 0.20),
        photoTwo: CGRect(x: 0.37, y: 0.65, width: 0.26, height: 0.20),
        photoThree: CGRect(x: 0.65, y: 0.65, width: 0.26, height: 0.20)
    )
}
// CGRect already conforms to Codable via the CoreGraphics/Foundation overlay
// (through CGPoint/CGSize), so no extension is needed here.
