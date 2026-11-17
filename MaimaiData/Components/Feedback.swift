import SwiftUI

extension View {
    /// The single adaptive glass helper: Liquid Glass on iOS 26+, material (plus tint) before that.
    /// This is the only place in the app that calls `glassEffect`.
    @ViewBuilder
    func appGlass<S: Shape>(in shape: S, tint: Color? = nil, interactive: Bool = true) -> some View {
        if #available(iOS 26.0, *) {
            let base: Glass = interactive ? .regular.interactive() : .regular
            glassEffect(tint.map { interactive ? Glass.regular.tint($0).interactive() : Glass.regular.tint($0) } ?? base, in: shape)
        } else {
            // Layer order matters: backgrounds applied later sit further behind. The tint must be
            // closest to the content so the material does not wash out the brand color.
            background {
                if let tint { shape.fill(tint.opacity(0.85)) }
            }
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                // Untinted fallback (secondary/circle buttons) needs a hairline edge on light pages.
                if tint == nil {
                    shape.stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }
            }
        }
    }

    /// Glass capsule container (search bar).
    func appGlassCapsule() -> some View {
        appGlass(in: Capsule())
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
func dismissToast(
    _ text: Binding<String?>,
    after seconds: Double,
    animated: Bool = false,
    ifContains expected: String? = nil
) async {
    try? await Task.sleep(for: .seconds(seconds))
    // A newer toast may have replaced this one while we waited.
    if let expected, text.wrappedValue?.contains(expected) != true { return }
    if animated {
        withAnimation { text.wrappedValue = nil }
    } else {
        text.wrappedValue = nil
    }
}

struct StatusToast: View {
    let text: String

    var body: some View {
        HStack(spacing: AppTheme.Space.s) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accentBright)
            Text(text)
                .font(AppTheme.Typography.captionSemibold)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppTheme.Space.l)
        .padding(.vertical, 10)
        .appGlass(in: Capsule(), interactive: false)
        .padding(.bottom, AppTheme.Space.xl)
        .accessibilityAddTraits(.isStaticText)
    }
}

struct SyncStatusBanner: View {
    @Bindable var store: DataStore

    var body: some View {
        if store.isLoadingLocalData || store.isSyncingSongs || store.syncNotice != nil {
            AppCard(padding: 12, tint: AppTheme.accent) {
                VStack(alignment: .leading, spacing: AppTheme.Space.s) {
                    HStack(alignment: .center, spacing: 10) {
                        if store.isLoadingLocalData || store.isSyncingSongs {
                            ProgressView().controlSize(.small)
                            Text(store.isLoadingLocalData ? "正在读取本地曲库…" : "正在检查曲库更新…")
                                .font(AppTheme.Typography.tag)
                                .foregroundStyle(.secondary)
                        } else if let notice = store.syncNotice {
                            Image(systemName: "wifi.exclamationmark")
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            Text(notice.message)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    if let notice = store.syncNotice {
                        HStack(spacing: 10) {
                            AppInlineButton(title: "重试", icon: "arrow.clockwise") {
                                store.syncNotice = nil
                                // Retry the operation that actually failed.
                                switch notice.kind {
                                case .songs:
                                    Task { await store.checkSongDataUpdateIfNeeded(force: true) }
                                case .stats:
                                    Task { await store.refreshChartStatsIfStale(force: true) }
                                }
                            }
                            .disabled(notice.kind == .songs ? store.isSyncingSongs : store.isSyncingStats)

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
