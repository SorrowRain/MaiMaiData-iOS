import SwiftUI

/// Standardized tinted capsule label with semantic presets.
///
/// Do not add ad-hoc padding/opacity/font parameters here; use one of the defined `Style` cases
/// so all pills across the app share consistent sizing and dark-mode contrast.
struct AppCapsuleLabel: View {
    enum Style {
        /// Section header count pill (e.g. "24 首").
        case count
        /// Active filter summary pill with subtle border.
        case filter
        /// Compact inline status/rank badge (e.g. "#1", "当前", "4x").
        case compact
        /// Prominent metric pill with a prefix label (e.g. "Ra 333").
        case metric(prefix: String)
    }

    @Environment(\.colorScheme) private var colorScheme
    let text: String
    var tint: Color = AppTheme.accent
    var style: Style = .count

    var body: some View {
        let isDark = colorScheme == .dark
        let spec = resolvedSpec
        let isNeutral = tint == .secondary

        HStack(spacing: AppTheme.Space.xs) {
            if let prefix = spec.prefix {
                Text(prefix)
                    .font(AppTheme.Typography.captionBold)
            }
            Text(text)
                .font(spec.font)
        }
        .padding(.horizontal, spec.hPadding)
        .padding(.vertical, spec.vPadding)
        .background(
            tint.opacity(isNeutral ? 0.10 : (isDark ? max(spec.bgOpacity, 0.22) : spec.bgOpacity)),
            in: Capsule()
        )
        .overlay(
            Capsule().strokeBorder(
                tint.opacity(isDark && spec.strokeOpacity > 0 ? max(spec.strokeOpacity, 0.42) : spec.strokeOpacity),
                lineWidth: spec.strokeOpacity > 0 ? 0.8 : 0
            )
        )
        .foregroundStyle(
            isNeutral
                ? Color.secondary
                : (isDark ? tint.brightened(toAtLeast: 1.0, maxSaturation: 0.5) : tint)
        )
    }

    private struct Spec {
        let font: Font
        let hPadding: CGFloat
        let vPadding: CGFloat
        let bgOpacity: Double
        let strokeOpacity: Double
        var prefix: String? = nil
    }

    private var resolvedSpec: Spec {
        switch style {
        case .count:
            return Spec(font: AppTheme.Typography.captionMeta, hPadding: 8, vPadding: 3, bgOpacity: 0.12, strokeOpacity: 0)
        case .filter:
            return Spec(font: AppTheme.Typography.caption2Semibold, hPadding: 9, vPadding: 4, bgOpacity: 0.14, strokeOpacity: 0.28)
        case .compact:
            return Spec(font: AppTheme.Typography.caption2Bold, hPadding: 6, vPadding: 2, bgOpacity: 0.14, strokeOpacity: 0)
        case .metric(let prefix):
            return Spec(font: AppTheme.Typography.heroTitle, hPadding: 10, vPadding: 4, bgOpacity: 0.12, strokeOpacity: 0, prefix: prefix)
        }
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
                .font(AppTheme.Typography.caption2Bold)
                .foregroundStyle(tint)
            Text(value)
                .font(AppTheme.Typography.captionMeta)
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
    @Environment(\.colorScheme) private var colorScheme
    let difficulty: DifficultyType
    let text: String

    var body: some View {
        let isRemaster = difficulty == .remaster
        let isDark = colorScheme == .dark
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.badge, style: .continuous)
        Text(text)
            .font(AppTheme.Typography.badge)
            .foregroundStyle(isRemaster ? AppTheme.Palette.chartRemaster : difficulty.readableForeground)
            .frame(minWidth: 36, minHeight: 22)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                isRemaster ? Color.white : difficulty.solidFill(isDark: isDark),
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

/// Unified genre-tinted capsule chrome (light 15% fill / 30% border, dark 22% fill / 45% border).
struct GenreTagChrome: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let genre: String

    func body(content: Content) -> some View {
        let bg = MaimaiConstants.genreColors(for: genre).bg
        let dark = colorScheme == .dark
        content
            .background(bg.opacity(dark ? 0.22 : 0.15), in: Capsule())
            .overlay(Capsule().strokeBorder(bg.opacity(dark ? 0.45 : 0.30), lineWidth: 0.8))
            .foregroundStyle(MaimaiConstants.genreTextColor(for: genre))
    }
}

struct GenreCapsuleTag: View {
    let genre: String

    var body: some View {
        Text(genre)
            .font(AppTheme.Typography.caption2Semibold)
            .padding(.horizontal, AppTheme.Space.s)
            .padding(.vertical, 3)
            .modifier(GenreTagChrome(genre: genre))
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
                    .padding(.horizontal, AppTheme.Space.xs)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.55), in: Capsule())
                    .padding(AppTheme.Space.xs)
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
                .padding(.horizontal, AppTheme.Space.m)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? AnyShapeStyle(selectedColor.gradient)
                        : AnyShapeStyle(
                            colorScheme == .dark
                                ? Color.white.opacity(0.07)
                                : AppTheme.Palette.hairline.opacity(0.055)
                        ),
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(
                        isSelected
                            ? Color.white.opacity(0.28)
                            : AppTheme.Palette.hairline.opacity(colorScheme == .dark ? 0.15 : 0.08),
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
