import Foundation

enum LXNSCatalogConverter {
    private static let genreMap: [String: String] = [
        "POPSアニメ": "流行&动漫",
        "niconicoボーカロイド": "niconico & VOCALOID",
        "東方Project": "东方Project",
        "ゲームバラエティ": "其他游戏",
        "maimai": "舞萌",
        "オンゲキCHUNITHM": "音击&中二节奏",
        "宴会場": MaimaiConstants.genreUtage
    ]

    private static let knownPlateMetadata: [String: (id: String, title: String, asset: String)] = [
        "真": ("真", "真 · maimai ~ PLUS", "maimai"),
        "超": ("超", "超 · GreeN", "maimai_green"),
        "檄": ("檄", "檄 · GreeN PLUS", "maimai_green_plus"),
        "橙": ("橙", "橙 · ORANGE", "maimai_orange"),
        "暁": ("暁", "暁 · ORANGE PLUS", "maimai_orange_plus"),
        "桃": ("桃", "桃 · PiNK", "maimai_pink"),
        "櫻": ("櫻", "櫻 · PiNK PLUS", "maimai_pink_plus"),
        "紫": ("紫", "紫 · MURASAKi", "maimai_murasaki"),
        "菫": ("菫", "菫 · MURASAKi PLUS", "maimai_murasaki_plus"),
        "白": ("白", "白 · MiLK", "maimai_milk"),
        "雪": ("雪", "雪 · MiLK PLUS", "maimai_milk_plus"),
        "輝": ("輝", "輝 · FiNALE", "maimai_finale"),
        "覇者/舞": ("舞", "舞 / 覇者 · 旧框全曲", "maimai_finale"),
        "熊/華": ("熊華", "熊 / 華 · 舞萌DX", "maimaidx_cn"),
        "爽/煌": ("爽煌", "爽 / 煌 · 舞萌DX 2021", "maimaidx_2021"),
        "宙/星": ("宙星", "宙 / 星 · 舞萌DX 2022", "maimaidx_2022"),
        "祭/祝": ("祭祝", "祭 / 祝 · 舞萌DX 2023", "maimaidx_2023"),
        "双/宴": ("双宴", "双 / 宴 · 舞萌DX 2024", "maimaidx_2024"),
        "鏡": ("鏡", "鏡 · 舞萌DX 2025", "maimaidx_2025")
    ]

    // MARK: - 1. CN Song & Alias Catalog Conversion

