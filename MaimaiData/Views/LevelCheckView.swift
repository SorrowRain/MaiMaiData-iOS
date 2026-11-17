import SwiftUI

struct LevelCheckView: View {
    @Environment(DataStore.self) private var store
    @State private var displayMode: CheckDisplayMode = .rank

    private var levels: [String] {
        Array(MaimaiConstants.allLevels.dropFirst()) // Drop "ALL"
    }

    private var currentLevelIndex: Int {
        min(max(0, store.lastLevelCheckIndex), levels.count - 1)
    }

    private var selectedLevel: String {
        levels[currentLevelIndex]
    }

    private struct ChartItem: Identifiable {
        var id: String { "\(song.id)_\(chart.index)" }
        let song: SongData
        let chart: ResolvedChart
    }

    private func makeChartItems() -> [ChartItem] {
        store.songs
            .filter { !$0.isUtage }
            .flatMap { song in
                song.resolvedCharts
                    .filter { $0.level == selectedLevel }
                    .map { ChartItem(song: song, chart: $0) }
            }
            .sorted { $0.chart.ds > $1.chart.ds }
    }

    var body: some View {
        @Bindable var storeBindable = store

        let chartItems = makeChartItems()
        let groupedByDS = Dictionary(grouping: chartItems) { $0.chart.ds }
        let sortedDSKeys = groupedByDS.keys.sorted(by: >)

        let songIds = Set(chartItems.map { $0.song.numericId })
        let levelRecords = store.records.filter { $0.level == selectedLevel && songIds.contains($0.songId) }
        let recordMap = Dictionary(
            levelRecords.map { ("\($0.songId)_\($0.levelIndex)", $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let stats = ChecklistStats(records: levelRecords, totalCount: chartItems.count)

        ScrollView {
            VStack(spacing: AppTheme.cardSpacing) {
                AppCard(padding: AppTheme.cardPadding, tint: AppTheme.Palette.noteHold) {
                    VStack(spacing: AppTheme.Space.m) {
                        HStack {
                            AppCircleIconButton(
                                systemImage: "chevron.left",
                                accessibilityLabel: "上一个等级",
                                isDisabled: currentLevelIndex == 0
                            ) {
                                if store.lastLevelCheckIndex > 0 {
                                    store.lastLevelCheckIndex -= 1
                                }
                            }

                            Spacer()
                            VStack(spacing: 2) {
                                Text("LEVEL \(selectedLevel)")
                                    .font(AppTheme.Typography.headlineBoldMonospaced)
                                Text("共 \(chartItems.count) 张谱面")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()

                            AppCircleIconButton(
                                systemImage: "chevron.right",
                                accessibilityLabel: "下一个等级",
                                isDisabled: currentLevelIndex == levels.count - 1
                            ) {
                                if store.lastLevelCheckIndex < levels.count - 1 {
                                    store.lastLevelCheckIndex += 1
                                }
                            }
                        }

                        Slider(
                            value: Binding(
                                get: { Double(currentLevelIndex) },
                                set: { storeBindable.lastLevelCheckIndex = Int($0.rounded()) }
                            ),
                            in: 0...Double(levels.count - 1),
                            step: 1
                        )
                        .tint(AppTheme.accent)
                    }
                }

                ChecklistStatsHeader(stats: stats, displayMode: $displayMode)

                ForEach(sortedDSKeys, id: \.self) { dsValue in
                    let items = groupedByDS[dsValue] ?? []
                    AppSectionCard(title: String(format: "定数 %.1f", dsValue)) {
                        AppCapsuleLabel(text: "\(items.count) 首")
                    } content: {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                            ForEach(items) { item in
                                NavigationLink(value: item.song) {
                                    ChecklistSongTile(
                                        song: item.song,
                                        record: recordMap["\(item.song.numericId)_\(item.chart.index)"],
                                        borderColor: item.chart.difficulty.color,
                                        displayMode: displayMode,
                                        showTypeBadge: true
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.vertical, AppTheme.Space.m)
        }
        .appPageBackground()
        .navigationTitle("等级进度表")
        .navigationBarTitleDisplayMode(.inline)
    }
}
