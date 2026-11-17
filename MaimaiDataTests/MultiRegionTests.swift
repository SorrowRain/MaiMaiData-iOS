import XCTest
import UIKit
@testable import MaimaiData

final class MultiRegionTests: XCTestCase {
    func testAPPlusOneSingleSongRatingAndRecordProjection() throws {
        // Base 14.8 @ 100.5000% = 333
        XCTAssertEqual(
            RatingCalculator.singleSongRating(ds: 14.8, achievement: 100.5, isAP: true, apBonusEnabled: false),
            333
        )
        XCTAssertEqual(
            RatingCalculator.singleSongRating(ds: 14.8, achievement: 100.5, isAP: true, apBonusEnabled: true),
            334
        )
        XCTAssertEqual(
            RatingCalculator.singleSongRating(ds: 14.8, achievement: 100.5, isAP: false, apBonusEnabled: true),
            333
        )

        let recordJSON = """
        {
            "achievements": 100.5000,
            "ds": 14.7,
            "fc": "ap",
            "fs": "fsp",
            "level": "14+",
            "level_index": 3,
            "ra": 330,
            "rate": "sssp",
            "song_id": 11663,
            "title": "Test Song",
            "type": "DX"
        }
        """.data(using: .utf8)!
        let cnRecord = try JSONDecoder().decode(ProberRecord.self, from: recordJSON)
        XCTAssertEqual(cnRecord.computedRating, 330)

        let jpSong = SongData(
            basicInfo: .init(
                artist: "Artist",
                bpm: 180,
                from: "MAGiCAL",
                genre: "舞萌",
                isNew: true,
                title: "Test Song",
                version: "MAGiCAL"
            ),
            charts: (0..<4).map { _ in .init(charter: "-", notes: [100, 10, 10, 10, 10]) },
            ds: [4.0, 8.0, 11.5, 14.8],
            oldDs: [4.0, 8.0, 11.5, 14.7],
            id: "11663",
            level: ["4", "8", "11+", "14+"],
            title: "Test Song",
            type: "DX",
            alias: nil
        )

        // CN keeps original 14.7 without AP+1 (330)
        let cnProjected = cnRecord.projected(onto: jpSong, region: .cn)
        XCTAssertEqual(cnProjected.ds, 14.7)
        XCTAssertEqual(cnProjected.computedRating, 330)

        // JP & INTL project to 14.8 (333) + AP bonus (+1) = 334
        let jpProjected = cnRecord.projected(onto: jpSong, region: .jp)
        XCTAssertEqual(jpProjected.ds, 14.8)
        XCTAssertEqual(jpProjected.computedRating, 334)

        let intlProjected = cnRecord.projected(onto: jpSong, region: .intl)
        XCTAssertEqual(intlProjected.computedRating, 334)

        // Round-trip encoding of ProberRecord stays clean
        let reencoded = try JSONEncoder().encode(jpProjected)
        let roundTrip = try JSONDecoder().decode(ProberRecord.self, from: reencoded)
        XCTAssertEqual(roundTrip.songId, 11663)
        XCTAssertEqual(roundTrip.apBonusEnabled, false)
    }

