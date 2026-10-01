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
}
