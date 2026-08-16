import Foundation

/// The fixed insurance/liability disclaimer printed in small type at the
/// bottom of every appraisal. Not user-editable `Appraisal` data — same
/// treatment as the "PER" stamp line in `PDFExportService`: it's the same
/// wording on every page, supplied by Tony, so it lives as a constant
/// rather than a field. Do not edit this wording without checking with him
/// first — it's the language his insurance/legal side signed off on.
enum NoticeText {
    static let disclaimer = """
    NOTICE: Because mountings can obscure full and accurate grading of cut, color, and clarity, all gemstone gradings and weights on this appraisal are estimates only, based on visual inspection and standard industry methods, and are not certified gradings unless the item was independently graded unset. Estimated replacement values reflect current retail replacement cost for insurance purposes only and do not represent resale, wholesale, liquidation, or auction value. Many gemstones are commonly treated or enhanced by methods that may not be detectable through standard testing; no representation is made as to treatment status unless specifically noted.

    This appraisal reflects the item's condition and estimated value as of the date shown and is valid for insurance scheduling purposes only. It is not an offer to buy or sell, a warranty, or a guarantee of authenticity, quality, or value, and it may not be relied upon for resale, loan collateral, tax, legal, or estate purposes. Values are opinion-based and may vary between appraisers. By accepting this appraisal, the client acknowledges these limitations. Tony's Jewelry and its employees assume no liability for actions taken in reliance on this document.
    """
}
