import Foundation

struct AppUpdateInfo: Codable {
    let apkVersion: String?
    let dataVersion4: String?
    let dataUrl4: String?
    let dataVersion5: String?
    let dataUrl5: String?

    enum CodingKeys: String, CodingKey {
        case apkVersion = "apk_version"
        case dataVersion4 = "data_version_4"
        case dataUrl4 = "data_url_4"
        case dataVersion5 = "data_version_5"
        case dataUrl5 = "data_url_5"
    }

    var bestDataVersionAndURL: (version: String, url: String)? {
        if let v5 = dataVersion5, let u5 = dataUrl5, !u5.isEmpty {
            if let v4 = dataVersion4, v4 > v5, let u4 = dataUrl4, !u4.isEmpty {
                return (v4, u4)
            }
            return (v5, u5)
        }
        if let v4 = dataVersion4, let u4 = dataUrl4, !u4.isEmpty {
            return (v4, u4)
        }
        return nil
    }
}

struct ChartStatsResponse: Codable {
    let charts: [String: [ChartStatEntry]]
}

struct ChartStatEntry: Codable {
    let cnt: Double?
    let diff: String?
    let fitDiff: Double?
    let avg: Double?
    let avgDx: Double?
    let stdDev: Double?

    enum CodingKeys: String, CodingKey {
        case cnt, diff
        case fitDiff = "fit_diff"
        case avg
        case avgDx = "avg_dx"
        case stdDev = "std_dev"
    }
}

struct ProberRecordsResponse: Codable {
    let nickname: String?
    let username: String?
    let rating: Int?
    let records: [ProberRecord]?
    let status: String?
    let message: String?
}

struct ProberRecord: Codable, Identifiable, Hashable {
    var id: String { "\(songId)_\(levelIndex)_\(type)" }

    let achievements: Double
    let ds: Double
    let dxScore: Int
    let fc: String
    let fs: String
    let level: String
    let levelIndex: Int
    let levelLabel: String
    let ra: Int
    let rate: String
    let songId: Int
    let title: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case achievements, ds
        case dxScore
        case fc, fs, level
        case levelIndex = "level_index"
        case levelLabel = "level_label"
        case ra, rate
        case songId = "song_id"
        case title, type
    }

    var difficulty: DifficultyType {
        DifficultyType(rawValue: levelIndex) ?? .unknown
    }

    var computedRating: Int {
        RatingCalculator.singleSongRating(ds: ds, achievement: achievements)
    }

    var maxPossibleRating: Int {
        Int(ds * 22.512)
    }

    var rankAssetName: String {
        switch rate {
        case "d", "c", "b", "bb", "bbb", "a", "aa", "aaa", "s", "sp", "ss", "ssp", "sss", "sssp":
            return "mmd_player_rtsong_\(rate)"
        default:
            return "mmd_player_rtsong_d"
        }
    }

    var fcAssetName: String? {
        switch fc {
        case "fc", "fcp", "ap", "app":
            return "mmd_player_rtsong_\(fc)"
        default:
            return nil
        }
    }

    var fsAssetName: String? {
        switch fs {
        case "fs", "fsp", "fsd", "fsdp":
            return "mmd_player_rtsong_\(fs)"
        default:
            return nil
        }
    }

    var typeAssetName: String {
        type == MaimaiConstants.chartTypeDX ? "mmd_player_rtsong_icon_dx" : "mmd_player_rtsong_icon_standard"
    }

    var ratingBoardAssetName: String {
        switch levelIndex {
        case 0: return "mmd_rating_board_bsc"
        case 1: return "mmd_rating_board_adv"
        case 2: return "mmd_rating_board_exp"
        case 3: return "mmd_rating_board_mas"
        default: return "mmd_rating_board_rem"
        }
    }

    var ratingDiffAssetName: String {
        switch levelIndex {
        case 0: return "mmd_rating_diff_basic"
        case 1: return "mmd_rating_diff_advanced"
        case 2: return "mmd_rating_diff_expert"
        case 3: return "mmd_rating_diff_master"
        default: return "mmd_rating_diff_remaster"
        }
    }
}

struct SavedAccount: Codable, Identifiable, Equatable {
    var id: String { username }
    let username: String
    let password: String
}

struct ChecklistStats: Equatable {
    let sssCount: Int
    let fcCount: Int
    let apCount: Int
    let fsdCount: Int
    let totalCount: Int

    init(records: [ProberRecord], totalCount: Int) {
        self.sssCount = records.filter { $0.achievements >= 100 }.count
        self.fcCount = records.filter { !$0.fc.isEmpty }.count
        self.apCount = records.filter { $0.fc == "ap" || $0.fc == "app" }.count
        self.fsdCount = records.filter { $0.fs == "fsd" || $0.fs == "fsdp" }.count
        self.totalCount = totalCount
    }
}

enum SongSortOption: String, CaseIterable, Identifiable {
    case defaultDesc = "默认排序"
    case expertAsc = "EXPERT-升序"
    case expertDesc = "EXPERT-降序"
    case masterAsc = "MASTER-升序"
    case masterDesc = "MASTER-降序"
    case remasterAsc = "RE:MASTER-升序"
    case remasterDesc = "RE:MASTER-降序"

    var id: String { rawValue }

    var filterDifficulty: DifficultyType? {
        switch self {
        case .defaultDesc: return nil
        case .expertAsc, .expertDesc: return .expert
        case .masterAsc, .masterDesc: return .master
        case .remasterAsc, .remasterDesc: return .remaster
        }
    }
}

struct SongFilterCriteria: Equatable {
    var keyword: String = ""
    var selectedGenres: Set<String> = []
    var selectedVersions: Set<String> = []
    var selectedLevel: String = "ALL"
    var useExactDS: Bool = false
    var exactDS: Double = 1.0
    var onlyFavorites: Bool = false
    var sortOption: SongSortOption = .defaultDesc

    var isActive: Bool {
        !selectedGenres.isEmpty ||
        !selectedVersions.isEmpty ||
        selectedLevel != "ALL" ||
        useExactDS ||
        onlyFavorites ||
        sortOption != .defaultDesc
    }
}
