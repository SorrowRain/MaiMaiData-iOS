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
            ("260", "maimaidx_circle")
        ]
        return map.first { versionCode.hasPrefix($0.0) }?.1
    }

    static func jpVersionFallbackTitle(for versionCode: String) -> String {
        let trimmed = versionCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "暂无数据" }
        if trimmed.hasPrefix("265") {
            return "maimai でらっくす CiRCLE PLUS"
        }
        return "Ver. \(trimmed)"
    }

    static func cnVersionAsset(for fromName: String) -> String? {
        cnVersions.first { $0.name == fromName }?.asset
    }
}
