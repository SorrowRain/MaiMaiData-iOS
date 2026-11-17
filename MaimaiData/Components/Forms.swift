import SwiftUI
import UIKit

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
                    : AppTheme.Palette.hairline.opacity(0.045),
                in: shape
            )
            .overlay(
                shape.strokeBorder(
                    isFocused
                        ? AppTheme.accent.opacity(0.6)
                        : (colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : AppTheme.Palette.hairline.opacity(0.10)),
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
                    : AppTheme.Palette.hairline.opacity(0.045),
                in: shape
            )
            .overlay(
                shape.strokeBorder(
                    isFocused
                        ? AppTheme.accent.opacity(0.6)
                        : (colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : AppTheme.Palette.hairline.opacity(0.10)),
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
