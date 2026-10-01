//
//  FileFeedCacheStoreTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-01.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

final class FileFeedCacheStoreTests: XCTestCase {
    private var directoryURL: URL!
    private var suiteName: String!

    
    override func setUp() {
        super.setUp()
        suiteName = "FileFeedCacheStoreTests.\(UUID().uuidString)"
        directoryURL = FileManager.default.temporaryDirectory
            .appending(path: suiteName, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directoryURL)
        UserDefaults().removePersistentDomain(forName: suiteName)
        directoryURL = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeStore() -> FileFeedCacheStore {
        .init(directoryURL: directoryURL, defaultsSuiteName: suiteName)
    }

    func testSaveReadsBackandUpdatesMarker() async {
        let store = makeStore()
        let day = TestSupport.feedCacheDay
        let key = FeedCacheKey.topHeadlines(category: .business, day: day)
        let page = NewsPage(
            articles: [
                .init(
                    title: "Hello",
                    url: "https://example.com/a",
                    publishedDate: TestSupport.staticDate
                )
            ],
            totalResults: 1
        )

        let startingCacheDay = await store.lastCacheDay()
        let startingPayload = await store.payload(for: key)
        XCTAssertNil(startingCacheDay)
        XCTAssertNil(startingPayload)

        await store.save(page, for: key, day: day)

        let cached = await store.payload(for: key)
        let cachedDay = await store.lastCacheDay()
        XCTAssertEqual(cached?.articles.count, 1)
        XCTAssertEqual(cached?.articles.first?.title, "Hello")
        XCTAssertEqual(
            cached?.articles.first?.publishedDate,
            TestSupport.staticDate
        )
        XCTAssertEqual(cachedDay, day)
    }

    func testRemovePayloadLeavesMarker() async {
        let store = makeStore()
        let day = TestSupport.feedCacheDay
        let key = FeedCacheKey.topHeadlines(category: .sports, day: day)
        let page = NewsPage(articles: [], totalResults: 1)

        await store.save(page, for: key, day: day)
        let savedPayload = await store.payload(for: key)
        let savedCachedDay = await store.lastCacheDay()
        XCTAssertNotNil(savedPayload)
        XCTAssertNotNil(savedCachedDay)

        await store.removePayload(for: key)

        let nilPayload = await store.payload(for: key)
        let leftCachedDay = await store.lastCacheDay()
        XCTAssertNil(nilPayload)
        XCTAssertEqual(leftCachedDay, day)
    }

    func testSetLastCachedDayAlone() async {
        let store = makeStore()
        let day = TestSupport.feedCacheDay
        await store.setLastCacheDay(day)

        let cached = await store.lastCacheDay()
        XCTAssertEqual(cached, day)
    }

    func testPayloadSurvivesNewStoreInstance() async {
        let day = TestSupport.feedCacheDay
        let key = FeedCacheKey.topHeadlines(category: .technology, day: day)
        let page = NewsPage(
            articles: [.init(title: "Persisted", url: "https://example.com/p")],
            totalResults: 1
        )

        let write = makeStore()
        await write.save(page, for: key, day: day)

        let reader = makeStore()
        let cached = await reader.payload(for: key)
        let cachedDay = await reader.lastCacheDay()
        XCTAssertEqual(cached?.articles.first?.title, "Persisted")
        XCTAssertEqual(cachedDay, day)
    }

    func testCorruptPayloadReturnsNil() async {
        let store = makeStore()
        let day = TestSupport.feedCacheDay
        let key = FeedCacheKey.topHeadlines(category: .science, day: day)

        await store.save(
            NewsPage(
                articles: [.init(title: "Ok", url: "https://example.com/ok")],
                totalResults: 1
            ),
            for: key,
            day: day
        )

        // Overwrite the only .json in the temp dir with garbage
        let files = try! FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        )
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        XCTAssertEqual(jsonFiles.count, 1)
        try! Data("not-json".utf8).write(to: jsonFiles[0])

        let cached = await store.payload(for: key)
        XCTAssertNil(cached)
        // Marker is independent of payload decode
        let cachedDay = await store.lastCacheDay()
        XCTAssertEqual(cachedDay, day)
    }
}
