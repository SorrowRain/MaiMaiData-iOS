import SwiftUI

/// Shared 2-column / 3-column achievement-to-Rating reference table.
/// Used by both `SongDetailView` (3 columns when logged in, 2 columns when logged out)
/// and `RatingCalculatorView` (2 columns).
struct RatingTierTable: View {
    @Environment(\.colorScheme) private var colorScheme
    let rows: [RatingCalculator.TierRow]
    var showB50Column: Bool = false

    private var singleRaColumnWidth: CGFloat {
        showB50Column ? 76 : 88
    }

    var body: some View {
        AppInsetGroup {
            VStack(spacing: 0) {
                HStack(spacing: AppTheme.Space.s) {
                    Text("分段档位")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("单曲 Ra")
                        .frame(width: singleRaColumnWidth, alignment: .center)
                    if showB50Column {
                        Text("B50 可加")
                            .frame(width: 76, alignment: .center)
                    }
                }
                .font(AppTheme.Typography.caption2Bold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppTheme.Space.m)
                .padding(.vertical, AppTheme.Space.s)

                ForEach(rows) { row in
                    Divider()
                    tierRowView(row)
                }
            }
        }
    }

    private func tierRowView(_ row: RatingCalculator.TierRow) -> some View {
        HStack(spacing: AppTheme.Space.s) {
            HStack(spacing: AppTheme.Space.s) {
                Image(row.rankAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 18, alignment: .leading)

                Text(row.achievementText)
                    .font(row.isCurrentTier ? AppTheme.Typography.captionMeta : AppTheme.Typography.captionMono)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(row.singleRating)")
                .font(AppTheme.Typography.captionMeta)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .frame(width: singleRaColumnWidth, alignment: .center)

            if showB50Column {
                let gain = row.b50Gain ?? 0
                Group {
                    if gain > 0 {
                        Text("+\(gain)")
                            .font(AppTheme.Typography.captionMetaBold)
                            .foregroundStyle(AppTheme.accentText)
                            .contentTransition(.numericText())
                    } else {
                        Text("+0")
                            .font(AppTheme.Typography.captionMono)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(width: 76, alignment: .center)
            }
        }
        .padding(.horizontal, AppTheme.Space.m)
        .padding(.vertical, 9)
        .background(
            row.isCurrentTier
                ? AppTheme.accent.opacity(colorScheme == .dark ? 0.18 : 0.09)
                : Color.clear
        )
        .opacity(row.isPassed ? 0.52 : 1.0)
        .accessibilityElement(children: .combine)
    }
}
