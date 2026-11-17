import UIKit

enum Best50Renderer {
    private static let itemWidth: CGFloat = 200
    private static let itemHeight: CGFloat = 250
    private static let itemPadding: CGFloat = 10
    private static let versionPadding: CGFloat = 50
    private static let headerHeight: CGFloat = 250
    private static let containerWidth: CGFloat = itemWidth * 10 + itemPadding * 10 + versionPadding
    private static let containerHeight: CGFloat = itemHeight * 5 + itemPadding * 5

    static func render(
        playerName: String,
        songsById: [Int: SongData],
        b35: [ProberRecord],
        b15: [ProberRecord]
    ) async -> UIImage? {
        let allRecords = b35 + b15
        guard !allRecords.isEmpty else { return nil }

        // Prefetch covers concurrently with a strict per-cover timeout so B50 never hangs
        var covers: [Int: UIImage] = [:]
        let uniqueIds = Array(Set(allRecords.map(\.songId)))

        for id in uniqueIds {
            if let song = songsById[id],
               let mem = CoverImageCache.shared.cachedMemoryImage(for: song) {
                covers[id] = mem
            }
        }

        let missingIds = uniqueIds.filter { covers[$0] == nil }
        if !missingIds.isEmpty {
            await withTaskGroup(of: (Int, UIImage?).self) { group in
                for id in missingIds {
                    guard let song = songsById[id] else { continue }
                    group.addTask {
                        let img = await CoverImageCache.shared.loadCover(song: song)
                        return (id, img)
                    }
                }
                for await (id, img) in group {
                    if let img { covers[id] = img }
                }
            }
        }

        let frozenCovers = covers
        return await Task.detached(priority: .userInitiated) {
            drawBest50Canvas(
                playerName: playerName,
                covers: frozenCovers,
                b35: b35,
                b15: b15
            )
        }.value
    }

