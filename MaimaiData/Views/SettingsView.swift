import SwiftUI

struct SettingsView: View {
    @Environment(DataStore.self) private var store
    @State private var cacheSizeText: String = "计算中..."

    private var appVersionText: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        if let build = info?["CFBundleVersion"] as? String, !build.isEmpty {
            return "v\(short) (\(build))"
        }
        return "v\(short)"
    }

    var body: some View {
        @Bindable var storeBindable = store

        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    // 1. 水鱼查分器账号（Push 进入二级页面 AccountManagementView）
                    AppSectionCard(title: "水鱼查分器账号") {
                        NavigationLink {
                            AccountManagementView()
                        } label: {
                            AppInsetGroup {
                                AppInsetRow(
                                    title: store.currentUsername.isEmpty ? "当前未登录" : store.displayPlayerName,
                                    subtitle: (!store.currentUsername.isEmpty && store.displayPlayerName != store.currentUsername)
                                        ? store.currentUsername
                                        : nil,
                                    showsChevron: true
                                ) {
                                    Text(store.currentUsername.isEmpty ? "登录 / 管理" : "切换账号")
                                        .font(AppTheme.Typography.inlineAction)
                                        .foregroundStyle(AppTheme.accentText)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // 2. 曲库与搜索
                    AppSectionCard(title: "曲库与搜索") {
                        AppInsetGroup {
                            VStack(spacing: 0) {
                                settingToggleRow(
                                    title: "曲目详情页显示别名",
                                    isOn: $storeBindable.enableShowAlias
                                )
                                Divider().padding(.leading, AppTheme.Space.m)
                                settingToggleRow(
                                    title: "搜索时匹配曲目别名",
                                    isOn: $storeBindable.enableAliasSearch
                                )
                                Divider().padding(.leading, AppTheme.Space.m)
                                settingToggleRow(
                                    title: "搜索时匹配谱师名称",
                                    isOn: $storeBindable.enableCharterSearch
                                )
                            }
                        }
                    }

                    // 3. Best50 图片设置（关闭水鱼昵称时才展示自定义昵称输入框）
                    AppSectionCard(title: "Best50 图片设置") {
                        VStack(spacing: AppTheme.itemSpacing) {
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
                        AppInsetGroup {
                            VStack(spacing: 0) {
                                AppInsetRow(
                                    title: "本地曲库",
                                    subtitle: "版本 \(store.dataVersion) · 共 \(store.songs.count) 首"
                                ) {
                                    AppInlineButton(
                                        title: "检查更新",
                                        icon: "arrow.down.circle",
                                        isLoading: store.isSyncingSongs
                                    ) {
                                        Task { await store.checkSongDataUpdateIfNeeded(force: true) }
                                    }
                                }

                                Divider().padding(.leading, AppTheme.Space.m)

                                AppInsetRow(
                                    title: "水鱼拟合定数",
                                    subtitle: store.lastChartStatsSync?.formatted(date: .abbreviated, time: .shortened) ?? "尚未同步"
                                ) {
                                    AppInlineButton(
                                        title: "立即刷新",
                                        icon: "arrow.clockwise",
                                        isLoading: store.isSyncingStats
                                    ) {
                                        Task { await store.refreshChartStatsIfStale(force: true) }
                                    }
                                }
                            }
                        }
                    }

                    // 5. 存储与缓存
                    AppSectionCard(title: "存储与缓存") {
                        AppInsetGroup {
                            AppInsetRow(
                                title: "封面磁盘缓存",
                                subtitle: "当前占用 \(cacheSizeText)",
                                monospacedSubtitle: true
                            ) {
                                AppInlineButton(
                                    title: "清除缓存",
                                    icon: "trash",
                                    tint: AppTheme.destructive
                                ) {
                                    CoverImageCache.shared.clearCache()
                                    refreshCacheSize()
                                }
                            }
                        }
                    }

                    // 6. 关于
                    AppSectionCard(title: "关于 MaimaiData") {
                        AppInsetGroup {
                            VStack(spacing: 0) {
                                aboutRow(title: "版本", value: appVersionText)
                                Divider().padding(.leading, AppTheme.Space.m)
                                aboutRow(title: "致谢参考", value: "PaperPig / Diving-Fish / LXNS")
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.pagePadding)
                .padding(.vertical, AppTheme.Space.m)
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.interactively)
            .appPageBackground()
            .navigationTitle("设置与数据")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshCacheSize()
            }
            .errorAlert("同步结果", message: $storeBindable.statusMessage)
        }
    }

    private func settingToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .font(AppTheme.Typography.rowTitle)
            .tint(AppTheme.accent)
            .padding(.horizontal, AppTheme.Space.m)
            .frame(minHeight: AppTheme.rowMinHeight)
    }

    private func aboutRow(title: String, value: String) -> some View {
        AppInsetRow(title: title) {
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundStyle(.secondary)
        }
    }

    private func refreshCacheSize() {
        let bytes = CoverImageCache.shared.cacheSizeBytes()
        cacheSizeText = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
