import SwiftUI
import UIKit

final class CoverImageCache: @unchecked Sendable {
    static let shared = CoverImageCache()

    private let memory = NSCache<NSString, UIImage>()
    private let diskDir: URL
    private let session: URLSession
    private let coordinator = InFlightCoordinator()

    private init() {
        memory.countLimit = 400
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskDir = caches.appendingPathComponent("MaimaiCovers", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDir, withIntermediateDirectories: true)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 30
        config.httpMaximumConnectionsPerHost = 8
        session = URLSession(configuration: config)
    }

    func clearCache() {
        memory.removeAllObjects()
        try? FileManager.default.removeItem(at: diskDir)
        try? FileManager.default.createDirectory(at: diskDir, withIntermediateDirectories: true)
    }

    func cacheSizeBytes() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(at: diskDir, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        return files.reduce(0) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return sum + Int64(size)
        }
    }

    private func cacheKey(for song: SongData) -> String {
        if song.numericId > 0, song.preferRemoteCover != true {
            return "jacket_\(song.baseJacketId)"
        }
        if let remote = song.remoteCoverName, !remote.isEmpty {
            let sanitized = remote.replacingOccurrences(of: "/", with: "_")
            let stem = (sanitized as NSString).deletingPathExtension
            return "jacket_remote_\(stem.isEmpty ? sanitized : stem)"
        }
        if song.numericId > 0 {
            return "jacket_\(song.baseJacketId)"
        }
        return "jacket_\(song.id)"
    }

    func cachedMemoryImage(for song: SongData) -> UIImage? {
        memory.object(forKey: cacheKey(for: song) as NSString)
    }

    func loadCover(song: SongData) async -> UIImage? {
        let keyString = cacheKey(for: song)
        let key = keyString as NSString

        if let cached = memory.object(forKey: key) {
            return cached
        }

        let urls = song.coverCandidateURLs
        let diskFile = diskDir.appendingPathComponent("\(keyString).png")
        let loaded = await coordinator.coalesce(key: keyString) { [session] in
            await Self.fetchFromDiskOrNetwork(diskFile: diskFile, urls: urls, session: session)
        }
        if let loaded {
            memory.setObject(loaded, forKey: key)
        }
        return loaded
    }

    private static func fetchFromDiskOrNetwork(
        diskFile: URL,
        urls: [URL],
        session: URLSession
    ) async -> UIImage? {
        if let diskImage = await Task.detached(priority: .utility, operation: { () -> UIImage? in
            guard let data = try? Data(contentsOf: diskFile) else { return nil }
            return UIImage(data: data)
        }).value {
            return await diskImage.byPreparingForDisplay() ?? diskImage
        }

        for url in urls {
            if Task.isCancelled { return nil }
            if let data = await downloadImageData(url: url, session: session),
               let rawImg = UIImage(data: data) {
                try? data.write(to: diskFile, options: .atomic)
                return await rawImg.byPreparingForDisplay() ?? rawImg
            }
        }
        return nil
    }

    private static func downloadImageData(url: URL, session: URLSession) async -> Data? {
        do {
            var req = URLRequest(url: url)
            req.setValue("MaimaiData-iOS/1.0", forHTTPHeaderField: "User-Agent")
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  !data.isEmpty else {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }
}

private actor InFlightCoordinator {
    private var tasks: [String: Task<UIImage?, Never>] = [:]

    func coalesce(key: String, operation: @escaping @Sendable () async -> UIImage?) async -> UIImage? {
        if let existing = tasks[key] {
            return await existing.value
        }
        let task = Task {
            await operation()
        }
        tasks[key] = task
        let result = await task.value
        tasks[key] = nil
        return result
    }
}

struct CoverImageView: View {
    let song: SongData?

    @State private var image: UIImage?

    var body: some View {
        let displayed = image ?? song.flatMap { CoverImageCache.shared.cachedMemoryImage(for: $0) }
        Group {
            if let displayed {
                Image(uiImage: displayed)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image("mmd_song_jacket_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .task(id: song?.id) {
            guard let song else {
                image = nil
                return
            }
            if let mem = CoverImageCache.shared.cachedMemoryImage(for: song) {
                image = mem
                return
            }
            if let loaded = await CoverImageCache.shared.loadCover(song: song) {
                withAnimation(.easeOut(duration: 0.18)) {
                    image = loaded
                }
            }
        }
    }
}
