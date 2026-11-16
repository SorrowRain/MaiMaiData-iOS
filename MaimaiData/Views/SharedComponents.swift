import Photos
import SwiftUI
import UIKit

// MARK: - Wrapping Chip Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let subProposal = maxWidth.isFinite ? ProposedViewSize(width: maxWidth, height: nil) : .unspecified
            let size = subview.sizeThatFits(subProposal)
            if currentX + size.width > maxWidth && currentX > 0 {
                maxLineWidth = max(maxLineWidth, currentX - spacing)
                currentX = 0
                currentY += lineHeight + lineSpacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        maxLineWidth = max(maxLineWidth, max(0, currentX - spacing))
        return CGSize(width: maxWidth.isFinite ? maxWidth : maxLineWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Unified Design Tokens

enum AppTheme {
    // Brand & Accent Colors
    static let accent = Color(hex: 0x1668DC)
    static let accentBright = Color(hex: 0x2B88FF)
    static let favoritePink = Color(hex: 0xF43F7E)

    // Semantic Palette (game terms + shared accents; values must not change)
    enum Palette {
        // Notes
        static let noteTap = Color(hex: 0x12B4FF)
        static let noteHold = Color(hex: 0xFF9C24)
        static let noteSlide = Color(hex: 0x2FCA4C)
        static let noteBreak = Color(hex: 0xF43F7E)

        // Chart / delta
        static let chartRemaster = Color(hex: 0x762D8C)
        static let deltaUp = Color(hex: 0xE53935)
        static let deltaDown = Color(hex: 0x1E8E3E)

        // Judgments
        static let judgePerfect = Color(hex: 0x854400)
        static let judgeGreat = Color(hex: 0xB72267)
        static let judgeGood = Color(hex: 0x176523)
        static let judgeMiss = Color(.secondaryLabel)

        // Rating tool row icons (reuse note values)
        static let ratingPurple = Color(hex: 0x9F51DC)
        static let ratingOrange = Color(hex: 0xFF9C24)
        static let ratingBlue = Color(hex: 0x12B4FF)

        // Difficulty
        static let diffBasic = Color(hex: 0x6FD43D)
        static let diffAdvanced = Color(hex: 0xF8B709)
        static let diffExpert = Color(hex: 0xFF818D)
        static let diffMaster = Color(hex: 0x9F51DC)
        static let diffRemaster = Color(hex: 0xCB5EEA)
        static let diffUtage = Color(hex: 0xB12876)
        static let diffBasicText = Color(hex: 0x183C12)
        static let diffAdvancedText = Color(hex: 0x4B3700)
        static let diffExpertText = Color(hex: 0x681B28)
        static let diffBasicDark = Color(hex: 0x025235)
        static let diffAdvancedDark = Color(hex: 0xC7450C)
        static let diffExpertDark = Color(hex: 0xC02138)
        static let diffMasterDark = Color(hex: 0x671B8D)
        static let diffRemasterDark = Color(hex: 0x8C2DD5)
        static let diffOtherDark = Color(hex: 0x053264)

        // Genres: (fill, stroke) and text
        static let genrePop: (bg: Color, stroke: Color) = (bg: Color(hex: 0xFF9C24), stroke: Color(hex: 0xFFD21F))
        static let genreNico: (bg: Color, stroke: Color) = (bg: Color(hex: 0x12B4FF), stroke: Color(hex: 0x7ED6FF))
        static let genreTouhou: (bg: Color, stroke: Color) = (bg: Color(hex: 0xCA6FEB), stroke: Color(hex: 0xE8A7FF))
        static let genreGame: (bg: Color, stroke: Color) = (bg: Color(hex: 0x287516), stroke: Color(hex: 0xBAFBA3))
        static let genreMaimai: (bg: Color, stroke: Color) = (bg: Color(hex: 0xFF4646), stroke: Color(hex: 0xFFA7A7))
        static let genreUtage: (bg: Color, stroke: Color) = (bg: Color(hex: 0xDC39B8), stroke: Color(hex: 0xB12876))
        static let genreOther: (bg: Color, stroke: Color) = (bg: Color(hex: 0x319DF8), stroke: Color(hex: 0x99D1FF))
        static let genrePopText = Color(hex: 0x8A4800)
        static let genreNicoText = Color(hex: 0x055C84)
        static let genreTouhouText = Color(hex: 0x762D8C)
        static let genreGameText = Color(hex: 0x1C560C)
        static let genreMaimaiText = Color(hex: 0x9A1B1B)
        static let genreUtageText = Color(hex: 0x8F1863)
        static let genreOtherText = Color(hex: 0x125BB8)

        // Checklist stat pills
        static let statSSS = Color(hex: 0xB46900)
        static let statFC = Color(hex: 0x237818)
        static let statAP = Color(hex: 0xC85A00)
        static let statFSD = Color(hex: 0x0A6BA1)
    }

    // Spacing & Sizing
    static let pagePadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let itemSpacing: CGFloat = 10
    static let rowMinHeight: CGFloat = 50

    // Corner Radii (Always use .continuous)
    enum Radius {
        static let card: CGFloat = 16
        static let inset: CGFloat = 12
        static let button: CGFloat = 14
        static let input: CGFloat = 12
        static let badge: CGFloat = 6
        static let tile: CGFloat = 10
        static let chip: CGFloat = 12
    }

    // Spacing scale
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // Typography Hierarchy (17pt Card Title > 15pt Row Title > 12pt Subtitle / Inline Button)
    enum Typography {
        static let cardTitle = Font.headline
        static let rowTitle = Font.subheadline.weight(.medium)
        static let songTitle = Font.subheadline.weight(.semibold)
        static let caption = Font.caption
        static let inlineAction = Font.caption.weight(.semibold)
        static let badge = Font.caption2.weight(.bold).monospacedDigit()
        static let tag = Font.caption.weight(.medium)
        static let sectionHeader = Font.subheadline.weight(.semibold)
        static let stat = Font.title3.weight(.semibold).monospacedDigit()
        static let footnote = Font.footnote
        static let captionSemibold = Font.caption.weight(.semibold)
    }
}

// MARK: - Lightweight Atmospheric Page Background (Zero Offscreen Blur Bottleneck)

struct AppPageBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var tint: Color = AppTheme.accent

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(hex: 0x0B1120), Color(hex: 0x0F172A), Color(hex: 0x111827)]
                : [Color(hex: 0xE8F0FC), Color(hex: 0xF1F5FB), Color(hex: 0xEDF2FA)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    tint.opacity(colorScheme == .dark ? 0.16 : 0.10),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
        }
        .ignoresSafeArea()
    }
}

