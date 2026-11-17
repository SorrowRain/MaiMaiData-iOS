import SwiftUI

// MARK: - Secondary Page: Account Management (Saved Accounts List + Add Account Entry)

struct AccountManagementView: View {
    @Environment(DataStore.self) private var store

    @State private var showAddAccountSheet = false
    @State private var switchingUsername: String?
    @State private var pendingDeleteAccount: SavedAccount?
    @State private var errorMessage: String?

    private var isPendingDeleteLoggedIn: Bool {
        guard let acct = pendingDeleteAccount else { return false }
        return !store.currentUsername.isEmpty && acct.username == store.currentUsername
    }

    var body: some View {
        List {
            Section {
                AppSectionHeader(
                    title: "已保存账号",
                    subtitle: "点击切换并登录账号，左滑可删除",
                    subtitleColor: Color(.secondaryLabel)
                )
                .padding(.vertical, AppTheme.Space.xs)

                if store.savedAccounts.isEmpty {
                    Text("暂无已保存账号，点击下方按钮添加")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, AppTheme.Space.s)
                } else {
                    ForEach(store.savedAccounts) { acct in
                        Button {
                            Task { await switchToSavedAccount(acct) }
                        } label: {
                            HStack(spacing: AppTheme.Space.s) {
                                Text(acct.username)
                                    .font(AppTheme.Typography.rowTitle)
                                    .foregroundStyle(Color(.label))

                                if !store.currentUsername.isEmpty && acct.username == store.currentUsername {
                                    AppCapsuleLabel(text: "当前", style: .compact)
                                }

                                Spacer()

                                if switchingUsername == acct.username {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                            }
                            .padding(.vertical, AppTheme.Space.xs)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(switchingUsername != nil)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDeleteAccount = acct
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }

            Section {
                AppPrimaryButton(
                    title: "添加账号",
                    icon: "plus.circle.fill",
                    isDisabled: switchingUsername != nil
                ) {
                    showAddAccountSheet = true
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .appPageBackground()
        .navigationTitle("账号管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddAccountSheet) {
            LoginSheet()
        }
        .alert(
            isPendingDeleteLoggedIn ? "退出并删除账号" : "删除账号",
            isPresented: Binding(
                get: { pendingDeleteAccount != nil },
                set: { if !$0 { pendingDeleteAccount = nil } }
            ),
            presenting: pendingDeleteAccount
        ) { acct in
            Button(isPendingDeleteLoggedIn ? "退出并删除" : "删除", role: .destructive) {
                store.removeSavedAccount(username: acct.username)
                pendingDeleteAccount = nil
            }
            Button("取消", role: .cancel) {
                pendingDeleteAccount = nil
            }
        } message: { acct in
            if !store.currentUsername.isEmpty && acct.username == store.currentUsername {
                Text("账号「\(acct.username)」当前处于登录状态，确定要退出登录并删除该账号吗？")
            } else {
                Text("确定要删除已保存的账号「\(acct.username)」吗？")
            }
        }
        .errorAlert("切换账号失败", message: $errorMessage)
    }

    private func switchToSavedAccount(_ acct: SavedAccount) async {
        switchingUsername = acct.username
        defer { switchingUsername = nil }
        do {
            try await store.loginAndSyncRecords(username: acct.username, password: acct.password)
        } catch let error as MaimaiAPIError {
            errorMessage = error.recoveryMessage
        } catch {
            errorMessage = "登录失败：\(error.localizedDescription)\n请检查网络连接后重试。"
        }
    }
}

// MARK: - Sheet Popup: Add / Login Account

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
