//
//  InMemoryFeedCacheStore.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-09-30.
//

import Foundation
import NewsFeedClient

actor InMemoryFeedCacheStore: FeedCacheStoring {
    private var marker: FeedCacheDay?
    private var pages: [String: NewsPage] = [:]

    func lastCacheDay() async -> FeedCacheDay? { marker }
    
    func setLastCacheDay(_ day: FeedCacheDay) async { marker = day }
    
    func payload(for key: FeedCacheKey) async -> NewsPage? {
        pages[key.rawValue]
    }
    
    func save(_ page: NewsPage, for key: FeedCacheKey, day: FeedCacheDay) async {
        pages[key.rawValue] = page
        marker = day
    }
    
    func removePayload(for key: FeedCacheKey) async {
        pages[key.rawValue] = nil
    }
}
