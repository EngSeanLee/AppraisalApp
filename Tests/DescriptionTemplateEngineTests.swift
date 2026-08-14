import XCTest
@testable import JewelryAppraisal

final class DescriptionTemplateEngineTests: XCTestCase {

    /// Regression test tied directly to the plan's worked example, so a
    /// change to the template engine that drifts from the spec's exact
    /// wording gets caught immediately.
    func test_ringExample_matchesPlanReferenceSentence() {
        var elements = DescriptionElements(itemType: .ring)
        elements.metal = .filled(MetalInfo(
            karat: "14 karat",
            metalName: "white gold",
            totalWeight: Quantity(value: 8.00, unit: "gram", isApproximate: false)
        ))
        elements.itemStyle = .filled(ItemStyleInfo(typePhrase: "Euro shank ring", settingStyle: "halo"))
        elements.centerStone = .filled(CenterStoneInfo(
            carat: Quantity(value: 3.05, unit: "carat", isApproximate: false),
            cut: "marquise cut",
            stoneType: "diamond"
        ))
        elements.certification = .filled(CertificationInfo(issuer: "IGI", number: "764659900", color: "E", clarity: "VS1"))
        elements.sideStones = .filled(SideStonesInfo(
            stoneType: "diamonds",
            totalWeight: Quantity(value: 0.53, unit: "carat", isApproximate: false)
        ))

        let expected = "14 karat white gold, 8.00 gram Euro shank ring with halo, set with a 3.05 carat marquise cut diamond in the center. The marquise diamond is certified by IGI #764659900, E, VS1. The halo consists of diamonds with a total weight of 0.53 carat."

        XCTAssertEqual(DescriptionTemplateEngine.assemble(elements), expected)
    }

    func test_skippedElements_areOmittedGracefully() {
        // A plain band: metal + item type only, everything else N/A.
        var elements = DescriptionElements(itemType: .ring)
        elements.metal = .filled(MetalInfo(
            karat: "10 karat",
            metalName: "yellow gold",
            totalWeight: Quantity(value: 4.00, unit: "gram", isApproximate: false)
        ))
        elements.itemStyle = .filled(ItemStyleInfo(typePhrase: "plain band", settingStyle: nil))
        elements.centerStone = .skipped
        elements.certification = .skipped
        elements.sideStones = .skipped

        let result = DescriptionTemplateEngine.assemble(elements)

        XCTAssertEqual(result, "10 karat yellow gold, 4.00 gram plain band.")
    }

    func test_emptyElements_producesEmptyString() {
        let elements = DescriptionElements(itemType: .ring)
        XCTAssertEqual(DescriptionTemplateEngine.assemble(elements), "")
    }
}