    private static func drawBest50Canvas(
        playerName: String,
        covers: [Int: UIImage],
        b35: [ProberRecord],
        b15: [ProberRecord]
    ) -> UIImage {
        let totalSize = CGSize(width: containerWidth, height: containerHeight + headerHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: totalSize, format: format)
        return renderer.image { _ in
            if let bg = UIImage(named: "mmd_player_best50") {
                bg.draw(in: CGRect(origin: .zero, size: totalSize))
            } else {
                UIColor(red: 0.25, green: 0.58, blue: 0.94, alpha: 1).setFill()
                UIRectFill(CGRect(origin: .zero, size: totalSize))
            }

            // Old Version (B35: 7 columns x 5 rows)
            for (idx, record) in b35.enumerated() {
                let x = CGFloat(idx % 7) * (itemWidth + itemPadding)
                let y = headerHeight + CGFloat(idx / 7) * (itemHeight + itemPadding)
                drawRecordCard(record, cover: covers[record.songId], at: CGPoint(x: x, y: y))
            }

            // New Version (B15: 3 columns x 5 rows)
            let newOriginX = (itemWidth + itemPadding) * 7 + versionPadding
            for (idx, record) in b15.enumerated() {
                let x = newOriginX + CGFloat(idx % 3) * (itemWidth + itemPadding)
                let y = headerHeight + CGFloat(idx / 3) * (itemHeight + itemPadding)
                drawRecordCard(record, cover: covers[record.songId], at: CGPoint(x: x, y: y))
            }

            let oldRating = b35.reduce(0) { $0 + $1.computedRating }
            let newRating = b15.reduce(0) { $0 + $1.computedRating }
            let totalRating = oldRating + newRating

            // Rating Plate
            if let plate = UIImage(named: ratingPlateName(for: totalRating)) {
                plate.draw(in: CGRect(x: 432, y: 49, width: 203, height: 52))
            }

            // Name Box + Rating Box
            UIImage(named: "mmd_player_name_box")?.draw(in: CGRect(x: 432, y: 110, width: 302, height: 46))
            UIImage(named: "mmd_player_rating_box")?.draw(in: CGRect(x: 432, y: 165, width: 302, height: 41))

            // Player Name
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.black,
                .kern: 3.0
            ]
            (playerName as NSString).draw(
                in: CGRect(x: 446, y: 116, width: 274, height: 34),
                withAttributes: nameAttrs
            )

            // Total Rating Digits (right-to-left like Android CreateBest50)
            var rem = totalRating
            var digitIdx = 0
            if rem == 0 {
                UIImage(named: "mmd_player_num_drating_0")?.draw(in: CGRect(x: 598, y: 58, width: 28, height: 34))
            } else {
                while rem > 0 {
                    let digit = rem % 10
                    rem /= 10
                    UIImage(named: "mmd_player_num_drating_\(digit)")?
                        .draw(in: CGRect(x: 598 - 21 * CGFloat(digitIdx), y: 58, width: 28, height: 34))
                    digitIdx += 1
                }
            }

            // Breakdown Text
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.black
            ]
            let breakdown = "旧版本：\(oldRating)   现行版本：\(newRating)" as NSString
            breakdown.draw(at: CGPoint(x: 472, y: 176), withAttributes: subAttrs)
        }
    }

    private static func drawRecordCard(_ record: ProberRecord, cover: UIImage?, at origin: CGPoint) {
        let cardRect = CGRect(origin: origin, size: CGSize(width: itemWidth, height: itemHeight))

        UIImage(named: record.ratingBoardAssetName)?.draw(in: cardRect)

        // Cover jacket
        let jacketRect = CGRect(x: origin.x + 21, y: origin.y + 24, width: 158, height: 155)
        let jacket = cover ?? UIImage(named: "mmd_song_jacket_placeholder")
        jacket?.draw(in: jacketRect)

        // Difficulty tag
        if let diffImg = UIImage(named: record.ratingDiffAssetName) {
            let w = diffImg.size.width * 0.5
            let h = diffImg.size.height * 0.5
            diffImg.draw(in: CGRect(x: origin.x + itemWidth - w - 25, y: origin.y + 30, width: w, height: h))
        }

        // DX / SD type badge
        UIImage(named: record.typeAssetName)?.draw(in: CGRect(x: origin.x + 101, y: origin.y, width: 96, height: 27))

        // Rank badge
        UIImage(named: record.rankAssetName)?.draw(in: CGRect(x: origin.x + 22, y: origin.y + 145, width: 84, height: 32))

        // FC / FS badges
        if let fcName = record.fcAssetName, let fcImg = UIImage(named: fcName) {
            if let fsName = record.fsAssetName, let fsImg = UIImage(named: fsName) {
                fcImg.draw(in: CGRect(x: origin.x + 115, y: origin.y + 145, width: 34, height: 36))
                fsImg.draw(in: CGRect(x: origin.x + 145, y: origin.y + 145, width: 34, height: 36))
            } else {
                fcImg.draw(in: CGRect(x: origin.x + 145, y: origin.y + 145, width: 34, height: 36))
            }
        }

        // Title
        let titleStyle = NSMutableParagraphStyle()
        titleStyle.alignment = .center
        titleStyle.lineBreakMode = .byTruncatingTail
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.white,
            .paragraphStyle: titleStyle
        ]
        (record.title as NSString).draw(
            in: CGRect(x: origin.x + 16, y: origin.y + 186, width: itemWidth - 32, height: 20),
            withAttributes: titleAttrs
        )

        // Bottom metrics (Lv, Achievement, Ra)
        let smallAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.white
        ]
        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = .center
        let centerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.white,
            .paragraphStyle: centerStyle
        ]

        ("Lv:\(String(format: "%.1f", record.ds))" as NSString)
            .draw(at: CGPoint(x: origin.x + 20, y: origin.y + 214), withAttributes: smallAttrs)
        (String(format: "%.4f%%", record.achievements) as NSString)
            .draw(in: CGRect(x: origin.x, y: origin.y + 214, width: itemWidth, height: 18), withAttributes: centerAttrs)
        ("Ra:\(record.computedRating)" as NSString)
            .draw(at: CGPoint(x: origin.x + 140, y: origin.y + 214), withAttributes: smallAttrs)
    }

    private static func ratingPlateName(for rating: Int) -> String {
        switch rating {
        case 0...999: return "mmd_rating_plate_normal"
        case 1000...1999: return "mmd_rating_plate_blue"
        case 2000...3999: return "mmd_rating_plate_green"
        case 4000...6999: return "mmd_rating_plate_orange"
        case 7000...9999: return "mmd_rating_plate_red"
        case 10000...11999: return "mmd_rating_plate_purple"
        case 12000...12999: return "mmd_rating_plate_bronze"
        case 13000...13999: return "mmd_rating_plate_silver"
        case 14000...14499: return "mmd_rating_plate_gold"
        case 14500...14999: return "mmd_rating_plate_platinum"
        default: return "mmd_rating_plate_rainbow"
        }
    }
}
