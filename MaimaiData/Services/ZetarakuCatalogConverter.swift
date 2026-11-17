import Foundation

struct ZetarakuCatalog: Codable, Sendable {
    let songs: [ZetarakuSong]
    let updateTime: String?
}

struct ZetarakuSong: Codable, Sendable {
    let songId: String
    let category: String
    let title: String
    let artist: String
    let bpm: Double?
    let imageName: String
    let version: String
    let releaseDate: String?
    let sheets: [ZetarakuSheet]
}

struct ZetarakuSheet: Codable, Sendable {
    let type: String
    let difficulty: String
    let level: String
    let levelValue: Double?
    let internalLevelValue: Double?
    let noteDesigner: String?
    let noteCounts: ZetarakuNoteCounts?
    let regions: ZetarakuRegions
    let regionOverrides: ZetarakuRegionOverrides?
    let version: String?
}

struct ZetarakuNoteCounts: Codable, Sendable {
    let tap: Int?
    let hold: Int?
    let slide: Int?
    let touch: Int?
    let breakCount: Int?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case tap, hold, slide, touch
        case breakCount = "break"
        case total
    }
}

struct ZetarakuRegions: Codable, Sendable {
    let jp: Bool?
    let intl: Bool?
    let usa: Bool?
    let cn: Bool?
}

struct ZetarakuRegionOverrides: Codable, Sendable {
    let intl: ZetarakuSheetOverride?
}

struct ZetarakuSheetOverride: Codable, Sendable {
    let level: String?
    let levelValue: Double?
    let internalLevelValue: Double?
    let version: String?
}

/// Pure converter transforming Zetaraku `maimai/data.json` into `[SongData]` for `.jp` or `.intl`,
/// joining CN Diving-Fish IDs, community aliases, and CN baseline constants (`oldDs`).
enum ZetarakuCatalogConverter {
    private struct CNLookupKey: Hashable {
        let title: String
        let genre: String
        let type: String
    }

    private static let difficultyOrder: [String: Int] = [
        "basic": 0,
        "advanced": 1,
        "expert": 2,
        "master": 3,
        "remaster": 4
    ]

    static func mapCategoryToCNGenre(_ category: String) -> String {
        switch category {
        case "POPS＆アニメ":
            return "流行&动漫"
        case "niconico＆ボーカロイド":
            return "niconico & VOCALOID"
        case "東方Project":
            return "东方Project"
        case "ゲーム＆バラエティ":
            return "其他游戏"
        case "maimai":
            return "舞萌"
        case "オンゲキ＆CHUNITHM":
            return "音击&中二节奏"
        case "宴会場":
            return MaimaiConstants.genreUtage
        default:
            return category
        }
    }

    /// Post-`CiRCLE` SEGA rule: `B15` covers the active version plus 1 immediately preceding half-version.
    static func isB15NewVersion(_ version: String, region: MaimaiConstants.ServerRegion) -> Bool {
        switch region {
        case .cn:
            return false
        case .jp:
            return version == "MAGiCAL" || version == "CiRCLE PLUS"
        case .intl:
            return version == "CiRCLE PLUS" || version == "CiRCLE" || version == "MAGiCAL"
        }
    }

