import XCTest
@testable import JewelryAppraisal

final class QuantityNormalizerTests: XCTestCase {

    func test_exactDigitInput_isNotMarkedApproximate() {
        let result = QuantityNormalizer.extractQuantity(from: "8 grams", unit: "gram")
        XCTAssertEqual(result.quantity?.value, 8)
        XCTAssertEqual(result.quantity?.isApproximate, false)
    }

    func test_exactDecimalInput() {
        let result = QuantityNormalizer.extractQuantity(from: "3.05 carat", unit: "carat")
        XCTAssertEqual(result.quantity?.value, 3.05)
        XCTAssertEqual(result.quantity?.isApproximate, false)
    }

    func test_spokenDecimal_threePointOhFive() {
        let result = QuantityNormalizer.extractQuantity(from: "three point oh five carat", unit: "carat")
        XCTAssertEqual(result.quantity?.value, 3.05)
        XCTAssertEqual(result.quantity?.isApproximate, false)
    }

    func test_vaguePhrase_aboutHalfACarat() {
        let result = QuantityNormalizer.extractQuantity(from: "about half a carat", unit: "carat")
        XCTAssertEqual(result.quantity?.value, 0.5)
        XCTAssertEqual(result.quantity?.isApproximate, true)
        XCTAssertEqual(result.quantity?.displayString, "approximately 0.50 carat")
    }

    func test_vaguePhrase_aCoupleGrams() {
        let result = QuantityNormalizer.extractQuantity(from: "a couple grams", unit: "gram")
        XCTAssertEqual(result.quantity?.value, 2)
        XCTAssertEqual(result.quantity?.isApproximate, true)
    }

    func test_hedgeWordWithExactNumber_isStillApproximate() {
        let result = QuantityNormalizer.extractQuantity(from: "approximately 2 grams", unit: "gram")
        XCTAssertEqual(result.quantity?.value, 2)
        XCTAssertEqual(result.quantity?.isApproximate, true)
    }

    func test_noMatch_returnsNilQuantity() {
        let result = QuantityNormalizer.extractQuantity(from: "a lovely ring", unit: "carat")
        XCTAssertNil(result.quantity)
    }
}
