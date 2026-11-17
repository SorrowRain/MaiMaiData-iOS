import SwiftUI

struct SongDetailView: View {
    private enum DetailTab: Int, CaseIterable {
        case overview = 0
        case rating = 1
        case tolerance = 2

        var title: String {
            switch self {
            case .overview: return "谱面概览"
            case .rating: return "Rating与推分"
            case .tolerance: return "容错参考"
            }
        }
    }

    @Environment(DataStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentSong: SongData
    @State private var selectedChartIndex: Int
    @State private var selectedTab: DetailTab = .overview
    @State private var showCoverZoom = false
    @State private var copiedToast: String?
    @State private var copyTrigger = 0

    init(song: SongData, initialDifficulty: DifficultyType? = nil) {
        _currentSong = State(initialValue: song)
        let reversed = Array(song.resolvedCharts.reversed())
        if let initialDifficulty,
           let matched = reversed.firstIndex(where: { $0.difficulty == initialDifficulty }) {
            _selectedChartIndex = State(initialValue: matched)
        } else {
            _selectedChartIndex = State(initialValue: 0)
        }
    }

    private var chartsDesc: [ResolvedChart] {
        Array(currentSong.resolvedCharts.reversed())
    }

    var body: some View {
        let genreColors = MaimaiConstants.genreColors(for: currentSong.basicInfo.genre)
        let isFav = store.isFavorite(currentSong)

        ScrollView {
            VStack(spacing: AppTheme.cardSpacing) {
                headerCard(genreColors: genreColors)

                if !chartsDesc.isEmpty {
                    difficultyPicker

                    Picker("详情分区", selection: $selectedTab.animation(.snappy(duration: 0.22))) {
                        ForEach(DetailTab.allCases, id: \.self) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    let currentIndex = min(selectedChartIndex, chartsDesc.count - 1)
                    let chart = chartsDesc[currentIndex]
                    tabContent(chart: chart, genreColors: genreColors)
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.vertical, AppTheme.Space.m)
        }
        .appPageBackground(tint: genreColors.bg)
        .navigationTitle("曲目详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(currentSong)
                } label: {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .foregroundStyle(isFav ? AppTheme.favoritePink : .primary)
                        .symbolEffect(.bounce, value: isFav)
                }
                .sensoryFeedback(.impact(weight: .light), trigger: isFav)
                .accessibilityLabel(isFav ? "取消收藏" : "收藏歌曲")
            }
        }
        .sensoryFeedback(.selection, trigger: selectedChartIndex)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sensoryFeedback(.selection, trigger: currentSong.id)
        .sensoryFeedback(.success, trigger: copyTrigger)
        .statusToast(copiedToast)
        .fullScreenCover(isPresented: $showCoverZoom) {
            CoverZoomView(song: currentSong)
        }
    }

    // MARK: - Hero Header Card

    private func headerCard(genreColors: (bg: Color, stroke: Color)) -> some View {
        let cardFill = MaimaiConstants.genreCardFill(for: currentSong.basicInfo.genre)
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
        let counterpart = store.counterpartSong(for: currentSong)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Button {
                    showCoverZoom = true
                } label: {
                    SongCoverBadgeView(
                        song: currentSong,
                        size: .hero,
                        borderColor: genreColors.stroke,
                        showCornerTypeBadge: true
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("放大查看《\(currentSong.title)》封面")

                VStack(alignment: .leading, spacing: 6) {
                    Text(currentSong.title)
                        .font(AppTheme.Typography.heroTitle)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, counterpart != nil ? 56 : 0)
                        .onLongPressGesture { copyText(currentSong.title, label: "歌曲名") }

                    Text(currentSong.basicInfo.artist)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                        .onLongPressGesture { copyText(currentSong.basicInfo.artist, label: "曲师") }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: AppTheme.Space.s) {
                factPill(label: "BPM", value: "\(currentSong.basicInfo.bpm)")
                factPill(label: "歌曲分类", value: currentSong.basicInfo.genre)
                factPill(label: "歌曲 ID", value: currentSong.id)
                    .onLongPressGesture { copyText(currentSong.id, label: "歌曲 ID") }
            }
        }
        .padding(AppTheme.cardPadding)
        .background(
            LinearGradient(
                colors: [cardFill, cardFill.opacity(0.84)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: shape
        )
        .overlay(
            shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if let counterpart {
                counterpartSwitchBadge(to: counterpart)
                    .padding(.top, 10)
                    .padding(.trailing, 10)
            }
        }
    }

    private func counterpartSwitchBadge(to counterpart: SongData) -> some View {
        Button {
            let activeDiff = chartsDesc[safe: min(selectedChartIndex, max(0, chartsDesc.count - 1))]?.difficulty
            let nextReversed = Array(counterpart.resolvedCharts.reversed())
            let nextIdx = activeDiff.flatMap { diff in
                nextReversed.firstIndex(where: { $0.difficulty == diff })
            } ?? 0
            withAnimation(.snappy(duration: 0.25)) {
                currentSong = counterpart
                selectedChartIndex = nextIdx
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(AppTheme.Typography.caption2)
                Text(counterpart.isDX ? "DX" : "标准")
                    .font(AppTheme.Typography.caption2Semibold)
            }
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, AppTheme.Space.s)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.18), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(counterpart.isDX ? "切换至 DX 谱面" : "切换至标准谱面")
    }

    private func factPill(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(AppTheme.Typography.caption2)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(AppTheme.Typography.rowMetric)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Space.s)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: AppTheme.Radius.inset, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.inset, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Difficulty Switcher

    private var difficultyPicker: some View {
        HStack(spacing: AppTheme.Space.s) {
            ForEach(Array(chartsDesc.enumerated()), id: \.element.id) { idx, chart in
                let isSelected = idx == min(selectedChartIndex, chartsDesc.count - 1)
                let isRemaster = chart.difficulty == .remaster
                let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.chip, style: .continuous)
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selectedChartIndex = idx
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(chart.difficulty.shortName)
                            .font(AppTheme.Typography.captionBold)
                        Text(chart.level)
                            .font(AppTheme.Typography.badge)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(tabBackground(isSelected: isSelected, chart: chart), in: shape)
                    .foregroundStyle(tabForeground(isSelected: isSelected, chart: chart))
                    .overlay(
                        shape.strokeBorder(
                            chart.difficulty.color.opacity(isSelected || isRemaster ? 1.0 : (colorScheme == .dark ? 0.75 : 0.45)),
                            lineWidth: isSelected ? 2 : 1
                        )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(chart.difficulty.shortName)，等级 \(chart.level)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func tabBackground(isSelected: Bool, chart: ResolvedChart) -> Color {
        if chart.difficulty == .remaster {
            if colorScheme == .dark && !isSelected { return chart.difficulty.color.opacity(0.26) }
            return isSelected ? Color.white : Color.white.opacity(0.65)
        }
        if isSelected { return chart.difficulty.solidFill(isDark: colorScheme == .dark) }
        return chart.difficulty.color.opacity(colorScheme == .dark ? 0.26 : 0.14)
    }

    private func tabForeground(isSelected: Bool, chart: ResolvedChart) -> Color {
        if chart.difficulty == .remaster {
            return colorScheme == .dark && !isSelected ? chart.difficulty.boardMainColor : AppTheme.Palette.chartRemaster
        }
        if isSelected { return chart.difficulty.readableForeground }
        return colorScheme == .dark ? chart.difficulty.boardMainColor : .primary
    }

    // MARK: - Segmented Tab Content

    @ViewBuilder
    private func tabContent(chart: ResolvedChart, genreColors: (bg: Color, stroke: Color)) -> some View {
        switch selectedTab {
        case .overview:
            overviewSection(chart: chart)
        case .rating:
            ratingSection(chart: chart)
        case .tolerance:
            if chart.totalWeightedScore > 0 {
                ChartToleranceCard(chart: chart, isDX: currentSong.isDX, tintColor: genreColors.bg)
            } else {
                AppSectionCard(title: "容错扣分参考") {
                    Text("当前谱面暂无物量数据")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Tab 1: Overview (Chart Info + Notes + Aliases)

    private func overviewSection(chart: ResolvedChart) -> some View {
        let record = store.record(forSongId: currentSong.numericId, difficultyIndex: chart.index)
        let fitDiff = store.chartStats[currentSong.numericId]?[safe: chart.index]?.fitDiff
        let versionInfo = MaimaiConstants.activeServerVersionDisplay(for: currentSong.basicInfo)
        let titleKey = currentSong.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let aliases = store.enableShowAlias
            ? (currentSong.alias ?? []).filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != titleKey }
            : []

        return VStack(spacing: AppTheme.cardSpacing) {
            AppSectionCard(title: "谱面信息") {
                VStack(spacing: AppTheme.itemSpacing) {
                    HStack(spacing: AppTheme.itemSpacing) {
                        AppMetricTile(title: "谱面定数") {
                            dsText(chart: chart)
                        }
                        AppMetricTile(title: "水鱼拟合定数") {
                            Text(fitDiff.map { String(format: "%.2f", $0) } ?? "—")
                                .font(AppTheme.Typography.statValue)
                                .foregroundStyle(.primary)
                                .contentTransition(.numericText())
                        }
                    }

                    AppInsetGroup {
                        VStack(spacing: 0) {
                            detailRow("收录版本") {
                                if let asset = versionInfo.asset {
                                    Image(asset)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 108, maxHeight: 22, alignment: .trailing)
                                        .accessibilityLabel(versionInfo.fallback)
                                } else {
                                    Text(versionInfo.fallback)
                                        .font(AppTheme.Typography.rowTitle)
                                        .foregroundStyle(.primary)
                                }
                            }

                            Divider().padding(.leading, AppTheme.Space.m)

                            detailRow("谱面作者") {
                                Text(chart.charter.isEmpty ? "—" : chart.charter)
                                    .font(AppTheme.Typography.rowTitle)
                                    .multilineTextAlignment(.trailing)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .onLongPressGesture { copyText(chart.charter, label: "谱面作者") }

                            Divider().padding(.leading, AppTheme.Space.m)

                            detailRow("我的成绩") {
                                recordSummary(record)
                            }
                        }
                    }
                }
            }

            ChartNotesBarCard(chart: chart, maxStats: store.maxNotesStats, barColor: chart.difficulty.color)

            if !aliases.isEmpty {
                AppSectionCard(title: "歌曲别名") {
                    FlowLayout(spacing: 6, lineSpacing: 6) {
                        ForEach(aliases, id: \.self) { alias in
                            GenreCapsuleTag(
                                genre: currentSong.basicInfo.genre,
                                text: alias,
                                style: .regular
                            )
                            .onLongPressGesture { copyText(alias, label: "别名") }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tab 2: Rating & B50 Gain Table

    @ViewBuilder
    private func ratingSection(chart: ResolvedChart) -> some View {
        if currentSong.isUtage || chart.ds <= 0 {
            AppSectionCard(title: "分段 Rating 对照") {
                Text("宴会场谱面不计入 Rating")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(.secondary)
            }
        } else {
            let record = store.record(forSongId: currentSong.numericId, difficultyIndex: chart.index)
            let baseline = store.b50BaselineRating(forSong: currentSong, difficultyIndex: chart.index)
            let rows = RatingCalculator.buildTierRows(
                ds: chart.ds,
                currentAchievement: record?.achievements,
                b50BaselineRating: baseline
            )

            AppSectionCard(title: "分段 Rating 对照") {
                AppCapsuleLabel(text: String(format: "定数 %.1f", chart.ds))
            } content: {
                RatingTierTable(rows: rows, showB50Column: store.isLoggedIn)
            }
        }
    }

    // MARK: - Helpers

    private func detailRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: AppTheme.Space.m) {
            Text(title)
                .font(AppTheme.Typography.inlineAction)
                .foregroundStyle(.secondary)
            Spacer(minLength: AppTheme.Space.m)
            content()
        }
        .padding(.horizontal, AppTheme.Space.m)
        .padding(.vertical, AppTheme.Space.s)
        .frame(maxWidth: .infinity, minHeight: 42)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func recordSummary(_ record: ProberRecord?) -> some View {
        if let record {
            HStack(spacing: AppTheme.Space.s) {
                Text(String(format: "%.4f%%", record.achievements))
                    .font(AppTheme.Typography.rowMetric)
                    .contentTransition(.numericText())
                RecordStatusBadges(record: record, size: .regular)
            }
        } else {
            Text("暂无成绩")
                .font(AppTheme.Typography.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func dsText(chart: ResolvedChart) -> some View {
        if let old = chart.oldDs, old > 0 {
            let deltaColor: Color = old < chart.ds ? AppTheme.Palette.deltaUp : (old > chart.ds ? AppTheme.Palette.deltaDown : .primary)
            let arrow = old < chart.ds ? "↑" : (old > chart.ds ? "↓" : "")
            HStack(spacing: AppTheme.Space.xs) {
                Text(String(format: "%.1f%@", chart.ds, arrow))
                    .font(AppTheme.Typography.statValue)
                    .foregroundStyle(deltaColor)
                    .contentTransition(.numericText())
                Text(String(format: "(旧 %.1f)", old))
                    .font(AppTheme.Typography.captionMono)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text(String(format: "%.1f", chart.ds))
                .font(AppTheme.Typography.statValue)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
    }

    private func copyText(_ value: String, label: String) {
        guard !value.isEmpty else { return }
        UIPasteboard.general.string = value
        copyTrigger += 1
        withAnimation {
            copiedToast = "已复制\(label)：\(value)"
        }
        Task {
            await dismissToast($copiedToast, after: 1.8, animated: true, ifContains: value)
        }
    }
}

private struct ChartNotesBarCard: View {
    let chart: ResolvedChart
    let maxStats: MaxNotesStats
    let barColor: Color

    var body: some View {
        let rows: [(String, Int, Int)] = [
            ("Total", chart.totalNotes, maxStats.total),
            ("Tap", chart.tap, maxStats.tap),
            ("Hold", chart.hold, maxStats.hold),
            ("Slide", chart.slide, maxStats.slide),
            ("Touch", chart.touch, maxStats.touch),
            ("Break", chart.breakCount, maxStats.breakCount)
        ]

        AppSectionCard(title: "物量分布") {
            Text("共 \(chart.totalNotes) Notes")
                .font(AppTheme.Typography.captionMeta)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        } content: {
            VStack(spacing: AppTheme.Space.s) {
                ForEach(rows, id: \.0) { label, value, maxValue in
                    HStack(spacing: AppTheme.itemSpacing) {
                        Text(label)
                            .font(AppTheme.Typography.captionMeta)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .trailing)

                        GeometryReader { geo in
                            let ratio = maxValue > 0 ? min(1.0, CGFloat(value) / CGFloat(maxValue)) : 0
                            let barW = value == 0 ? 0 : max(10, geo.size.width * ratio)
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.07))
                                Capsule()
                                    .fill(barColor.gradient)
                                    .frame(width: barW)
                                    .animation(.snappy(duration: 0.28), value: barW)
                            }
                        }
                        .frame(height: 12)

                        Text("\(value)")
                            .font(AppTheme.Typography.captionMeta)
                            .contentTransition(.numericText())
                            .frame(width: 40, alignment: .leading)
                    }
                }
            }
        }
    }
}

private struct ChartToleranceCard: View {
    let chart: ResolvedChart
    let isDX: Bool
    let tintColor: Color

    var body: some View {
        let total = Double(chart.totalWeightedScore)
        let brk = Double(chart.breakCount)

        AppSectionCard(
            title: "容错扣分参考",
            subtitle: "各判定单项损失达成率"
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Space.m) {
                AppInsetGroup {
                    VStack(spacing: 0) {
                        toleranceRow("音符", values: ["Great", "Good", "Miss"], isHeader: true)
                        Divider()
                        toleranceRow("Tap", values: [pct(1.0 / total * 0.2), pct(1.0 / total * 0.5), pct(1.0 / total)])
                        Divider()
                        toleranceRow("Hold", values: [pct(2.0 / total * 0.2), pct(2.0 / total * 0.5), pct(2.0 / total)])
                        Divider()
                        toleranceRow("Slide", values: [pct(3.0 / total * 0.2), pct(3.0 / total * 0.5), pct(3.0 / total)])
                    }
                }

                if brk > 0 {
                    Text("Break（绝赞）单项扣分")
                        .font(AppTheme.Typography.inlineAction)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    VStack(spacing: AppTheme.Space.s) {
                        // Row 1 (2 cells): Perfect -50 | Perfect -100
                        HStack(spacing: AppTheme.Space.s) {
                            breakCell(
                                label: "Perfect",
                                badge: "-50",
                                value: pct(0.01 / brk * 0.25),
                                tint: AppTheme.Palette.judgePerfect
                            )
                            breakCell(
                                label: "Perfect",
                                badge: "-100",
                                value: pct(0.01 / brk * 0.5),
                                tint: AppTheme.Palette.judgePerfect
                            )
                        }

                        // Row 2 (3 cells): Great 4x | 3x | 2.5x
                        HStack(spacing: AppTheme.Space.s) {
                            breakCell(
                                label: "Great",
                                badge: "4x",
                                value: pct(5.0 / total * 0.2 + (0.01 / brk) * 0.6),
                                tint: AppTheme.Palette.judgeGreat
                            )
                            breakCell(
                                label: "Great",
                                badge: "3x",
                                value: pct(5.0 / total * 0.4 + (0.01 / brk) * 0.6),
                                tint: AppTheme.Palette.judgeGreat
                            )
                            breakCell(
                                label: "Great",
                                badge: "2.5x",
                                value: pct(5.0 / total * 0.5 + (0.01 / brk) * 0.6),
                                tint: AppTheme.Palette.judgeGreat
                            )
                        }

                        // Row 3 (2 cells): Good | Miss
                        HStack(spacing: AppTheme.Space.s) {
                            breakCell(
                                label: "Good",
                                value: pct(5.0 / total * 0.6 + (0.01 / brk) * 0.7),
                                tint: AppTheme.Palette.judgeGood
                            )
                            breakCell(
                                label: "Miss",
                                value: pct(5.0 / total + 0.01 / brk),
                                tint: AppTheme.Palette.judgeMiss
                            )
                        }
                    }
                }

                if !isDX && chart.difficulty != .utage && chart.difficulty != .utagePlayer2 {
                    let num = Double(chart.tap * 500 + chart.hold * 1000 + chart.slide * 1500 + chart.breakCount * 2600)
                    let den = Double(chart.tap * 500 + chart.hold * 1000 + chart.slide * 1500 + chart.breakCount * 2500)
                    if den > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(AppTheme.Typography.caption2)
                            Text(String(format: "FiNALE 旧框理论值（全 2600）：%.2f%%", floor(num / den * 10000) / 100))
                                .font(AppTheme.Typography.captionMeta)
                        }
                        .foregroundStyle(tintColor)
                        .padding(.top, 2)
                    }
                }
            }
        }
    }

    private func breakCell(
        label: String,
        badge: String? = nil,
        value: String,
        tint: Color
    ) -> some View {
        AppInsetGroup(padding: AppTheme.itemSpacing) {
            VStack(alignment: .center, spacing: AppTheme.Space.xs) {
                HStack(spacing: AppTheme.Space.xs) {
                    Text(label)
                        .font(AppTheme.Typography.caption2Bold)
                        .foregroundStyle(.secondary)
                    if let badge {
                        AppCapsuleLabel(text: badge, tint: tint, style: .compact)
                    }
                }
                Text("-\(value)")
                    .font(AppTheme.Typography.captionMeta)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .accessibilityElement(children: .combine)
    }

    private func toleranceRow(
        _ label: String,
        values: [String],
        isHeader: Bool = false
    ) -> some View {
        HStack(spacing: AppTheme.Space.s) {
            Text(label)
                .foregroundStyle(isHeader ? .secondary : .primary)
                .frame(width: 48, alignment: .center)
            ForEach(values, id: \.self) { value in
                Text(isHeader ? value : "-\(value)")
                    .foregroundStyle(isHeader ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .minimumScaleFactor(0.85)
                    .contentTransition(.numericText())
            }
        }
        .font(isHeader ? AppTheme.Typography.captionBold : AppTheme.Typography.captionMono)
        .padding(.horizontal, AppTheme.Space.m)
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }

    private func pct(_ ratio: Double) -> String {
        String(format: "%.4f%%", ratio * 100)
    }
}