extension View {
    func appPageBackground(tint: Color = AppTheme.accent) -> some View {
        background {
            AppPageBackground(tint: tint)
        }
    }
}

// MARK: - High-Performance Card & Inset Containers (120fps Transition Safe)

struct AppCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var padding: CGFloat = AppTheme.cardPadding
    var tint: Color? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                colorScheme == .dark
                    ? Color(hex: 0x172135)
                    : Color.white.opacity(0.92),
                in: shape
            )
            .overlay {
                if let tint {
                    shape.fill(
                        LinearGradient(
                            colors: [tint.opacity(colorScheme == .dark ? 0.10 : 0.055), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
                }
            }
            .overlay {
                shape.strokeBorder(
                    colorScheme == .dark
                        ? Color.white.opacity(0.09)
                        : Color(hex: 0x0F2952, alpha: 0.08),
                    lineWidth: 1
                )
            }
    }
}

struct AppSectionCard<Trailing: View, Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var padding: CGFloat = AppTheme.cardPadding
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        padding: CGFloat = AppTheme.cardPadding,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.padding = padding
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        AppCard(padding: padding) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Capsule()
                        .fill(AppTheme.accent.gradient)
                        .frame(width: 4, height: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundStyle(Color(.label))
                        if let subtitle {
                            Text(subtitle)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8)
                    trailing()
                }

                content()
            }
        }
    }
}

