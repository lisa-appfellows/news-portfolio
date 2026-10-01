//
//  FeedCacheStoring.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-09-30.
//

import Foundation
import NewsFeedClient

protocol FeedCacheStoring: Sendable {
    /// Calendar day last successfully written anywhere in the feed cache.
    /// Used as the global day-roll marker (`lastFeedCacheDay`)
    func lastCacheDay() async -> FeedCacheDay?

    func setLastCacheDay(_ day: FeedCacheDay) async
    func payload(for key: FeedCacheKey) async -> NewsPage?
    func save(_ page: NewsPage, for key: FeedCacheKey, day: FeedCacheDay) async
    func removePayload(for key: FeedCacheKey) async
}
