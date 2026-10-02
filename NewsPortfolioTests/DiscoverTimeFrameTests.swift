//
//  DiscoverTimeFrameTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-01.
//

import XCTest
@testable import NewsPortfolio

final class DiscoverTimeFrameTests: XCTestCase {
    private var calendar: Calendar { TestSupport.calendar }
    private var now: Date {
        TestSupport.createNow(year: 2026, month: 6, day: 2, hour: 10, minute: 30)
    }

    func testTodayStartsAtStartOfDayEndsAtNow() {
        let range = DiscoverTimeFrame.today.dateRange(calendar: calendar, now: now)
        XCTAssertEqual(range.from, calendar.startOfDay(for: now))
        XCTAssertEqual(range.to, now)
    }

    func testYesterdayIsFullPriorLocalDay() {
        let range = DiscoverTimeFrame.yesterday.dateRange(calendar: calendar, now: now)
        let startOfToday = calendar.startOfDay(for: now)
        let expectedStart = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let expectedEnd = calendar.date(byAdding: .second, value: -1, to: startOfToday)!

        XCTAssertEqual(range.from, expectedStart)
        XCTAssertEqual(range.to, expectedEnd)
    }

    func testLastTwoWeeksFromFourteenDaysAgo() {
        let range = DiscoverTimeFrame.lastTwoWeeks.dateRange(calendar: calendar, now: now)
        let expectedFrom = calendar.date(byAdding: .day, value: -14, to: now)!

        XCTAssertEqual(range.from, expectedFrom)
        XCTAssertEqual(range.to, now)
    }

    func testThisMonthStartsAtFirstOfMonth() {
        let range = DiscoverTimeFrame.thisMonth.dateRange(calendar: calendar, now: now)
        var comps = calendar.dateComponents([.year, .month], from: now)
        comps.day = 1
        let expectedStart = calendar.date(from: comps)!

        XCTAssertEqual(range.from, expectedStart)
        XCTAssertEqual(range.to, now)
    }
}
