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
    /// still comfortably clear of the border. Drawn by
    /// `PDFExportService.drawNotice`, a shrink-to-fit down to a 6pt floor
    /// like every other field, but with tighter paragraph spacing and a
    /// hard clip to this rect so it can never bleed past it.
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
        // logo bottom ~17.6% down).
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
        // depends on width. Moved up slightly further (0.59 → 0.57) from
        // the first UAT round to open up real breathing room above
        // `perLine`, which was reading as crowded against the photo row.
        photoOne: CGRect(x: 0.09, y: 0.57, width: 0.26, height: 0.20),
        photoTwo: CGRect(x: 0.37, y: 0.57, width: 0.26, height: 0.20),
        photoThree: CGRect(x: 0.65, y: 0.57, width: 0.26, height: 0.20),
        replacementValue: CGRect(x: 0.09, y: 0.51, width: 0.82, height: 0.04),
        // Right-aligned to the same right edge (0.91) every other field
        // lines up against. Shrunk (0.04 → 0.03 height, 13pt → 11pt font
        // in `PDFExportService.drawPerLine`) and given real clearance from
        // the photo row above (0.77 → 0.80, a 0.03 gap vs. the original
        // 0.02) — both per UAT feedback that it was crowding the photos.
        perLine: CGRect(x: 0.46, y: 0.80, width: 0.45, height: 0.03),
        // Full width, in the space reclaimed by the logo move. Vertical
        // sizing (0.83–0.93, ~79pt) is unchanged from round 3: starts at
        // perLine's bottom edge, ends ~10pt above the letterhead border's
        // measured straight-edge inner line (y≈0.9427). But the straight
        // edge isn't the real constraint at this box's own bottom-left and
        // bottom-right corners — the letterhead's decorative corner
        // medallions curve inward there, past the 0.09/0.91 margin every
        // other field uses safely (measured off the actual artwork: the
        // curve starts around y≈0.897 and reaches x≈0.127 from the left,
        // mirrored on the right, by this box's bottom edge — round 3's
        // taller box put its own bottom corners squarely in that zone).
        // No rectangle avoids that on its own; `PDFExportService
        // .drawNotice` lays the text out with `NSTextContainer
        // .exclusionPaths` so lines in the bottom third of this box
        // actually narrow around both medallions instead of running
        // through them, with the round-3 hard clip still underneath as a
        // backstop.
        notice: CGRect(x: 0.09, y: 0.83, width: 0.82, height: 0.10)
    )
}
// CGRect already conforms to Codable via the CoreGraphics/Foundation overlay
// (through CGPoint/CGSize), so no extension is needed here.
