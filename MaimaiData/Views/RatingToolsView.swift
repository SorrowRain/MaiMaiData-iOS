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
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        KeyboardDismiss.hide()
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .appPageBackground()
            .navigationTitle("Rating 与查分")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottom) {
                if let syncToast {
                    StatusToast(text: syncToast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .alert("同步失败", isPresented: .constant(syncErrorMessage != nil)) {
                Button("确定") { syncErrorMessage = nil }
            } message: {
                Text(syncErrorMessage ?? "")
            }
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
        let split = store.best35AndBest15()
        let b35Sum = split.b35.reduce(0) { $0 + $1.computedRating }
        let b15Sum = split.b15.reduce(0) { $0 + $1.computedRating }
        let totalRa = b35Sum + b15Sum

        return AppCard(padding: AppTheme.cardPadding, tint: AppTheme.accent) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text(store.currentUsername.isEmpty ? "水鱼查分器（未登录）" : store.displayPlayerName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if store.currentUsername.isEmpty {
                        Text("可在「设置与数据」中登录")
                            .font(.caption)
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

                HStack(spacing: 8) {
                    ratingMetricBox(
                        label: "总 Rating",
                        value: "\(totalRa)",
                        highlight: true
                    )
                    ratingMetricBox(
                        label: "旧版本 B35",
                        value: "\(b35Sum)",
                        highlight: false
                    )
                    ratingMetricBox(
                        label: "现行版本 B15",
                        value: "\(b15Sum)",
                        highlight: false
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
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                syncToast = nil
            }
        } catch {
            syncErrorMessage = error.localizedDescription
        }
    }

    private func ratingMetricBox(label: String, value: String, highlight: Bool) -> some View {
        AppInsetGroup(padding: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(highlight ? AppTheme.accent : .secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.headline.weight(.bold).monospacedDigit())
                    .foregroundStyle(highlight ? AppTheme.accent : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    // MARK: - 2. Tools Grid Card

    private var toolsGridCard: some View {
        AppSectionCard(title: "实用工具") {
            EmptyView()
        } content: {
            AppInsetGroup {
                VStack(spacing: 0) {
                    NavigationLink(value: ToolRoute.prober) {
                        toolRow(
                            icon: "trophy.fill",
                            color: AppTheme.accent,
                            title: "Best 50",
                            subtitle: "查看 B50 成绩列表并导出图片"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 56)

                    NavigationLink(value: ToolRoute.versionCheck) {
                        toolRow(
                            icon: "square.grid.3x3.fill",
                            color: Color(hex: 0x9F51DC),
                            title: "版本进度表 / 牌子查询",
                            subtitle: "按国服版本查看 Master 谱面完成度"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 56)

                    NavigationLink(value: ToolRoute.levelCheck) {
                        toolRow(
                            icon: "slider.horizontal.3",
                            color: Color(hex: 0xFF9C24),
                            title: "等级进度表",
                            subtitle: "按 1~15 级定数分组查看完成情况"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 56)

                    NavigationLink(value: ToolRoute.finaleToDx) {
                        toolRow(
                            icon: "arrow.left.arrow.right",
                            color: Color(hex: 0x12B4FF),
                            title: "旧框 (FiNALE) 分数换算 DX",
                            subtitle: "由 Tap / Hold / Slide / Break 判定换算"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toolRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.rowTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(AppTheme.Typography.rowSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    // MARK: - 3. Single Song Rating Calculator

    private func singleRatingCard(proxy: ScrollViewProxy) -> some View {
        AppSectionCard(
            title: "单曲 Rating 计算",
            subtitle: "输入谱面定数与达成率即时换算"
        ) {
            HStack(spacing: 4) {
                Text("Ra")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                Text("\(computedSingleRating)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppTheme.accent.opacity(0.12), in: Capsule())
        } content: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
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
                        .font(.caption)
                        .foregroundStyle(Color(.systemRed))
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
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .bottom, spacing: 10) {
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

                    Button {
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
                    } label: {
                        Text("推算")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(minHeight: AppTheme.rowMinHeight)
                            .contentShape(RoundedRectangle(cornerRadius: AppTheme.Radius.input, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        .regular.tint(AppTheme.accent).interactive(),
                        in: RoundedRectangle(cornerRadius: AppTheme.Radius.input, style: .continuous)
                    )
                }

                if let targetError {
                    Label(targetError, systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color(.systemRed))
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
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)

                            ForEach(targetRows) { row in
                                Divider()
                                HStack {
                                    Text(String(format: "%.1f", row.level))
                                        .fontWeight(.semibold)
                                        .frame(width: 48, alignment: .leading)
                                    Text(row.achievementText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("\(row.singleRating)")
                                        .foregroundStyle(AppTheme.accent)
                                        .fontWeight(.semibold)
                                        .frame(width: 64, alignment: .trailing)
                                    Text("\(row.totalRating)")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 72, alignment: .trailing)
                                }
                                .font(.caption.monospacedDigit())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
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
