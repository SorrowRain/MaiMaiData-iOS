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

    func testFinaleToDxConversion() throws {
        // Missing break notes must throw
        XCTAssertThrowsError(
            try RatingCalculator.convertFinaleToDx(.init(tapPerfect: 100))
        )
        // All Perfect without breakScore returns 100.5000% ~ 101.0000%
        let rangeText = try RatingCalculator.convertFinaleToDx(
            .init(tapPerfect: 100, breakPerfect: 10)
        )
        XCTAssertEqual(rangeText, "100.5000% ~ 101.0000%")

        // All 2600 Critical Break Perfect returns exact 101.0000%
        let exactMax = try RatingCalculator.convertFinaleToDx(
            .init(tapPerfect: 100, breakPerfect: 10, breakScore: 26_000)
        )
        XCTAssertEqual(exactMax, "101.0000%")

        // Invalid breakScore (< 2500 per break) throws
        XCTAssertThrowsError(
            try RatingCalculator.convertFinaleToDx(
                .init(tapPerfect: 100, breakPerfect: 10, breakScore: 24_900)
            )
        )
    }

    func testVersionStringNumericComparison() {
        XCTAssertTrue(VersionString.isNewer("20261113", than: "2026113"))
        XCTAssertFalse(VersionString.isNewer("2026113", than: "20261113"))
        XCTAssertTrue(VersionString.isNewer("1.10.0", than: "1.9.9"))
        XCTAssertFalse(VersionString.isNewer("1.0.0", than: "1.0.0"))
    }

    func testBuildTierRowsIncludesSSSIntraTierJumpThresholdsAndB50Gains() {
        // 14.8 has SSS base 319 (100.0000%), +1 jumps at 100.1002% (320) and 100.4130% (321), SSS+ 333 (100.5000%)
        let rows = RatingCalculator.buildTierRows(
            ds: 14.8,
            currentAchievement: 98.3500,
            b50BaselineRating: 300
        )

        let sssRows = rows.filter { $0.rate == "sss" }
        XCTAssertEqual(sssRows.map(\.achiTenThousandths), [1_004_130, 1_001_002, 1_000_000])
        XCTAssertEqual(sssRows.map(\.singleRating), [321, 320, 319])

        // Current score 98.3500% highlights S+ (98.0000%), which has 0 remaining gain
        let current = rows.first { $0.isCurrentTier }
        XCTAssertEqual(current?.rate, "sp")
        XCTAssertEqual(current?.b50Gain, 0)

        // Tiers below S+ (97%, 94%) are marked passed with +0 gain
        let sRow = rows.first { $0.rate == "s" }
        XCTAssertEqual(sRow?.isPassed, true)
        XCTAssertEqual(sRow?.b50Gain, 0)

        // SS (99.0% -> 304) exceeds baseline 300 by +4; SSS+ (333) exceeds by +33
        XCTAssertEqual(rows.first { $0.rate == "ss" }?.b50Gain, 4)
        XCTAssertEqual(rows.first { $0.rate == "sssp" }?.b50Gain, 33)

        // Un-gainable song (baseline 340 > 333 max) yields +0 for all unreached tiers
        let zeroGainRows = RatingCalculator.buildTierRows(ds: 14.8, currentAchievement: nil, b50BaselineRating: 340)
        XCTAssertTrue(zeroGainRows.allSatisfy { $0.b50Gain == 0 })

        // Logged-out state (b50BaselineRating == nil) omits b50Gain across all rows
        let loggedOutRows = RatingCalculator.buildTierRows(ds: 14.8, currentAchievement: nil, b50BaselineRating: nil)
        XCTAssertTrue(loggedOutRows.allSatisfy { $0.b50Gain == nil })
    }
}
