//
//  InMemoryFeedCacheStoreTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-09-30.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

final class InMemoryFeedCacheStoreTests: XCTestCase {
    func testSaveReadsBackAndUpdatesMarker() async {
        let store = InMemoryFeedCacheStore()
        let day = FeedCacheDay(rawValue: "2026-06-01")!
        let key = FeedCacheKey.topHeadlines(category: .business, day: day)
        let page = NewsPage(
            articles: [.init(title: "Hello", url: "https://example.com/a")],
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
        XCTAssertEqual(cachedDay, day)
    }

    func testRemovePayloadLeavesMarker() async {
        let store = InMemoryFeedCacheStore()
        let day = FeedCacheDay(rawValue: "2026-06-01")!
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

    func testSetLastCacheDayAlone() async {
        let store = InMemoryFeedCacheStore()
        let day = FeedCacheDay(rawValue: "2026-06-01")!
        await store.setLastCacheDay(day)

        let cached = await store.lastCacheDay()
        XCTAssertEqual(cached, day)
    }
}
