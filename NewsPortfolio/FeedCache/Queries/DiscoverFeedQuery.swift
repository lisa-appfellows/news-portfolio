//
//  DiscoverFeedQuery.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation
import NewsFeedClient

enum DiscoverContentLanguage {
    /// System language -> `en` / `es`; anything else -> `en`.
    static func code(from locale: Locale = .current) -> String {
        let language = locale.language.languageCode?.identifier ?? "en"
        switch language {
        case "es": return "es"
        default: return "en"
        }
    }
}

struct DiscoverFeedQuery: Equatable, Sendable {
    var q: String
    var timeFrame: DiscoverTimeFrame
    var language: String
    var page: Int = 1
    var pageSize: Int = 20

    func dateRange(
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> QueryDateRange {
        timeFrame.dateRange(calendar: calendar, now: now)
    }

    func makeKey(
        _ day: FeedCacheDay,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> FeedCacheKey {
        let range = dateRange(calendar: calendar, now: now)
        return .everything(
            q: q,
            language: language,
            from: range.from,
            to: range.to,
            day: day, page: page
        )
    }

    func request(
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> EverythingRequest {
        let range = dateRange(calendar: calendar, now: now)
        return .init(
            q: q,
            from: range.from,
            to: range.to,
            language: language,
            sortBy: .publishedAt,
            pageSize: pageSize,
            page: page
        )
    }
}
