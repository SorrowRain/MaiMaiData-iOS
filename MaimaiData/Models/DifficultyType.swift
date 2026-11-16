import SwiftUI

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
        case .basic: return AppTheme.Palette.diffBasic
        case .advanced: return AppTheme.Palette.diffAdvanced
        case .expert: return AppTheme.Palette.diffExpert
        case .master: return AppTheme.Palette.diffMaster
        case .remaster: return AppTheme.Palette.diffRemaster
        case .utage, .utagePlayer2: return AppTheme.Palette.diffUtage
        case .unknown: return .gray
        }
    }

    /// 难度色保留 Android 配色；浅色底上的文字使用高对比深色。
    var readableForeground: Color {
        switch self {
        case .basic: return AppTheme.Palette.diffBasicText
        case .advanced: return AppTheme.Palette.diffAdvancedText
        case .expert: return AppTheme.Palette.diffExpertText
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
        case .basic: return AppTheme.Palette.diffBasicDark
        case .advanced: return AppTheme.Palette.diffAdvancedDark
        case .expert: return AppTheme.Palette.diffExpertDark
        case .master: return AppTheme.Palette.diffMasterDark
        case .remaster: return AppTheme.Palette.diffRemasterDark
        default: return AppTheme.Palette.diffOtherDark
        }
    }
}
