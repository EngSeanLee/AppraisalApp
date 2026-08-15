import XCTest
@testable import JewelryAppraisal

final class AppraisalTests: XCTestCase {

    // MARK: - ReplacementValue.displayString

    func test_replacementValue_dotLeaderFormatWithCommaThousands() {
        let value = ReplacementValue(amount: 12899, marketNote: "")
        XCTAssertEqual(value.displayString, "Replacement Value…….$12,899.00")
    }

    func test_replacementValue_includesOptionalMarketNote() {
        let value = ReplacementValue(amount: 49250, marketNote: "1.08 carats ($4375/oz)")
        XCTAssertEqual(value.displayString, "Replacement Value…….$49,250.00 (1.08 carats ($4375/oz))")
    }

    func test_replacementValue_emptyWhenNoAmount() {
        XCTAssertEqual(ReplacementValue().displayString, "")
        XCTAssertTrue(ReplacementValue().isEmpty)
    }

    // MARK: - Appraisal.replacementValueLines

    func test_combinedValuation_producesOneLine() {
        var appraisal = Appraisal()
        appraisal.valuationMode = .combined
        appraisal.combinedReplacementValue = ReplacementValue(amount: 7850, marketNote: "")

        XCTAssertEqual(appraisal.replacementValueLines, ["Replacement Value…….$7,850.00"])
    }

    /// Itemized mode (spec clause #6): each priced piece gets its own
    /// labeled line, e.g. "Replacement Value engagement ring……$6,950.00" /
    /// "Replacement Value on the band……$2,500.00" — matching Phoenix
    /// Carter's real appraisal in the spec.
    func test_itemizedValuation_producesOneLinePerPricedPiece() {
        var appraisal = Appraisal()
        appraisal.valuationMode = .itemized

        var engagementRing = Piece(itemType: .ring)
        engagementRing.pieceLabel = "engagement ring"
        engagementRing.replacementValue = ReplacementValue(amount: 6950, marketNote: "")

        var band = Piece(itemType: .ring)
        band.pieceLabel = "on the band"
        band.replacementValue = ReplacementValue(amount: 2500, marketNote: "")

        appraisal.pieces = [engagementRing, band]

        XCTAssertEqual(appraisal.replacementValueLines, [
            "Replacement Value engagement ring…….$6,950.00",
            "Replacement Value on the band…….$2,500.00"
        ])
    }

    func test_itemizedValuation_skipsPiecesWithoutAValueYet() {
        var appraisal = Appraisal()
        appraisal.valuationMode = .itemized

        var priced = Piece(itemType: .ring)
        priced.pieceLabel = "ring"
        priced.replacementValue = ReplacementValue(amount: 1000, marketNote: "")

        let unpriced = Piece(itemType: .ring)

        appraisal.pieces = [priced, unpriced]

        XCTAssertEqual(appraisal.replacementValueLines, ["Replacement Value ring…….$1,000.00"])
    }
}
