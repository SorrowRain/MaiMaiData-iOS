import SwiftUI

enum CheckDisplayMode: Int, CaseIterable {
    case rank = 0
    case fc = 1
    case fs = 2

    var label: String {
        switch self {
        case .rank: return "达成率"
        case .fc: return "FC / AP"
        case .fs: return "FS / FDX"
        }
    }

    func next() -> CheckDisplayMode {
        CheckDisplayMode(rawValue: (rawValue + 1) % Self.allCases.count) ?? .rank
    }
}

private let checklistGridColumns = [GridItem(.adaptive(minimum: 72), spacing: AppTheme.itemSpacing)]

struct ChecklistStatsHeader: View {
    let stats: ChecklistStats
    @Binding var displayMode: CheckDisplayMode

    var body: some View {
        AppSectionCard(
            title: "完成度统计",
            subtitle: "当前角标：\(displayMode.label)"
        ) {
            AppInlineButton(title: "切换标识", icon: "arrow.triangle.2.circlepath") {
                displayMode = displayMode.next()
            }
        } content: {
            LazyVGrid(columns: checklistGridColumns, spacing: AppTheme.itemSpacing) {
                AppStatTile(title: "SSS", value: "\(stats.sssCount)/\(stats.totalCount)", tint: AppTheme.Palette.statSSS)
                AppStatTile(title: "FC", value: "\(stats.fcCount)/\(stats.totalCount)", tint: AppTheme.Palette.statFC)
                AppStatTile(title: "AP", value: "\(stats.apCount)/\(stats.totalCount)", tint: AppTheme.Palette.statAP)
                AppStatTile(title: "FSD", value: "\(stats.fsdCount)/\(stats.totalCount)", tint: AppTheme.Palette.statFSD)
            }
        }
    }
}

struct ChecklistSongGrid<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(columns: checklistGridColumns, spacing: AppTheme.itemSpacing) {
            content()
        }
    }
}

struct ChecklistSongTile: View {
    let song: SongData
    let record: ProberRecord?
    let borderColor: Color
    let displayMode: CheckDisplayMode
    var showTypeBadge: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.tile, style: .continuous)
        ZStack(alignment: .topTrailing) {
            CoverImageView(song: song)
                .frame(width: 72, height: 72)
                .clipped()
                .overlay {
                    if record != nil {
                        Color.black.opacity(0.46)
                    }
                }
                .overlay {
                    if let record {
                        overlayMark(for: record)
                    }
                }
                .clipShape(shape)
                .overlay(
                    shape.strokeBorder(borderColor, lineWidth: 2.5)
                )

            if showTypeBadge {
                ChartTypeBadge(isDX: song.isDX, compact: true)
                    .padding(3)
            }
        }
    }

    @ViewBuilder
    private func overlayMark(for record: ProberRecord) -> some View {
        switch displayMode {
        case .rank:
            Image(record.rankAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 24)
                .accessibilityLabel(record.rankAccessibilityLabel)
        case .fc:
            if let fc = record.fcAssetName {
                Image(fc)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .accessibilityLabel(record.fcAccessibilityLabel)
            }
        case .fs:
            if let fs = record.fsAssetName {
                Image(fs)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .accessibilityLabel(record.fsAccessibilityLabel)
            }
        }
    }
}