    static func convertCatalog(
        songResponse: LXNSSongListResponse,
        aliasResponse: LXNSAliasListResponse?,
        existingBaseline: [SongData] = [],
        previousVersionResponse: LXNSSongListResponse? = nil
    ) -> (songs: [SongData], latestMajorVersion: Int, latestVersionTitle: String) {
        let sortedVersions = songResponse.versions.sorted { $0.version < $1.version }
        let latestMajor = sortedVersions.last?.version ?? 25500
        let latestTitle = sortedVersions.last?.title ?? "舞萌DX 2026"

        var aliasByBaseId: [Int: [String]] = [:]
        if let aliasResponse {
            aliasByBaseId.reserveCapacity(aliasResponse.aliases.count)
            for item in aliasResponse.aliases where !item.aliases.isEmpty {
                aliasByBaseId[item.songId] = item.aliases
            }
        }

        // Detect whether the local baseline comes from an earlier major version (so its `ds` becomes the new `oldDs`),
        // or the same major version (so we preserve its existing `oldDs` and rich Utage comments).
        let existingById: [Int: SongData] = Dictionary(
            existingBaseline.compactMap { $0.numericId > 0 ? ($0.numericId, $0) : nil },
            uniquingKeysWith: { first, _ in first }
        )
        let existingMaxMajor: Int = existingBaseline.compactMap { Int($0.basicInfo.version) }.max() ?? latestMajor
        let didAdvanceMajorVersion = existingMaxMajor < latestMajor

        var explicitPreviousDs: [String: Double] = [:]
        if let previousVersionResponse {
            for prevSong in previousVersionResponse.songs {
                for diff in prevSong.difficulties.standard {
                    explicitPreviousDs["\(prevSong.id)_\(diff.difficulty)"] = diff.levelValue
                }
                let dxId = prevSong.id < 10_000 ? prevSong.id + 10_000 : prevSong.id
                for diff in prevSong.difficulties.dx {
                    explicitPreviousDs["\(dxId)_\(diff.difficulty)"] = diff.levelValue
                }
            }
        }

        func resolveFromName(for chartVersion: Int) -> String {
            guard !sortedVersions.isEmpty else { return "舞萌DX" }
            var matched = sortedVersions[0]
            for ver in sortedVersions {
                if ver.version <= chartVersion {
                    matched = ver
                } else {
                    break
                }
            }
            if matched.version >= 12_000 && matched.version < 20_000 && !matched.title.hasPrefix("maimai") {
                return "maimai \(matched.title)"
            }
            return matched.title
        }

        func resolveOldDs(songId: Int, chartCount: Int) -> [Double]? {
            if !explicitPreviousDs.isEmpty {
                let arr = (0..<chartCount).map { idx in explicitPreviousDs["\(songId)_\(idx)"] ?? 0 }
                return arr.contains(where: { $0 > 0 }) ? arr : nil
            }
            guard let existing = existingById[songId] else { return nil }
            let source = didAdvanceMajorVersion ? existing.ds : (existing.oldDs ?? [])
            guard !source.isEmpty else { return nil }
            let padded = (0..<chartCount).map { idx in source[safe: idx] ?? 0 }
            return padded.contains(where: { $0 > 0 }) ? padded : nil
        }

        var result: [SongData] = []
        result.reserveCapacity(songResponse.songs.count + 120)

        for song in songResponse.songs {
            let sid = song.id
            let mappedGenre = genreMap[song.genre] ?? song.genre
            let isDisabledFlag: Bool? = (song.disabled == true) ? true : nil
            let resolvedAliases = aliasByBaseId[sid] ?? existingById[sid]?.alias ?? existingById[sid + 10_000]?.alias

            // 1. Utage songs (id >= 100000)
            if sid >= 100_000 || !(song.difficulties.utage ?? []).isEmpty {
                guard let u = song.difficulties.utage?.first else { continue }
                let cver = u.version ?? song.version
                let fromName = resolveFromName(for: cver)
                let charter = (u.noteDesigner?.isEmpty == false) ? u.noteDesigner! : "-"
                let kanji = (u.kanji?.isEmpty == false) ? u.kanji : nil
                let existingComment = existingById[sid]?.comment
                let comment: String? = {
                    if let existingComment, !existingComment.isEmpty {
                        return existingComment
                    }
                    if let desc = u.description, !desc.isEmpty {
                        return desc
                    }
                    return nil
                }()

                let inferredDs = inferUtageDs(level: u.level, explicitValue: u.levelValue)
                var rawCharts: [SongData.RawChart] = []
                var dsList: [Double] = []
                var levelList: [String] = []

                switch u.notes {
                case .buddy(let left, let right) where u.isBuddy == true:
                    rawCharts.append(SongData.RawChart(charter: charter, notes: left.dxArray, kanji: kanji))
                    rawCharts.append(SongData.RawChart(charter: charter, notes: right.dxArray, kanji: kanji))
                    dsList = [inferredDs, inferredDs]
                    levelList = [u.level, u.level]
                case .buddy(let left, _):
                    rawCharts.append(SongData.RawChart(charter: charter, notes: left.dxArray, kanji: kanji))
                    dsList = [inferredDs]
                    levelList = [u.level]
                case .single(let notes):
                    rawCharts.append(SongData.RawChart(charter: charter, notes: notes.dxArray, kanji: kanji))
                    dsList = [inferredDs]
                    levelList = [u.level]
                case .none:
                    rawCharts.append(SongData.RawChart(charter: charter, notes: [0, 0, 0, 0, 0], kanji: kanji))
                    dsList = [inferredDs]
                    levelList = [u.level]
                }

                result.append(
                    SongData(
                        basicInfo: SongData.BasicInfo(
                            artist: song.artist,
                            bpm: song.bpm,
                            from: fromName,
                            genre: MaimaiConstants.genreUtage,
                            isNew: false,
                            title: song.title,
                            version: "\(cver)"
                        ),
                        charts: rawCharts,
                        ds: dsList,
                        oldDs: nil,
                        id: "\(sid)",
                        level: levelList,
                        title: song.title,
                        type: MaimaiConstants.chartTypeDX,
                        alias: resolvedAliases,
                        comment: comment,
                        isDisabled: isDisabledFlag
                    )
                )
                continue
            }

            // 2. Standard charts
            if !song.difficulties.standard.isEmpty {
                let stdDiffs = song.difficulties.standard.sorted { $0.difficulty < $1.difficulty }
                let cver = stdDiffs.first?.version ?? song.version
                let fromName = resolveFromName(for: cver)
                let isNew = cver >= latestMajor
                let charts = stdDiffs.map { diff in
                    SongData.RawChart(
                        charter: (diff.noteDesigner?.isEmpty == false) ? diff.noteDesigner! : "-",
                        notes: diff.notes?.sdArray ?? [0, 0, 0, 0]
                    )
                }
                result.append(
                    SongData(
                        basicInfo: SongData.BasicInfo(
                            artist: song.artist,
                            bpm: song.bpm,
                            from: fromName,
                            genre: mappedGenre,
                            isNew: isNew,
                            title: song.title,
                            version: "\(cver)"
                        ),
                        charts: charts,
                        ds: stdDiffs.map(\.levelValue),
                        oldDs: resolveOldDs(songId: sid, chartCount: stdDiffs.count),
                        id: "\(sid)",
                        level: stdDiffs.map(\.level),
                        title: song.title,
                        type: MaimaiConstants.chartTypeSD,
                        alias: resolvedAliases,
                        isDisabled: isDisabledFlag
                    )
                )
            }

            // 3. DX charts (`id < 10000` normalized to `id + 10000`)
            if !song.difficulties.dx.isEmpty {
                let dxDiffs = song.difficulties.dx.sorted { $0.difficulty < $1.difficulty }
                let dxSongId = sid < 10_000 ? sid + 10_000 : sid
                let cver = dxDiffs.first?.version ?? song.version
                let fromName = resolveFromName(for: cver)
                let isNew = cver >= latestMajor
                let charts = dxDiffs.map { diff in
                    SongData.RawChart(
                        charter: (diff.noteDesigner?.isEmpty == false) ? diff.noteDesigner! : "-",
                        notes: diff.notes?.dxArray ?? [0, 0, 0, 0, 0]
                    )
                }
                result.append(
                    SongData(
                        basicInfo: SongData.BasicInfo(
                            artist: song.artist,
                            bpm: song.bpm,
                            from: fromName,
                            genre: mappedGenre,
                            isNew: isNew,
                            title: song.title,
                            version: "\(cver)"
                        ),
                        charts: charts,
                        ds: dxDiffs.map(\.levelValue),
                        oldDs: resolveOldDs(songId: dxSongId, chartCount: dxDiffs.count),
                        id: "\(dxSongId)",
                        level: dxDiffs.map(\.level),
                        title: song.title,
                        type: MaimaiConstants.chartTypeDX,
                        alias: resolvedAliases,
                        isDisabled: isDisabledFlag
                    )
                )
            }
        }

        return (result, latestMajor, latestTitle)
    }

