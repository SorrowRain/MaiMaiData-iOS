import SwiftUI

struct RatingToolsView: View {
    @Environment(DataStore.self) private var store

    @State private var dsInput = "14.8"
    @State private var achiInput = "100.5000"

    @State private var targetRatingInput = "15000"
    @State private var targetRows: [RatingCalculator.TargetRow] = []
    @State private var targetError: String?
    @State private var syncToast: String?
    @State private var syncErrorMessage: String?

    private enum ToolRoute: Hashable {
        case prober, versionCheck, levelCheck, finaleToDx
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.cardSpacing) {
                        ratingSummaryCard
                        toolsGridCard
                        singleRatingCard(proxy: proxy)
                            .id("singleRatingCard")
                        reverseRatingCard(proxy: proxy)
                            .id("reverseRatingCard")
                    }
                    .padding(.horizontal, AppTheme.pagePadding)
                    .padding(.vertical, AppTheme.Space.m)
                    .dismissKeyboardOnTap()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .appPageBackground()
            .navigationTitle("Rating 与查分")
            .navigationBarTitleDisplayMode(.inline)
            .statusToast(syncToast)
            .errorAlert("同步失败", message: $syncErrorMessage)
            .navigationDestination(for: ToolRoute.self) { route in
                switch route {
                case .prober:
                    ProberView()
                case .versionCheck:
                    VersionCheckView()
                case .levelCheck:
                    LevelCheckView()
                case .finaleToDx:
                    FinaleToDxView()
                }
            }
            .navigationDestination(for: SongData.self) { song in
                SongDetailView(song: song)
            }
        }
    }

    // MARK: - 1. Player & Rating Summary Card

    private var ratingSummaryCard: some View {
        let summary = store.best35AndBest15()

        return AppCard(padding: AppTheme.cardPadding, tint: AppTheme.accent) {
            VStack(alignment: .leading, spacing: AppTheme.Space.m) {
                HStack(alignment: .center) {
                    Text(store.currentUsername.isEmpty ? "水鱼查分器（未登录）" : store.displayPlayerName)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if store.currentUsername.isEmpty {
                        Text("可在「设置与数据」中登录")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        AppInlineButton(
                            title: "同步成绩",
                            icon: "arrow.clockwise",
                            isLoading: store.isSyncingRecords
                        ) {
                            KeyboardDismiss.hide()
                            Task { await syncRecords() }
                        }
                    }
                }

                HStack(spacing: AppTheme.Space.s) {
                    AppMetricTile(
                        title: "总 Rating",
                        value: "\(summary.totalRating)",
                        highlight: true
                    )
                    AppMetricTile(
                        title: "旧版本 B35",
                        value: "\(summary.b35Rating)"
                    )
                    AppMetricTile(
                        title: "现行版本 B15",
                        value: "\(summary.b15Rating)"
                    )
                }
            }
        }
    }

    private func syncRecords() async {
        do {
            try await store.fetchRecordsWithCurrentCookie()
            withAnimation {
                syncToast = "成绩已同步"
            }
            await dismissToast($syncToast, after: 2, animated: true)
        } catch {
            syncErrorMessage = error.localizedDescription
        }
    }

    // MARK: - 2. Tools Grid Card

    private var toolsGridCard: some View {
        AppSectionCard(title: "实用工具") {
            AppInsetGroup {
                VStack(spacing: 0) {
                    NavigationLink(value: ToolRoute.prober) {
                        AppInsetRow(
                            icon: "trophy.fill",
                            iconColor: AppTheme.accent,
                            title: "Best 50",
                            subtitle: "查看 B50 成绩列表并导出图片"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 58)

                    NavigationLink(value: ToolRoute.versionCheck) {
                        AppInsetRow(
                            icon: "square.grid.3x3.fill",
                            iconColor: AppTheme.Palette.ratingPurple,
                            title: "版本进度表 / 牌子查询",
                            subtitle: "按国服版本查看 Master 谱面完成度"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 58)

                    NavigationLink(value: ToolRoute.levelCheck) {
                        AppInsetRow(
                            icon: "slider.horizontal.3",
                            iconColor: AppTheme.Palette.ratingOrange,
                            title: "等级进度表",
                            subtitle: "按 1~15 级定数分组查看完成情况"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 58)

                    NavigationLink(value: ToolRoute.finaleToDx) {
                        AppInsetRow(
                            icon: "arrow.left.arrow.right",
                            iconColor: AppTheme.Palette.ratingBlue,
                            title: "旧框 (FiNALE) 分数换算 DX",
                            subtitle: "由 Tap / Hold / Slide / Break 判定换算"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 3. Single Song Rating Calculator

    private func singleRatingCard(proxy: ScrollViewProxy) -> some View {
        AppSectionCard(
            title: "单曲 Rating 计算",
            subtitle: "输入谱面定数与达成率即时换算"
        ) {
            AppCapsuleLabel(
                text: "\(computedSingleRating)",
                style: .metric(prefix: "Ra")
            )
        } content: {
            VStack(alignment: .leading, spacing: AppTheme.itemSpacing) {
                HStack(spacing: AppTheme.Space.m) {
                    AppTextField(
                        title: "谱面定数",
                        placeholder: "14.8",
                        text: $dsInput,
                        keyboardType: .decimalPad
                    ) { focused in
                        if focused {
                            scrollToCard(proxy, id: "singleRatingCard")
                        }
                    }

                    AppTextField(
                        title: "达成率 (%)",
                        placeholder: "100.5000",
                        text: $achiInput,
                        keyboardType: .decimalPad
                    ) { focused in
                        if focused {
                            scrollToCard(proxy, id: "singleRatingCard")
                        }
                    }
                }

                if let singleInputError {
                    Label(singleInputError, systemImage: "exclamationmark.circle.fill")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.destructive)
                }
            }
        }
    }

    // MARK: - 4. Reverse Target Rating Calculator

    private func reverseRatingCard(proxy: ScrollViewProxy) -> some View {
        AppSectionCard(
            title: "目标 Rating 达成率反推",
            subtitle: "按 50 首均分推算所需最低定数与达成率"
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Space.m) {
                HStack(alignment: .bottom, spacing: AppTheme.itemSpacing) {
                    AppTextField(
                        title: "目标总 Rating",
                        placeholder: "如 15000",
                        text: $targetRatingInput,
                        keyboardType: .numberPad
                    ) { focused in
                        if focused {
                            scrollToCard(proxy, id: "reverseRatingCard")
                        }
                    }

                    AppPrimaryButton(
                        title: "推算",
                        style: .inputCompanion
                    ) {
                        KeyboardDismiss.hide()
                        let val = Int(targetRatingInput.trimmingCharacters(in: .whitespaces)) ?? 0
                        targetRows = RatingCalculator.reverseCalculate(targetTotalRating: val)
                        if val <= 0 {
                            targetError = "请输入大于 0 的目标 Rating"
                        } else if targetRows.isEmpty {
                            targetError = "当前目标无法生成达成率建议，请检查数值范围"
                        } else {
                            targetError = nil
                        }
                    }
                }

                if let targetError {
                    Label(targetError, systemImage: "exclamationmark.circle.fill")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.destructive)
                }

                if !targetRows.isEmpty {
                    AppInsetGroup {
                        VStack(spacing: 0) {
                            HStack {
                                Text("定数")
                                    .frame(width: 48, alignment: .leading)
                                Text("所需达成率")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("单曲 Ra")
                                    .frame(width: 64, alignment: .trailing)
                                Text("50首总计")
                                    .frame(width: 72, alignment: .trailing)
                            }
                            .font(AppTheme.Typography.caption2Bold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppTheme.Space.m)
                            .padding(.vertical, AppTheme.Space.s)

                            ForEach(targetRows) { row in
                                Divider()
                                HStack {
                                    Text(String(format: "%.1f", row.level))
                                        .font(AppTheme.Typography.captionMeta)
                                        .frame(width: 48, alignment: .leading)
                                    Text(row.achievementText)
                                        .font(AppTheme.Typography.captionMono)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("\(row.singleRating)")
                                        .font(AppTheme.Typography.captionMeta)
                                        .foregroundStyle(AppTheme.accentText)
                                        .frame(width: 64, alignment: .trailing)
                                    Text("\(row.totalRating)")
                                        .font(AppTheme.Typography.captionMono)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 72, alignment: .trailing)
                                }
                                .padding(.horizontal, AppTheme.Space.m)
                                .padding(.vertical, AppTheme.Space.s)
                            }
                        }
                    }
                }
            }
        }
    }

    private func scrollToCard(_ proxy: ScrollViewProxy, id: String) {
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.snappy(duration: 0.25)) {
                proxy.scrollTo(id, anchor: .top)
            }
        }
    }

    private var singleInputError: String? {
        guard let ds = Double(dsInput), ds > 0 else { return "请输入有效的谱面定数" }
        guard let achi = Double(achiInput), achi >= 0 else { return "请输入有效的达成率" }
        return nil
    }

    private var computedSingleRating: Int {
        guard let ds = Double(dsInput), let achi = Double(achiInput), ds > 0, achi >= 0 else {
            return 0
        }
        return RatingCalculator.singleSongRating(ds: ds, achievement: achi)
    }
}
