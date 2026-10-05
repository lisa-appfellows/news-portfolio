//
//  MainDrillInModelTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-05.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

@MainActor
final class MainDrillInModelTests: XCTestCase {
    private let yesterday = TestSupport.yesterday
    private let today = TestSupport.today

    private var now: Date {
        TestSupport.createNow(year: 2026, month: 6, day: 2, hour: 10)
    }

    private func makeModel(
        category: NewsCategory = .technology,
        store: InMemoryFeedCacheStore = .init(),
        probe: DrillInClientProbe
    ) -> MainDrillInModel {
        let feeds = TestSupport.createFeed(store: store, probe: probe)
        return .init(
            category: category,
            feeds: feeds,
            calendar: TestSupport.calendar,
            now: { [now] in now }
        )
    }

    private func makePage(count: Int, totalResults: Int, urlPrefix: String) -> NewsPage {
        let articles = (1...count).map { index in
            Article(
                title: "\(urlPrefix)-\(index)",
                url: "https://example.com/\(urlPrefix)/\(index)"
            )
        }
        return NewsPage(articles: articles, totalResults: totalResults)
    }

    func testLoadInitialUsesDrillInPageSizeTwent() async {
        let page = makePage(count: 20, totalResults: 40, urlPrefix: "p1")
        let probe = DrillInClientProbe(pagesByPageNumber: [1: page])
        let model = makeModel(probe: probe)

        await model.loadInitial()

        let requests = await probe.topHeadlinesRequests

        XCTAssertEqual(requests.count, 1)

        let first = requests.first
        XCTAssertEqual(first?.pageSize, 20)
        XCTAssertEqual(first?.page, 1)
        XCTAssertEqual(first?.category, .technology)

        XCTAssertEqual(model.phase, .loaded)
        XCTAssertEqual(model.articles.count, 20)
        XCTAssertTrue(model.canLoadMore)
    }

    func testLoadInitialSameDayCacheHitDoesNotFetch() async {
        let store = InMemoryFeedCacheStore()
        let cached = makePage(count: 20, totalResults: 40, urlPrefix: "cached")
        let query = MainFeedQuery(category: .business, kind: .drillIn(page: 1))
        await store.save(cached, for: query.makeKey(today), day: today)

        let probe = DrillInClientProbe(pagesByPageNumber: [:])
        let model = makeModel(category: .business, store: store, probe: probe)

        await model.loadInitial()

        let requests = await probe.topHeadlinesRequests
        XCTAssertEqual(requests.count, 0)
        XCTAssertEqual(model.phase, .loaded)
        XCTAssertEqual(model.articles.count, 20)
        XCTAssertEqual(model.articles.first?.title, "cached-1")
    }

    func testLoadInitialFailureWithNoArticlesIsFailed() async {
        let probe = DrillInClientProbe(error: .transport("offline"))
        let model = makeModel(probe: probe)

        await model.loadInitial()

        XCTAssertEqual(model.phase, .failed(.transport("offline")))
        XCTAssertTrue(model.articles.isEmpty)
        XCTAssertFalse(model.canLoadMore)
    }

    func testLoadMoreAppendsNextPageAndAdvances() async {
        let page1 = makePage(count: 20, totalResults: 40, urlPrefix: "p1")
        let page2 = makePage(count: 20, totalResults: 40, urlPrefix: "p2")
        let probe = DrillInClientProbe(pagesByPageNumber: [1: page1, 2: page2])
        let model = makeModel(probe: probe)

        await model.loadInitial()
        await model.loadMore()

        let requests = await probe.topHeadlinesRequests
        XCTAssertEqual(requests.map(\.page), [1, 2])
        XCTAssertEqual(model.articles.count, 40)
        XCTAssertEqual(model.articles.first?.url, "https://example.com/p1/1")
        XCTAssertEqual(model.articles.last?.url, "https://example.com/p2/20")
        XCTAssertFalse(model.canLoadMore) // hit totalResults
        XCTAssertFalse(model.isLoadingMore)
    }

    func testLoadMoreShortPageStopsPagination() async {
        let page1 = makePage(count: 20, totalResults: 100, urlPrefix: "p1")
        let page2 = makePage(count: 5, totalResults: 100, urlPrefix: "p2")
        let probe = DrillInClientProbe(pagesByPageNumber: [1: page1, 2: page2])
        let model = makeModel(probe: probe)

        await model.loadInitial()
        await model.loadMore()

        XCTAssertEqual(model.articles.count, 25)
        XCTAssertFalse(model.canLoadMore)
    }

    func testLoadMoreFailureKeepsArticlesAndSetsFlag() async {
        let page1 = makePage(count: 20, totalResults: 40, urlPrefix: "p1")
        let probe = DrillInClientProbe(pagesByPageNumber: [1: page1])
        await probe.setError(.rateLimited, forPage: 2)
        let model = makeModel(probe: probe)

        await model.loadInitial()
        await model.loadMore()

        XCTAssertEqual(model.phase, .loaded)
        XCTAssertEqual(model.articles.count, 20)
        XCTAssertTrue(model.loadMoreFailed)
        XCTAssertTrue(model.canLoadMore)
        XCTAssertFalse(model.isLoadingMore)
    }

    func testStaleInitialStaysQuietWhenRevalidateFails() async {
        let store = InMemoryFeedCacheStore()
        let stale = makePage(count: 20, totalResults: 40, urlPrefix: "stale")
        let query = MainFeedQuery(category: .sports, kind: .drillIn(page: 1))
        await store.save(stale, for: query.makeKey(yesterday), day: yesterday)

        let probe = DrillInClientProbe(error: .transport("offline"))
        let model = makeModel(category: .sports, store: store, probe: probe)

        await model.loadInitial()

        XCTAssertEqual(model.phase, .loaded)
        XCTAssertEqual(model.articles.count, 20)
        XCTAssertEqual(model.articles.first?.title, "stale-1")
    }
}

// MARK: - Helper
private actor DrillInClientProbe: TestFeedProbing {
    private var pagesByPageNumber: [Int: NewsPage]
    private var errorByPage: [Int: NewsFeedError] = [:]
    private var defaultError: NewsFeedError?
    private(set) var topHeadlinesRequests: [TopHeadlinesRequest] = []

    init(pagesByPageNumber: [Int: NewsPage]) {
        self.pagesByPageNumber = pagesByPageNumber
        self.defaultError = nil
    }

    init(error: NewsFeedError) {
        self.pagesByPageNumber = [:]
        self.defaultError = error
    }

    func setError(_ error: NewsFeedError, forPage page: Int) {
        errorByPage[page] = error
    }

    func topHeadlines(_ request: TopHeadlinesRequest) async throws -> NewsPage {
        topHeadlinesRequests.append(request)
        let page = request.page

        if let error = errorByPage[page] ?? defaultError {
            throw error
        }

        guard let newsPage = pagesByPageNumber[page] else {
            throw NewsFeedError.transport("missing page \(page)")
        }

        return newsPage
    }

    func everything(_ request: EverythingRequest) async throws -> NewsPage {
        TestSupport.newsPageEmpty()
    }
}
