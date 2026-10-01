//
//  FeedCacheDayTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-09-30.
//

import XCTest
@testable import NewsPortfolio

final class FeedCacheDayTests: XCTestCase {
    func testFormatsLocalCalendarDay() {
        let cal = TestSupport.calendar

        var comps = DateComponents()
        comps.year = 2026
        comps.month = 6
        comps.day = 15
        comps.hour = 23
        comps.minute = 45
        let date = cal.date(from: comps)!

        let day = FeedCacheDay(date: date, calendar: cal)
        XCTAssertEqual(day.rawValue, "2026-06-15")
    }

    func testTodayUsesProvidedNow() {
        let cal = TestSupport.calendar

        var comps = DateComponents()
        comps.year = 2025
        comps.month = 1
        comps.day = 2
        let now = cal.date(from: comps)!

        let day = FeedCacheDay.today(calendar: cal, now: now)
        XCTAssertEqual(day.rawValue, "2025-01-02")
    }

    func testRawValueRejectsMalformed() {
        XCTAssertNil(FeedCacheDay(rawValue: "2026-6-1"))
        XCTAssertNil(FeedCacheDay(rawValue: "2026/06/01"))
        XCTAssertNil(FeedCacheDay(rawValue: "abc"))
        XCTAssertEqual(FeedCacheDay(rawValue: "2026-06-01")?.rawValue, "2026-06-01")
    }

    func testComparableByRawValue() {
        let a = FeedCacheDay(rawValue: "2026-06-01")!
        let b = FeedCacheDay(rawValue: "2026-06-02")!
        XCTAssertTrue(a < b)
    }
}
