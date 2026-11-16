import SwiftUI

// MARK: - Song Data Schema

struct SongData: Codable, Identifiable, Hashable {
    let basicInfo: BasicInfo
    let charts: [RawChart]
    let ds: [Double]
    let oldDs: [Double]?
    let id: String
    let level: [String]
    let title: String
    let titleKana: String?
    let type: String
    let alias: [String]?

    enum CodingKeys: String, CodingKey {
        case basicInfo = "basic_info"
        case charts
        case ds
        case oldDs = "old_ds"
        case id
        case level
        case title
        case titleKana = "title_kana"
        case type
        case alias
    }

    var numericId: Int { Int(id) ?? 0 }
    var baseJacketId: Int {
        let rem = numericId % 10000
        return rem > 0 ? rem : numericId
    }
    var isUtage: Bool { basicInfo.genre == MaimaiConstants.genreUtage }
    var isDX: Bool { type == MaimaiConstants.chartTypeDX }

    var resolvedCharts: [ResolvedChart] {
        charts.indices.map { idx in
            let raw = charts[idx]
            let isSD = type == MaimaiConstants.chartTypeSD
            let notes = raw.notes
            let tap = notes.indices.contains(0) ? notes[0] : 0
            let hold = notes.indices.contains(1) ? notes[1] : 0
            let slide = notes.indices.contains(2) ? notes[2] : 0
            let touch = isSD ? 0 : (notes.indices.contains(3) ? notes[3] : 0)
            let breakCount = isSD
                ? (notes.indices.contains(3) ? notes[3] : 0)
                : (notes.indices.contains(4) ? notes[4] : 0)
            let difficulty = DifficultyType.from(genre: basicInfo.genre, index: idx)
            return ResolvedChart(
                index: idx,
                difficulty: difficulty,
                ds: ds.indices.contains(idx) ? ds[idx] : 0,
                oldDs: (oldDs?.indices.contains(idx) == true) ? oldDs![idx] : nil,
                level: level.indices.contains(idx) ? level[idx] : "-",
                charter: raw.charter,
                tap: tap,
                hold: hold,
                slide: slide,
                touch: touch,
                breakCount: breakCount,
                totalNotes: notes.reduce(0, +)
            )
        }
    }

    /// Ordered domestic CDN cover URLs (LXNS COS CDN -> Diving-Fish 5-digit padded IDs).
    var coverCandidateURLs: [URL] {
        var urls: [URL] = []
        if let lxns = URL(string: "https://assets2.lxns.net/maimai/jacket/\(baseJacketId).png") {
            urls.append(lxns)
        }
        let paddedFull = String(format: "%05d", numericId)
        if let dfFull = URL(string: "https://www.diving-fish.com/covers/\(paddedFull).png") {
            urls.append(dfFull)
        }
        if baseJacketId != numericId {
            let paddedBase = String(format: "%05d", baseJacketId)
            if let dfBase = URL(string: "https://www.diving-fish.com/covers/\(paddedBase).png") {
                urls.append(dfBase)
            }
        }
        return urls
    }

    struct BasicInfo: Codable, Hashable {
        let artist: String
        let bpm: Int
        let from: String
        let genre: String
        let catcode: String?
        let isNew: Bool
        let title: String
        let imageUrl: String
        let version: String
        let kanji: String?
        let comment: String?
        let buddy: String?

        enum CodingKeys: String, CodingKey {
            case artist, bpm, from, genre, catcode
            case isNew = "is_new"
            case title
            case imageUrl = "image_url"
            case version, kanji, comment, buddy
        }
    }

    struct RawChart: Codable, Hashable {
        let charter: String
        let notes: [Int]
    }
}

struct ResolvedChart: Identifiable, Hashable {
    var id: Int { index }
    let index: Int
    let difficulty: DifficultyType
    let ds: Double
    let oldDs: Double?
    let level: String
    let charter: String
    let tap: Int
    let hold: Int
    let slide: Int
    let touch: Int
    let breakCount: Int
    let totalNotes: Int

    var totalWeightedScore: Int {
        (tap + touch) + hold * 2 + slide * 3 + breakCount * 5
    }
}

