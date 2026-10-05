//
//  FeedCacheKey.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-09-30.
//

import Foundation
import NewsFeedClient

/// Stable cache identity for a feed payload. `day` is when the entry was
/// written / is valid for - not Discover's `from`/`to` window.
struct FeedCacheKey: Hashable, Sendable {
    let rawValue: String

    static func topHeadlines(
        country: String = "us",
        category: NewsCategory,
        day: FeedCacheDay,
        pageSize: Int,
        page: Int = 1
    ) ->  FeedCacheKey {
        FeedCacheKey(
            rawValue: [
                "topHeadlines",
                country, 
                category.rawValue,
                day.rawValue, 
                "ps\(pageSize)",
                "p\(page)"
            ]
            .joined(separator: "|")
        )
    }

    static func everything(
        q: String,
        language: String,
        from: Date?,
        to: Date?,
        day: FeedCacheDay,
        page: Int = 1
    ) -> FeedCacheKey {
        FeedCacheKey(
            rawValue: [
                "everything",
                q,
                language,
                Self.dateStamp(from),
                Self.dateStamp(to),
                day.rawValue,
                "p\(page)"
            ]
            .joined(separator: "|")
        )
    }

    private static func dateStamp(_ date: Date?) -> String {
        guard let date else { return "-" }
        return isoFormatter.string(from: date)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
