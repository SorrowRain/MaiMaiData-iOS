import Foundation
import Observation

@MainActor
@Observable
final class DataStore {
    // MARK: - Domain Data
    private(set) var songs: [SongData] = []
    private(set) var songsById: [Int: SongData] = [:]
    private(set) var chartStats: [Int: [ChartStatEntry]] = [:]
    private(set) var records: [ProberRecord] = [] {
        didSet {
            var map: [String: ProberRecord] = [:]
            map.reserveCapacity(records.count)
            for rec in records {
                map["\(rec.songId)_\(rec.levelIndex)"] = rec
            }
            recordsByKey = map
        }
    }
    private var recordsByKey: [String: ProberRecord] = [:]
    /// Monotonic token distinguishing network-fetched records from a slower cache backfill.
    private var recordsEpoch = 0
    private(set) var maxNotesStats: MaxNotesStats = .fallback

    // MARK: - Loading & Status
    private(set) var isSyncingSongs = false
    private(set) var isSyncingRecords = false
    private(set) var isSyncingStats = false
    private(set) var isLoadingLocalData = true
    var statusMessage: String?
    var syncNotice: DataSyncNotice?

    // MARK: - User Preferences & Account State
    var favoriteIds: Set<String> {
        didSet { UserDefaults.standard.set(Array(favoriteIds), forKey: Keys.favorites) }
    }
    var searchHistory: [String] {
        didSet { UserDefaults.standard.set(searchHistory, forKey: Keys.searchHistory) }
    }
    var savedAccounts: [SavedAccount] {
        didSet {
            AccountCredentialStore.saveAccounts(savedAccounts)
        }
    }

    var currentUsername: String {
        didSet {
            guard oldValue != currentUsername else { return }
            UserDefaults.standard.set(currentUsername, forKey: Keys.username)
            restoreCachedRecords()
        }
    }
    var currentPassword: String {
        didSet { AccountCredentialStore.save(currentPassword, key: Keys.password) }
    }
    var currentCookie: String {
        didSet { AccountCredentialStore.save(currentCookie, key: Keys.cookie) }
    }
    var divingFishNickname: String {
        didSet { UserDefaults.standard.set(divingFishNickname, forKey: Keys.dfNickname) }
    }
    var dataVersion: String {
        didSet { UserDefaults.standard.set(dataVersion, forKey: Keys.dataVersion) }
    }
    var lastChartStatsSync: Date? {
        didSet { UserDefaults.standard.set(lastChartStatsSync?.timeIntervalSince1970, forKey: Keys.chartStatsSync) }
    }

    // Settings
    var enableShowAlias: Bool {
        didSet { UserDefaults.standard.set(enableShowAlias, forKey: Keys.showAlias) }
    }
    var enableAliasSearch: Bool {
        didSet { UserDefaults.standard.set(enableAliasSearch, forKey: Keys.aliasSearch) }
    }
    var enableCharterSearch: Bool {
        didSet { UserDefaults.standard.set(enableCharterSearch, forKey: Keys.charterSearch) }
    }
    var useDivingFishNickname: Bool {
        didSet { UserDefaults.standard.set(useDivingFishNickname, forKey: Keys.useDFNickname) }
    }
    var customNickname: String {
        didSet { UserDefaults.standard.set(customNickname, forKey: Keys.customNickname) }
    }
    var lastVersionCheckIndex: Int {
        didSet { UserDefaults.standard.set(lastVersionCheckIndex, forKey: Keys.lastVersionCheck) }
    }
    var lastLevelCheckIndex: Int {
        didSet { UserDefaults.standard.set(lastLevelCheckIndex, forKey: Keys.lastLevelCheck) }
    }

    private typealias Keys = PreferenceKeys

    private static let seedDataVersion = "20261113"
    private var didBootstrap = false

    private var appSupportDir: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MaimaiData", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var cachedSongsURL: URL { appSupportDir.appendingPathComponent("songdata.json") }
    private var cachedStatsURL: URL { appSupportDir.appendingPathComponent("chart_stats.json") }
    private var cachedRecordsURL: URL {
        guard !currentUsername.isEmpty else {
            return appSupportDir.appendingPathComponent("records_anonymous.json")
        }
        return appSupportDir.appendingPathComponent("records_\(currentUsername.sha256Hex).json")
    }

