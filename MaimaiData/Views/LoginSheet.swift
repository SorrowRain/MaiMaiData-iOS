import SwiftUI

struct LoginSheet: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var shouldDismissAfterAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    AppSectionCard(
                        title: "添加水鱼查分器账号",
                        subtitle: "凭据仅安全保存在本机 Keychain"
                    ) {
                        VStack(spacing: AppTheme.Space.m) {
                            AppTextField(
                                title: "用户名",
                                placeholder: "输入水鱼用户名",
                                text: $username
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.username)
                            .submitLabel(.next)

                            AppSecureField(
                                title: "密码",
                                placeholder: "输入水鱼密码",
                                text: $password
                            )

                            AppPrimaryButton(
                                title: isSubmitting ? "正在登录并同步成绩…" : "登录并保存账号",
                                icon: "arrow.right.circle.fill",
                                isLoading: isSubmitting,
                                isDisabled: isSubmitting || username.isEmpty || password.isEmpty
                            ) {
                                KeyboardDismiss.hide()
                                Task { await submitLogin() }
                            }
                            .padding(.top, AppTheme.Space.xs)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.pagePadding)
                .padding(.vertical, AppTheme.Space.m)
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(store.isLoadingLocalData || isSubmitting)
            .appPageBackground()
            .navigationTitle("添加账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .errorAlert("登录或同步提示", message: $errorMessage)
            .onChange(of: errorMessage) { oldVal, newVal in
                if oldVal != nil && newVal == nil && shouldDismissAfterAlert {
                    dismiss()
                }
            }
        }
    }

    private func submitLogin() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await store.loginAndSyncRecords(username: username, password: password)
            dismiss()
        } catch let error as MaimaiAPIError {
            if case .recordSyncFailedAfterLogin = error {
                shouldDismissAfterAlert = true
            }
            errorMessage = error.recoveryMessage
        } catch {
            errorMessage = "登录失败：\(error.localizedDescription)\n请检查网络连接或水鱼查分器是否可访问。"
        }
    }
}
