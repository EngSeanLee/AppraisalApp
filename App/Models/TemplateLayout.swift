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
    /// The appraiser "PER" line — name and, when present, its credential
    /// line stacked underneath (drawn as "name\ncredential").
    var appraiser: CGRect
    var itemDescription: CGRect
    /// Three equal-width photo slots side by side, spanning the same
    /// horizontal footprint the single photo box used to occupy alone —
    /// multiple angles of the piece, not one enlarged shot.
    var photoOne: CGRect
    var photoTwo: CGRect
    var photoThree: CGRect
    /// One or more "Replacement Value…….$X,XXX.00" lines, stacked
    /// top-to-bottom when the appraisal is itemized per piece.
    var replacementValue: CGRect

    /// The three photo slots in left-to-right order, for callers that want
    /// to iterate (the on-screen preview, PDF export) rather than name
    /// each one individually.
    var photoSlots: [CGRect] { [photoOne, photoTwo, photoThree] }

    static let `default` = TemplateLayout(
        customerName: CGRect(x: 0.09, y: 0.27, width: 0.52, height: 0.035),
        date: CGRect(x: 0.66, y: 0.27, width: 0.25, height: 0.035),
        address: CGRect(x: 0.09, y: 0.32, width: 0.82, height: 0.035),
        appraiser: CGRect(x: 0.09, y: 0.365, width: 0.55, height: 0.045),
        // Shrunk 25% (0.30 -> 0.225) and moved up flush against the
        // appraiser row (0.42 -> 0.41) so a full-length description no
        // longer crowds the photo row or the Replacement Value line below.
        itemDescription: CGRect(x: 0.09, y: 0.41, width: 0.82, height: 0.225),
        // Same combined footprint the old single 0.36-wide photo box
        // occupied (x: 0.09–0.45), split into 3 equal 0.11-wide slots with
        // 0.015 gaps between them: 3×0.11 + 2×0.015 = 0.36.
        photoOne: CGRect(x: 0.09, y: 0.74, width: 0.11, height: 0.14),
        photoTwo: CGRect(x: 0.215, y: 0.74, width: 0.11, height: 0.14),
        photoThree: CGRect(x: 0.34, y: 0.74, width: 0.11, height: 0.14),
        replacementValue: CGRect(x: 0.09, y: 0.90, width: 0.82, height: 0.05)
    )
}
// CGRect already conforms to Codable via the CoreGraphics/Foundation overlay
// (through CGPoint/CGSize), so no extension is needed here.
