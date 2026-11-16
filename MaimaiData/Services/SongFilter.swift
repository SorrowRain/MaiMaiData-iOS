import Foundation

/// Pure filtering/sorting logic for the song list (no store state), so it can be unit tested.
enum SongFilter {
    static func apply(
        _ criteria: SongFilterCriteria,
        to songs: [SongData],
        favoriteIds: Set<String>,
        enableAliasSearch: Bool,
        enableCharterSearch: Bool
    ) -> [SongData] {
        let query = criteria.keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let expandedVersions = MaimaiConstants.expandVersionFilter(Array(criteria.selectedVersions))
        let targetDS = criteria.useExactDS ? (criteria.exactDS * 10).rounded() / 10 : nil
        let levelFilter = criteria.useExactDS ? nil : criteria.selectedLevel
        let seqDiff = criteria.sortOption.filterDifficulty

        let filtered = songs.filter { song in
            // 1. Genre (default excludes 宴会場 when no genre selected, matching Android DAO)
            if criteria.selectedGenres.isEmpty {
                if song.isUtage { return false }
            } else if !criteria.selectedGenres.contains(song.basicInfo.genre) {
                return false
            }

            // 2. Version
            if !expandedVersions.isEmpty && !expandedVersions.contains(song.basicInfo.from) {
                return false
            }

            // 3. Favorites
            if criteria.onlyFavorites && !favoriteIds.contains(song.id) {
                return false
            }

            // 4. Keyword
            if !query.isEmpty {
                let titleMatch = song.title.lowercased().contains(query)
                let aliasMatch = enableAliasSearch && (song.alias?.contains { $0.lowercased().contains(query) } ?? false)
                let charterMatch = enableCharterSearch && song.charts.contains { $0.charter.lowercased().contains(query) }
                let idMatch = song.id == query
                if !(titleMatch || aliasMatch || charterMatch || idMatch) {
                    return false
                }
            }

            // 5. Level or DS
            if let targetDS {
                if !song.ds.contains(where: { abs($0 - targetDS) < 0.001 }) {
                    return false
                }
            } else if let levelFilter, levelFilter != "ALL" {
                if let seqDiff {
                    let idx = seqDiff.rawValue
                    guard song.level.indices.contains(idx), song.level[idx] == levelFilter else {
                        return false
                    }
                } else if !song.level.contains(levelFilter) {
                    return false
                }
            }

            return true
        }

        switch criteria.sortOption {
        case .defaultDesc:
            return filtered.sorted { $0.numericId > $1.numericId }
        case .expertAsc:
            return filtered.sorted { ($0.ds[safe: 2] ?? 0) < ($1.ds[safe: 2] ?? 0) }
        case .expertDesc:
            return filtered.sorted { ($0.ds[safe: 2] ?? 0) > ($1.ds[safe: 2] ?? 0) }
        case .masterAsc:
            return filtered.sorted { ($0.ds[safe: 3] ?? 0) < ($1.ds[safe: 3] ?? 0) }
        case .masterDesc:
            return filtered.sorted { ($0.ds[safe: 3] ?? 0) > ($1.ds[safe: 3] ?? 0) }
        case .remasterAsc:
            return filtered.sorted { Self.compareRemaster($0, $1, ascending: true) }
        case .remasterDesc:
            return filtered.sorted { Self.compareRemaster($0, $1, ascending: false) }
        }
    }

    private static func compareRemaster(_ a: SongData, _ b: SongData, ascending: Bool) -> Bool {
        let aHas = a.ds.count >= 5
        let bHas = b.ds.count >= 5
        if aHas != bHas { return aHas }
        let aDs = a.ds[safe: 4] ?? 0
        let bDs = b.ds[safe: 4] ?? 0
        if aDs == bDs { return a.numericId > b.numericId }
        return ascending ? aDs < bDs : aDs > bDs
    }
}
