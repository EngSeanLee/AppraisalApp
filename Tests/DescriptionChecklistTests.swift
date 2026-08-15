import XCTest
@testable import JewelryAppraisal

final class DescriptionChecklistTests: XCTestCase {

    func test_emptyText_hasNoHints() {
        XCTAssertEqual(DescriptionChecklist.missingHints(for: ""), [])
        XCTAssertEqual(DescriptionChecklist.missingHints(for: "   "), [])
    }

    func test_completeDescription_hasNoHints() {
        let text = "Ladies' 14kt white gold ring set with a 3.05 carat marquise cut diamond, VS1, E in color."
        XCTAssertEqual(DescriptionChecklist.missingHints(for: text), [])
    }

    func test_missingMetal_isFlagged() {
        let text = "Ring set with a 3.05 carat marquise cut diamond, VS1, E in color, weighs 8.00 grams."
        let hints = DescriptionChecklist.missingHints(for: text)
        XCTAssertTrue(hints.contains { $0.contains("Metal") })
    }

    func test_missingWeight_isFlagged() {
        let text = "14kt white gold ring set with a marquise cut diamond, VS1, E in color."
        let hints = DescriptionChecklist.missingHints(for: text)
        XCTAssertTrue(hints.contains { $0.contains("weight") })
    }

    func test_stoneMentionedWithoutGrading_isFlagged() {
        let text = "14kt white gold ring, 8.00 grams, set with a diamond."
        let hints = DescriptionChecklist.missingHints(for: text)
        XCTAssertTrue(hints.contains { $0.contains("grading") })
    }

    func test_noStoneMentioned_doesNotAskForGrading() {
        // A plain band has no stone at all -- shouldn't be nagged about
        // grading it doesn't have.
        let text = "14kt yellow gold plain band, 4.00 grams."
        let hints = DescriptionChecklist.missingHints(for: text)
        XCTAssertFalse(hints.contains { $0.contains("grading") })
    }
}
