import SwiftUI

/// Shared 2-column / 3-column achievement-to-Rating reference table.
/// Used by both `SongDetailView` (3 columns when logged in, 2 columns when logged out)
/// and `RatingCalculatorView` (2 columns).
struct RatingTierTable: View {
    @Environment(\.colorScheme) private var colorScheme
    let rows: [RatingCalculator.TierRow]
    var showB50Column: Bool = false

    var body: some View {
        AppInsetGroup {
            VStack(spacing: 0) {
                HStack(spacing: AppTheme.Space.s) {
                    Text("分段档位")
                        .frame(maxWidth: .infinity, alignment: .center)
                    if showB50Column {
                        Text("单曲 Ra")
                            .frame(width: 82, alignment: .center)
                        Text("B50 可加")
                            .frame(width: 82, alignment: .center)
                    } else {
                        Text("单曲 Ra")
                            .frame(maxWidth: .infinity, alignment: .center)
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
            HStack(spacing: 6) {
                Image(row.rankAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 18, alignment: .center)

                Text(row.achievementText)
                    .font(row.isCurrentTier ? AppTheme.Typography.captionMeta : AppTheme.Typography.captionMono)
                    .foregroundStyle(.primary)
                    .frame(width: 68, alignment: .trailing)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            if showB50Column {
                Text("\(row.singleRating)")
                    .font(AppTheme.Typography.captionMeta)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .frame(width: 82, alignment: .center)

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
                .frame(width: 82, alignment: .center)
            } else {
                Text("\(row.singleRating)")
                    .font(AppTheme.Typography.captionMeta)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity, alignment: .center)
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
