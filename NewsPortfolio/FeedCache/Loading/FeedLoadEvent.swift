//
//  FeedLoadEvent.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation
import NewsFeedClient

enum FeedFreshness: Equatable, Sendable {
    /// Same calendar day cache hit - no network
    case cached
    /// Prior day's payload painted while revalidating
    case stale
    /// Successful network response (and now saved for today)
    case network
}

enum FeedLoadEvent: Equatable, Sendable {
    case loading
    case page(NewsPage, freshness: FeedFreshness)
    case failure(NewsFeedError)
}