    init() {
        let ud = UserDefaults.standard
        PreferenceKeys.registerDefaults(in: ud)

        self.favoriteIds = Set(ud.stringArray(forKey: Keys.favorites) ?? [])
        self.searchHistory = ud.stringArray(forKey: Keys.searchHistory) ?? []
        self.savedAccounts = AccountCredentialStore.loadAccounts(
            legacyData: ud.data(forKey: Keys.savedAccounts)
        )
        self.currentUsername = ud.string(forKey: Keys.username) ?? ""
        self.currentPassword = AccountCredentialStore.load(Keys.password)
        self.currentCookie = AccountCredentialStore.load(Keys.cookie)
        // 一次性清理由旧版本写入 UserDefaults 的凭据，后续统一走 Keychain。
        ud.removeObject(forKey: Keys.savedAccounts)
        ud.removeObject(forKey: Keys.password)
        ud.removeObject(forKey: Keys.cookie)
        self.divingFishNickname = ud.string(forKey: Keys.dfNickname) ?? ""
        self.dataVersion = ud.string(forKey: Keys.dataVersion) ?? Self.seedDataVersion
        if let ts = ud.object(forKey: Keys.chartStatsSync) as? TimeInterval {
            self.lastChartStatsSync = Date(timeIntervalSince1970: ts)
        } else {
            self.lastChartStatsSync = nil
        }

        self.enableShowAlias = ud.bool(forKey: Keys.showAlias)
        self.enableAliasSearch = ud.bool(forKey: Keys.aliasSearch)
        self.enableCharterSearch = ud.bool(forKey: Keys.charterSearch)
        self.useDivingFishNickname = ud.bool(forKey: Keys.useDFNickname)
        self.customNickname = ud.string(forKey: Keys.customNickname) ?? ""
        self.lastVersionCheckIndex = ud.integer(forKey: Keys.lastVersionCheck)
        self.lastLevelCheckIndex = ud.integer(forKey: Keys.lastLevelCheck)
    }

    // MARK: - Bootstrap & Local Caching

    private func loadLocalCaches() async {
        let songsURL = cachedSongsURL
        let statsURL = cachedStatsURL
        let recordsURL = cachedRecordsURL
        let caches = await Task.detached(priority: .userInitiated) { () -> LocalCaches in
            var cache = LocalCaches()
            if let data = try? Data(contentsOf: songsURL) {
                cache.songs = try? JSONDecoder().decode([SongData].self, from: data)
            }
            if cache.songs == nil,
               let seedURL = Bundle.main.url(forResource: "songdata_seed", withExtension: "json"),
               let data = try? Data(contentsOf: seedURL),
               let decoded = try? JSONDecoder().decode([SongData].self, from: data) {
                try? data.write(to: songsURL, options: .atomic)
                cache.songs = decoded
                cache.usedSeed = true
            }
            if let data = try? Data(contentsOf: statsURL) {
                cache.stats = try? JSONDecoder().decode(ChartStatsResponse.self, from: data)
            }
            if let data = try? Data(contentsOf: recordsURL) {
                cache.records = try? JSONDecoder().decode([ProberRecord].self, from: data)
            }
            return cache
        }.value

        if let songs = caches.songs {
            await applySongs(songs)
            if caches.usedSeed { dataVersion = Self.seedDataVersion }
        }
        if let stats = caches.stats { applyChartStats(stats) }
        records = caches.records ?? []
        isLoadingLocalData = false
        prefetchBest50Covers()
    }

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        await loadLocalCaches()