    static func convert(
        _ catalog: ZetarakuCatalog,
        region: MaimaiConstants.ServerRegion,
        cnReference: [SongData]
    ) -> [SongData] {
        let enrichedCN = SongData.mergingCounterpartAliases(cnReference)

        var cnByExactKey: [CNLookupKey: SongData] = [:]
        var cnShareableAliasesBySong: [String: [String]] = [:]
        var cnUtageByTitle: [String: SongData] = [:]
        cnByExactKey.reserveCapacity(enrichedCN.count)

        for cnSong in enrichedCN {
            if cnSong.isUtage {
                cnUtageByTitle[cnSong.title] = cnSong
            } else {
                let key = CNLookupKey(
                    title: cnSong.title,
                    genre: cnSong.basicInfo.genre,
                    type: cnSong.type
                )
                cnByExactKey[key] = cnSong
                if let aliases = cnSong.alias, !aliases.isEmpty {
                    let songGroupKey = "\(cnSong.title)|\(cnSong.basicInfo.genre)"
                    let filtered = aliases.filter { raw in
                        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        return !lower.hasPrefix("标") && !lower.hasPrefix("sd") && !lower.hasPrefix("dx")
                    }
                    if !filtered.isEmpty, cnShareableAliasesBySong[songGroupKey] == nil {
                        cnShareableAliasesBySong[songGroupKey] = filtered
                    }
                }
            }
        }

        var versionRank: [String: Int] = [:]
        for (idx, item) in MaimaiConstants.jpVersions.enumerated() {
            versionRank[item.name] = idx
        }

        var output: [SongData] = []
        output.reserveCapacity(catalog.songs.count + 256)

        for (catalogIdx, zSong) in catalog.songs.enumerated() {
            let activeSheets = zSong.sheets.filter { isSheetAvailable($0, in: region) }
            guard !activeSheets.isEmpty else { continue }

            let mappedGenre = mapCategoryToCNGenre(zSong.category)
            let bpmInt = Int((zSong.bpm ?? 0).rounded())

            for sheetType in ["std", "dx", "utage"] {
                let rawGroup = activeSheets.filter { $0.type == sheetType }
                guard !rawGroup.isEmpty else { continue }

                if sheetType == "utage" {
                    let matchedCN = cnUtageByTitle[zSong.title]
                    let fromVersion = effectiveVersion(of: rawGroup[0], songVersion: zSong.version, region: region)
                    let vRank = versionRank[fromVersion] ?? 0
                    let sortOrder = vRank * 100_000 + catalogIdx * 2

                    let charts: [SongData.RawChart] = rawGroup.enumerated().map { idx, sh in
                        let charter = cleanedCharter(sh.noteDesigner)
                        if let nc = sh.noteCounts, nc.total != nil {
                            return SongData.RawChart(
                                charter: charter,
                                notes: [nc.tap ?? 0, nc.hold ?? 0, nc.slide ?? 0, nc.touch ?? 0, nc.breakCount ?? 0]
                            )
                        } else if let cnChart = matchedCN?.charts[safe: idx] {
                            return cnChart
                        } else {
                            return SongData.RawChart(charter: charter, notes: [0, 0, 0, 0, 0])
                        }
                    }

                    let levels = rawGroup.map { effectiveLevel(of: $0, region: region) }
                    let dsValues = rawGroup.map { effectiveDS(of: $0, region: region) }

                    let basic = SongData.BasicInfo(
                        artist: zSong.artist,
                        bpm: bpmInt,
                        from: fromVersion,
                        genre: MaimaiConstants.genreUtage,
                        isNew: false,
                        title: zSong.title,
                        version: fromVersion
                    )

                    output.append(
                        SongData(
                            basicInfo: basic,
                            charts: charts,
                            ds: dsValues,
                            oldDs: nil,
                            id: matchedCN?.id ?? "zeta_utage_\(zSong.songId)",
                            level: levels,
                            title: zSong.title,
                            type: MaimaiConstants.chartTypeDX,
                            alias: matchedCN?.alias,
                            remoteCoverName: zSong.imageName,
                            sortOrder: sortOrder
                        )
                    )
                } else {
                    let sortedSheets = rawGroup.sorted {
                        (difficultyOrder[$0.difficulty] ?? 99) < (difficultyOrder[$1.difficulty] ?? 99)
                    }
                    let isDX = (sheetType == "dx")
                    let mappedType = isDX ? MaimaiConstants.chartTypeDX : MaimaiConstants.chartTypeSD
                    let cnLookupTitle = (zSong.songId == "Link (2)") ? "Link(CoF)" : zSong.title
                    let matchedCN = cnByExactKey[
                        CNLookupKey(title: cnLookupTitle, genre: mappedGenre, type: mappedType)
                    ]

                    let fromVersion = effectiveVersion(of: sortedSheets[0], songVersion: zSong.version, region: region)
                    let vRank = versionRank[fromVersion] ?? 0
                    let sortOrder = vRank * 100_000 + catalogIdx * 2 + (isDX ? 1 : 0)

                    let charts: [SongData.RawChart] = sortedSheets.map { sh in
                        let nc = sh.noteCounts
                        let tap = nc?.tap ?? 0
                        let hold = nc?.hold ?? 0
                        let slide = nc?.slide ?? 0
                        let touch = nc?.touch ?? 0
                        let brk = nc?.breakCount ?? 0
                        let notes = isDX ? [tap, hold, slide, touch, brk] : [tap, hold, slide, brk]
                        return SongData.RawChart(
                            charter: cleanedCharter(sh.noteDesigner),
                            notes: notes
                        )
                    }

                    let levels = sortedSheets.map { effectiveLevel(of: $0, region: region) }
                    let dsValues = sortedSheets.map { effectiveDS(of: $0, region: region) }
                    let cnBaselineDs: [Double]? = matchedCN.map { cn in
                        sortedSheets.indices.map { idx in cn.ds[safe: idx] ?? 0 }
                    }

                    var resolvedAliases = matchedCN?.alias ?? cnShareableAliasesBySong["\(cnLookupTitle)|\(mappedGenre)"]
                    if zSong.songId == "Link (2)" {
                        var list = resolvedAliases ?? []
                        if !list.contains(where: { $0.caseInsensitiveCompare("Link(CoF)") == .orderedSame }) {
                            list.insert("Link(CoF)", at: 0)
                        }
                        resolvedAliases = list
                    }

                    let basic = SongData.BasicInfo(
                        artist: zSong.artist,
                        bpm: bpmInt,
                        from: fromVersion,
                        genre: mappedGenre,
                        isNew: isB15NewVersion(fromVersion, region: region),
                        title: zSong.title,
                        version: fromVersion
                    )

                    output.append(
                        SongData(
                            basicInfo: basic,
                            charts: charts,
                            ds: dsValues,
                            oldDs: cnBaselineDs,
                            id: matchedCN?.id ?? "zeta_\(sheetType)_\(zSong.songId)",
                            level: levels,
                            title: zSong.title,
                            type: mappedType,
                            alias: resolvedAliases,
                            remoteCoverName: zSong.imageName,
                            sortOrder: sortOrder
                        )
                    )
                }
            }
        }

        return output
    }

