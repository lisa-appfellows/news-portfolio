//
//  FeedCacheKeyTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-09-30.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

final class FeedCacheKeyTests: XCTestCase {
    func testTopHeadlinesShape() {
        let day = FeedCacheDay(rawValue: "2026-06-01")!
        let key = FeedCacheKey.topHeadlines(
            country: "us",
            category: .technology,
            day: day,
            page: 1
        )
        
        XCTAssertEqual(key.rawValue, "topHeadlines|us|technology|2026-06-01|p1")
    }
    
    func testEverythingIncludesPageAndNilDates() {
        let day = FeedCacheDay(rawValue: "2026-06-01")!
        let key = FeedCacheKey.everything(
            q: "swift",
            language: "en",
            from: nil,
            to: nil,
            day: day,
            page: 2
        )
        
        XCTAssertEqual(key.rawValue, "everything|swift|en|-|-|2026-06-01|p2")
    }
    
    func testEverythingDatesAreStableISO8601() {
        let day = FeedCacheDay(rawValue: "2026-06-01")!
        let from = Date(timeIntervalSince1970: 1_718_000_000) // fixed instant
        let key = FeedCacheKey.everything(
            q: "ios",
            language: "es",
            from: from,
            to: from,
            day: day
        )

        let parts = key.rawValue.split(separator: "|").map(String.init)
        XCTAssertEqual(parts[0], "everything")
        XCTAssertEqual(parts[1], "ios")
        XCTAssertEqual(parts[2], "es")
        XCTAssertEqual(parts[3], parts[4]) // same instance
        XCTAssertFalse(parts[3].isEmpty)
        XCTAssertNotEqual(parts[3], "-")
        XCTAssertEqual(parts[5], "2026-06-01")
        XCTAssertEqual(parts[6], "p1")
    }
}