    // MARK: - 2. CN Official Plate Rules Extraction

    static func extractPlateCatalog(
        from response: LXNSPlateListResponse,
        updatedAt: String = Self.todayISOString()
    ) -> CNPlateCatalog {
        struct DraftGroup {
            var prefixes: [String]
            var description: String
            var badges: [String]
            var b2mOrdered: [Int]
            var b2mSet: Set<Int>
            var remOrdered: [Int]
            var remSet: Set<Int>
        }

        let validSuffixes = ["極", "将", "神", "舞舞"]
        var drafts: [DraftGroup] = []

        for plate in response.plates {
            guard plate.genre == "実績",
                  let reqs = plate.required,
                  let firstReq = reqs.first else { continue }
            let name = plate.name
            let isVersionPlate = (name == "覇者") || validSuffixes.contains(where: { name.hasSuffix($0) })
            guard isVersionPlate else { continue }

            let b2mIds = (firstReq.songs ?? []).map { normalizeSongId(id: $0.id, type: $0.type) }
            guard b2mIds.count > 1 else { continue }
            let remIds: [Int] = reqs.count > 1
                ? (reqs[1].songs ?? []).map { normalizeSongId(id: $0.id, type: $0.type) }
                : []

            let prefix = (name == "覇者") ? "覇者" : String(name.prefix(1))
            let b2mSet = Set(b2mIds)
            let remSet = Set(remIds)

            if let idx = drafts.firstIndex(where: { $0.b2mSet == b2mSet && $0.remSet == remSet }) {
                if !drafts[idx].prefixes.contains(prefix) {
                    drafts[idx].prefixes.append(prefix)
                }
                if !drafts[idx].badges.contains(name) {
                    drafts[idx].badges.append(name)
                }
            } else {
                drafts.append(
                    DraftGroup(
                        prefixes: [prefix],
                        description: plate.description ?? "",
                        badges: [name],
                        b2mOrdered: b2mIds,
                        b2mSet: b2mSet,
                        remOrdered: remIds,
                        remSet: remSet
                    )
                )
            }
        }

        let groups: [CNPlateRuleGroup] = drafts.map { draft in
            let key = draft.prefixes.joined(separator: "/")
            if let meta = knownPlateMetadata[key] {
                return CNPlateRuleGroup(
                    id: meta.id,
                    title: meta.title,
                    versionAsset: meta.asset,
                    badges: draft.badges,
                    basicToMasterSongIds: draft.b2mOrdered,
                    remasterSongIds: draft.remOrdered
                )
            }
            let gid = draft.prefixes.joined()
            let versionLabel: String = {
                if let range = draft.description.range(of: " 全曲") {
                    return String(draft.description[..<range.lowerBound])
                }
                return draft.description.components(separatedBy: "/").first ?? gid
            }()
            let asset = MaimaiConstants.cnVersionAsset(for: versionLabel) ?? "maimaidx_2026"
            return CNPlateRuleGroup(
                id: gid,
                title: "\(draft.prefixes.joined(separator: " / ")) · \(versionLabel)",
                versionAsset: asset,
                badges: draft.badges,
                basicToMasterSongIds: draft.b2mOrdered,
                remasterSongIds: draft.remOrdered
            )
        }

        return CNPlateCatalog(updatedAt: updatedAt, groups: groups)
    }

