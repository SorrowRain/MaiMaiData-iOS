import SwiftUI

struct SettingsView: View {
    @Environment(DataStore.self) private var store
    @State private var cacheSizeText: String = "计算中..."
    @State private var showAcknowledgmentsSheet = false

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

                    // 2. 游戏区服
                    AppSectionCard(title: "游戏区服") {
                        AppInsetGroup {
                            AppInsetRow(title: "当前曲库与区服") {
                                HStack(spacing: AppTheme.Space.s) {
                                    if store.isSyncingSongs && store.serverRegion != .cn {
                                        ProgressView().controlSize(.small)
                                    }
                                    Menu {
                                        Picker(
                                            "游戏区服",
                                            selection: Binding(
                                                get: { store.serverRegion },
                                                set: { region in
                                                    Task { await store.switchServerRegion(region) }
                                                }
                                            )
                                        ) {
                                            ForEach(MaimaiConstants.ServerRegion.allCases) { region in
                                                Text(region.displayName).tag(region)
                                            }
                                        }
                                    } label: {
                                        AppMenuCapsule(title: store.serverRegion.shortName)
                                    }
                                }
                            }
                        }
                    }

                    // 3. 曲库与搜索
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
                                    subtitle: store.activeCatalogSubtitle
                                ) {
                                    AppInlineButton(
                                        title: "检查更新",
                                        icon: "arrow.down.circle",
                                        isLoading: store.isSyncingSongs
                                    ) {
                                        Task { await store.syncActiveRegionSongs(force: true) }
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
                                Button {
                                    showAcknowledgmentsSheet = true
                                } label: {
                                    AppInsetRow(title: "致谢与参考", showsChevron: true) {
                                        Text("查看详情")
                                            .font(AppTheme.Typography.inlineAction)
                                            .foregroundStyle(AppTheme.accentText)
                                    }
                                }
                                .buttonStyle(.plain)
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
            .sensoryFeedback(.selection, trigger: store.serverRegion)
            .navigationTitle("设置与数据")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshCacheSize()
            }
            .sheet(isPresented: $showAcknowledgmentsSheet) {
                AcknowledgmentsSheet()
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

private struct AcknowledgmentsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct ReferenceItem: Identifiable {
        var id: String { name }
        let name: String
        let tag: String
        let summary: String
        let urlString: String
        let displayHost: String
    }

    private static let designReferences: [ReferenceItem] = [
        ReferenceItem(
            name: "PaperPig / MaimaiData",
            tag: "客户端参考",
            summary: "Android 端开源舞萌 DX 查询工具，为本项目提供了基础功能形态、国服离线曲库结构与部分贴图素材参考。",
            urlString: "https://github.com/PaperPig/MaimaiData",
            displayHost: "github.com/PaperPig/MaimaiData"
        )
    ]

    private static let proberReferences: [ReferenceItem] = [
        ReferenceItem(
            name: "Diving-Fish（水鱼查分器）",
            tag: "查分与统计",
            summary: "提供国服玩家成绩同步接口、水鱼全服拟合定数统计数据以及曲绘封面兜底服务。",
            urlString: "https://github.com/Diving-Fish/maimaidx-prober",
            displayHost: "diving-fish.com"
        ),
        ReferenceItem(
            name: "LXNS（落雪咖啡屋）",
            tag: "曲绘镜像",
            summary: "提供国内高速稳定的高清曲绘 CDN 镜像服务与舞萌 DX 曲库数据结构参考。",
            urlString: "https://maimai.lxns.net",
            displayHost: "maimai.lxns.net"
        )
    ]

    private static let multiRegionReferences: [ReferenceItem] = [
        ReferenceItem(
            name: "zetaraku / arcade-songs-fetch",
            tag: "多区服曲库",
            summary: "提供日服与国际服完整曲库、版本归属、区服定数覆写、外服曲绘镜像及宴会场谱面说明数据。",
            urlString: "https://github.com/zetaraku/arcade-songs-fetch",
            displayHost: "github.com/zetaraku/arcade-songs-fetch"
        ),
        ReferenceItem(
            name: "DXRating (gekichumai)",
            tag: "ID 与新规参考",
            summary: "提供日服与国际服曲目底层数字 ID 实时映射数据，以及 CiRCLE 起实行的两代 B15 与 AP+1 新规参考。",
            urlString: "https://github.com/gekichumai/dxrating",
            displayHost: "dxrating.net"
        ),
        ReferenceItem(
            name: "Yuri-YuzuChaN & 社区资源库",
            tag: "别名与贴图",
            summary: "提供社区共同维护的舞萌 DX 曲目中文别名库，以及各世代版本与评级贴图静态素材整理。",
            urlString: "https://github.com/Yuri-YuzuChaN/maimaiDX",
            displayHost: "github.com/Yuri-YuzuChaN/maimaiDX"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    referenceSection(title: "客户端与设计参考", items: Self.designReferences)
                    referenceSection(title: "查分器与曲绘服务", items: Self.proberReferences)
                    referenceSection(title: "多区服数据与社区生态", items: Self.multiRegionReferences)

                    AppSectionCard(title: "版权与免责声明") {
                        AppInsetGroup(padding: AppTheme.Space.m) {
                            Text("《maimai でらっくす》与《舞萌 DX》游戏本体及其曲绘封面、版本标识、评级贴图等相关美术与音乐素材版权均归 SEGA 及华立科技（Wahlap）所有。本应用为非商用开源工具，仅作玩家个人谱面查询与算分辅助使用。")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.pagePadding)
                .padding(.vertical, AppTheme.Space.m)
            }
            .appPageBackground()
            .navigationTitle("致谢与参考")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func referenceSection(title: String, items: [ReferenceItem]) -> some View {
        AppSectionCard(title: title) {
            VStack(spacing: AppTheme.itemSpacing) {
                ForEach(items) { item in
                    if let url = URL(string: item.urlString) {
                        Link(destination: url) {
                            referenceCardContent(item)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.name)，\(item.tag)，点击在浏览器中打开")
                    } else {
                        referenceCardContent(item)
                    }
                }
            }
        }
    }

    private func referenceCardContent(_ item: ReferenceItem) -> some View {
        AppInsetGroup(padding: AppTheme.Space.m) {
            VStack(alignment: .leading, spacing: AppTheme.Space.s) {
                HStack(alignment: .center, spacing: AppTheme.Space.s) {
                    Text(item.name)
                        .font(AppTheme.Typography.songTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    AppCapsuleLabel(text: item.tag, style: .compact)

                    Spacer(minLength: AppTheme.Space.xs)

                    Image(systemName: "arrow.up.right")
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(.tertiary)
                }

                Text(item.summary)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.displayHost)
                    .font(AppTheme.Typography.captionMono)
                    .foregroundStyle(AppTheme.accentText)
                    .lineLimit(1)
            }
        }
    }
}