struct AppInsetGroup<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var padding: CGFloat = 0
    @ViewBuilder let content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.inset, style: .continuous)
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                colorScheme == .dark
                    ? Color.white.opacity(0.045)
                    : Color(hex: 0x0F2952, alpha: 0.04),
                in: shape
            )
            .overlay(
                shape.strokeBorder(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color(hex: 0x0F2952, alpha: 0.065),
                    lineWidth: 1
                )
            )
    }
}

// MARK: - Unified Buttons

/// Full-width primary action button.
struct AppPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = AppTheme.accent
    var isLoading = false
    var isDisabled = false
    var fullWidth = true
    var horizontalPadding: CGFloat = 18
    var verticalPadding: CGFloat = 12
    var minHeight: CGFloat = 46
    var radius: CGFloat = AppTheme.Radius.button
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: minHeight)
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
        .buttonStyle(.plain)
        .glassEffect(
            .regular.tint(tint).interactive(),
            in: RoundedRectangle(cornerRadius: radius, style: .continuous)
        )
        .opacity(isLoading || isDisabled ? 0.5 : 1)
        .disabled(isLoading || isDisabled)
    }
}

/// Compact inline action button for rows and card headers (Guaranteed smaller than 17pt row titles).
struct AppInlineButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = AppTheme.accent
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.caption2.weight(.bold))
                }
                Text(title)
                    .font(AppTheme.Typography.inlineAction)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(tint.opacity(0.11), in: Capsule())
            .overlay(Capsule().strokeBorder(tint.opacity(0.22), lineWidth: 0.8))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}


/// Secondary glass button (e.g. "重置选项").
struct AppSecondaryButton: View {
    let title: String
    var tint: Color = AppTheme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.songTitle)
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity, minHeight: 46)
                .contentShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .glassEffect(
            .regular.interactive(),
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous)
        )
    }
}

/// Label for a Menu rendered as a tinted capsule (sort menu, version switcher).
struct AppMenuCapsule: View {
    let title: String
    var tint: Color = AppTheme.accent

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.inlineAction)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(tint.opacity(0.11), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.22), lineWidth: 0.8))
    }
}

/// Circular glass icon button. An accessibility label is required.
struct AppCircleIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
        .accessibilityLabel(accessibilityLabel)
    }
}

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

extension View {
    /// Glass capsule container (search bar).
    func appGlassCapsule() -> some View {
        glassEffect(.regular.interactive(), in: Capsule())
    }

    /// Tap on empty area dismisses the keyboard.
    func dismissKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture { KeyboardDismiss.hide() }
    }

    /// Error alert driven by an optional message; clears the message on dismiss.
    func errorAlert(_ title: String, message: Binding<String?>) -> some View {
        alert(
            title,
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button("确定") { message.wrappedValue = nil }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}

/// Clears an optional toast text after a delay.
@MainActor
func dismissToast(_ text: Binding<String?>, after seconds: Double, animated: Bool = false) async {
    try? await Task.sleep(for: .seconds(seconds))
    if animated {
        withAnimation { text.wrappedValue = nil }
    } else {
        text.wrappedValue = nil
    }
}

// MARK: - Unified Text & Secure Fields (Full-Box Edge Tap + Focus Highlight)

enum KeyboardDismiss {
    static func hide() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AppTextField: View {
    @Environment(\.colorScheme) private var colorScheme
    var title: String? = nil
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var onFocusChange: ((Bool) -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.input, style: .continuous)
        VStack(alignment: .leading, spacing: 5) {
            if let title {
                Text(title)
                    .font(AppTheme.Typography.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 0) {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .font(.subheadline.weight(.medium).monospacedDigit())
                    .focused($isFocused)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: AppTheme.rowMinHeight)
            .background(
                colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color(hex: 0x0F2952, alpha: 0.045),
                in: shape
            )
            .overlay(
                shape.strokeBorder(
                    isFocused
                        ? AppTheme.accent.opacity(0.6)
                        : (colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color(hex: 0x0F2952, alpha: 0.10)),
                    lineWidth: isFocused ? 1.2 : 1
                )
            )
            .contentShape(shape)
            .onTapGesture {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { _, focused in
            onFocusChange?(focused)
        }
    }
}

struct AppSecureField: View {
    @Environment(\.colorScheme) private var colorScheme
    var title: String? = nil
    let placeholder: String
    @Binding var text: String

    @State private var showPassword = false
    @FocusState private var isFocused: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.input, style: .continuous)
        VStack(alignment: .leading, spacing: 5) {
            if let title {
                Text(title)
                    .font(AppTheme.Typography.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.password)
                            .focused($isFocused)
                    } else {
                        SecureField(placeholder, text: $text)
                            .textContentType(.password)
                            .focused($isFocused)
                    }
                }
                .font(.subheadline.weight(.medium))

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showPassword ? "隐藏密码" : "显示密码")
            }
            .padding(.horizontal, 12)
            .frame(minHeight: AppTheme.rowMinHeight)
            .background(
                colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color(hex: 0x0F2952, alpha: 0.045),
                in: shape
            )
            .overlay(
                shape.strokeBorder(
                    isFocused
                        ? AppTheme.accent.opacity(0.6)
                        : (colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color(hex: 0x0F2952, alpha: 0.10)),
                    lineWidth: isFocused ? 1.2 : 1
                )
            )
            .contentShape(shape)
            .onTapGesture {
                isFocused = true
            }
        }
    }
}

