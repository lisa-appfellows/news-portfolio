//
//  MainHomeModelTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-01.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

@MainActor
final class MainHomeModelTests: XCTestCase {
    private let yesterday = TestSupport.yesterday
    private let today = TestSupport.today

    private var now: Date {
        TestSupport.createNow(year: 2026, month: 6, day: 2, hour: 10)
    }

    private func makeModel(
        store: InMemoryFeedCacheStore = .init(),
        probe: HomeClientProbe
    ) -> MainHomeModel {
        let feeds = TestSupport.createFeed(store: store, probe: probe)
        return MainHomeModel(
            feeds: feeds,
            calendar: TestSupport.calendar,
            now: { [now] in now }
        )
    }

    func testHomeOrderIsTechnologyFirstWithSevenKnownCategories() {
        let order = MainHomeModel.homeOrder
        let orderSet = Set(order)
        XCTAssertEqual(order.first, .technology)
        XCTAssertEqual(order.count, 7)
        XCTAssertEqual(orderSet.count, 7)

        let expected: Set<NewsCategory> = [
            .technology, .business, .entertainment, .general,
            .health, .science, .sports
        ]

        XCTAssertEqual(orderSet, expected)
    }

    func testHomeLoadsAllSectionsAndUsesHomePageSizes() async {
        let page = TestSupport.newsPage1Article(
            title: "Ok",
            url: "https://example.com/ok"
        )
        let probe = HomeClientProbe(defaultBehavior: .page(page))
        let model = makeModel(probe: probe)

        await model.loadHome()

        let requests = await probe.topHeadlinesRequests
        XCTAssertEqual(requests.count, 7)
        XCTAssertFalse(model.isFullyFailed)

        for section in model.sections {
            XCTAssertEqual(section.phase, .loaded(page, freshness: .network))
        }

        let tech = requests.first { $0.category == .technology }
        let business = requests.first { $0.category == .business }
        XCTAssertEqual(tech?.pageSize, 4)
        XCTAssertEqual(business?.pageSize, 6)
    }

    func testLoadHomeAllFailuresIsFullyLoaded() async {
        let probe = HomeClientProbe(defaultBehavior: .error(.transport("offline")))
        let model = makeModel(probe: probe)

        await model.loadHome()

        XCTAssertTrue(model.isFullyFailed)
        for section in model.sections {
            XCTAssertEqual(section.phase, .failed(.transport("offline")))
        }
    }

    func testPartialFailureLeavesOtherSectionsLoaded() async {
        let page = TestSupport.newsPage1Article(
            title: "Ok",
            url: "https://example.com/ok"
        )
        let probe = HomeClientProbe(defaultBehavior: .page(page))
        await probe.setBehavior(.error(.rateLimited), for: .sports)
        let model = makeModel(probe: probe)

        await model.loadHome()

        XCTAssertFalse(model.isFullyFailed)

        let sports = model.sections.first { $0.category == .sports }
        let tech = model.sections.first { $0.category == .technology }
        XCTAssertEqual(sports?.phase, .failed(.rateLimited))
        XCTAssertEqual(tech?.phase, .loaded(page, freshness: .network))
    }

    func testStaleSectionStaysQuietWhenRevalidateFails() async {
        let store = InMemoryFeedCacheStore()
        let stale = TestSupport.newsPage1Article(
            title: "Yesterday",
            url: "https://example.com/y"
        )
        let query = MainFeedQuery(category: .technology, kind: .home)
        await store.save(stale, for: query.makeKey(yesterday), day: yesterday)

        let probe = HomeClientProbe(defaultBehavior: .error(.transport("offline")))
        let model = makeModel(store: store, probe: probe)

        await model.loadHome()

        let tech = model.sections.first { $0.category == .technology }
        XCTAssertEqual(tech?.phase, .loaded(stale, freshness: .stale))
        XCTAssertFalse(model.isFullyFailed)
    }
}

// MARK: - Helper
private actor HomeClientProbe: TestFeedProbing {
    enum Behavior: Sendable {
        case page(NewsPage)
        case error(NewsFeedError)
    }

    private var defaultBehavior: Behavior
    private var behaviorByCategory: [NewsCategory: Behavior] = [:]
    private(set) var topHeadlinesRequests: [TopHeadlinesRequest] = []

    init(defaultBehavior: Behavior) {
        self.defaultBehavior = defaultBehavior
    }

    func setBehavior(_ behavior: Behavior, for category: NewsCategory) {
        behaviorByCategory[category] = behavior
    }

    func topHeadlines(_ request: TopHeadlinesRequest) async throws -> NewsPage {
        topHeadlinesRequests.append(request)
        let category = request.category ?? .general
        switch behaviorByCategory[category] ?? defaultBehavior {
        case .page(let page):
            return page
        case .error(let error):
            throw error
        }
    }

    func everything(_ request: EverythingRequest) async throws -> NewsPage {
        TestSupport.newsPageEmpty()
    }
}
