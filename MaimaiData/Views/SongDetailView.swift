import SwiftUI

struct SongDetailView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    let song: SongData

    @State private var selectedChartIndex: Int = 0
    @State private var showCoverZoom = false
    @State private var copiedToast: String?

    private var chartsDesc: [ResolvedChart] {
        Array(song.resolvedCharts.reversed())
    }

    var body: some View {
        let genreColors = MaimaiConstants.genreColors(for: song.basicInfo.genre)

        ScrollView {
            VStack(spacing: AppTheme.cardSpacing) {
                headerCard(genreColors: genreColors)

                if store.enableShowAlias, let aliases = song.alias, !aliases.isEmpty {
                    aliasCard(aliases: aliases, genreColors: genreColors)
                }

                versionCard()

                if !chartsDesc.isEmpty {
                    difficultyPicker

                    let currentIndex = min(selectedChartIndex, chartsDesc.count - 1)
                    let chart = chartsDesc[currentIndex]
                    chartDetailSection(chart: chart, genreColors: genreColors)
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.vertical, 12)
        }
        .appPageBackground(tint: genreColors.bg)
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(song)
                } label: {
                    Image(systemName: store.isFavorite(song) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(song) ? AppTheme.favoritePink : .primary)
                }
                .accessibilityLabel(store.isFavorite(song) ? "取消收藏" : "收藏歌曲")
            }
        }
        .overlay(alignment: .bottom) {
            if let copiedToast {
                StatusToast(text: copiedToast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: $showCoverZoom) {
            CoverZoomView(song: song)
        }
    }

    // MARK: - Hero Header Card

    private func headerCard(genreColors: (bg: Color, stroke: Color)) -> some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Button {
                    showCoverZoom = true
                } label: {
                    SongCoverBadgeView(
                        song: song,
                        size: .hero,
                        borderColor: genreColors.stroke,
                        showCornerTypeBadge: true
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("放大查看《\(song.title)》封面")

                VStack(alignment: .leading, spacing: 6) {
                    Text(song.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .onLongPressGesture { copyText(song.title, label: "歌曲名") }

                    Text(song.basicInfo.artist)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                        .onLongPressGesture { copyText(song.basicInfo.artist, label: "曲师") }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                factPill(label: "BPM", value: "\(song.basicInfo.bpm)")
                factPill(label: "歌曲分类", value: song.basicInfo.genre)
                factPill(label: "歌曲 ID", value: song.id)
                    .onLongPressGesture { copyText(song.id, label: "歌曲 ID") }
            }
        }
        .padding(AppTheme.cardPadding)
        .background(
            LinearGradient(
                colors: [genreColors.bg, genreColors.bg.opacity(0.84)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: shape
        )
        .overlay(
            shape.strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
        )
    }

    private func factPill(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: AppTheme.Radius.inset, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.inset, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Alias & Version Cards

    private func aliasCard(aliases: [String], genreColors: (bg: Color, stroke: Color)) -> some View {
        let genre = song.basicInfo.genre
        return AppSectionCard(title: "歌曲别名") {
            EmptyView()
        } content: {
            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(aliases, id: \.self) { alias in
                    Text(alias)
                        .font(AppTheme.Typography.tag)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .modifier(GenreTagChrome(genre: genre, lightFill: 0.13, lightStroke: 0.28))
                        .onLongPressGesture { copyText(alias, label: "别名") }
                }
            }
        }
    }

    private func versionCard() -> some View {
        AppSectionCard(title: "收录版本") {
            EmptyView()
        } content: {
            HStack(alignment: .center, spacing: 10) {
                versionBox(
                    title: "日服收录",
                    asset: MaimaiConstants.jpVersionAsset(for: song.basicInfo.version),
                    fallback: "暂无数据"
                )
                versionBox(
                    title: "国服收录",
                    asset: MaimaiConstants.cnVersionAsset(for: song.basicInfo.from),
                    fallback: song.basicInfo.from.isEmpty ? "暂无数据" : song.basicInfo.from
                )
            }
        }
    }

    private func versionBox(title: String, asset: String?, fallback: String) -> some View {
        AppInsetGroup(padding: 10) {
            VStack(alignment: .center, spacing: 6) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                ZStack {
                    if let asset {
                        Image(asset)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 108, maxHeight: 36)
                            .accessibilityLabel(fallback)
                    } else {
                        Text(fallback)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .center)
            }
        }
    }

    // MARK: - Difficulty Switcher

    private var difficultyPicker: some View {
        HStack(spacing: 8) {
            ForEach(Array(chartsDesc.enumerated()), id: \.element.id) { idx, chart in
                let isSelected = idx == min(selectedChartIndex, chartsDesc.count - 1)
                let isRemaster = chart.difficulty == .remaster
                let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.chip, style: .continuous)
                Button {
                    selectedChartIndex = idx
                } label: {
                    VStack(spacing: 2) {
                        Text(chart.difficulty.shortName)
                            .font(.caption.weight(.bold))
                        Text(chart.level)
                            .font(.caption2.weight(.semibold).monospacedDigit())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(tabBackground(isSelected: isSelected, chart: chart), in: shape)
                    .foregroundStyle(tabForeground(isSelected: isSelected, chart: chart))
                    .overlay(
                        shape.strokeBorder(
                            chart.difficulty.color.opacity(isSelected || isRemaster ? 1.0 : 0.45),
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
            if colorScheme == .dark && !isSelected { return chart.difficulty.color.opacity(0.22) }
            return isSelected ? Color.white : Color.white.opacity(0.65)
        }
        if isSelected { return chart.difficulty.solidFill(isDark: colorScheme == .dark) }
        return chart.difficulty.color.opacity(colorScheme == .dark ? 0.22 : 0.14)
    }

    private func tabForeground(isSelected: Bool, chart: ResolvedChart) -> Color {
        if chart.difficulty == .remaster {
            return colorScheme == .dark && !isSelected ? chart.difficulty.boardMainColor : AppTheme.Palette.chartRemaster
        }
        if isSelected { return chart.difficulty.readableForeground }
        return colorScheme == .dark ? chart.difficulty.boardMainColor : .primary
    }

    // MARK: - Chart Details

    @ViewBuilder
    private func chartDetailSection(chart: ResolvedChart, genreColors: (bg: Color, stroke: Color)) -> some View {
        let record = store.record(forSongId: song.numericId, difficultyIndex: chart.index)
        let fitDiff = store.chartStats[song.numericId]?[safe: chart.index]?.fitDiff

        VStack(spacing: AppTheme.cardSpacing) {
            AppSectionCard(title: "谱面信息") {
                EmptyView()
            } content: {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        metricBox(title: "谱面定数") {
                            dsText(chart: chart)
                        }
                        metricBox(title: "水鱼拟合定数") {
                            Text(fitDiff.map { String(format: "%.2f", $0) } ?? "—")
                                .font(.callout.weight(.bold).monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }

                    AppInsetGroup(padding: 12) {
                        VStack(spacing: 10) {
                            detailRow("谱面作者") {
                                Text(chart.charter.isEmpty ? "—" : chart.charter)
                                    .font(.subheadline.weight(.medium))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .contentShape(Rectangle())
                            .onLongPressGesture { copyText(chart.charter, label: "谱面作者") }

                            Divider()

                            detailRow("我的成绩") {
                                recordSummary(record)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            ChartNotesBarCard(chart: chart, maxStats: store.maxNotesStats, barColor: chart.difficulty.color)

            if chart.totalWeightedScore > 0 {
                ChartToleranceCard(chart: chart, tintColor: genreColors.bg)
            }
        }
    }

    private func metricBox<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        AppInsetGroup(padding: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                content()
            }
        }
    }

    private func detailRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func recordSummary(_ record: ProberRecord?) -> some View {
        if let record {
            HStack(spacing: 8) {
                Text(String(format: "%.4f%%", record.achievements))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                Image(record.rankAssetName)
                    .resizable().scaledToFit().frame(height: 20)
                    .accessibilityLabel("评级 \(record.rate)")
                if let fc = record.fcAssetName {
                    Image(fc)
                        .resizable().scaledToFit().frame(height: 22)
                        .accessibilityLabel("连击状态 \(record.fc)")
                }
                if let fs = record.fsAssetName {
                    Image(fs)
                        .resizable().scaledToFit().frame(height: 22)
                        .accessibilityLabel("同步状态 \(record.fs)")
                }
            }
        } else {
            Text("暂无成绩")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func dsText(chart: ResolvedChart) -> some View {
        if let old = chart.oldDs, old > 0 {
            let deltaColor: Color = old < chart.ds ? AppTheme.Palette.deltaUp : (old > chart.ds ? AppTheme.Palette.deltaDown : .primary)
            let arrow = old < chart.ds ? "↑" : (old > chart.ds ? "↓" : "")
            HStack(spacing: 4) {
                Text(String(format: "%.1f%@", chart.ds, arrow))
                    .font(.callout.weight(.bold).monospacedDigit())
                    .foregroundStyle(deltaColor)
                Text(String(format: "(旧 %.1f)", old))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        } else {
            Text(String(format: "%.1f", chart.ds))
                .font(.callout.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
        }
    }

    private func copyText(_ value: String, label: String) {
        UIPasteboard.general.string = value
        withAnimation {
            copiedToast = "已复制\(label)：\(value)"
        }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation {
                if copiedToast?.contains(value) == true {
                    copiedToast = nil
                }
            }
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
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
        } content: {
            VStack(spacing: 8) {
                ForEach(rows, id: \.0) { label, value, maxValue in
                    HStack(spacing: 10) {
                        Text(label)
                            .font(.caption.weight(.semibold).monospaced())
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
                            }
                        }
                        .frame(height: 12)

                        Text("\(value)")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .frame(width: 40, alignment: .leading)
                    }
                }
            }
        }
    }
}

private struct ChartToleranceCard: View {
    let chart: ResolvedChart
    let tintColor: Color

    var body: some View {
        let total = Double(chart.totalWeightedScore)
        let brk = Double(chart.breakCount)

        AppSectionCard(
            title: "容错扣分参考",
            subtitle: "各判定单项损失达成率"
        ) {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 12) {
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
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    AppInsetGroup {
                        VStack(spacing: 0) {
                            breakToleranceRow("Great", detail: "4x", value: pct(5.0 / total * 0.2 + (0.01 / brk) * 0.6), color: AppTheme.Palette.judgeGreat)
                            Divider()
                            breakToleranceRow("Great", detail: "3x", value: pct(5.0 / total * 0.4 + (0.01 / brk) * 0.6), color: AppTheme.Palette.judgeGreat)
                            Divider()
                            breakToleranceRow("Great", detail: "2.5x", value: pct(5.0 / total * 0.5 + (0.01 / brk) * 0.6), color: AppTheme.Palette.judgeGreat)
                            Divider()
                            breakToleranceRow("Good", value: pct(5.0 / total * 0.6 + (0.01 / brk) * 0.7), color: AppTheme.Palette.judgeGood)
                            Divider()
                            breakToleranceRow("Miss", value: pct(5.0 / total + 0.01 / brk), color: AppTheme.Palette.judgeMiss)
                            Divider()
                            breakToleranceRow("小P", detail: "-50", value: pct(0.01 / brk * 0.25), color: AppTheme.Palette.judgePerfect)
                            Divider()
                            breakToleranceRow("大P", detail: "-100", value: pct(0.01 / brk * 0.5), color: AppTheme.Palette.judgePerfect)
                        }
                    }
                }

                if !songIsDX {
                    let num = Double(chart.tap * 500 + chart.hold * 1000 + chart.slide * 1500 + chart.breakCount * 2600)
                    let den = Double(chart.tap * 500 + chart.hold * 1000 + chart.slide * 1500 + chart.breakCount * 2500)
                    if den > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text(String(format: "FiNALE 旧框理论值（全 2600）：%.2f%%", floor(num / den * 10000) / 100))
                                .font(.caption.monospacedDigit().weight(.semibold))
                        }
                        .foregroundStyle(tintColor)
                        .padding(.top, 2)
                    }
                }
            }
        }
    }

    private func breakToleranceRow(
        _ label: String,
        detail: String = "",
        value: String,
        color: Color
    ) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            if !detail.isEmpty {
                AppCapsuleLabel(text: detail, tint: color, font: .caption2.weight(.bold), backgroundOpacity: 0.14, horizontalPadding: 6, verticalPadding: 2)
            }
            Spacer(minLength: 0)
            Text(value)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }

    private func toleranceRow(
        _ label: String,
        values: [String],
        isHeader: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .foregroundStyle(isHeader ? .secondary : .primary)
                .frame(width: 48, alignment: .leading)
            ForEach(values, id: \.self) { value in
                Text(value)
                    .foregroundStyle(isHeader ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.85)
            }
        }
        .font(isHeader ? .caption.weight(.bold) : .caption.monospacedDigit())
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }

    private var songIsDX: Bool {
        chart.touch > 0 || chart.difficulty == .utage || chart.difficulty == .utagePlayer2
    }

    private func pct(_ ratio: Double) -> String {
        String(format: "%.4f%%", ratio * 100)
    }
}
