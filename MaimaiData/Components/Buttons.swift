import SwiftUI

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
        .appGlass(in: RoundedRectangle(cornerRadius: radius, style: .continuous), tint: tint)
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
        .appGlass(in: RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
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
        .appGlass(in: Circle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
        .accessibilityLabel(accessibilityLabel)
    }
}
