//
//  DiscoverFeedQueryTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-01.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

final class DiscoverFeedQueryTests: XCTestCase {
    private var calendar: Calendar { TestSupport.calendar }
    private let day = TestSupport.feedCacheDay

    private var now: Date {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 6
        comps.day = 2
        comps.hour = 15
        return calendar.date(from: comps)!
    }

    func testRequestUsesPublishedAtAndPageSize() {
        let query = DiscoverFeedQuery(
            q: "swift",
            timeFrame: .today,
            language: "en",
            page: 2,
            pageSize: 20
        )
        let request = query.request(calendar: calendar, now: now)

        XCTAssertEqual(request.q, "swift")
        XCTAssertEqual(request.language, "en")
        XCTAssertEqual(request.sortBy, .publishedAt)
        XCTAssertEqual(request.page, 2)
        XCTAssertEqual(request.pageSize, 20)
    }

    func testMakeKeyAlignsWithRequestDates() {
        let query = DiscoverFeedQuery(
            q: "ios",
            timeFrame: .lastTwoWeeks,
            language: "es"
        )
        let request = query.request(calendar: calendar, now: now)
        let key = query.makeKey(day, calendar: calendar, now: now)
        let expected = FeedCacheKey.everything(
            q: "ios",
            language: "es",
            from: request.from,
            to: request.to,
            day: day,
            page: 1
        )

        XCTAssertEqual(key, expected)
    }

    func testContentLanguageSpanishAndFallback() {
        XCTAssertEqual(DiscoverContentLanguage.code(from: Locale(identifier: "es")), "es")
        XCTAssertEqual(DiscoverContentLanguage.code(from: Locale(identifier: "es-MX")), "es")
        XCTAssertEqual(DiscoverContentLanguage.code(from: Locale(identifier: "fr")), "en")
        XCTAssertEqual(DiscoverContentLanguage.code(from: Locale(identifier: "en-US")), "en")
    }
}
