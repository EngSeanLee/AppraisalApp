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
/// (bottom edge ~17.5% down — the logo was moved up in the artwork itself,
/// closer to the border, per UAT feedback; see the imageset's edit
/// history). Eyeballed, not pixel-measured — nudge these if the real
/// printed/exported page looks off once someone can view it on an actual
/// device or printer.
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
    /// The "Replacement Value…….$X,XXX.00" line, immediately after the
    /// description rather than pinned to the bottom of the page.
    var replacementValue: CGRect
    /// The static "PER ________" stamp line, under the photos — Tony
    /// signs/stamps this by hand after printing. Not bound to any
    /// `Appraisal` field: the appraiser is always Tony, so there's nothing
    /// to type here, just a printed label + blank line for the physical
    /// signature/stamp.
    var perLine: CGRect
    /// The fixed-wording insurance/liability disclaimer (`NoticeText`),
    /// full width, in small type at the very bottom — below `perLine`,
    /// still comfortably clear of the border. `PDFExportService` draws it
    /// shrink-to-fit the same way every other field is drawn, down to a
    /// 6pt floor.
    var notice: CGRect

    /// The three photo slots in left-to-right order, for callers that want
    /// to iterate (the on-screen preview, PDF export) rather than name
    /// each one individually.
    var photoSlots: [CGRect] { [photoOne, photoTwo, photoThree] }

    static let `default` = TemplateLayout(
        // Every field below is the original tuned layout shifted up by
        // 0.06 (6% of page height) as a block, preserving the original
        // gaps between fields — that's exactly how much vertical room the
        // logo move freed at the top (old logo bottom ~23.8% down, new
        // logo bottom ~17.6% down). The reclaimed space at the *bottom*
        // (perLine's old position through the border) is what makes room
        // for `notice` below without crowding anything.
        customerName: CGRect(x: 0.09, y: 0.21, width: 0.52, height: 0.035),
        date: CGRect(x: 0.66, y: 0.21, width: 0.25, height: 0.035),
        address: CGRect(x: 0.09, y: 0.26, width: 0.82, height: 0.035),
        itemDescription: CGRect(x: 0.09, y: 0.31, width: 0.82, height: 0.19125),
        // Full content width (0.09–0.91, matching every other field) split
        // into 3 equal slots with 0.02 gaps: 3×0.26 + 2×0.02 = 0.82. Height
        // is width × (page width ÷ page height) = 0.26 × (8.5/11) ≈ 0.20,
        // so each slot renders as an actual square on the US-Letter page,
        // not a portrait-cropped rectangle. Unaffected by the vertical
        // shift — width/height ratio (and therefore squareness) only
        // depends on width.
        photoOne: CGRect(x: 0.09, y: 0.59, width: 0.26, height: 0.20),
        photoTwo: CGRect(x: 0.37, y: 0.59, width: 0.26, height: 0.20),
        photoThree: CGRect(x: 0.65, y: 0.59, width: 0.26, height: 0.20),
        replacementValue: CGRect(x: 0.09, y: 0.51, width: 0.82, height: 0.04),
        // Right under the photo row (which ends at 0.79) — right-aligned
        // to the same right edge (0.91) every other field lines up
        // against.
        perLine: CGRect(x: 0.46, y: 0.81, width: 0.45, height: 0.04),
        // Full width, in the space reclaimed by the logo move. Sized
        // generously (0.065 ≈ 51pt on an 11" page) for ~900 characters of
        // fine print at a 6–7pt shrink-to-fit — see `PDFExportService`'s
        // notice draw call — with margin to spare before the border
        // (~0.94).
        notice: CGRect(x: 0.09, y: 0.865, width: 0.82, height: 0.065)
    )
}
// CGRect already conforms to Codable via the CoreGraphics/Foundation overlay
// (through CGPoint/CGSize), so no extension is needed here.
