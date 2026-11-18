import SwiftUI

struct AccountManagementView: View {
    @Environment(DataStore.self) private var store

    @State private var showAddProfileSheet = false
    @State private var pendingDeleteProfile: ScoreProfile?
    @State private var toastMessage: String?
    @State private var errorMessage: String?

    private var isPendingDeleteActive: Bool {
        guard let target = pendingDeleteProfile else { return false }
        return target.id == store.activeProfileId
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.cardSpacing) {
                AppSectionCard(
                    title: "已存成绩档案",
                    subtitle: store.profiles.isEmpty
                        ? "支持添加多个落雪咖啡屋或水鱼查分器档案并随时本地切换"
                        : "点击档案即可秒切本地成绩单"
                ) {
                    if store.activeProfile != nil {
                        AppInlineButton(
                            title: "同步当前",
                            icon: "arrow.clockwise",
                            isLoading: store.isSyncingRecords
                        ) {
                            Task { await syncActiveProfile() }
                        }
                    }
                } content: {
                    if store.profiles.isEmpty {
                        AppInsetGroup(padding: AppTheme.cardPadding) {
                            Text("暂无成绩档案，点击下方按钮选择落雪或水鱼添加")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        AppInsetGroup {
                            VStack(spacing: 0) {
                                ForEach(Array(store.profiles.enumerated()), id: \.element.id) { idx, profile in
                                    if idx > 0 {
                                        Divider().padding(.leading, AppTheme.Space.m)
                                    }
                                    profileRow(profile)
                                }
                            }
                        }
                    }
                }

                AppPrimaryButton(
                    title: "添加成绩档案",
                    icon: "plus.circle.fill",
                    isDisabled: store.isSyncingRecords
                ) {
                    showAddProfileSheet = true
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.vertical, AppTheme.Space.m)
        }
        .appPageBackground()
        .sensoryFeedback(.selection, trigger: store.activeProfileId)
        .navigationTitle("成绩档案")
        .navigationBarTitleDisplayMode(.inline)
        .statusToast(toastMessage)
        .sheet(isPresented: $showAddProfileSheet) {
            LoginSheet()
        }
        .alert(
            isPendingDeleteActive ? "移除当前成绩档案" : "移除成绩档案",
            isPresented: Binding(
                get: { pendingDeleteProfile != nil },
                set: { if !$0 { pendingDeleteProfile = nil } }
            ),
            presenting: pendingDeleteProfile
        ) { profile in
            Button("移除", role: .destructive) {
                store.removeProfile(id: profile.id)
                pendingDeleteProfile = nil
            }
            Button("取消", role: .cancel) {
                pendingDeleteProfile = nil
            }
        } message: { profile in
            if profile.id == store.activeProfileId {
                Text("确定要移除当前使用的成绩档案「\(profile.displayTitle)」及其本地缓存成绩吗？")
            } else {
                Text("确定要移除成绩档案「\(profile.displayTitle)」及其本地缓存成绩吗？")
            }
        }
        .errorAlert("同步失败", message: $errorMessage)
    }

    private func profileRow(_ profile: ScoreProfile) -> some View {
        let isCurrent = (profile.id == store.activeProfileId)
        let providerTint = profile.provider == .lxns ? AppTheme.Palette.ratingPurple : AppTheme.accent

        var subParts = [profile.subtitleText]
        if let syncedAt = profile.lastSyncedAt {
            subParts.append(syncedAt.formatted(date: .abbreviated, time: .shortened))
        }

        return HStack(spacing: AppTheme.Space.s) {
            Button {
                guard !isCurrent else { return }
                store.switchProfile(to: profile.id)
                Task {
                    withAnimation {
                        toastMessage = "已切换至 \(profile.displayTitle)"
                    }
                    await dismissToast($toastMessage, after: 1.6, animated: true)
                }
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: AppTheme.Space.s) {
                        Text(profile.displayTitle)
                            .font(AppTheme.Typography.rowTitle)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        AppCapsuleLabel(
                            text: profile.provider.shortName,
                            tint: providerTint,
                            style: .compact
                        )

                        if isCurrent {
                            AppCapsuleLabel(text: "当前", style: .compact)
                        }
                    }

                    Text(subParts.joined(separator: " · "))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: AppTheme.rowMinHeight, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                pendingDeleteProfile = profile
            } label: {
                Image(systemName: "trash")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.destructive)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(store.isSyncingRecords)
            .accessibilityLabel("移除成绩档案 \(profile.displayTitle)")
        }
        .padding(.leading, AppTheme.Space.m)
        .padding(.trailing, AppTheme.Space.s)
        .contextMenu {
            Button(role: .destructive) {
                pendingDeleteProfile = profile
            } label: {
                Label("移除档案", systemImage: "trash")
            }
        }
    }

    private func syncActiveProfile() async {
        do {
            try await store.syncActiveProfileRecords()
            withAnimation {
                toastMessage = "成绩已同步"
            }
            await dismissToast($toastMessage, after: 2, animated: true)
        } catch let error as MaimaiAPIError {
            errorMessage = error.recoveryMessage
        } catch {
            errorMessage = "同步失败：\(error.localizedDescription)"
        }
    }
}
