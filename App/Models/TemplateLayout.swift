import CoreGraphics
import Foundation

/// Where each anchored region sits on the background template image, as
/// fractions (0–1) of the image's width/height — so layout survives the
/// image being scaled to fit different screen/print sizes.
///
/// The numbers below are placeholder guesses, NOT the real letterhead
/// layout — see plan's Open Items ("Finalize the template image ... field
/// positions"). Once the real template image and its field coordinates
/// exist, replace `TemplateLayout.default` (or load a JSON override) —
/// nothing else in the view layer needs to change, since every view reads
/// positions from here rather than hardcoding them.
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
        customerName: CGRect(x: 0.08, y: 0.14, width: 0.55, height: 0.05),
        date: CGRect(x: 0.70, y: 0.14, width: 0.22, height: 0.05),
        address: CGRect(x: 0.08, y: 0.21, width: 0.55, height: 0.05),
        itemDescription: CGRect(x: 0.08, y: 0.32, width: 0.84, height: 0.30),
        photo: CGRect(x: 0.08, y: 0.65, width: 0.35, height: 0.28)
    )
}
// CGRect already conforms to Codable via the CoreGraphics/Foundation overlay
// (through CGPoint/CGSize), so no extension is needed here.
