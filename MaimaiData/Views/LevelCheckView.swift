import SwiftUI

struct LevelCheckView: View {
    @Environment(DataStore.self) private var store
    @State private var displayMode: CheckDisplayMode = .rank
    @State private var dsGroups: [DSGroup] = []
    @State private var totalChartCount: Int = 0

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

    private struct DSGroup: Identifiable {
        var id: Double { ds }
        let ds: Double
        let items: [ChartItem]
    }

    private func rebuildGroups() {
        let level = selectedLevel
        let items = store.songs
            .filter { !$0.isUtage }
            .flatMap { song in
                song.resolvedCharts
                    .filter { $0.level == level }
                    .map { ChartItem(song: song, chart: $0) }
            }
            .sorted { $0.chart.ds > $1.chart.ds }

        let grouped = Dictionary(grouping: items) { $0.chart.ds }
        dsGroups = grouped.keys.sorted(by: >).map { DSGroup(ds: $0, items: grouped[$0] ?? []) }
        totalChartCount = items.count
    }

    var body: some View {
        @Bindable var storeBindable = store

        let matchedRecords = dsGroups.flatMap(\.items).compactMap {
            store.record(forSongId: $0.song.numericId, difficultyIndex: $0.chart.index)
        }
        let stats = ChecklistStats(records: matchedRecords, totalCount: totalChartCount)

        ScrollView {
            VStack(spacing: AppTheme.cardSpacing) {
                AppCard(padding: AppTheme.cardPadding, tint: AppTheme.Palette.progressAccent) {
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
                                    .font(AppTheme.Typography.sectionMetric)
                                Text("共 \(totalChartCount) 张谱面")
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

                ForEach(dsGroups) { group in
                    AppSectionCard(title: String(format: "定数 %.1f", group.ds)) {
                        AppCapsuleLabel(text: "\(group.items.count) 首")
                    } content: {
                        ChecklistSongGrid {
                            ForEach(group.items) { item in
                                NavigationLink(value: item.song) {
                                    ChecklistSongTile(
                                        song: item.song,
                                        record: store.record(forSongId: item.song.numericId, difficultyIndex: item.chart.index),
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
        .onAppear {
            if dsGroups.isEmpty && !store.songs.isEmpty {
                rebuildGroups()
            }
        }
        .onChange(of: store.lastLevelCheckIndex) { _, _ in rebuildGroups() }
        .onChange(of: store.songs.count) { _, _ in rebuildGroups() }
    }
}
