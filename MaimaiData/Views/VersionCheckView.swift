import SwiftUI

struct VersionCheckView: View {
    @Environment(DataStore.self) private var store
    @State private var displayMode: CheckDisplayMode = .sss
    @State private var onlyUnfinished: Bool = false
    @State private var selectedDifficulty: DifficultyType = .master
    @State private var groupedSongs: [LevelGroup] = []

    private struct LevelGroup: Identifiable {
        var id: String { level }
        let level: String
        let songs: [SongData]
    }

    private struct CheckScopeItem {
        let title: String
        let asset: String
        let badgeSummary: String?
        let cnGroup: CNPlateRuleGroup?
    }

    private var scopeItems: [CheckScopeItem] {
        if store.serverRegion == .cn {
            let cnGroups = store.cnPlateCheckGroups
            if !cnGroups.isEmpty {
                return cnGroups.map { group in
                    CheckScopeItem(
                        title: group.title,
                        asset: group.versionAsset,
                        badgeSummary: group.badges.isEmpty ? nil : group.badgeSummary,
                        cnGroup: group
                    )
                }
            }
        }
        return MaimaiConstants.checklistVersions(for: store.serverRegion).map { ver in
            CheckScopeItem(title: ver.name, asset: ver.asset, badgeSummary: nil, cnGroup: nil)
        }
    }

    private var activeScope: CheckScopeItem {
        let items = scopeItems
        guard !items.isEmpty else {
            return CheckScopeItem(title: "舞萌DX", asset: "maimaidx_cn", badgeSummary: nil, cnGroup: nil)
        }
        let idx = min(max(0, store.activeVersionCheckIndex), items.count - 1)
        return items[idx]
    }

    private var availableDifficulties: [DifficultyType] {
        if let cnGroup = activeScope.cnGroup {
            if !cnGroup.remasterSongIds.isEmpty {
                return [.basic, .advanced, .expert, .master, .remaster]
            }
            return [.basic, .advanced, .expert, .master]
        }
        return [.basic, .advanced, .expert, .master, .remaster]
    }

    private func rebuildGroups() {
        if !availableDifficulties.contains(selectedDifficulty) {
            selectedDifficulty = .master
        }
        let diffIdx = selectedDifficulty.rawValue
        let filtered: [SongData]

        if let cnGroup = activeScope.cnGroup {
            let requiredIds = Set(
                selectedDifficulty == .remaster
                    ? cnGroup.remasterSongIds
                    : cnGroup.basicToMasterSongIds
            )
            filtered = store.songs.filter { song in
                !song.isUtage &&
                song.isDisabled != true &&
                requiredIds.contains(song.numericId) &&
                song.charts.count > diffIdx
            }
        } else {
            let verName = activeScope.title
            filtered = store.songs.filter { song in
                song.basicInfo.from == verName &&
                !song.isUtage &&
                song.isDisabled != true &&
                song.charts.count > diffIdx
            }
        }

        let sorted = filtered.sorted { ($0.ds[safe: diffIdx] ?? 0) > ($1.ds[safe: diffIdx] ?? 0) }
        let dict = Dictionary(grouping: sorted) { $0.level[safe: diffIdx] ?? "?" }
        groupedSongs = dict.keys.sorted { levelOrder($0) > levelOrder($1) }
            .map { LevelGroup(level: $0, songs: dict[$0] ?? []) }
    }

