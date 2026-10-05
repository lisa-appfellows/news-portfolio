//
//  MainFeedQueryTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-01.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

final class MainFeedQueryTests: XCTestCase {
    private let day = TestSupport.feedCacheDay

    func testHomeTechnologyPageSizeFour() {
        let request = MainFeedQuery(
            category: .technology,
            kind: .home
        ).request
        XCTAssertEqual(request.pageSize, 4)
        XCTAssertEqual(request.page, 1)
        XCTAssertEqual(request.country, "us")
        XCTAssertEqual(request.category, .technology)
    }

    func testHomeOtherCategoriesPageSizeSix() {
        let query = MainFeedQuery(category: .business, kind: .home)
        XCTAssertEqual(query.request.pageSize, 6)
    }

    func testDrillInUsesTwentyAndPage() {
        let request = MainFeedQuery(
            category: .sports,
            kind: .drillIn(page: 3)
        ).request
        XCTAssertEqual(request.pageSize, 20)
        XCTAssertEqual(request.page, 3)
    }

    func testMakeKeyMatchesTopHeadlinesShape() {
        let query = MainFeedQuery(category: .science, kind: .home)
        XCTAssertEqual(
            query.makeKey(day).rawValue,
            "topHeadlines|us|science|2026-06-01|ps6|p1"
        )
    }

    func testDrillInMakeKeyUsesPageSizeTwenty() {
        let query = MainFeedQuery(category: .technology, kind: .drillIn(page: 1))
        XCTAssertEqual(
            query.makeKey(day).rawValue,
            "topHeadlines|us|technology|2026-06-01|ps20|p1"
        )
    }
}
