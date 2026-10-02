//
//  FeedLoaderTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-01.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

final class FeedLoaderTests: XCTestCase {
    private let yesterday = FeedCacheDay(rawValue: "2026-06-01")!
    private let today = FeedCacheDay(rawValue: "2026-06-02")!

    private var now: Date {
        TestSupport.createNow(year: 2026, month: 6, day: 2, hour: 10)
    }

    private func makeKey(_ day: FeedCacheDay) -> FeedCacheKey {
        FeedCacheKey.topHeadlines(category: .technology, day: day)
    }

    private func collect(
        _ stream: AsyncStream<FeedLoadEvent>
    ) async -> [FeedLoadEvent] {
        var events: [FeedLoadEvent] = []
        for await event in stream {
            events.append(event)
        }
        return events
    }

    private func collectedEvents(probe: FetchProbe, loader: FeedLoader) async -> [FeedLoadEvent] {
        await collect(
            loader.load(
                calendar: TestSupport.calendar,
                now: now, 
                makeKey: { [self] day in makeKey(day) },
                fetch: { try await probe.fetch() }
            )
        )
    }
}

// MARK: - Same Day
extension FeedLoaderTests {
    func testSameDayCacheHitDoesNotFetch() async {
        let store = InMemoryFeedCacheStore()
        let cachedPage = TestSupport.newsPage1Article(
            title: "Cached",
            url: "https://example.com/c"
        )

        await store.save(cachedPage, for: makeKey(today), day: today)

        let probe = FetchProbe(page: TestSupport.newsPageEmpty())
        let loader = FeedLoader(store: store)

        let events = await collectedEvents(probe: probe, loader: loader)

        let callCount = await probe.callCount
        XCTAssertEqual(callCount, 0)
        XCTAssertEqual(events, [.page(cachedPage, freshness: .cached)])
    }

    func testSameDayMissFetchesAndSaves() async {
        let store = InMemoryFeedCacheStore()
        await store.setLastCacheDay(today)

        let networkPage = TestSupport.newsPage1Article(
            title: "Fresh",
            url: "https://example.com/f"
        )
        let probe = FetchProbe(page: networkPage)
        let loader = FeedLoader(store: store)

        let events = await collectedEvents(probe: probe, loader: loader)

        let callCount = await probe.callCount
        let saved = await store.payload(for: makeKey(today))
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(events, [.loading, .page(networkPage, freshness: .network)])
        XCTAssertEqual(saved, networkPage)
    }
}

// MARK: - Never Cached
extension FeedLoaderTests {
    func testNeverCachedSuccess() async {
        let store = InMemoryFeedCacheStore()
        let networkPage = TestSupport.newsPage1Article(
            title: "First",
            url: "https://example.com/1"
        )
        let probe = FetchProbe(page: networkPage)
        let loader = FeedLoader(store: store)
        
        let events = await collectedEvents(probe: probe, loader: loader)

        let marker = await store.lastCacheDay()
        XCTAssertEqual(events, [.loading, .page(networkPage, freshness: .network)])
        XCTAssertEqual(marker, today)
    }

    func testNeverCachedFailure() async {
        let store = InMemoryFeedCacheStore()
        let probe = FetchProbe(error: .rateLimited)
        let loader = FeedLoader(store: store)

        let events = await collectedEvents(probe: probe, loader: loader)

        XCTAssertEqual(events, [.loading, .failure(.rateLimited)])
    }
}

// MARK: - Day Roll (SWR)
extension FeedLoaderTests {
    func testDayRollPaintsStaleThenNetworkAndRemovesOld() async {
        let store = InMemoryFeedCacheStore()
        let stalePage = TestSupport.newsPage1Article(
            title: "Yesterday",
            url: "https://example.com/y"
        )
        let networkPage = TestSupport.newsPage1Article(
            title: "Today",
            url: "https://example.com/t"
        )
        await store.save(stalePage, for: makeKey(yesterday), day: yesterday)

        let probe = FetchProbe(page: networkPage)
        let loader = FeedLoader(store: store)

        let events = await collectedEvents(probe: probe, loader: loader)

        let oldPayload = await store.payload(for: makeKey(yesterday))
        let newPayload = await store.payload(for: makeKey(today))
        let marker = await store.lastCacheDay()

        XCTAssertEqual(
            events,
            [.page(stalePage, freshness: .stale),
             .page(networkPage, freshness: .network)]
        )
        XCTAssertNil(oldPayload)
        XCTAssertEqual(newPayload, networkPage)
        XCTAssertEqual(marker, today)
    }

    func testDayRollFetchFailureKeepsStaleQuietly() async {
        let store = InMemoryFeedCacheStore()
        let stalePage = TestSupport.newsPage1Article(
            title: "Stale",
            url: "https://example.com/s"
        )
        let yesterdayKey = makeKey(yesterday)
        await store.save(stalePage, for: yesterdayKey, day: yesterday)

        let probe = FetchProbe(error: .transport("offline"))
        let loader = FeedLoader(store: store)

        let events = await collectedEvents(probe: probe, loader: loader)

        let oldPayload = await store.payload(for: yesterdayKey)
        XCTAssertEqual(events, [.page(stalePage, freshness: .stale)])
        XCTAssertEqual(oldPayload, stalePage)
    }

    func testDayRollMarkerWithoutPayloadStillLoads() async {
        let store = InMemoryFeedCacheStore()
        await store.setLastCacheDay(yesterday)

        let networkPage = TestSupport.newsPage1Article(
            title: "New",
            url: "https://example.com/n"
        )
        let probe = FetchProbe(page: networkPage)
        let loader = FeedLoader(store: store)

        let events  = await collectedEvents(probe: probe, loader: loader)

        XCTAssertEqual(events, [.loading, .page(networkPage, freshness: .network)])
    }
}

// MARK: - Helper
private actor FetchProbe {
    private let page: NewsPage?
    private let error: NewsFeedError?
    private(set) var callCount = 0

    init(page: NewsPage) {
        self.page = page
        self.error = nil
    }

    init(error: NewsFeedError) {
        self.page = nil
        self.error = error
    }

    func fetch() async throws -> NewsPage {
        callCount += 1
        if let error {
            throw error
        }
        return page!
    }
}
