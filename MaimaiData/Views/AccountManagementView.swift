import SwiftUI

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
        ScrollView {
            VStack(spacing: AppTheme.cardSpacing) {
                AppSectionCard(
                    title: "已保存账号",
                    subtitle: store.savedAccounts.isEmpty ? "添加水鱼查分器账号后可随时切换" : "点击账号即可切换并同步成绩"
                ) {
                    if store.savedAccounts.isEmpty {
                        AppInsetGroup(padding: AppTheme.cardPadding) {
                            Text("暂无已保存账号，点击下方按钮添加")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        AppInsetGroup {
                            VStack(spacing: 0) {
                                ForEach(Array(store.savedAccounts.enumerated()), id: \.element.id) { idx, acct in
                                    if idx > 0 {
                                        Divider().padding(.leading, AppTheme.Space.m)
                                    }
                                    accountRow(acct)
                                }
                            }
                        }
                    }
                }

                AppPrimaryButton(
                    title: "添加账号",
                    icon: "plus.circle.fill",
                    isDisabled: switchingUsername != nil
                ) {
                    showAddAccountSheet = true
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.vertical, AppTheme.Space.m)
        }
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

    private func accountRow(_ acct: SavedAccount) -> some View {
        let isCurrent = !store.currentUsername.isEmpty && acct.username == store.currentUsername
        return HStack(spacing: AppTheme.Space.s) {
            Button {
                Task { await switchToSavedAccount(acct) }
            } label: {
                HStack(spacing: AppTheme.Space.s) {
                    Text(acct.username)
                        .font(AppTheme.Typography.rowTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if isCurrent {
                        AppCapsuleLabel(text: "当前", style: .compact)
                    }

                    Spacer(minLength: 4)

                    if switchingUsername == acct.username {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: AppTheme.rowMinHeight, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(switchingUsername != nil)

            Button {
                pendingDeleteAccount = acct
            } label: {
                Image(systemName: "trash")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.destructive)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(switchingUsername != nil)
            .accessibilityLabel("删除账号 \(acct.username)")
        }
        .padding(.leading, AppTheme.Space.m)
        .padding(.trailing, AppTheme.Space.s)
        .contextMenu {
            Button(role: .destructive) {
                pendingDeleteAccount = acct
            } label: {
                Label("删除账号", systemImage: "trash")
            }
        }
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
