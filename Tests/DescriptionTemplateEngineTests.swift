import XCTest
@testable import JewelryAppraisal

final class DescriptionTemplateEngineTests: XCTestCase {

    /// Exercises the full clause set on one piece — qualifier, custom-made,
    /// metal, style, a certified/graded center stone, and a graded accent
    /// group — modeled on appraisal-description-spec.md's real examples
    /// rather than the plan's single synthetic worked example (the spec,
    /// derived from 12 of Tony's actual appraisals, superseded the plan as
    /// ground truth once it existed).
    func test_fullClauseSet_ringWithCenterAndAccentStones() {
        var piece = Piece(itemType: .ring)
        piece.qualifier = "Ladies'"
        piece.isCustomMade = true
        piece.metal = .filled(MetalInfo(
            karat: "14 karat",
            metalName: "white gold",
            totalWeight: Quantity(value: 8.00, unit: "gram", isApproximate: false)
        ))
        piece.itemStyle = .filled(ItemStyleInfo(typePhrase: "Euro shank ring", settingStyle: "halo"))
        piece.stones = [
            StoneEntry(
                role: .center,
                count: 1,
                cut: "marquise cut",
                stoneType: "diamond",
                carat: Quantity(value: 3.05, unit: "carat", isApproximate: false),
                color: "E",
                clarity: "VS1",
                certification: StoneCertification(issuer: "IGI", number: "764659900")
            ),
            StoneEntry(
                role: .accent,
                count: 10,
                cut: "round brilliant cut",
                stoneType: "diamonds",
                carat: Quantity(value: 0.53, unit: "carat", isApproximate: false),
                color: "H",
                clarity: "SI1"
            )
        ]

        let expected = "Ladies' custom made 14 karat white gold, 8.00 gram Euro shank ring with halo, set with a 3.05 carat marquise cut diamond, VS1, E in color in the center. This marquise diamond is certified by IGI #764659900. The halo also consists of 10 round brilliant cut diamonds. These diamonds are SI1, H in color with the weight of 0.53 carat."

        XCTAssertEqual(DescriptionTemplateEngine.assemble(piece), expected)
    }

    func test_skippedElements_areOmittedGracefully() {
        // A plain band: metal + item type only, no stones at all.
        var piece = Piece(itemType: .ring)
        piece.metal = .filled(MetalInfo(
            karat: "10 karat",
            metalName: "yellow gold",
            totalWeight: Quantity(value: 4.00, unit: "gram", isApproximate: false)
        ))
        piece.itemStyle = .filled(ItemStyleInfo(typePhrase: "plain band", settingStyle: nil))

        XCTAssertEqual(DescriptionTemplateEngine.assemble(piece), "10 karat yellow gold, 4.00 gram plain band.")
    }

    func test_emptyPiece_producesEmptyString() {
        let piece = Piece(itemType: .ring)
        XCTAssertEqual(DescriptionTemplateEngine.assemble(piece), "")
    }

    /// Clause #5: stone-less pieces (chains, Cuban-link bracelets) use the
    /// chain/length clause instead of any stone clause — modeled closely
    /// on the spec's own Miami Cuban links example.
    func test_stoneLessPiece_usesChainClause() {
        var piece = Piece(itemType: .bracelet)
        piece.metal = .filled(MetalInfo(
            karat: "14 karat",
            metalName: "yellow gold",
            totalWeight: Quantity(value: 32.0, unit: "gram", isApproximate: false)
        ))
        piece.chain = .filled(ChainInfo(
            styleName: "Miami Cuban links",
            length: Quantity(value: 7.5, unit: "inch", isApproximate: false)
        ))

        XCTAssertEqual(
            DescriptionTemplateEngine.assemble(piece),
            "Miami Cuban links bracelet weighs 32.00 gram 14 karat yellow gold 7.5 in length."
        )
    }

    /// A loose (unmounted) stone has no metal/setting wrapper and no "in
    /// the center" framing — the stone itself is the whole subject.
    func test_looseStone_hasNoMetalOrSettingWrapper() {
        var piece = Piece(itemType: .looseStone)
        piece.stones = [
            StoneEntry(
                role: .center,
                cut: "oval cut",
                stoneType: "diamond",
                carat: Quantity(value: 2.00, unit: "carat", isApproximate: false),
                color: "E",
                clarity: "SI2"
            )
        ]

        XCTAssertEqual(DescriptionTemplateEngine.assemble(piece), "A 2.00 carat oval cut diamond, SI2, E in color.")
    }

    /// Multi-item appraisals (spec clause #6) just contribute each piece's
    /// clauses one after another into the same description text.
    func test_multiplePieces_areConcatenated() {
        var ring = Piece(itemType: .ring)
        ring.metal = .filled(MetalInfo(karat: "10 karat", metalName: "yellow gold", totalWeight: Quantity(value: 4.00, unit: "gram", isApproximate: false)))
        ring.itemStyle = .filled(ItemStyleInfo(typePhrase: "plain band", settingStyle: nil))

        var bracelet = Piece(itemType: .bracelet)
        bracelet.metal = .filled(MetalInfo(karat: "14 karat", metalName: "yellow gold", totalWeight: Quantity(value: 32.0, unit: "gram", isApproximate: false)))
        bracelet.chain = .filled(ChainInfo(styleName: "Miami Cuban links", length: Quantity(value: 7.5, unit: "inch", isApproximate: false)))

        let expected = "10 karat yellow gold, 4.00 gram plain band. Miami Cuban links bracelet weighs 32.00 gram 14 karat yellow gold 7.5 in length."

        XCTAssertEqual(DescriptionTemplateEngine.assemble([ring, bracelet]), expected)
    }

    /// The lab-grown/natural flag never affects the generated text on its
    /// own — it's surfaced elsewhere (guided-step UI) as an explicit
    /// disclosure, never silently inferred from an "LG"-prefixed cert
    /// number. Whatever the user typed into the cert number is reproduced
    /// verbatim either way.
    func test_labGrownFlag_doesNotAlterGeneratedText() {
        func describe(origin: StoneOrigin) -> String {
            var piece = Piece(itemType: .ring)
            piece.stones = [
                StoneEntry(
                    role: .center,
                    cut: "round cut",
                    stoneType: "diamond",
                    carat: Quantity(value: 1.00, unit: "carat", isApproximate: false),
                    origin: origin,
                    certification: StoneCertification(issuer: "IGI", number: "LG651440496")
                )
            ]
            return DescriptionTemplateEngine.assemble(piece)
        }

        XCTAssertEqual(describe(origin: .natural), describe(origin: .labGrown))
        XCTAssertEqual(describe(origin: .labGrown), describe(origin: .unspecified))
    }
}