    private static func isSheetAvailable(_ sheet: ZetarakuSheet, in region: MaimaiConstants.ServerRegion) -> Bool {
        switch region {
        case .intl:
            return sheet.regions.intl == true
        case .jp, .cn:
            return sheet.regions.jp == true
        }
    }

    private static func effectiveVersion(
        of sheet: ZetarakuSheet,
        songVersion: String,
        region: MaimaiConstants.ServerRegion
    ) -> String {
        if region == .intl,
           let intlVer = sheet.regionOverrides?.intl?.version,
           !intlVer.isEmpty {
            return intlVer
        }
        if let sheetVer = sheet.version, !sheetVer.isEmpty {
            return sheetVer
        }
        return songVersion
    }

    private static func effectiveLevel(of sheet: ZetarakuSheet, region: MaimaiConstants.ServerRegion) -> String {
        if region == .intl,
           let intlLv = sheet.regionOverrides?.intl?.level,
           !intlLv.isEmpty {
            return intlLv
        }
        return sheet.level
    }

    private static func effectiveDS(of sheet: ZetarakuSheet, region: MaimaiConstants.ServerRegion) -> Double {
        if region == .intl, let intlOverride = sheet.regionOverrides?.intl {
            if let internalVal = intlOverride.internalLevelValue { return internalVal }
            if let lvVal = intlOverride.levelValue { return lvVal }
        }
        return sheet.internalLevelValue ?? sheet.levelValue ?? 0
    }

    private static func cleanedCharter(_ raw: String?) -> String {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return "-"
        }
        return trimmed
    }
}