    // MARK: - 3. LXNS Player Score -> ProberRecord Conversion

    static func convertScores(
        _ scores: [LXNSScore],
        songsById: [Int: SongData]
    ) -> [ProberRecord] {
        var bestByKey: [String: ProberRecord] = [:]
        bestByKey.reserveCapacity(scores.count)

        for score in scores {
            let songId = normalizeSongId(id: score.id, type: score.type)
            let recordType = (score.type.lowercased() == "standard")
                ? MaimaiConstants.chartTypeSD
                : MaimaiConstants.chartTypeDX
            let song = songsById[songId]
            let ds = song?.ds[safe: score.levelIndex] ?? 0
            let level = song?.level[safe: score.levelIndex] ?? score.level ?? "-"
            let title = song?.title ?? score.songName ?? "Song #\(songId)"
            let fc = (score.fc ?? "").lowercased()
            let fs = (score.fs ?? "").lowercased()
            let rate = (score.rate?.isEmpty == false)
                ? score.rate!.lowercased()
                : fallbackRateString(for: score.achievements)
            let computedRa: Int = {
                if ds > 0 {
                    return RatingCalculator.singleSongRating(ds: ds, achievement: score.achievements)
                }
                if let dxRating = score.dxRating {
                    return Int(floor(dxRating))
                }
                return 0
            }()

            let record = ProberRecord(
                achievements: score.achievements,
                ds: ds,
                fc: fc,
                fs: fs,
                level: level,
                levelIndex: score.levelIndex,
                ra: computedRa,
                rate: rate,
                songId: songId,
                title: title,
                type: recordType
            )

            let key = "\(songId)_\(score.levelIndex)"
            if let existing = bestByKey[key], existing.achievements >= record.achievements {
                continue
            }
            bestByKey[key] = record
        }

        return Array(bestByKey.values)
    }

    // MARK: - Helpers

    static func normalizeSongId(id: Int, type: String) -> Int {
        let lower = type.lowercased()
        if lower == "utage" || id >= 100_000 {
            return id
        }
        if lower == "dx" && id < 10_000 {
            return id + 10_000
        }
        return id
    }

    private static func inferUtageDs(level: String, explicitValue: Double?) -> Double {
        if let explicitValue, explicitValue > 0 {
            return explicitValue
        }
        let cleaned = level.replacingOccurrences(of: "?", with: "").trimmingCharacters(in: .whitespaces)
        if cleaned.hasSuffix("+"), let base = Double(cleaned.dropLast()) {
            return base + 0.6
        }
        return Double(cleaned) ?? 0
    }

    static func fallbackRateString(for achievements: Double) -> String {
        let achi = Int((achievements * 10_000).rounded())
        switch achi {
        case 1_005_000...: return "sssp"
        case 1_000_000..<1_005_000: return "sss"
        case 995_000..<1_000_000: return "ssp"
        case 990_000..<995_000: return "ss"
        case 980_000..<990_000: return "sp"
        case 970_000..<980_000: return "s"
        case 940_000..<970_000: return "aaa"
        case 900_000..<940_000: return "aa"
        case 800_000..<900_000: return "a"
        case 750_000..<800_000: return "bbb"
        case 700_000..<750_000: return "bb"
        case 600_000..<700_000: return "b"
        case 500_000..<600_000: return "c"
        default: return "d"
        }
    }

    private static func todayISOString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
