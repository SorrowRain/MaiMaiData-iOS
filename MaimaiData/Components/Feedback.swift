import SwiftUI

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