        async let songCheck: Void = checkSongDataUpdateIfNeeded()
        async let statsCheck: Void = refreshChartStatsIfStale()
        _ = await (songCheck, statsCheck)
    }

    private func applySongs(_ list: [SongData]) async {
        let snapshot = await Task.detached(priority: .userInitiated) { () -> SongSnapshot in
            let ordered = list.sorted {
                if $0.numericId != $1.numericId { return $0.numericId > $1.numericId }
                return $0.id > $1.id
            }
            var map: [Int: SongData] = [:]
            map.reserveCapacity(ordered.count)
            for song in ordered { map[song.numericId] = song }
            return SongSnapshot(songs: ordered, songsById: map, maxNotes: MaxNotesStats.compute(from: ordered))
        }.value
        songs = snapshot.songs
        songsById = snapshot.songsById
        maxNotesStats = snapshot.maxNotes
    }

    private func applyChartStats(_ response: ChartStatsResponse) {
        var map: [Int: [ChartStatEntry]] = [:]
        map.reserveCapacity(response.charts.count)
        for (key, value) in response.charts {
            if let id = Int(key) {
                map[id] = value
            }
        }
        self.chartStats = map
    }

    // MARK: - Remote Sync

    func checkSongDataUpdateIfNeeded(force: Bool = false) async {
        guard !isSyncingSongs else { return }
        isSyncingSongs = true
        defer { isSyncingSongs = false }
        do {
            let info = try await MaimaiAPI.fetchUpdateInfo()
            guard let (remoteVer, remoteURL) = info.bestDataVersionAndURL else { return }
            if force || VersionString.isNewer(remoteVer, than: dataVersion) || songs.isEmpty {
                let raw = try await MaimaiAPI.downloadSongData(from: remoteURL)
                let decoded = try JSONDecoder().decode([SongData].self, from: raw)
                try raw.write(to: cachedSongsURL, options: .atomic)
                dataVersion = remoteVer
                await applySongs(decoded)
                if force {
                    statusMessage = "曲库已更新至 \(remoteVer)（共 \(decoded.count) 首）"
                }
            } else if force {
                statusMessage = "当前曲库已是最新版本（\(dataVersion)）"
            }
        } catch {
            statusMessage = force ? "曲库更新失败：\(error.localizedDescription)" : nil
            syncNotice = DataSyncNotice(
                kind: .songs,
                message: "曲库更新失败，正在使用本地数据。请检查网络后重试。\n\(error.localizedDescription)"
            )
        }
    }

    func refreshChartStatsIfStale(force: Bool = false) async {
        guard !isSyncingStats else { return }
        let fiveDays: TimeInterval = 5 * 24 * 3600
        if !force, let last = lastChartStatsSync, Date().timeIntervalSince(last) < fiveDays, !chartStats.isEmpty {
            return
        }
        isSyncingStats = true
        defer { isSyncingStats = false }
        do {
            let raw = try await MaimaiAPI.fetchChartStats()
            let decoded = try JSONDecoder().decode(ChartStatsResponse.self, from: raw)
            try raw.write(to: cachedStatsURL, options: .atomic)
            lastChartStatsSync = Date()
            applyChartStats(decoded)
            if force {
                statusMessage = "拟合定数已刷新"
            }
        } catch {
            statusMessage = force ? "拟合定数获取失败：\(error.localizedDescription)" : nil
            syncNotice = DataSyncNotice(
                kind: .stats,
                message: "拟合定数获取失败，正在使用本地数据。可前往「设置与数据」重试。"
            )
        }
    }

    func loginAndSyncRecords(username: String, password: String) async throws {
        // 同步进行中不能静默丢弃登录请求：把忙状态作为错误抛给调用方，
        // 由登录弹窗/账号管理页展示，而不是关闭弹窗后仍是未登录状态。
        guard !isSyncingRecords else { throw MaimaiAPIError.syncInProgress }
        isSyncingRecords = true
        defer { isSyncingRecords = false }

        let cookie = try await MaimaiAPI.login(username: username, password: password)
        // 先设置 Cookie，避免切换账号时短暂清空新登录状态。
        currentCookie = cookie
        currentUsername = username
        currentPassword = password
        saveOrUpdateAccount(username: username, password: password)
        isSyncingRecords = false
        try await fetchRecordsWithCurrentCookie()
    }

    func fetchRecordsWithCurrentCookie() async throws {
        guard !isSyncingRecords else { return }
        guard !currentCookie.isEmpty || (!currentUsername.isEmpty && !currentPassword.isEmpty) else {
            throw MaimaiAPIError.unauthorized("请先登录水鱼查分器")
        }
        isSyncingRecords = true
        defer { isSyncingRecords = false }

        let username = currentUsername
        let password = currentPassword
        var cookie = currentCookie

        // 使用非结构化 Task 执行网络请求，避免 SwiftUI .refreshable 在视图状态更新时触发 NSURLErrorCancelled。
        let (resp, usedCookie) = try await Task { () -> (ProberRecordsResponse, String) in
            if cookie.isEmpty, !username.isEmpty, !password.isEmpty {
                cookie = try await MaimaiAPI.login(username: username, password: password)
            }
            do {
                let r = try await MaimaiAPI.fetchPlayerRecords(cookie: cookie)
                return (r, cookie)
            } catch {
                // 若 Cookie 过期且本地有保存的账号密码，自动重新登录并重试一次。
                if !username.isEmpty, !password.isEmpty {
                    let newCookie = try await MaimaiAPI.login(username: username, password: password)
                    let r = try await MaimaiAPI.fetchPlayerRecords(cookie: newCookie)
                    return (r, newCookie)
                }
                throw error
            }
        }.value

        guard currentUsername == username else { return }
        if usedCookie != currentCookie {
            currentCookie = usedCookie
        }
        if useDivingFishNickname {
            divingFishNickname = resp.nickname ?? ""
        }
        let fetched = resp.records ?? []
        // Invalidate any in-flight restoreCachedRecords() before installing fresher data.
        recordsEpoch += 1
        self.records = fetched
        if let encoded = try? JSONEncoder().encode(fetched) {
            try? encoded.write(to: cachedRecordsURL, options: .atomic)
        }
        prefetchBest50Covers()
    }

    private func prefetchBest50Covers() {
        let split = best35AndBest15()
        let b50Songs = (split.b35 + split.b15).compactMap { songsById[$0.songId] }
        guard !b50Songs.isEmpty else { return }
        Task(priority: .utility) {
            for song in b50Songs {
                _ = await CoverImageCache.shared.loadCover(song: song)
            }
        }
    }

    func logout() {
        currentUsername = ""
        currentPassword = ""
        currentCookie = ""
        divingFishNickname = ""
        records = []
    }

    private func saveOrUpdateAccount(username: String, password: String) {
        var list = savedAccounts
        if let idx = list.firstIndex(where: { $0.username == username }) {
            list[idx] = SavedAccount(username: username, password: password)
        } else {
            list.append(SavedAccount(username: username, password: password))
        }
        savedAccounts = list
    }

    func removeSavedAccount(username: String) {
        if username == currentUsername {
            logout()
        }
        let recordFile = appSupportDir.appendingPathComponent("records_\(username.sha256Hex).json")
        try? FileManager.default.removeItem(at: recordFile)
        savedAccounts.removeAll { $0.username == username }
    }

    // MARK: - Search, Filter & Favorites

    private func restoreCachedRecords() {
        let username = currentUsername
        // Any older pending restore belongs to a previous account/data generation.
        recordsEpoch += 1
        let epoch = recordsEpoch
        records = []
        guard !username.isEmpty else { return }
        let url = cachedRecordsURL
        Task(priority: .userInitiated) {
            let cached = await Task.detached(priority: .utility) { () -> [ProberRecord]? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode([ProberRecord].self, from: data)
            }.value
            // Never let an older cache read replace fresher network data or another account.
            guard currentUsername == username,
                  recordsEpoch == epoch,
                  !isSyncingRecords else { return }
            records = cached ?? []
        }
    }

    func isFavorite(_ song: SongData) -> Bool {
        favoriteIds.contains(song.id)
    }

    func toggleFavorite(_ song: SongData) {
        if favoriteIds.contains(song.id) {
            favoriteIds.remove(song.id)
        } else {
            favoriteIds.insert(song.id)
        }
    }

    func addSearchHistory(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var list = searchHistory.filter { $0 != trimmed }
        list.insert(trimmed, at: 0)
        if list.count > 20 { list = Array(list.prefix(20)) }
        searchHistory = list
    }

    func clearSearchHistory() {
        searchHistory = []
    }

    func filteredSongs(criteria: SongFilterCriteria) -> [SongData] {
        SongFilter.apply(
            criteria,
            to: songs,
            favoriteIds: favoriteIds,
            enableAliasSearch: enableAliasSearch,
            enableCharterSearch: enableCharterSearch
        )
    }

    // MARK: - Records & Best50 Helpers

    func record(forSongId songId: Int, difficultyIndex: Int) -> ProberRecord? {
        recordsByKey["\(songId)_\(difficultyIndex)"]
    }

    func sortedRecords(isNewVersion: Bool) -> [ProberRecord] {
        records.filter { rec in
            guard let song = songsById[rec.songId] else { return false }
            return song.basicInfo.isNew == isNewVersion
        }.sorted { $0.ra > $1.ra }
    }

    func best35AndBest15() -> (b35: [ProberRecord], b15: [ProberRecord], isMatching: Bool) {
        var matching = true
        var oldList: [ProberRecord] = []
        var newList: [ProberRecord] = []
        for rec in records {
            guard let song = songsById[rec.songId] else {
                matching = false
                continue
            }
            if song.basicInfo.isNew {
                newList.append(rec)
            } else {
                oldList.append(rec)
            }
        }
        oldList.sort { $0.ra > $1.ra }
        newList.sort { $0.ra > $1.ra }
        return (Array(oldList.prefix(35)), Array(newList.prefix(15)), matching)
    }

    var displayPlayerName: String {
        if !useDivingFishNickname {
            let trimmed = customNickname.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        if !divingFishNickname.isEmpty {
            return divingFishNickname
        }
        return currentUsername.isEmpty ? "Player" : currentUsername
    }
}

private struct LocalCaches {
    var songs: [SongData]?
    var stats: ChartStatsResponse?
    var records: [ProberRecord]?
    var usedSeed = false
}

private struct SongSnapshot {
    let songs: [SongData]
    let songsById: [Int: SongData]
    let maxNotes: MaxNotesStats
}

struct DataSyncNotice: Identifiable, Equatable {
    enum Kind: Equatable {
        case songs
        case stats
    }

    let id = UUID()
    let kind: Kind
    let message: String
}
