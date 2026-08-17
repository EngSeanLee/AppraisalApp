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

    // MARK: - Appraisal.isReadyToExport

    func test_isReadyToExport_falseUntilNameDescriptionAndAPhotoAreAllPresent() {
        var appraisal = Appraisal()
        XCTAssertFalse(appraisal.isReadyToExport)

        appraisal.customerName = "Jane Smith"
        XCTAssertFalse(appraisal.isReadyToExport)

        appraisal.descriptionText = "14kt white gold ring with a round diamond."
        XCTAssertFalse(appraisal.isReadyToExport, "still missing a photo")

        appraisal.photoFilenames[0] = "photo.jpg"
        XCTAssertTrue(appraisal.isReadyToExport)
    }

    func test_isReadyToExport_anyOfTheThreePhotoSlotsCounts() {
        var appraisal = Appraisal()
        appraisal.customerName = "Jane Smith"
        appraisal.descriptionText = "A ring."
        appraisal.photoFilenames = [nil, "photo.jpg", nil]

        XCTAssertTrue(appraisal.isReadyToExport)
    }

    // MARK: - Appraisal.isBlank

    func test_isBlank_trueForFreshAppraisal() {
        XCTAssertTrue(Appraisal().isBlank)
    }

    func test_isBlank_falseOnceAnyFieldIsSet() {
        var name = Appraisal(); name.customerName = "Jane Smith"
        XCTAssertFalse(name.isBlank)

        var address = Appraisal(); address.address = "123 Main St"
        XCTAssertFalse(address.isBlank)

        var description = Appraisal(); description.descriptionText = "A ring."
        XCTAssertFalse(description.isBlank)

        var value = Appraisal(); value.replacementValue = ReplacementValue(amount: 100)
        XCTAssertFalse(value.isBlank)

        var photo = Appraisal(); photo.photoFilenames[1] = "photo.jpg"
        XCTAssertFalse(photo.isBlank)
    }

    func test_isBlank_ignoresWhitespaceOnlyText() {
        // `.whitespaces` (matching `isReadyToExport`'s existing
        // convention, which `isBlank` deliberately follows) covers spaces
        // and tabs -- not newlines, that's `.whitespacesAndNewlines` --
        // so this only exercises what `.whitespaces` actually trims.
        var appraisal = Appraisal()
        appraisal.customerName = "   "
        appraisal.address = "\t"
        XCTAssertTrue(appraisal.isBlank)
    }
}
