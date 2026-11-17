import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = AppTheme.Space.s
    var lineSpacing: CGFloat = AppTheme.Space.s

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
                    ? AppTheme.Palette.surfaceDark
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
                        : AppTheme.Palette.hairline.opacity(0.08),
                    lineWidth: 1
                )
            }
    }
}

struct AppSectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var subtitleColor: Color = .secondary
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        subtitleColor: Color = .secondary,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleColor = subtitleColor
        self.trailing = trailing
    }

    init(
        title: String,
        subtitle: String? = nil,
        subtitleColor: Color = .secondary
    ) where Trailing == EmptyView {
        self.init(title: title, subtitle: subtitle, subtitleColor: subtitleColor, trailing: { EmptyView() })
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Space.s) {
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
                        .foregroundStyle(subtitleColor)
                }
            }

            Spacer(minLength: 8)
            trailing()
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

    init(
        title: String,
        subtitle: String? = nil,
        padding: CGFloat = AppTheme.cardPadding,
        @ViewBuilder content: @escaping () -> Content
    ) where Trailing == EmptyView {
        self.init(title: title, subtitle: subtitle, padding: padding, trailing: { EmptyView() }, content: content)
    }

    var body: some View {
        AppCard(padding: padding) {
            VStack(alignment: .leading, spacing: AppTheme.Space.m) {
                AppSectionHeader(title: title, subtitle: subtitle) {
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
                    : AppTheme.Palette.hairline.opacity(0.04),
                in: shape
            )
            .overlay(
                shape.strokeBorder(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : AppTheme.Palette.hairline.opacity(0.065),
                    lineWidth: 1
                )
            )
    }
}
