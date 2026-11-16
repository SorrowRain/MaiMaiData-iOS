import SwiftUI

struct SettingsView: View {
    @Environment(DataStore.self) private var store
    @State private var cacheSizeText: String = "计算中..."
    @State private var showSyncAlert = false

    var body: some View {
        @Bindable var storeBindable = store

        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    // 1. 水鱼查分器账号（Push 进入二级页面 AccountManagementView）
                    AppSectionCard(title: "水鱼查分器账号") {
                        EmptyView()
                    } content: {
                        NavigationLink {
                            AccountManagementView()
                        } label: {
                            AppInsetGroup {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(store.currentUsername.isEmpty ? "当前未登录" : store.displayPlayerName)
                                            .font(AppTheme.Typography.rowTitle)
                                            .foregroundStyle(.primary)
                                        if !store.currentUsername.isEmpty && store.displayPlayerName != store.currentUsername {
                                            Text(store.currentUsername)
                                                .font(AppTheme.Typography.rowSubtitle)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer(minLength: 8)
                                    HStack(spacing: 4) {
                                        Text(store.currentUsername.isEmpty ? "登录 / 管理" : "切换账号")
                                            .font(AppTheme.Typography.inlineAction)
                                            .foregroundStyle(AppTheme.accent)
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .frame(minHeight: AppTheme.rowMinHeight)
                                .contentShape(Rectangle())
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // 2. 曲库与搜索
                    AppSectionCard(title: "曲库与搜索") {
                        EmptyView()
                    } content: {
                        AppInsetGroup {
                            VStack(spacing: 0) {
                                settingToggleRow(
                                    title: "曲目详情页显示别名",
                                    isOn: $storeBindable.enableShowAlias
                                )
                                Divider().padding(.leading, 12)
                                settingToggleRow(
                                    title: "搜索时匹配曲目别名",
                                    isOn: $storeBindable.enableAliasSearch
                                )
                                Divider().padding(.leading, 12)
                                settingToggleRow(
                                    title: "搜索时匹配谱师名称",
                                    isOn: $storeBindable.enableCharterSearch
                                )
                            }
                        }
                    }

                    // 3. Best50 图片设置（关闭水鱼昵称时才展示自定义昵称输入框）
                    AppSectionCard(title: "Best50 图片设置") {
                        EmptyView()
                    } content: {
                        VStack(spacing: 10) {
                            AppInsetGroup {
                                settingToggleRow(
                                    title: "使用水鱼查分器昵称",
                                    isOn: $storeBindable.useDivingFishNickname.animation(.snappy(duration: 0.2))
                                )
                            }

                            if !store.useDivingFishNickname {
                                AppTextField(
                                    placeholder: "输入生成 Best50 时显示的玩家昵称",
                                    text: $storeBindable.customNickname
                                )
                                .submitLabel(.done)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }

                    // 4. 数据与同步
                    AppSectionCard(title: "数据与同步") {
                        EmptyView()
                    } content: {
                        AppInsetGroup {
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("本地曲库")
                                            .font(AppTheme.Typography.rowTitle)
                                        Text("版本 \(store.dataVersion) · 共 \(store.songs.count) 首")
                                            .font(AppTheme.Typography.rowSubtitle)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 8)
                                    AppInlineButton(
                                        title: "检查更新",
                                        icon: "arrow.down.circle",
                                        isLoading: store.isSyncingSongs
                                    ) {
                                        Task { await store.checkSongDataUpdateIfNeeded(force: true) }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)

                                Divider().padding(.leading, 12)

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("水鱼拟合定数")
                                            .font(AppTheme.Typography.rowTitle)
                                        Text(store.lastChartStatsSync?.formatted(date: .abbreviated, time: .shortened) ?? "尚未同步")
                                            .font(AppTheme.Typography.rowSubtitle)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 8)
                                    AppInlineButton(
                                        title: "立即刷新",
                                        icon: "arrow.clockwise",
                                        isLoading: store.isSyncingStats
                                    ) {
                                        Task { await store.refreshChartStatsIfStale(force: true) }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                            }
                        }
                    }

                    // 5. 存储与缓存
                    AppSectionCard(title: "存储与缓存") {
                        EmptyView()
                    } content: {
                        AppInsetGroup {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("封面磁盘缓存")
                                        .font(AppTheme.Typography.rowTitle)
                                    Text("当前占用 \(cacheSizeText)")
                                        .font(AppTheme.Typography.rowSubtitle)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                                Spacer(minLength: 8)
                                AppInlineButton(
                                    title: "清除缓存",
                                    icon: "trash",
                                    tint: Color(.systemRed)
                                ) {
                                    CoverImageCache.shared.clearCache()
                                    refreshCacheSize()
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                        }
                    }

                    // 6. 关于
                    AppSectionCard(title: "关于 MaimaiData") {
                        EmptyView()
                    } content: {
                        AppInsetGroup {
                            VStack(spacing: 0) {
                                aboutRow(title: "版本", value: "v1.0.0")
                                Divider().padding(.leading, 12)
                                aboutRow(title: "致谢参考", value: "PaperPig / Diving-Fish / LXNS")
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.pagePadding)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    KeyboardDismiss.hide()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .appPageBackground()
            .navigationTitle("设置与数据")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshCacheSize()
            }
            .onChange(of: store.statusMessage) { _, msg in
                if msg != nil { showSyncAlert = true }
            }
            .alert("同步结果", isPresented: $showSyncAlert) {
                Button("确定") { store.statusMessage = nil }
            } message: {
                Text(store.statusMessage ?? "")
            }
        }
    }

    private func settingToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .font(AppTheme.Typography.rowTitle)
            .tint(AppTheme.accent)
            .padding(.horizontal, 12)
            .frame(minHeight: AppTheme.rowMinHeight)
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.rowTitle)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: AppTheme.rowMinHeight)
    }

    private func refreshCacheSize() {
        let bytes = CoverImageCache.shared.cacheSizeBytes()
        cacheSizeText = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
