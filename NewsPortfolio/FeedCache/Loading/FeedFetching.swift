//
//  FeedFetching.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation
import NewsFeedClient

struct FeedFetching: Sendable {
    private let loader: FeedLoader
    private let fetchTopHeadlines: @Sendable (TopHeadlinesRequest) async throws -> NewsPage
    private let fetchEverything: @Sendable (EverythingRequest) async throws -> NewsPage

    init(
        loader: FeedLoader,
        fetchTopHeadlines: @escaping @Sendable (TopHeadlinesRequest) async throws -> NewsPage,
        fetchEverything: @escaping @Sendable (EverythingRequest) async throws -> NewsPage
    ) {
        self.loader = loader
        self.fetchTopHeadlines = fetchTopHeadlines
        self.fetchEverything = fetchEverything
    }

    /// Production wiring. Prefer this at the app composition root.
    static func live(
        store: any FeedCacheStoring,
        client: NewsFeedClient
    ) -> FeedFetching {
        .init(
            loader: FeedLoader(store: store),
            fetchTopHeadlines: { try await client.topHeadlines($0) },
            fetchEverything: { try await client.everything($0) }
        )
    }

    func load(
        _ query: MainFeedQuery,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> AsyncStream<FeedLoadEvent> {
        let fetchTopHeadlines = self.fetchTopHeadlines
        return loader.load(
            calendar: calendar,
            now: now,
            makeKey: { query.makeKey($0) },
            fetch: { try await fetchTopHeadlines(query.request) }
        )
    }

    func load(
        _ query: DiscoverFeedQuery,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> AsyncStream<FeedLoadEvent> {
        let fetchEverything = self.fetchEverything
        return loader.load(
            calendar: calendar,
            now: now,
            makeKey: { query.makeKey($0, calendar: calendar, now: now) },
            fetch: { try await fetchEverything(query.request(calendar: calendar, now: now)) }
        )
    }
}