// MARK: - Difficulty & Genre Styling

enum DifficultyType: Int, Codable, CaseIterable, Hashable {
    case basic = 0
    case advanced = 1
    case expert = 2
    case master = 3
    case remaster = 4
    case utage = 5
    case utagePlayer2 = 6
    case unknown = -1

    static func from(genre: String, index: Int) -> DifficultyType {
        if genre == MaimaiConstants.genreUtage {
            switch index {
            case 0: return .utage
            case 1: return .utagePlayer2
            default: return .unknown
            }
        }
        return DifficultyType(rawValue: index) ?? .unknown
    }

    var shortName: String {
        switch self {
        case .basic: return "BAS"
        case .advanced: return "ADV"
        case .expert: return "EXP"
        case .master: return "MAS"
        case .remaster: return "Re:MAS"
        case .utage: return "宴会場"
        case .utagePlayer2: return "2P"
        case .unknown: return "?"
        }
    }

    var color: Color {
        switch self {
        case .basic: return Color(hex: 0x6FD43D)
        case .advanced: return Color(hex: 0xF8B709)
        case .expert: return Color(hex: 0xFF818D)
        case .master: return Color(hex: 0x9F51DC)
        case .remaster: return Color(hex: 0xCB5EEA)
        case .utage, .utagePlayer2: return Color(hex: 0xB12876)
        case .unknown: return .gray
        }
    }

    /// 难度色保留 Android 配色；浅色底上的文字使用高对比深色。
    var readableForeground: Color {
        switch self {
        case .basic: return Color(hex: 0x183C12)
        case .advanced: return Color(hex: 0x4B3700)
        case .expert: return Color(hex: 0x681B28)
        default: return .white
        }
    }

    var boardMainColor: Color {
        switch self {
        case .basic: return Color(hex: 0x6FE163)
        case .advanced: return Color(hex: 0xF8DF3B)
        case .expert: return Color(hex: 0xFF818D)
        case .master: return Color(hex: 0xC27FF4)
        case .remaster: return Color(hex: 0xE5DDEA)
        default: return Color(hex: 0xB12876)
        }
    }

    var boardDarkColor: Color {
        switch self {
        case .basic: return Color(hex: 0x025235)
        case .advanced: return Color(hex: 0xC7450C)
        case .expert: return Color(hex: 0xC02138)
        case .master: return Color(hex: 0x671B8D)
        case .remaster: return Color(hex: 0x8C2DD5)
        default: return Color(hex: 0x053264)
        }
    }
}

enum MaimaiConstants {
    static let genreUtage = "宴会場"
    static let chartTypeDX = "DX"
    static let chartTypeSD = "SD"

    static let allGenres: [String] = [
        "流行&动漫",
        "niconico & VOCALOID",
        "东方Project",
        "其他游戏",
        "舞萌",
        "音击&中二节奏",
        "宴会場"
    ]

    static let allLevels: [String] = [
        "ALL", "1", "2", "3", "4", "5", "6", "7", "7+",
        "8", "8+", "9", "9+", "10", "10+", "11", "11+",
        "12", "12+", "13", "13+", "14", "14+", "15"
    ]

    static let cnVersions: [(name: String, asset: String)] = [
        ("maimai", "maimai"),
        ("maimai PLUS", "maimai_plus"),
        ("maimai GreeN", "maimai_green"),
        ("maimai GreeN PLUS", "maimai_green_plus"),
        ("maimai ORANGE", "maimai_orange"),
        ("maimai ORANGE PLUS", "maimai_orange_plus"),
        ("maimai PiNK", "maimai_pink"),
        ("maimai PiNK PLUS", "maimai_pink_plus"),
        ("maimai MURASAKi", "maimai_murasaki"),
        ("maimai MURASAKi PLUS", "maimai_murasaki_plus"),
        ("maimai MiLK", "maimai_milk"),
        ("maimai MiLK PLUS", "maimai_milk_plus"),
        ("maimai FiNALE", "maimai_finale"),
        ("舞萌DX", "maimaidx_cn"),
        ("舞萌DX 2021", "maimaidx_2021"),
        ("舞萌DX 2022", "maimaidx_2022"),
        ("舞萌DX 2023", "maimaidx_2023"),
        ("舞萌DX 2024", "maimaidx_2024"),
        ("舞萌DX 2025", "maimaidx_2025"),
        ("舞萌DX 2026", "maimaidx_2026")
    ]

