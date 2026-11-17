import Foundation

enum MaimaiAPIError: LocalizedError {
    case invalidURL
    case httpError(Int, String?)
    case missingCookie
    case unauthorized(String)
    case syncInProgress
    case recordSyncFailedAfterLogin(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .httpError(let code, let message):
            return message ?? "网络请求失败 (HTTP \(code))"
        case .missingCookie:
            return "登录未返回有效 Cookie"
        case .unauthorized(let message):
            return message
        case .syncInProgress:
            return "正在同步成绩，请稍后再试。"
        case .recordSyncFailedAfterLogin(let detail):
            return "登录已成功，但成绩同步失败：\(detail)\n请稍后下拉刷新或重试。"
        }
    }

    var recoveryMessage: String {
        errorDescription ?? "请求失败，请检查网络后重试。"
    }
}

enum MaimaiAPI {
    private static let updateInfoURL = URL(string: "https://bucket-1256206908.cos.ap-shanghai.myqcloud.com/update.json")!
    private static let zetarakuDataURL = URL(string: "https://dp4p6x0xfi5o9.cloudfront.net/maimai/data.json")!
    private static let dxDataURL = URL(string: "https://miruku.dxrating.net/api/v1/dxdata")!
    private static let divingFishBase = "https://www.diving-fish.com"
    private static let userAgent = "okhttp/4.9.3"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpShouldSetCookies = false
        return URLSession(configuration: config)
    }()

    static func fetchUpdateInfo() async throws -> AppUpdateInfo {
        var req = URLRequest(url: updateInfoURL)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        try validateHTTP(resp, data: data)
        return try JSONDecoder().decode(AppUpdateInfo.self, from: data)
    }

    static func downloadSongData(from urlString: String) async throws -> (raw: Data, songs: [SongData]) {
        guard let url = URL(string: urlString) else { throw MaimaiAPIError.invalidURL }
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        try validateHTTP(resp, data: data)
        // Decode once off the MainActor before replacing local cache.
        let decoded = try JSONDecoder().decode([SongData].self, from: data)
        return (data, decoded)
    }

    static func fetchZetarakuCatalog() async throws -> (raw: Data, catalog: ZetarakuCatalog) {
        var req = URLRequest(url: zetarakuDataURL)
        req.setValue("MaimaiData-iOS/1.0", forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        try validateHTTP(resp, data: data)
        let decoded = try JSONDecoder().decode(ZetarakuCatalog.self, from: data)
        return (data, decoded)
    }

    static func fetchDXDataIdMap() async throws -> DXDataIdMap {
        var req = URLRequest(url: dxDataURL)
        req.setValue("MaimaiData-iOS/1.0", forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        try validateHTTP(resp, data: data)
        return try await Task.detached(priority: .utility) {
            let rawCatalog = try JSONDecoder().decode(DXDataRawCatalog.self, from: data)
            return DXDataIdMap.extract(from: rawCatalog)
        }.value
    }

    static func fetchChartStats() async throws -> (raw: Data, stats: ChartStatsResponse) {
        let url = URL(string: "\(divingFishBase)/api/maimaidxprober/chart_stats")!
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        try validateHTTP(resp, data: data)
        let decoded = try JSONDecoder().decode(ChartStatsResponse.self, from: data)
        return (data, decoded)
    }

    static func shouldRetryLogin(after error: Error) -> Bool {
        switch error {
        case MaimaiAPIError.unauthorized:
            return true
        case let MaimaiAPIError.httpError(code, _):
            return code == 400 || code == 401 || code == 403
        default:
            return false
        }
    }

    static func login(username: String, password: String) async throws -> String {
        let url = URL(string: "\(divingFishBase)/api/maimaidxprober/login")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.httpBody = try JSONEncoder().encode(["username": username, "password": password])

        let (data, resp) = try await session.data(for: req)
        guard let httpResp = resp as? HTTPURLResponse else {
            throw MaimaiAPIError.httpError(-1, "无效的服务器响应")
        }
        if httpResp.statusCode != 200 {
            let errMsg = extractErrorMessage(from: data) ?? "登录失败 (HTTP \(httpResp.statusCode))"
            throw MaimaiAPIError.httpError(httpResp.statusCode, errMsg)
        }
        let cookieHeader = httpResp.value(forHTTPHeaderField: "Set-Cookie") ?? ""
        guard !cookieHeader.isEmpty else {
            throw MaimaiAPIError.missingCookie
        }
        return cookieHeader
    }

    static func fetchPlayerRecords(cookie: String) async throws -> ProberRecordsResponse {
        let url = URL(string: "\(divingFishBase)/api/maimaidxprober/player/records")!
        var req = URLRequest(url: url)
        req.setValue(cookie, forHTTPHeaderField: "Cookie")
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        try validateHTTP(resp, data: data)
        let decoded = try JSONDecoder().decode(ProberRecordsResponse.self, from: data)
        if decoded.status == "error" {
            throw MaimaiAPIError.unauthorized(decoded.message ?? "登录已过期，请重新登录")
        }
        return decoded
    }

    private static func validateHTTP(_ resp: URLResponse, data: Data) throws {
        guard let httpResp = resp as? HTTPURLResponse else {
            throw MaimaiAPIError.httpError(-1, "无效响应")
        }
        guard (200...299).contains(httpResp.statusCode) else {
            throw MaimaiAPIError.httpError(httpResp.statusCode, extractErrorMessage(from: data))
        }
    }

    private static func extractErrorMessage(from data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return obj["message"] as? String
    }
}
