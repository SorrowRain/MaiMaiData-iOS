import XCTest
@testable import MaimaiData

final class RatingCalculatorTests: XCTestCase {
    func testSSSPlusCapsAtMaxAchievement() {
        // 14.8 @ 100.5% -> 148 * 1005000 * 22.4 / 1e7 = 333.2 -> 333
        XCTAssertEqual(RatingCalculator.singleSongRating(ds: 14.8, achievement: 100.5), 333)
        // Achievement above 100.5% is capped.
        XCTAssertEqual(RatingCalculator.singleSongRating(ds: 14.8, achievement: 101.0), 333)
    }

    func testTierBoundaries() {
        XCTAssertEqual(RatingCalculator.achievementToRating(levelTenths: 100, achievementTenThousandths: 1_004_999), 223)
        XCTAssertEqual(RatingCalculator.achievementToRating(levelTenths: 100, achievementTenThousandths: 1_000_000), 216)
        XCTAssertEqual(RatingCalculator.achievementToRating(levelTenths: 100, achievementTenThousandths: 970_000), 194)
        XCTAssertEqual(RatingCalculator.achievementToRating(levelTenths: 100, achievementTenThousandths: 969_999), 170)
        XCTAssertEqual(RatingCalculator.achievementToRating(levelTenths: 100, achievementTenThousandths: 50_000), 0)
    }

    func testRatingIsMonotonicInAchievement() {
        var previous = 0
        for achi in stride(from: 0, through: 1_010_000, by: 5_000) {
            let r = RatingCalculator.achievementToRating(levelTenths: 130, achievementTenThousandths: achi)
            XCTAssertGreaterThanOrEqual(r, previous, "rating dropped at \(achi)")
            previous = r
        }
    }

    func testReverseCalculateRejectsNonPositiveTarget() {
        XCTAssertTrue(RatingCalculator.reverseCalculate(targetTotalRating: 0).isEmpty)
        XCTAssertTrue(RatingCalculator.reverseCalculate(targetTotalRating: -5).isEmpty)
    }

    func testReverseCalculateRowsReachTarget() {
        let rows = RatingCalculator.reverseCalculate(targetTotalRating: 15000)
        XCTAssertFalse(rows.isEmpty)
        for row in rows {
            XCTAssertGreaterThanOrEqual(row.singleRating, 15000 / 50)
            XCTAssertEqual(row.totalRating, row.singleRating * 50)
        }
    }
}
