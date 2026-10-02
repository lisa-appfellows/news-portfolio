//
//  TestSupport.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation
import NewsFeedClient
@testable import NewsPortfolio

enum TestSupport {
    static let staticDate = Date(timeIntervalSince1970: 1_718_000_000)
    static let rawFeedCacheDay = "2026-06-01"
    static let feedCacheDay = FeedCacheDay(rawValue: rawFeedCacheDay)!

    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    static func newsPage1Article(
        title: String,
        url: String,
        publishedDate: Date? = nil
    ) -> NewsPage {
        NewsPage(
            articles: [
                .init(title: title, url: url, publishedDate: publishedDate)
            ],
            totalResults: 1
        )
    }

    static func newsPageEmpty() -> NewsPage {
        NewsPage(articles: [], totalResults: 0)
    }

    static func createNow(
        year: Int,
        month: Int,
        day: Int,
        hour: Int? = nil,
        minute: Int? = nil
    ) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        if let hour { comps.hour = hour }
        if let minute { comps.minute = minute }
        return calendar.date(from: comps)!
    }
}
