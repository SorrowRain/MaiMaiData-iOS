import Foundation
import Observation

@MainActor
@Observable
final class DataStore {
    // MARK: - Domain Data
    private(set) var songs: [SongData] = []
    private(set) var songsById: [Int: SongData] = [:]
    private(set) var catalogRevision = 0
    private var cnSongs: [SongData] = []
    private var cnSongsById: [Int: SongData] = [:]
    private var zetarakuCatalog: ZetarakuCatalog?
    private var dxDataIdMap: DXDataIdMap?
    private var regionEpoch = 0
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
    private var isFetchingCNSongs = false
    private var isFetchingZetaraku = false
    var isSyncingSongs: Bool { isFetchingCNSongs || isFetchingZetaraku }
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
    var serverRegion: MaimaiConstants.ServerRegion {
        didSet { UserDefaults.standard.set(serverRegion.rawValue, forKey: Keys.serverRegion) }
    }
    var lastZetarakuSync: Date? {
        didSet { UserDefaults.standard.set(lastZetarakuSync?.timeIntervalSince1970, forKey: Keys.zetarakuSync) }
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
    var lastVersionCheckIntlIndex: Int {
        didSet { UserDefaults.standard.set(lastVersionCheckIntlIndex, forKey: Keys.lastVersionCheckIntl) }
    }
    var lastVersionCheckJpIndex: Int {
        didSet { UserDefaults.standard.set(lastVersionCheckJpIndex, forKey: Keys.lastVersionCheckJp) }
    }
    var lastLevelCheckIndex: Int {
        didSet { UserDefaults.standard.set(lastLevelCheckIndex, forKey: Keys.lastLevelCheck) }
    }

    var activeVersionCheckIndex: Int {
        get {
            switch serverRegion {
            case .cn: return lastVersionCheckIndex
            case .intl: return lastVersionCheckIntlIndex
            case .jp: return lastVersionCheckJpIndex
            }
        }
        set {
            switch serverRegion {
            case .cn: lastVersionCheckIndex = newValue
            case .intl: lastVersionCheckIntlIndex = newValue
            case .jp: lastVersionCheckJpIndex = newValue
            }
        }
    }

    var activeCatalogSubtitle: String {
        switch serverRegion {
        case .cn:
            return "国服版本 \(dataVersion) · 共 \(songs.count) 首"
        case .intl, .jp:
            let stamp: String
            if let updateTime = zetarakuCatalog?.updateTime, !updateTime.isEmpty {
                stamp = String(updateTime.prefix(10))
            } else if let last = lastZetarakuSync {
                stamp = last.formatted(date: .numeric, time: .omitted)
            } else {
                stamp = "尚未同步"
            }
            return "\(serverRegion.shortName)数据 \(stamp) · 共 \(songs.count) 首"
        }
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
    private var cachedZetarakuURL: URL { appSupportDir.appendingPathComponent("zetaraku_data.json") }
    private var cachedDXDataIdMapURL: URL { appSupportDir.appendingPathComponent("dxdata_id_map.json") }
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
        self.serverRegion = ud.string(forKey: Keys.serverRegion)
            .flatMap(MaimaiConstants.ServerRegion.init(rawValue:)) ?? .cn
        if let zTs = ud.object(forKey: Keys.zetarakuSync) as? TimeInterval {
            self.lastZetarakuSync = Date(timeIntervalSince1970: zTs)
        } else {
            self.lastZetarakuSync = nil
        }
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
        self.lastVersionCheckIntlIndex = (ud.object(forKey: Keys.lastVersionCheckIntl) as? Int)
            ?? max(0, MaimaiConstants.checklistVersions(for: .intl).count - 1)
        self.lastVersionCheckJpIndex = (ud.object(forKey: Keys.lastVersionCheckJp) as? Int)
            ?? max(0, MaimaiConstants.checklistVersions(for: .jp).count - 1)
        self.lastLevelCheckIndex = ud.integer(forKey: Keys.lastLevelCheck)
    }

    // MARK: - Bootstrap & Local Caching

    private func loadLocalCaches() async {
        let songsURL = cachedSongsURL
        let zetarakuURL = cachedZetarakuURL
        let dxIdMapURL = cachedDXDataIdMapURL
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
            if let zData = try? Data(contentsOf: zetarakuURL) {
                cache.zetaraku = try? JSONDecoder().decode(ZetarakuCatalog.self, from: zData)
            }
            if let idData = try? Data(contentsOf: dxIdMapURL) {
                cache.dxIdMap = try? JSONDecoder().decode(DXDataIdMap.self, from: idData)
            }
            if let data = try? Data(contentsOf: statsURL) {
                cache.stats = try? JSONDecoder().decode(ChartStatsResponse.self, from: data)
            }
            if let data = try? Data(contentsOf: recordsURL) {
                cache.records = try? JSONDecoder().decode([ProberRecord].self, from: data)
            }
            return cache
        }.value

        zetarakuCatalog = caches.zetaraku
        dxDataIdMap = caches.dxIdMap
        if let loadedCNSongs = caches.songs {
            await storeCNBaseline(loadedCNSongs)
            if caches.usedSeed { dataVersion = Self.seedDataVersion }
        }

        let epoch = regionEpoch
        switch serverRegion {
        case .cn:
            if !cnSongs.isEmpty {
                await applySongs(cnSongs, epoch: epoch)
            }
        case .intl, .jp:
            if let catalog = zetarakuCatalog {
                await applyZetarakuCatalog(catalog, for: serverRegion, epoch: epoch)
            }
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
        async let regionCheck: Void = bootstrapSupplementalCatalogIfNeeded()
        _ = await (songCheck, statsCheck, regionCheck)
    }

    private func bootstrapSupplementalCatalogIfNeeded() async {
        if serverRegion != .cn {
            if zetarakuCatalog == nil || dxDataIdMap == nil {
                await syncZetarakuCatalog(force: false)
            } else {
                await refreshZetarakuIfStale()
            }
        } else if zetarakuCatalog == nil {
            // Silently cache Utage descriptions ("谱面说明") in background on first CN launch as well.
            await syncZetarakuCatalog(force: false)
        }
    }

    private func storeCNBaseline(_ rawList: [SongData]) async {
        let zCatalog = zetarakuCatalog
        let snapshot = await Task.detached(priority: .userInitiated) {
            let withUtageMeta = ZetarakuCatalogConverter.enrichCNSongsWithUtageMetadata(rawList, from: zCatalog)
            return Self.buildSnapshotSync(from: withUtageMeta)
        }.value
        cnSongs = snapshot.songs
        cnSongsById = snapshot.songsById
    }

    private func applySongs(_ list: [SongData], epoch: Int? = nil) async {
        let snapshot = await Self.buildSnapshot(from: list)
        if let epoch, regionEpoch != epoch { return }
        songs = snapshot.songs
        songsById = snapshot.songsById
        maxNotesStats = snapshot.maxNotes
        catalogRevision &+= 1
    }

    private func applyZetarakuCatalog(
        _ catalog: ZetarakuCatalog,
        for region: MaimaiConstants.ServerRegion,
        epoch: Int? = nil
    ) async {
        let cnRef = cnSongs
        let idMap = dxDataIdMap
        let (snapshot, migrations) = await Task.detached(priority: .userInitiated) { () -> (SongSnapshot, [(legacyId: String, resolvedId: String)]) in
            let output = ZetarakuCatalogConverter.convertWithMigrations(
                catalog,
                region: region,
                cnReference: cnRef,
                dxIdMap: idMap
            )
            return (Self.buildSnapshotSync(from: output.songs), output.migratedIdPairs)
        }.value
        if let epoch, regionEpoch != epoch { return }
        migrateFavoriteIdsIfNeeded(migrations)
        songs = snapshot.songs
        songsById = snapshot.songsById
        maxNotesStats = snapshot.maxNotes
        catalogRevision &+= 1
    }

    /// Smoothly upgrades any favorited temporary key (`zeta_dx_*`) to its official numeric ID once online `dxdata` provides it.
    private func migrateFavoriteIdsIfNeeded(_ pairs: [(legacyId: String, resolvedId: String)]) {
        guard !favoriteIds.isEmpty, !pairs.isEmpty else { return }
        var updated = favoriteIds
        var changed = false
        for pair in pairs where updated.contains(pair.legacyId) {
            updated.remove(pair.legacyId)
            updated.insert(pair.resolvedId)
            changed = true
        }
        if changed {
            favoriteIds = updated
        }
    }

    private static func buildSnapshot(from list: [SongData]) async -> SongSnapshot {
        await Task.detached(priority: .userInitiated) {
            buildSnapshotSync(from: list)
        }.value
    }

    nonisolated private static func buildSnapshotSync(from list: [SongData]) -> SongSnapshot {
        let enriched = SongData.mergingCounterpartAliases(list)
        let ordered = enriched.sorted {
            if $0.defaultSortKey != $1.defaultSortKey { return $0.defaultSortKey > $1.defaultSortKey }
            return $0.id > $1.id
        }
        var map: [Int: SongData] = [:]
        map.reserveCapacity(ordered.count)
        for song in ordered where song.numericId > 0 {
            map[song.numericId] = song
        }
        return SongSnapshot(songs: ordered, songsById: map, maxNotes: MaxNotesStats.compute(from: ordered))
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

    // MARK: - Server Region Switching & Remote Sync

    func switchServerRegion(_ newRegion: MaimaiConstants.ServerRegion) async {
        guard newRegion != serverRegion else { return }
        regionEpoch += 1
        let epoch = regionEpoch
        serverRegion = newRegion
        syncNotice = nil

        switch newRegion {
        case .cn:
            await applySongs(cnSongs, epoch: epoch)
        case .intl, .jp:
            if let catalog = zetarakuCatalog {
                await applyZetarakuCatalog(catalog, for: newRegion, epoch: epoch)
                await refreshZetarakuIfStale()
            } else {
                songs = []
                songsById = [:]
                catalogRevision &+= 1
                await loadOrFetchZetaraku(for: newRegion, epoch: epoch)
            }
        }
        guard regionEpoch == epoch else { return }
        prefetchBest50Covers()
    }

    func syncActiveRegionSongs(force: Bool = false) async {
        switch serverRegion {
        case .cn:
            await checkSongDataUpdateIfNeeded(force: force)
        case .intl, .jp:
            await syncZetarakuCatalog(force: force)
        }
    }

    private func loadOrFetchZetaraku(for region: MaimaiConstants.ServerRegion, epoch: Int) async {
        let zURL = cachedZetarakuURL
        let idURL = cachedDXDataIdMapURL
        let (diskCatalog, diskIdMap) = await Task.detached(priority: .userInitiated, operation: { () -> (ZetarakuCatalog?, DXDataIdMap?) in
            let z = (try? Data(contentsOf: zURL)).flatMap { try? JSONDecoder().decode(ZetarakuCatalog.self, from: $0) }
            let m = (try? Data(contentsOf: idURL)).flatMap { try? JSONDecoder().decode(DXDataIdMap.self, from: $0) }
            return (z, m)
        }).value
        if let diskIdMap, dxDataIdMap == nil {
            dxDataIdMap = diskIdMap
        }
        if let diskCatalog {
            guard regionEpoch == epoch else { return }
            zetarakuCatalog = diskCatalog
            await applyZetarakuCatalog(diskCatalog, for: region, epoch: epoch)
            await refreshZetarakuIfStale()
            return
        }
        await syncZetarakuCatalog(force: false)
    }

    private func refreshZetarakuIfStale() async {
        let oneDay: TimeInterval = 24 * 3600
        if let last = lastZetarakuSync,
           Date().timeIntervalSince(last) < oneDay,
           zetarakuCatalog != nil,
           dxDataIdMap != nil {
            return
        }
        await syncZetarakuCatalog(force: false)
    }

    func syncZetarakuCatalog(force: Bool = false) async {
        guard !isFetchingZetaraku else { return }
        isFetchingZetaraku = true
        defer { isFetchingZetaraku = false }

        // Fetch Zetaraku catalog and DXRating live internalId map concurrently with independent fault isolation:
        // a temporary failure on one endpoint never blocks or corrupts the other.
        async let zetarakuTask: Result<(raw: Data, catalog: ZetarakuCatalog), Error> = {
            do {
                return .success(try await MaimaiAPI.fetchZetarakuCatalog())
            } catch {
                return .failure(error)
            }
        }()
        async let dxIdTask: DXDataIdMap? = try? await MaimaiAPI.fetchDXDataIdMap()

        let (zResult, fetchedIdMap) = await (zetarakuTask, dxIdTask)

        if let fetchedIdMap {
            dxDataIdMap = fetchedIdMap
            if let encoded = try? JSONEncoder().encode(fetchedIdMap) {
                try? encoded.write(to: cachedDXDataIdMapURL, options: .atomic)
            }
        }

        switch zResult {
        case .success(let (raw, decoded)):
            try? raw.write(to: cachedZetarakuURL, options: .atomic)
            zetarakuCatalog = decoded
            lastZetarakuSync = Date()
            if !cnSongs.isEmpty {
                await storeCNBaseline(cnSongs)
            }
            if serverRegion == .cn {
                if !cnSongs.isEmpty {
                    await applySongs(cnSongs, epoch: regionEpoch)
                }
            } else {
                await applyZetarakuCatalog(decoded, for: serverRegion, epoch: regionEpoch)
                if force {
                    let verText = decoded.updateTime.map { String($0.prefix(10)) } ?? "最新"
                    statusMessage = "\(serverRegion.shortName)曲库与 ID 映射已同步（\(verText)，共 \(songs.count) 首）"
                }
            }
        case .failure(let error):
            // Even if Zetaraku failed, if DXData updated and we have a local Zetaraku cache, re-apply with fresher IDs!
            if fetchedIdMap != nil, let existingCatalog = zetarakuCatalog, serverRegion != .cn {
                await applyZetarakuCatalog(existingCatalog, for: serverRegion, epoch: regionEpoch)
            }
            if serverRegion != .cn {
                statusMessage = force ? "\(serverRegion.shortName)曲库更新失败：\(error.localizedDescription)" : nil
                syncNotice = DataSyncNotice(
                    kind: .songs,
                    message: "\(serverRegion.shortName)曲库更新失败，正在使用本地缓存。请检查网络后重试。\n\(error.localizedDescription)"
                )
            }
        }
    }

    func checkSongDataUpdateIfNeeded(force: Bool = false) async {
        guard !isFetchingCNSongs else { return }
        isFetchingCNSongs = true
        defer { isFetchingCNSongs = false }
        do {
            let info = try await MaimaiAPI.fetchUpdateInfo()
            guard let (remoteVer, remoteURL) = info.bestDataVersionAndURL else { return }
            if force || VersionString.isNewer(remoteVer, than: dataVersion) || cnSongs.isEmpty {
                let (raw, decoded) = try await MaimaiAPI.downloadSongData(from: remoteURL)
                try raw.write(to: cachedSongsURL, options: .atomic)
                dataVersion = remoteVer
                await storeCNBaseline(decoded)
                if serverRegion == .cn {
                    await applySongs(cnSongs, epoch: regionEpoch)
                    if force {
                        statusMessage = "曲库已更新至 \(remoteVer)（共 \(decoded.count) 首）"
                    }
                } else if let catalog = zetarakuCatalog {
                    await applyZetarakuCatalog(catalog, for: serverRegion, epoch: regionEpoch)
                }
            } else if force && serverRegion == .cn {
                statusMessage = "当前曲库已是最新版本（\(dataVersion)）"
            }
        } catch {
            guard serverRegion == .cn else { return }
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
            let (raw, decoded) = try await MaimaiAPI.fetchChartStats()
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

        do {
            try await performFetchRecordsWithCurrentCookie()
        } catch {
            throw MaimaiAPIError.recordSyncFailedAfterLogin(error.localizedDescription)
        }
    }

    func fetchRecordsWithCurrentCookie() async throws {
        guard !isSyncingRecords else { return }
        guard !currentCookie.isEmpty || (!currentUsername.isEmpty && !currentPassword.isEmpty) else {
            throw MaimaiAPIError.unauthorized("请先登录水鱼查分器")
        }
        isSyncingRecords = true
        defer { isSyncingRecords = false }

        try await performFetchRecordsWithCurrentCookie()
    }

    private func performFetchRecordsWithCurrentCookie() async throws {
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
            } catch where MaimaiAPI.shouldRetryLogin(after: error) {
                // 仅当 Cookie 过期或鉴权失效且本地有保存的凭据时，自动重新登录并重试一次。
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
        // 始终缓存水鱼返回的昵称，由 displayPlayerName 根据 useDivingFishNickname 开关决定展示哪一个。
        divingFishNickname = resp.nickname ?? ""
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
                  recordsEpoch == epoch else { return }
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
            enableCharterSearch: enableCharterSearch,
            region: serverRegion
        )
    }

    // MARK: - Records & Best50 Helpers

    var isLoggedIn: Bool {
        !currentUsername.isEmpty || !currentCookie.isEmpty
    }

    /// Finds the SD <-> DX counterpart of the same song (`id ± 10000` or same title+genre in JP/INTL), if present.
    func counterpartSong(for song: SongData) -> SongData? {
        guard !song.isUtage else { return nil }
        if song.numericId > 0 {
            let targetId = song.numericId < 10_000 ? song.numericId + 10_000 : song.numericId - 10_000
            if let candidate = songsById[targetId],
               !candidate.isUtage,
               candidate.title == song.title,
               candidate.isDX != song.isDX {
                return candidate
            }
        }
        return songs.first { candidate in
            !candidate.isUtage &&
            candidate.isDX != song.isDX &&
            candidate.title == song.title &&
            candidate.basicInfo.genre == song.basicInfo.genre
        }
    }

    /// Baseline single-song rating a chart must exceed to increase total B50 rating.
    /// Returns `nil` when the user is not logged in or when viewing non-CN servers.
    func b50BaselineRating(forSong song: SongData, difficultyIndex: Int, summary: Best50Summary? = nil) -> Int? {
        guard isLoggedIn, serverRegion == .cn, song.numericId > 0 else { return nil }
        let resolved = summary ?? best35AndBest15()
        let bucket = song.basicInfo.isNew ? resolved.b15 : resolved.b35
        let limit = song.basicInfo.isNew ? 15 : 35
        if let existing = bucket.first(where: { $0.songId == song.numericId && $0.levelIndex == difficultyIndex }) {
            return existing.computedRating
        }
        if bucket.count >= limit {
            return bucket.last?.computedRating ?? 0
        }
        return 0
    }

    func record(forSongId songId: Int, difficultyIndex: Int) -> ProberRecord? {
        guard songId > 0 else { return nil }
        return recordsByKey["\(songId)_\(difficultyIndex)"]
    }

    func sortedRecords(isNewVersion: Bool) -> [ProberRecord] {
        let region = serverRegion
        return records.compactMap { rec in
            guard let song = songsById[rec.songId],
                  !song.isUtage,
                  rec.levelIndex < song.ds.count,
                  song.basicInfo.isNew == isNewVersion else {
                return nil
            }
            return rec.projected(onto: song, region: region)
        }.sorted(by: Self.recordOrder)
    }

    func best35AndBest15() -> Best50Summary {
        let region = serverRegion
        var matching = true
        var oldList: [ProberRecord] = []
        var newList: [ProberRecord] = []
        for rec in records {
            guard let song = songsById[rec.songId] else {
                if region == .cn || cnSongsById[rec.songId] == nil {
                    matching = false
                }
                continue
            }
            guard !song.isUtage, rec.levelIndex < song.ds.count else { continue }
            let projected = rec.projected(onto: song, region: region)
            if song.basicInfo.isNew {
                newList.append(projected)
            } else {
                oldList.append(projected)
            }
        }
        oldList.sort(by: Self.recordOrder)
        newList.sort(by: Self.recordOrder)
        let b35 = Array(oldList.prefix(35))
        let b15 = Array(newList.prefix(15))
        return Best50Summary(b35: b35, b15: b15, isMatching: matching)
    }

    private static func recordOrder(_ lhs: ProberRecord, _ rhs: ProberRecord) -> Bool {
        if lhs.computedRating != rhs.computedRating {
            return lhs.computedRating > rhs.computedRating
        }
        if lhs.achievements != rhs.achievements {
            return lhs.achievements > rhs.achievements
        }
        return lhs.ds > rhs.ds
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
    var zetaraku: ZetarakuCatalog?
    var dxIdMap: DXDataIdMap?
    var stats: ChartStatsResponse?
    var records: [ProberRecord]?
    var usedSeed = false
}

private struct SongSnapshot {
    let songs: [SongData]
    let songsById: [Int: SongData]
    let maxNotes: MaxNotesStats
}

struct Best50Summary {
    let b35: [ProberRecord]
    let b15: [ProberRecord]
    let isMatching: Bool
    let b35Rating: Int
    let b15Rating: Int

    var totalRating: Int { b35Rating + b15Rating }

    init(b35: [ProberRecord], b15: [ProberRecord], isMatching: Bool) {
        self.b35 = b35
        self.b15 = b15
        self.isMatching = isMatching
        self.b35Rating = b35.reduce(0) { $0 + $1.computedRating }
        self.b15Rating = b15.reduce(0) { $0 + $1.computedRating }
    }
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
