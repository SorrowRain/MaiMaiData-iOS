import SwiftUI

struct VersionCheckView: View {
    @Environment(DataStore.self) private var store
    @State private var displayMode: CheckDisplayMode = .rank
    @State private var groupedSongs: [LevelGroup] = []

    private struct LevelGroup: Identifiable {
        var id: String { level }
        let level: String
        let songs: [SongData]
    }

    private var selectedVersion: (name: String, asset: String) {
        let idx = min(max(0, store.lastVersionCheckIndex), MaimaiConstants.cnVersions.count - 1)
        return MaimaiConstants.cnVersions[idx]
    }

    private func rebuildGroups() {
        let verName = selectedVersion.name
        let filtered = store.songs.filter { $0.basicInfo.from == verName && !$0.isUtage && $0.charts.count > 3 }
        let sorted = filtered.sorted { ($0.ds[safe: 3] ?? 0) > ($1.ds[safe: 3] ?? 0) }
        let dict = Dictionary(grouping: sorted) { $0.level[safe: 3] ?? "?" }
        groupedSongs = dict.keys.sorted { levelOrder($0) > levelOrder($1) }
            .map { LevelGroup(level: $0, songs: dict[$0] ?? []) }
    }

    var body: some View {
        @Bindable var storeBindable = store

        let allSongs = groupedSongs.flatMap(\.songs)
        let matchedRecords = allSongs.compactMap { store.record(forSongId: $0.numericId, difficultyIndex: 3) }
        let stats = ChecklistStats(records: matchedRecords, totalCount: allSongs.count)

        ScrollView {
            VStack(spacing: AppTheme.cardSpacing) {
                AppCard(padding: AppTheme.cardPadding, tint: DifficultyType.master.color) {
                    HStack(spacing: AppTheme.Space.m) {
                        Image(selectedVersion.asset)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 38)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedVersion.name)
                                .font(AppTheme.Typography.rowTitle)
                            Text("共 \(allSongs.count) 首 Master 曲目")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Menu {
                            Picker("版本", selection: $storeBindable.lastVersionCheckIndex) {
                                ForEach(Array(MaimaiConstants.cnVersions.enumerated()), id: \.offset) { idx, ver in
                                    Text(ver.name).tag(idx)
                                }
                            }
                        } label: {
                            AppMenuCapsule(title: "切换版本")
                        }
                    }
                }

                ChecklistStatsHeader(stats: stats, displayMode: $displayMode)

                ForEach(groupedSongs) { group in
                    AppSectionCard(title: "Level \(group.level)") {
                        AppCapsuleLabel(text: "\(group.songs.count) 首", tint: DifficultyType.master.color)
                    } content: {
                        ChecklistSongGrid {
                            ForEach(group.songs) { song in
                                NavigationLink(value: song) {
                                    ChecklistSongTile(
                                        song: song,
                                        record: store.record(forSongId: song.numericId, difficultyIndex: 3),
                                        borderColor: DifficultyType.master.color,
                                        displayMode: displayMode
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
        .navigationTitle("版本进度表 (MAS)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if groupedSongs.isEmpty && !store.songs.isEmpty {
                rebuildGroups()
            }
        }
        .onChange(of: store.lastVersionCheckIndex) { _, _ in rebuildGroups() }
        .onChange(of: store.songs.count) { _, _ in rebuildGroups() }
    }

    private func levelOrder(_ level: String) -> Double {
        if level.hasSuffix("+"), let num = Double(level.dropLast()) {
            return num + 0.5
        }
        return Double(level) ?? 0
    }
}
