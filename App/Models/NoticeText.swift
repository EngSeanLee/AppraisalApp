import Foundation

/// The fixed insurance/liability disclaimer printed in small type at the
/// bottom of every appraisal. Not user-editable `Appraisal` data — same
/// treatment as the "PER" stamp line in `PDFExportService`: it's the same
/// wording on every page, supplied by Tony, so it lives as a constant
/// rather than a field.
///
/// Condensed from the original (~1,225 characters) to this (~585
/// characters) after five rounds of the bottom notice section not fitting
/// the printed page — see `PDFExportService.drawNotice` and
/// `TemplateLayout.notice`. Every substantive protection from the original
/// is kept (gradings/weights are estimates and uncertified unless graded
/// unset, treatment may be undetectable, replacement value is
/// insurance-only and not resale/wholesale/auction value, not an offer or
/// warranty, not for resale/loan/tax/legal/estate use, opinion-based,
/// liability disclaimer) — only the phrasing is tightened. Drafted by
/// Claude, approved by the app owner in the session that produced it.
/// This still hasn't had the direct once-over from Tony's insurance/legal
/// side that the original wording had, the way the original comment here
/// called for — worth an actual read from him when there's a chance,
/// same as before.
enum NoticeText {
    static let disclaimer = """
    NOTICE: Gradings, weights, and treatment status are estimates based on visual inspection and standard methods, not certified unless graded unset; some gemstone enhancements may not be detectable by standard testing.

    Estimated replacement value is for insurance purposes only, as of the date shown — not resale, wholesale, or auction value, a warranty, or an offer to buy or sell. Not for resale, loan, tax, legal, or estate use. Values are opinion-based and may vary by appraiser. Acceptance acknowledges these limits; Tony's Jewelry assumes no liability for reliance on this document.
    """
}