    func testZetarakuConverterCNJoinOverridesB15AndNullSafety() throws {
        let cnLink = SongData(
            basicInfo: .init(
                artist: "Clean Tears",
                bpm: 132,
                from: "maimai ORANGE",
                genre: "niconico & VOCALOID",
                isNew: false,
                title: "Link(CoF)",
                version: "14000"
            ),
            charts: (0..<4).map { _ in .init(charter: "-", notes: [100, 20, 20, 10]) },
            ds: [3.0, 6.0, 9.0, 12.4],
            oldDs: nil,
            id: "383",
            level: ["3", "6", "9", "12"],
            title: "Link(CoF)",
            type: "SD",
            alias: ["cof", "link cof"]
        )

        let cnUtage = SongData(
            basicInfo: .init(
                artist: "Artist U",
                bpm: 200,
                from: "舞萌DX 2025",
                genre: "宴会場",
                isNew: false,
                title: "[協]Test Utage",
                version: "25000"
            ),
            charts: [.init(charter: "Utage Charter", notes: [200, 30, 40, 10, 20])],
            ds: [13.7],
            oldDs: nil,
            id: "100018",
            level: ["13+?"],
            title: "[協]Test Utage",
            type: "DX",
            alias: nil
        )

        let rawCatalogJSON = """
        {
          "updateTime": "2026-10-29",
          "songs": [
            {
              "songId": "Link (2)",
              "category": "niconico＆ボーカロイド",
              "title": "Link",
              "artist": "Clean Tears",
              "bpm": 132.0,
              "imageName": "link_cof.png",
              "version": "ORANGE",
              "releaseDate": "2014-09-18",
              "sheets": [
                { "type": "std", "difficulty": "basic", "level": "3", "internalLevelValue": 3.0, "noteDesigner": null, "noteCounts": { "tap": 100, "hold": 20, "slide": 20, "touch": null, "break": 10, "total": 150 }, "regions": { "jp": true, "intl": true }, "version": "ORANGE" },
                { "type": "std", "difficulty": "advanced", "level": "6", "internalLevelValue": 6.0, "noteDesigner": null, "noteCounts": { "tap": 100, "hold": 20, "slide": 20, "touch": null, "break": 10, "total": 150 }, "regions": { "jp": true, "intl": true }, "version": "ORANGE" },
                { "type": "std", "difficulty": "expert", "level": "9", "internalLevelValue": 9.0, "noteDesigner": "-", "noteCounts": { "tap": 100, "hold": 20, "slide": 20, "touch": null, "break": 10, "total": 150 }, "regions": { "jp": true, "intl": true }, "version": "ORANGE" },
                {
                  "type": "std",
                  "difficulty": "master",
                  "level": "12+",
                  "internalLevelValue": 12.6,
                  "noteDesigner": "Re-rated Charter",
                  "noteCounts": { "tap": 300, "hold": 40, "slide": 50, "touch": null, "break": 20, "total": 410 },
                  "regions": { "jp": true, "intl": true },
                  "regionOverrides": {
                    "intl": { "level": "12", "internalLevelValue": 12.5, "version": "ORANGE" }
                  },
                  "version": "ORANGE"
                }
              ]
            },
            {
              "songId": "Happy Halloween",
              "category": "POPS＆アニメ",
              "title": "Happy Halloween",
              "artist": "Junky",
              "bpm": 150.0,
              "imageName": "happy_halloween.png",
              "version": "MAGiCAL",
              "releaseDate": "2026-10-29",
              "sheets": [
                { "type": "dx", "difficulty": "basic", "level": "4", "internalLevelValue": 4.0, "noteDesigner": "-", "noteCounts": { "tap": 80, "hold": 10, "slide": 10, "touch": 5, "break": 5, "total": 110 }, "regions": { "jp": true, "intl": false }, "version": "MAGiCAL" },
                { "type": "dx", "difficulty": "advanced", "level": "7", "internalLevelValue": 7.2, "noteDesigner": "-", "noteCounts": { "tap": 120, "hold": 15, "slide": 15, "touch": 10, "break": 8, "total": 168 }, "regions": { "jp": true, "intl": false }, "version": "MAGiCAL" },
                { "type": "dx", "difficulty": "expert", "level": "10+", "internalLevelValue": 10.6, "noteDesigner": "Ex", "noteCounts": { "tap": 250, "hold": 30, "slide": 30, "touch": 20, "break": 15, "total": 345 }, "regions": { "jp": true, "intl": false }, "version": "MAGiCAL" },
                { "type": "dx", "difficulty": "master", "level": "13+", "internalLevelValue": 13.8, "noteDesigner": "Mas", "noteCounts": { "tap": 450, "hold": 60, "slide": 70, "touch": 40, "break": 30, "total": 650 }, "regions": { "jp": true, "intl": false }, "version": "MAGiCAL" }
              ]
            },
            {
              "songId": "[協]Test Utage",
              "category": "宴会場",
              "title": "[協]Test Utage",
              "artist": "Artist U",
              "bpm": null,
              "imageName": "utage.png",
              "version": "PRiSM",
              "releaseDate": "2025-01-01",
              "sheets": [
                { "type": "utage", "difficulty": "【協】", "level": "13+?", "internalLevelValue": 13.7, "noteDesigner": null, "noteCounts": { "tap": null, "hold": null, "slide": null, "touch": null, "break": null, "total": null }, "regions": { "jp": true, "intl": true }, "version": null }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let catalog = try JSONDecoder().decode(ZetarakuCatalog.self, from: rawCatalogJSON)

        // JP conversion
        let jpSongs = ZetarakuCatalogConverter.convert(catalog, region: .jp, cnReference: [cnLink, cnUtage])
        XCTAssertEqual(jpSongs.count, 3)

        let jpLink = try XCTUnwrap(jpSongs.first { $0.id == "383" })
        XCTAssertEqual(jpLink.ds[3], 12.6)
        // Master changed 12.4 -> 12.6, so resolvedCharts[3].oldDs exposes 12.4; Basic stayed 3.0 -> nil
        XCTAssertEqual(jpLink.resolvedCharts[3].oldDs, 12.4)
        XCTAssertNil(jpLink.resolvedCharts[0].oldDs)
        XCTAssertTrue(jpLink.alias?.contains("cof") == true)
        XCTAssertTrue(jpLink.alias?.contains("Link(CoF)") == true)
        XCTAssertFalse(jpLink.basicInfo.isNew)

        let jpMagical = try XCTUnwrap(jpSongs.first { $0.title == "Happy Halloween" })
        XCTAssertEqual(jpMagical.numericId, 0)
        XCTAssertTrue(jpMagical.basicInfo.isNew)
        XCTAssertEqual(jpMagical.basicInfo.genre, "流行&动漫")
        XCTAssertEqual(
            jpMagical.coverCandidateURLs.map(\.absoluteString),
            ["https://dp4p6x0xfi5o9.cloudfront.net/maimai/img/cover/happy_halloween.png"]
        )

        let jpUtage = try XCTUnwrap(jpSongs.first { $0.isUtage })
        XCTAssertEqual(jpUtage.id, "100018")
        XCTAssertEqual(jpUtage.basicInfo.bpm, 0)
        // Null Zetaraku Utage noteCounts fell back to CN Utage's note counts
        XCTAssertEqual(jpUtage.resolvedCharts[0].totalNotes, 300)

        // INTL conversion excludes JP-only MAGiCAL song and applies intl override on Link Master (12.5)
        let intlSongs = ZetarakuCatalogConverter.convert(catalog, region: .intl, cnReference: [cnLink, cnUtage])
        XCTAssertEqual(intlSongs.count, 2)
        let intlLink = try XCTUnwrap(intlSongs.first { $0.id == "383" })
        XCTAssertEqual(intlLink.ds[3], 12.5)
        XCTAssertEqual(intlLink.level[3], "12")
    }

    func testB15TwoGenerationRuleAndAllVersionAssetsExist() {
        XCTAssertTrue(ZetarakuCatalogConverter.isB15NewVersion("MAGiCAL", region: .jp))
        XCTAssertTrue(ZetarakuCatalogConverter.isB15NewVersion("CiRCLE PLUS", region: .jp))
        XCTAssertFalse(ZetarakuCatalogConverter.isB15NewVersion("CiRCLE", region: .jp))

        XCTAssertTrue(ZetarakuCatalogConverter.isB15NewVersion("CiRCLE PLUS", region: .intl))
        XCTAssertTrue(ZetarakuCatalogConverter.isB15NewVersion("CiRCLE", region: .intl))
        XCTAssertFalse(ZetarakuCatalogConverter.isB15NewVersion("PRiSM PLUS", region: .intl))

        XCTAssertEqual(MaimaiConstants.checklistVersions(for: .cn).count, 20)
        XCTAssertEqual(MaimaiConstants.checklistVersions(for: .intl).count, 27)
        XCTAssertEqual(MaimaiConstants.checklistVersions(for: .jp).count, 28)

        XCTAssertEqual(
            MaimaiConstants.expandVersionFilter(["GreeN", "MAGiCAL"], region: .jp),
            ["GreeN", "GreeN PLUS", "MAGiCAL"]
        )

        for ver in MaimaiConstants.cnVersions {
            XCTAssertNotNil(UIImage(named: ver.asset), "Missing CN version asset: \(ver.asset)")
        }
        for ver in MaimaiConstants.jpVersions {
            XCTAssertNotNil(UIImage(named: ver.asset), "Missing JP version asset: \(ver.asset)")
        }
    }
}
