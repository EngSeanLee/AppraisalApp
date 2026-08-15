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
    var photo: CGRect

    static let `default` = TemplateLayout(
        customerName: CGRect(x: 0.09, y: 0.27, width: 0.52, height: 0.035),
        date: CGRect(x: 0.66, y: 0.27, width: 0.25, height: 0.035),
        address: CGRect(x: 0.09, y: 0.32, width: 0.82, height: 0.035),
        itemDescription: CGRect(x: 0.09, y: 0.39, width: 0.82, height: 0.34),
        photo: CGRect(x: 0.09, y: 0.76, width: 0.36, height: 0.17)
    )
}
// CGRect already conforms to Codable via the CoreGraphics/Foundation overlay
// (through CGPoint/CGSize), so no extension is needed here.
