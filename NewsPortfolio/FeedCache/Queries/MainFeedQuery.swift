//
//  MainFeedQuery.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation
import NewsFeedClient

enum MainFeedKind: Equatable, Sendable {
    /// Home Section: Technology mosaic `pageSize=4`, other categories `pageSize=6`.
    case home
    /// Category drill-in list; default first page.
    case drillIn(page: Int = 1)

    func pageSize(for category: NewsCategory) -> Int {
        switch self {
        case .home:
            return category == .technology ? 4 : 6
        case .drillIn:
            return 20
        }
    }

    var page: Int {
        switch self {
        case .home:
            return 1
        case .drillIn(let page):
            return page
        }
    }
}

struct MainFeedQuery: Equatable, Sendable {
    var category: NewsCategory
    var kind: MainFeedKind
    var country: String = "us"

    func makeKey(_ day: FeedCacheDay) -> FeedCacheKey {
        .topHeadlines(
            country: country,
            category: category,
            day: day,
            pageSize: kind.pageSize(for: category),
            page: kind.page
        )
    }

    var request: TopHeadlinesRequest {
        .init(
            country: country,
            category: category,
            pageSize: kind.pageSize(for: category),
            page: kind.page
        )
    }
}
