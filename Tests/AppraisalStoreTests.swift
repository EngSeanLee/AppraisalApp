import XCTest
@testable import JewelryAppraisal

final class AppraisalStoreTests: XCTestCase {

    /// `AppraisalStore` writes to a real, fixed location under Application
    /// Support (not an injected/mockable path) — deliberately, since it's
    /// a tiny enum with no state to configure. These tests clean up after
    /// themselves via `AppraisalStore.delete` so they don't leave fixtures
    /// behind for a real run of the app to pick up.

    func test_save_thenLoadAll_roundTrips() {
        var appraisal = Appraisal()
        appraisal.customerName = "Round Trip Test"
        appraisal.descriptionText = "14kt gold ring."

        AppraisalStore.save(appraisal)
        defer { AppraisalStore.delete(appraisal) }

        let loaded = AppraisalStore.loadAll()
        XCTAssertTrue(loaded.contains { $0.id == appraisal.id && $0.customerName == "Round Trip Test" })
    }

    func test_save_overwritesRatherThanDuplicating() {
        var appraisal = Appraisal()
        appraisal.customerName = "Overwrite Test"

        AppraisalStore.save(appraisal)
        appraisal.customerName = "Overwrite Test (edited)"
        AppraisalStore.save(appraisal)
        defer { AppraisalStore.delete(appraisal) }

        let matches = AppraisalStore.loadAll().filter { $0.id == appraisal.id }
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.customerName, "Overwrite Test (edited)")
    }

    func test_save_skipsBlankAppraisal() {
        let appraisal = Appraisal() // untouched -- isBlank
        AppraisalStore.save(appraisal)

        XCTAssertFalse(AppraisalStore.loadAll().contains { $0.id == appraisal.id })
    }

    func test_delete_removesIt() {
        var appraisal = Appraisal()
        appraisal.customerName = "Delete Test"
        AppraisalStore.save(appraisal)

        AppraisalStore.delete(appraisal)

        XCTAssertFalse(AppraisalStore.loadAll().contains { $0.id == appraisal.id })
    }
}
