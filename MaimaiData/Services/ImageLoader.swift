import SwiftUI
import UIKit

final class CoverImageCache: @unchecked Sendable {
    static let shared = CoverImageCache()

    private let memory = NSCache<NSString, UIImage>()
    private let diskDir: URL
    private let session: URLSession

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
        "jacket_\(song.baseJacketId)"
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

        let diskFile = diskDir.appendingPathComponent("\(keyString).png")
        if let data = try? Data(contentsOf: diskFile),
           let rawImg = UIImage(data: data) {
            let prepared = await rawImg.byPreparingForDisplay() ?? rawImg
            memory.setObject(prepared, forKey: key)
            return prepared
        }

        for url in song.coverCandidateURLs {
            if Task.isCancelled { return nil }
            if let data = await downloadImageData(url: url),
               let rawImg = UIImage(data: data) {
                try? data.write(to: diskFile, options: .atomic)
                let prepared = await rawImg.byPreparingForDisplay() ?? rawImg
                memory.setObject(prepared, forKey: key)
                return prepared
            }
        }
        return nil
    }

    private func downloadImageData(url: URL) async -> Data? {
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
                image = loaded
            }
        }
    }
}
