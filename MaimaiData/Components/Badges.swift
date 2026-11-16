import SwiftUI

/// Small tinted capsule used for counts and inline tags.
struct AppCapsuleLabel: View {
    let text: String
    var tint: Color = AppTheme.accent
    var font: Font = .caption.weight(.semibold).monospacedDigit()
    var backgroundOpacity: Double = 0.12
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 3
    var foreground: Color? = nil

    var body: some View {
        Text(text)
            .font(font)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(tint.opacity(backgroundOpacity), in: Capsule())
            .foregroundStyle(foreground ?? tint)
    }
}

/// Statistic tile: caption title above value, tinted background.
struct AppStatTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Space.s)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.Radius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.tile, style: .continuous)
                .strokeBorder(tint.opacity(0.24), lineWidth: 1)
        )
    }
}

struct DifficultyLevelBadge: View {
    let difficulty: DifficultyType
    let text: String

    var body: some View {
        let isRemaster = difficulty == .remaster
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.badge, style: .continuous)
        Text(text)
            .font(AppTheme.Typography.badge)
            .foregroundStyle(isRemaster ? AppTheme.Palette.chartRemaster : difficulty.readableForeground)
            .frame(minWidth: 36, minHeight: 22)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                isRemaster ? Color.white : difficulty.color,
                in: shape
            )
            .overlay(
                shape.strokeBorder(
                    isRemaster ? difficulty.color : Color.black.opacity(0.08),
                    lineWidth: isRemaster ? 1.5 : 0.5
                )
            )
    }
}

struct GenreCapsuleTag: View {
    let genre: String

    var body: some View {
        let colors = MaimaiConstants.genreColors(for: genre)
        let textColor = MaimaiConstants.genreTextColor(for: genre)
        Text(genre)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(colors.bg.opacity(0.15), in: Capsule())
            .overlay(
                Capsule().strokeBorder(colors.bg.opacity(0.30), lineWidth: 0.8)
            )
            .foregroundStyle(textColor)
    }
}

struct ChartTypeBadge: View {
    let isDX: Bool
    var compact: Bool = false

    var body: some View {
        Image(isDX ? "ic_deluxe" : "ic_standard")
            .resizable()
            .scaledToFit()
            .frame(height: compact ? 13 : 15)
            .accessibilityLabel(isDX ? "DX 谱面" : "标准谱面")
    }
}

struct SongCoverBadgeView: View {
    enum Size {
        case compact // 56pt
        case list    // 64pt
        case hero    // 100pt

        var dimension: CGFloat {
            switch self {
            case .compact: return 56
            case .list: return 64
            case .hero: return 100
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .compact: return AppTheme.Radius.tile
            case .list: return AppTheme.Radius.inset
            case .hero: return AppTheme.Radius.button
            }
        }

        var strokeWidth: CGFloat {
            switch self {
            case .compact, .list: return 2
            case .hero: return 3
            }
        }
    }

    let song: SongData?
    var size: Size = .list
    var borderColor: Color = AppTheme.accent
    var showCornerTypeBadge: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
        ZStack(alignment: .bottomTrailing) {
            CoverImageView(song: song)
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(shape)
                .overlay(
                    shape.strokeBorder(borderColor, lineWidth: size.strokeWidth)
                )

            if showCornerTypeBadge, let song {
                ChartTypeBadge(isDX: song.isDX, compact: size != .hero)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.55), in: Capsule())
                    .padding(4)
            }
        }
    }
}

struct FilterCapsuleChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isSelected: Bool
    var selectedColor: Color = AppTheme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.tag)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? AnyShapeStyle(selectedColor.gradient)
                        : AnyShapeStyle(
                            colorScheme == .dark
                                ? Color.white.opacity(0.07)
                                : Color(hex: 0x0F2952, alpha: 0.055)
                        ),
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(
                        isSelected
                            ? Color.white.opacity(0.28)
                            : Color(hex: 0x0F2952, alpha: colorScheme == .dark ? 0.15 : 0.08),
                        lineWidth: 1
                    )
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "已选中" : "未选中")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