// MARK: - Unified Maimai Domain Badges & Tags

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

// MARK: - Status Toast & Sync Banner

struct StatusToast: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accentBright)
            Text(text)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule())
        .padding(.bottom, 24)
        .accessibilityAddTraits(.isStaticText)
    }
}

struct SyncStatusBanner: View {
    @Bindable var store: DataStore

    var body: some View {
        if store.isLoadingLocalData || store.isSyncingSongs || store.syncNotice != nil {
            AppCard(padding: 12, tint: AppTheme.accent) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 10) {
                        if store.isLoadingLocalData || store.isSyncingSongs {
                            ProgressView().controlSize(.small)
                            Text(store.isLoadingLocalData ? "正在读取本地曲库…" : "正在检查曲库更新…")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        } else if let notice = store.syncNotice {
                            Image(systemName: "wifi.exclamationmark")
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            Text(notice.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    if store.syncNotice != nil {
                        HStack(spacing: 10) {
                            AppInlineButton(title: "重试", icon: "arrow.clockwise") {
                                store.syncNotice = nil
                                Task { await store.checkSongDataUpdateIfNeeded(force: true) }
                            }
                            .disabled(store.isSyncingSongs)

                            AppInlineButton(title: "关闭", tint: .secondary) {
                                store.syncNotice = nil
                            }
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
        }
    }
}

// MARK: - Photos Save & Share Helpers

enum PhotoLibrarySaver {
    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw NSError(domain: "MaimaiData", code: 1, userInfo: [NSLocalizedDescriptionKey: "请在系统设置中允许访问相册权限"])
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ZoomableImageScrollView: UIViewRepresentable {
    let image: UIImage

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.5
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if context.coordinator.imageView?.image !== image {
            context.coordinator.imageView?.image = image
            uiView.setZoomScale(1.0, animated: false)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView, let imageView else { return }
            if scrollView.zoomScale > 1.05 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                let point = gesture.location(in: imageView)
                let targetScale: CGFloat = 2.6
                let width = scrollView.bounds.width / targetScale
                let height = scrollView.bounds.height / targetScale
                let rect = CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height)
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
}

// MARK: - Checklist Shared Header & Tile

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
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                AppStatTile(title: "SSS", value: "\(stats.sssCount)/\(stats.totalCount)", tint: AppTheme.Palette.statSSS)
                AppStatTile(title: "FC", value: "\(stats.fcCount)/\(stats.totalCount)", tint: AppTheme.Palette.statFC)
                AppStatTile(title: "AP", value: "\(stats.apCount)/\(stats.totalCount)", tint: AppTheme.Palette.statAP)
                AppStatTile(title: "FSD", value: "\(stats.fsdCount)/\(stats.totalCount)", tint: AppTheme.Palette.statFSD)
            }
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
        case .fc:
            if let fc = record.fcAssetName {
                Image(fc)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
        case .fs:
            if let fs = record.fsAssetName {
                Image(fs)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
        }
    }
}
