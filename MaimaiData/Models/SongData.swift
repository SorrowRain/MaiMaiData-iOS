import Foundation

struct SongData: Codable, Identifiable, Hashable {
    let basicInfo: BasicInfo
    let charts: [RawChart]
    let ds: [Double]
    let oldDs: [Double]?
    let id: String
    let level: [String]
    let title: String
    let type: String
    let alias: [String]?

    enum CodingKeys: String, CodingKey {
        case basicInfo = "basic_info"
        case charts
        case ds
        case oldDs = "old_ds"
        case id
        case level
        case title
        case type
        case alias
    }

    var numericId: Int { Int(id) ?? 0 }
    var baseJacketId: Int {
        let rem = numericId % 10000
        return rem > 0 ? rem : numericId
    }
    var isUtage: Bool { basicInfo.genre == MaimaiConstants.genreUtage }
    var isDX: Bool { type == MaimaiConstants.chartTypeDX }

    var resolvedCharts: [ResolvedChart] {
        charts.indices.map { idx in
            let raw = charts[idx]
            let isSD = type == MaimaiConstants.chartTypeSD
            let notes = raw.notes
            let tap = notes.indices.contains(0) ? notes[0] : 0
            let hold = notes.indices.contains(1) ? notes[1] : 0
            let slide = notes.indices.contains(2) ? notes[2] : 0
            let touch = isSD ? 0 : (notes.indices.contains(3) ? notes[3] : 0)
            let breakCount = isSD
                ? (notes.indices.contains(3) ? notes[3] : 0)
                : (notes.indices.contains(4) ? notes[4] : 0)
            let difficulty = DifficultyType.from(genre: basicInfo.genre, index: idx)
            return ResolvedChart(
                index: idx,
                difficulty: difficulty,
                ds: ds.indices.contains(idx) ? ds[idx] : 0,
                oldDs: (oldDs?.indices.contains(idx) == true) ? oldDs![idx] : nil,
                level: level.indices.contains(idx) ? level[idx] : "-",
                charter: raw.charter,
                tap: tap,
                hold: hold,
                slide: slide,
                touch: touch,
                breakCount: breakCount,
                totalNotes: notes.reduce(0, +)
            )
        }
    }

    /// Ordered domestic CDN cover URLs (LXNS COS CDN -> Diving-Fish 5-digit padded IDs).
    var coverCandidateURLs: [URL] {
        var urls: [URL] = []
        if let lxns = URL(string: "https://assets2.lxns.net/maimai/jacket/\(baseJacketId).png") {
            urls.append(lxns)
        }
        let paddedFull = String(format: "%05d", numericId)
        if let dfFull = URL(string: "https://www.diving-fish.com/covers/\(paddedFull).png") {
            urls.append(dfFull)
        }
        if baseJacketId != numericId {
            let paddedBase = String(format: "%05d", baseJacketId)
            if let dfBase = URL(string: "https://www.diving-fish.com/covers/\(paddedBase).png") {
                urls.append(dfBase)
            }
        }
        return urls
    }

    struct BasicInfo: Codable, Hashable {
        let artist: String
        let bpm: Int
        let from: String
        let genre: String
        let isNew: Bool
        let title: String
        let version: String

        enum CodingKeys: String, CodingKey {
            case artist, bpm, from, genre
            case isNew = "is_new"
            case title
            case version
        }
    }

    struct RawChart: Codable, Hashable {
        let charter: String
        let notes: [Int]
    }
}

struct ResolvedChart: Identifiable, Hashable {
    var id: Int { index }
    let index: Int
    let difficulty: DifficultyType
    let ds: Double
    let oldDs: Double?
    let level: String
    let charter: String
    let tap: Int
    let hold: Int
    let slide: Int
    let touch: Int
    let breakCount: Int
    let totalNotes: Int

    var totalWeightedScore: Int {
        (tap + touch) + hold * 2 + slide * 3 + breakCount * 5
    }
}

/// Navigation route carrying an optional target difficulty when jumping from B50 or checklists.
struct SongDetailRoute: Hashable {
    let song: SongData
    var initialDifficulty: DifficultyType? = nil
}
