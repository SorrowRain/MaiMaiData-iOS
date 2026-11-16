import SwiftUI

enum RatingCalculator {
    /// Exact match of ConvertUtils.achievementToRating(levelInt, achiInt)
    /// - Parameters:
    ///   - levelTenths: e.g. 14.8 -> 148
    ///   - achievementTenThousandths: e.g. 100.5000 -> 1005000
    static func achievementToRating(levelTenths: Int, achievementTenThousandths achi: Int) -> Int {
        let multiplier: Double
        switch achi {
        case 1_005_000...: multiplier = 22.4
        case 1_004_999: multiplier = 22.2
        case 1_000_000...1_004_998: multiplier = 21.6
        case 999_999: multiplier = 21.4
        case 995_000...999_998: multiplier = 21.1
        case 990_000...994_999: multiplier = 20.8
        case 989_999: multiplier = 20.6
        case 980_000...989_998: multiplier = 20.3
        case 970_000...979_999: multiplier = 20.0
        case 969_999: multiplier = 17.6
        case 940_000...969_998: multiplier = 16.8
        case 900_000...939_999: multiplier = 15.2
        case 800_000...899_999: multiplier = 13.6
        case 799_999: multiplier = 12.8
        case 750_000...799_998: multiplier = 12.0
        case 700_000...749_999: multiplier = 11.2
        case 600_000...699_999: multiplier = 9.6
        case 500_000...599_999: multiplier = 8.0
        case 400_000...499_999: multiplier = 6.4
        case 300_000...399_999: multiplier = 4.8
        case 200_000...299_999: multiplier = 3.2
        case 100_000...199_999: multiplier = 1.6
        default: multiplier = 0.0
        }
        let capped = min(achi, 1_005_000)
        return Int(Double(capped) * Double(levelTenths) * multiplier / 10_000_000.0)
    }

    static func singleSongRating(ds: Double, achievement: Double) -> Int {
        achievementToRating(
            levelTenths: Int((ds * 10).rounded()),
            achievementTenThousandths: Int((achievement * 10000).rounded())
        )
    }

    struct TargetRow: Identifiable {
        let id = UUID()
        let level: Double
        let achievementText: String
        let singleRating: Int
        let totalRating: Int
    }

    static func reverseCalculate(targetTotalRating: Int) -> [TargetRow] {
        guard targetTotalRating > 0 else { return [] }
        let perSong = targetTotalRating / 50
        var minLv = 0
        for i in 10...150 {
            if perSong < achievementToRating(levelTenths: i, achievementTenThousandths: 1_005_000) {
                minLv = i
                break
            }
        }
        var bestByAchi: [Int: Int] = [:]
        for lv in stride(from: 150, through: minLv, by: -1) {
            let achi = reachableAchievement(levelTenths: lv, targetSingleRating: perSong)
            if [800_000, 900_000, 940_000].contains(achi) || (970_000...1_010_000).contains(achi) {
                bestByAchi[achi] = lv
            }
        }
        return bestByAchi.keys.sorted(by: <).compactMap { achi in
            guard let lv = bestByAchi[achi] else { return nil }
            let r = achievementToRating(levelTenths: lv, achievementTenThousandths: achi)
            return TargetRow(
                level: Double(lv) / 10.0,
                achievementText: String(format: "%.4f%%", Double(achi) / 10000.0),
                singleRating: r,
                totalRating: r * 50
            )
        }
    }

    private static func reachableAchievement(levelTenths: Int, targetSingleRating: Int) -> Int {
        if achievementToRating(levelTenths: levelTenths, achievementTenThousandths: 1_005_000) < targetSingleRating {
            return 1_010_001
        }
        var maxAchi = 1_010_000
        var minAchi = 0
        for _ in 0...20 where maxAchi - minAchi >= 2 {
            let mid = (maxAchi + minAchi) / 2
            if achievementToRating(levelTenths: levelTenths, achievementTenThousandths: mid) < targetSingleRating {
                minAchi = mid
            } else {
                maxAchi = mid
            }
        }
        return maxAchi
    }
}

struct MaxNotesStats {
    let total: Int
    let tap: Int
    let hold: Int
    let slide: Int
    let touch: Int
    let breakCount: Int

    static let fallback = MaxNotesStats(total: 1400, tap: 1000, hold: 300, slide: 400, touch: 300, breakCount: 150)

    static func compute(from songs: [SongData]) -> MaxNotesStats {
        var maxTotal = 1, maxTap = 1, maxHold = 1, maxSlide = 1, maxTouch = 1, maxBreak = 1
        for song in songs {
            for chart in song.resolvedCharts {
                maxTotal = max(maxTotal, chart.totalNotes)
                maxTap = max(maxTap, chart.tap)
                maxHold = max(maxHold, chart.hold)
                maxSlide = max(maxSlide, chart.slide)
                maxTouch = max(maxTouch, chart.touch)
                maxBreak = max(maxBreak, chart.breakCount)
            }
        }
        return MaxNotesStats(total: maxTotal, tap: maxTap, hold: maxHold, slide: maxSlide, touch: maxTouch, breakCount: maxBreak)
    }
}