    var body: some View {
        @Bindable var storeBindable = store
        let diffIdx = selectedDifficulty.rawValue
        let diffTint = selectedDifficulty.color
        let items = scopeItems

        let allSongs = groupedSongs.flatMap(\.songs)
        let matchedRecords = allSongs.compactMap { store.record(forSongId: $0.numericId, difficultyIndex: diffIdx) }
        let stats = ChecklistStats(records: matchedRecords, totalCount: allSongs.count)

        let visibleGroups: [LevelGroup] = onlyUnfinished
            ? groupedSongs.compactMap { group in
                let remaining = group.songs.filter { song in
                    !displayMode.isCompleted(store.record(forSongId: song.numericId, difficultyIndex: diffIdx))
                }
                return remaining.isEmpty ? nil : LevelGroup(level: group.level, songs: remaining)
            }
            : groupedSongs

        let subtitleText: String = {
            if let badgeSummary = activeScope.badgeSummary {
                return "\(allSongs.count) 首 \(selectedDifficulty.shortName) · \(badgeSummary)"
            }
            return "共 \(allSongs.count) 首 \(selectedDifficulty.shortName) 曲目"
        }()

        ScrollView {
            VStack(spacing: AppTheme.cardSpacing) {
                AppCard(padding: AppTheme.cardPadding, tint: diffTint) {
                    VStack(alignment: .leading, spacing: AppTheme.Space.m) {
                        HStack(spacing: AppTheme.Space.m) {
                            Image(activeScope.asset)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(activeScope.title)
                                    .font(AppTheme.Typography.rowTitle)
                                    .lineLimit(1)
                                Text(subtitleText)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }

                        HStack(spacing: AppTheme.Space.s) {
                            Menu {
                                Picker("版本或牌子", selection: $storeBindable.activeVersionCheckIndex) {
                                    ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                                        Text(item.title).tag(idx)
                                    }
                                }
                            } label: {
                                AppMenuCapsule(title: store.serverRegion == .cn ? "切换牌子" : "切换版本")
                            }

                            Menu {
                                Picker("难度", selection: $selectedDifficulty) {
                                    ForEach(availableDifficulties, id: \.self) { diff in
                                        Text(diff.shortName).tag(diff)
                                    }
                                }
                            } label: {
                                AppMenuCapsule(title: selectedDifficulty.shortName, tint: diffTint)
                            }

                            Spacer()
                        }
                    }
                }

                ChecklistStatsHeader(
                    stats: stats,
                    displayMode: $displayMode,
                    onlyUnfinished: $onlyUnfinished
                )

                if visibleGroups.isEmpty && !allSongs.isEmpty {
                    ContentUnavailableView(
                        "已全部达成 \(displayMode.title)",
                        systemImage: "checkmark.seal.fill",
                        description: Text("当前筛选下全部 \(selectedDifficulty.shortName) 谱面均已达成该目标")
                    )
                    .padding(.top, AppTheme.Space.xl)
                } else {
                    ForEach(visibleGroups) { group in
                        AppSectionCard(title: "Level \(group.level)") {
                            AppCapsuleLabel(text: "\(group.songs.count) 首", tint: diffTint)
                        } content: {
                            ChecklistSongGrid {
                                ForEach(group.songs) { song in
                                    NavigationLink(value: SongDetailRoute(song: song, initialDifficulty: selectedDifficulty)) {
                                        ChecklistSongTile(
                                            song: song,
                                            record: store.record(forSongId: song.numericId, difficultyIndex: diffIdx),
                                            borderColor: diffTint,
                                            displayMode: displayMode,
                                            region: store.serverRegion
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.vertical, AppTheme.Space.m)
        }
        .appPageBackground()
        .sensoryFeedback(.selection, trigger: store.activeVersionCheckIndex)
        .sensoryFeedback(.selection, trigger: selectedDifficulty)
        .navigationTitle(store.serverRegion == .cn ? "牌子与版本进度" : "版本进度表")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if groupedSongs.isEmpty && !store.songs.isEmpty {
                rebuildGroups()
            }
        }
        .onChange(of: store.activeVersionCheckIndex) { _, _ in rebuildGroups() }
        .onChange(of: selectedDifficulty) { _, _ in rebuildGroups() }
        .onChange(of: store.serverRegion) { _, _ in rebuildGroups() }
        .onChange(of: store.catalogRevision) { _, _ in rebuildGroups() }
    }

    private func levelOrder(_ level: String) -> Double {
        if level.hasSuffix("+"), let num = Double(level.dropLast()) {
            return num + 0.5
        }
        return Double(level) ?? 0
    }
}
