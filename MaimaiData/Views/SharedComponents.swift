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
    }

    // Typography Hierarchy (17pt Card Title > 15pt Row Title > 12pt Subtitle / Inline Button)
    enum Typography {
        static let cardTitle = Font.headline
        static let rowTitle = Font.subheadline.weight(.medium)
        static let songTitle = Font.subheadline.weight(.semibold)
        static let rowSubtitle = Font.caption
        static let caption = Font.caption
        static let inlineAction = Font.caption.weight(.semibold)
        static let badge = Font.caption2.weight(.bold).monospacedDigit()
        static let tag = Font.caption.weight(.medium)
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
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 46)
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .glassEffect(
            .regular.tint(tint).interactive(),
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous)
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
            .foregroundStyle(isRemaster ? Color(hex: 0x762D8C) : difficulty.readableForeground)
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
            case .compact: return 9
            case .list: return 11
            case .hero: return 14
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
                statPill(title: "SSS", value: "\(stats.sssCount)/\(stats.totalCount)", color: Color(hex: 0xB46900))
                statPill(title: "FC", value: "\(stats.fcCount)/\(stats.totalCount)", color: Color(hex: 0x237818))
                statPill(title: "AP", value: "\(stats.apCount)/\(stats.totalCount)", color: Color(hex: 0xC85A00))
                statPill(title: "FSD", value: "\(stats.fsdCount)/\(stats.totalCount)", color: Color(hex: 0x0A6BA1))
            }
        }
    }

    private func statPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(color.opacity(0.24), lineWidth: 1)
        )
    }
}

struct ChecklistSongTile: View {
    let song: SongData
    let record: ProberRecord?
    let borderColor: Color
    let displayMode: CheckDisplayMode
    var showTypeBadge: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
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