    /// Filter chips mirror Android SearchLayout's grouped version chips.
    static let searchVersions: [String] = [
        "maimai", "GreeN", "ORANGE", "PiNK", "MURASAKi", "MiLK", "FiNALE",
        "舞萌DX", "舞萌DX 2021", "舞萌DX 2022", "舞萌DX 2023",
        "舞萌DX 2024", "舞萌DX 2025", "舞萌DX 2026"
    ]

    static func expandVersionFilter(_ selected: [String]) -> Set<String> {
        var result = Set<String>()
        for item in selected {
            if item == "maimai" {
                result.insert("maimai")
                result.insert("maimai PLUS")
            } else if item == "FiNALE" {
                result.insert("maimai FiNALE")
            } else if !item.hasPrefix("舞萌") && !item.contains("FiNALE") {
                result.insert("maimai \(item) PLUS")
                result.insert("maimai \(item)")
            } else {
                result.insert(item)
            }
        }
        return result
    }

    static func genreColors(for genre: String) -> (bg: Color, stroke: Color) {
        switch genre {
        case "流行&动漫":
            return (Color(hex: 0xFF9C24), Color(hex: 0xFFD21F))
        case "niconico & VOCALOID":
            return (Color(hex: 0x12B4FF), Color(hex: 0x7ED6FF))
        case "东方Project":
            return (Color(hex: 0xCA6FEB), Color(hex: 0xE8A7FF))
        case "其他游戏":
            return (Color(hex: 0x287516), Color(hex: 0xBAFBA3))
        case "舞萌":
            return (Color(hex: 0xFF4646), Color(hex: 0xFFA7A7))
        case "宴会場":
            return (Color(hex: 0xDC39B8), Color(hex: 0xB12876))
        default:
            return (Color(hex: 0x319DF8), Color(hex: 0x99D1FF))
        }
    }

    static func genreTextColor(for genre: String) -> Color {
        switch genre {
        case "流行&动漫": return Color(hex: 0x8A4800)
        case "niconico & VOCALOID": return Color(hex: 0x055C84)
        case "东方Project": return Color(hex: 0x762D8C)
        case "其他游戏": return Color(hex: 0x1C560C)
        case "舞萌": return Color(hex: 0x9A1B1B)
        case "宴会場": return Color(hex: 0x8F1863)
        default: return Color(hex: 0x125BB8)
        }
    }

    static func jpVersionAsset(for versionCode: String) -> String? {
        let map: [(String, String)] = [
            ("100", "maimai"), ("110", "maimai_plus"),
            ("120", "maimai_green"), ("130", "maimai_green_plus"),
            ("140", "maimai_orange"), ("150", "maimai_orange_plus"),
            ("160", "maimai_pink"), ("170", "maimai_pink_plus"),
            ("180", "maimai_murasaki"), ("185", "maimai_murasaki_plus"),
            ("190", "maimai_milk"), ("195", "maimai_milk_plus"),
            ("199", "maimai_finale"),
            ("200", "maimaidx"), ("205", "maimaidx_plus"),
            ("210", "maimaidx_splash"), ("215", "maimaidx_splash_plus"),
            ("220", "maimaidx_universe"), ("225", "maimaidx_universe_plus"),
            ("230", "maimaidx_festival"), ("235", "maimaidx_festival_plus"),
            ("240", "maimaidx_buddies"), ("245", "maimaidx_buddies_plus"),
            ("250", "maimaidx_prism"), ("255", "maimaidx_prism_plus"),
            ("260", "maimaidx_circle")
        ]
        return map.first { versionCode.hasPrefix($0.0) }?.1
    }

    static func cnVersionAsset(for fromName: String) -> String? {
        cnVersions.first { $0.name == fromName }?.asset
    }
}

// MARK: - Rating & Max Notes Helpers

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

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
