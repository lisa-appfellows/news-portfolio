//
//  FeedFetchingTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-01.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

final class FeedFetchingTests: XCTestCase {
    private let today = TestSupport.feedCacheDay
    private var now: Date {
        TestSupport.createNow(year: 2026, month: 6, day: 1, hour: 10)
    }

    private func collect(_ stream: AsyncStream<FeedLoadEvent>) async -> [FeedLoadEvent] {
        var events: [FeedLoadEvent] = []
        for await event in stream {
            events.append(event)
        }
        return events
    }

    private func makeFetching(store: InMemoryFeedCacheStore, probe: ClientProbe) -> FeedFetching {
        TestSupport.createFeed(store: store, probe: probe)
    }

    func testLoadMainUsesTopHeadlinesAndSaves() async {
        let store = InMemoryFeedCacheStore()
        let page = TestSupport.newsPage1Article(
            title: "Main",
            url: "https://example.com/m"
        )
        let probe = ClientProbe(page: page)
        let feeds = makeFetching(store: store, probe: probe)
        let query = MainFeedQuery(category: .technology, kind: .home)

        let events = await collect(
            feeds.load(query, calendar: TestSupport.calendar, now: now)
        )

        let topCount = await probe.topHeadlinesCount
        let everythingCount = await probe.everythingCount
        let lastTop = await probe.lastTopHeadlinesRequest
        let saved = await store.payload(for: query.makeKey(today))

        XCTAssertEqual(events, [.loading, .page(page, freshness: .network)])
        XCTAssertEqual(topCount, 1)
        XCTAssertEqual(everythingCount, 0)
        XCTAssertEqual(lastTop, query.request)
        XCTAssertEqual(saved, page)
    }

    func testLoadDiscoverUsesEverythingAndPublishedAt() async {
        let store = InMemoryFeedCacheStore()
        let page = TestSupport.newsPage1Article(
            title: "Discover",
            url: "https://example.com/d"
        )
        let probe = ClientProbe(page: page)
        let feeds = makeFetching(store: store, probe: probe)
        let query = DiscoverFeedQuery(q: "swift", timeFrame: .today, language: "en")

        let events = await collect(
            feeds.load(query, calendar: TestSupport.calendar, now: now)
        )

        let topCount = await probe.topHeadlinesCount
        let everythingCount = await probe.everythingCount
        let lastEverything = await probe.lastEverythingRequest
        let expectedRequest = query.request(calendar: TestSupport.calendar, now: now)

        XCTAssertEqual(events, [.loading, .page(page, freshness: .network)])
        XCTAssertEqual(topCount, 0)
        XCTAssertEqual(everythingCount, 1)
        XCTAssertEqual(lastEverything, expectedRequest)
        XCTAssertEqual(lastEverything?.sortBy, .publishedAt)
    }

    func testMainSameDayCacheHitDoesNotCallClient() async {
        let store = InMemoryFeedCacheStore()
        let query = MainFeedQuery(category: .business, kind: .home)
        let cached = TestSupport.newsPage1Article(
            title: "Cached",
            url: "https://example.com/c"
        )
        await store.save(cached, for: query.makeKey(today), day: today)
        
        let probe = ClientProbe(page: TestSupport.newsPageEmpty())
        let feeds = makeFetching(store: store, probe: probe)
        
        let events = await collect(
            feeds.load(query, calendar: TestSupport.calendar, now: now)
        )

        let topCount = await probe.topHeadlinesCount
        let everythingCount = await probe.everythingCount

        XCTAssertEqual(events, [.page(cached, freshness: .cached)])
        XCTAssertEqual(topCount, 0)
        XCTAssertEqual(everythingCount, 0)
    }
}

// MARK: - Helper
private actor ClientProbe: TestFeedProbing {
    private let page: NewsPage
    private(set) var topHeadlinesCount = 0
    private(set) var everythingCount = 0
    private(set) var lastTopHeadlinesRequest: TopHeadlinesRequest?
    private(set) var lastEverythingRequest: EverythingRequest?

    init(page: NewsPage) {
        self.page = page
    }

    func topHeadlines(_ request: TopHeadlinesRequest) async throws -> NewsPage {
        topHeadlinesCount += 1
        lastTopHeadlinesRequest = request
        return page
    }

    func everything(_ request: EverythingRequest) async throws -> NewsPage {
        everythingCount += 1
        lastEverythingRequest = request
        return page
    }
}
