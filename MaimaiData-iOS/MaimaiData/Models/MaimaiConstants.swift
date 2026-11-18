import SwiftUI

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

    /// Complete SEGA arcade version table matching Zetaraku `data.json` version strings.
    static let jpVersions: [(name: String, asset: String)] = [
        ("maimai", "maimai"),
        ("maimai PLUS", "maimai_plus"),
        ("GreeN", "maimai_green"),
        ("GreeN PLUS", "maimai_green_plus"),
        ("ORANGE", "maimai_orange"),
        ("ORANGE PLUS", "maimai_orange_plus"),
        ("PiNK", "maimai_pink"),
        ("PiNK PLUS", "maimai_pink_plus"),
        ("MURASAKi", "maimai_murasaki"),
        ("MURASAKi PLUS", "maimai_murasaki_plus"),
        ("MiLK", "maimai_milk"),
        ("MiLK PLUS", "maimai_milk_plus"),
        ("FiNALE", "maimai_finale"),
        ("maimaiでらっくす", "maimaidx"),
        ("maimaiでらっくす PLUS", "maimaidx_plus"),
        ("Splash", "maimaidx_splash"),
        ("Splash PLUS", "maimaidx_splash_plus"),
        ("UNiVERSE", "maimaidx_universe"),
        ("UNiVERSE PLUS", "maimaidx_universe_plus"),
        ("FESTiVAL", "maimaidx_festival"),
        ("FESTiVAL PLUS", "maimaidx_festival_plus"),
        ("BUDDiES", "maimaidx_buddies"),
        ("BUDDiES PLUS", "maimaidx_buddies_plus"),
        ("PRiSM", "maimaidx_prism"),
        ("PRiSM PLUS", "maimaidx_prism_plus"),
        ("CiRCLE", "maimaidx_circle"),
        ("CiRCLE PLUS", "maimaidx_circle_plus"),
        ("MAGiCAL", "maimaidx_magical")
    ]

    private static let classicEraChips: [String] = [
        "maimai", "GreeN", "ORANGE", "PiNK", "MURASAKi", "MiLK", "FiNALE"
    ]

    /// Filter chips mirror Android SearchLayout's grouped version chips for CN.
    static let searchVersions: [String] = classicEraChips + [
        "舞萌DX", "舞萌DX 2021", "舞萌DX 2022", "舞萌DX 2023",
        "舞萌DX 2024", "舞萌DX 2025", "舞萌DX 2026"
    ]

    static func checklistVersions(for region: ServerRegion) -> [(name: String, asset: String)] {
        switch region {
        case .cn:
            return cnVersions
        case .intl:
            return jpVersions.filter { $0.name != "MAGiCAL" }
        case .jp:
            return jpVersions
        }
    }

    static func searchVersionChips(for region: ServerRegion) -> [String] {
        switch region {
        case .cn:
            return searchVersions
        case .intl, .jp:
            let dxNames = checklistVersions(for: region).dropFirst(13).map(\.name)
            return classicEraChips + dxNames
        }
    }

    static func expandVersionFilter(_ selected: [String], region: ServerRegion = .cn) -> Set<String> {
        var result = Set<String>()
        switch region {
        case .cn:
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
        case .intl, .jp:
            let groupedClassic: Set<String> = ["GreeN", "ORANGE", "PiNK", "MURASAKi", "MiLK"]
            for item in selected {
                if item == "maimai" {
                    result.insert("maimai")
                    result.insert("maimai PLUS")
                } else if groupedClassic.contains(item) {
                    result.insert(item)
                    result.insert("\(item) PLUS")
                } else {
                    result.insert(item)
                }
            }
        }
        return result
    }

    static func genreColors(for genre: String) -> (bg: Color, stroke: Color) {
        switch genre {
        case "流行&动漫":
            return AppTheme.Palette.genrePop
        case "niconico & VOCALOID":
            return AppTheme.Palette.genreNico
        case "东方Project":
            return AppTheme.Palette.genreTouhou
        case "其他游戏":
            return AppTheme.Palette.genreGame
        case "舞萌":
            return AppTheme.Palette.genreMaimai
        case "宴会場":
            return AppTheme.Palette.genreUtage
        default:
            return AppTheme.Palette.genreOther
        }
    }

    /// Fill for the big genre card on the song detail page. Locked genre colors stay
    /// untouched; only 其他游戏 uses a lighter green so white text reads comfortably.
    static func genreCardFill(for genre: String) -> Color {
        genre == "其他游戏" ? AppTheme.Palette.genreGameCardFill : genreColors(for: genre).bg
    }

    static func genreTextColor(for genre: String) -> Color {
        let light: Color
        switch genre {
        case "流行&动漫": light = AppTheme.Palette.genrePopText
        case "niconico & VOCALOID": light = AppTheme.Palette.genreNicoText
        case "东方Project": light = AppTheme.Palette.genreTouhouText
        case "其他游戏": light = AppTheme.Palette.genreGameText
        case "舞萌": light = AppTheme.Palette.genreMaimaiText
        case "宴会場": light = AppTheme.Palette.genreUtageText
        default: light = AppTheme.Palette.genreOtherText
        }
        // Dark mode: same hue as the genre color, brightness >= 0.85.
        return .adaptive(light: light, dark: genreColors(for: genre).bg.brightened(toAtLeast: 1.0, maxSaturation: 0.5))
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
            ("260", "maimaidx_circle"), ("265", "maimaidx_circle_plus"),
            ("270", "maimaidx_magical")
        ]
        return map.first { versionCode.hasPrefix($0.0) }?.1
    }

    static func jpVersionFallbackTitle(for versionCode: String) -> String {
        let trimmed = versionCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "暂无数据" }
        if trimmed.hasPrefix("265") {
            return "maimai でらっくす CiRCLE PLUS"
        }
        if trimmed.hasPrefix("270") {
            return "maimai でらっくす MAGiCAL"
        }
        return "Ver. \(trimmed)"
    }

    static func cnVersionAsset(for fromName: String) -> String? {
        cnVersions.first { $0.name == fromName }?.asset
    }

    static func jpVersionAssetByName(_ fromName: String) -> String? {
        jpVersions.first { $0.name == fromName }?.asset
    }

    enum ServerRegion: String, Codable, CaseIterable, Identifiable {
        case cn
        case intl
        case jp

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .cn: return "国服（舞萌DX）"
            case .intl: return "国际服（International）"
            case .jp: return "日服（日本版）"
            }
        }

        var shortName: String {
            switch self {
            case .cn: return "国服"
            case .intl: return "国际服"
            case .jp: return "日服"
            }
        }

        /// Starting from `CiRCLE` in JP / International, `AP` and `AP+` grant `+1` single-song Rating.
        var usesAPBonus: Bool {
            switch self {
            case .cn: return false
            case .intl, .jp: return true
            }
        }
    }

    static func shortGenreDisplayName(for genre: String) -> String {
        genre == "niconico & VOCALOID" ? "VOCALOID" : genre
    }

    enum RankIconTheme: String {
        case prism
        case circle
    }

    static let validRankKeys: Set<String> = [
        "d", "c", "b", "bb", "bbb", "a", "aa", "aaa", "s", "sp", "ss", "ssp", "sss", "sssp"
    ]

    static func rankIconTheme(for region: ServerRegion) -> RankIconTheme {
        switch region {
        case .cn:
            return .prism
        case .intl, .jp:
            return .circle
        }
    }

    static func rankAssetName(for rate: String, region: ServerRegion) -> String {
        let lower = rate.lowercased()
        if lower == "ap" || lower == "app" {
            return "mmd_player_rtsong_\(lower)"
        }
        let safeRate = validRankKeys.contains(lower) ? lower : "d"
        return "mmd_rank_\(rankIconTheme(for: region).rawValue)_\(safeRate)"
    }

    /// Resolves the version logo asset and fallback label for the active game server.
    static func activeServerVersionDisplay(
        for info: SongData.BasicInfo,
        region: ServerRegion = .cn
    ) -> (asset: String?, fallback: String) {
        switch region {
        case .cn:
            let asset = cnVersionAsset(for: info.from)
            let fallback = info.from.isEmpty ? "暂无数据" : info.from
            return (asset, fallback)
        case .jp, .intl:
            let asset = jpVersionAssetByName(info.from) ?? jpVersionAsset(for: info.version)
            let fallback = !info.from.isEmpty ? info.from : jpVersionFallbackTitle(for: info.version)
            return (asset, fallback)
        }
    }
}
