//
//  AppComposition.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation
import NewsFeedClient

enum AppComposition {
    @MainActor
    static func makeMainHomeModel() -> MainHomeModel {
        let store = makeStore()
        let client = makeNewsClient()
        let feeds = FeedFetching.live(store: store, client: client)
        return MainHomeModel(feeds: feeds)
    }

    private static func makeStore() -> any FeedCacheStoring {
        do {
            return try FileFeedCacheStore.makeDefault()
        } catch {
            // Fallback keeps the app runnable if Application Support can't be created
            return InMemoryFeedCacheStore()
        }
    }

    private static func makeNewsClient() -> NewsFeedClient {
        if AppConfiguration.hasNewsAPIKey {
            return .live(apiKey: AppConfiguration.newsAPIKey)
        }
        return .fixture(Self.fixturePage)
    }

    private static let fixturePage = NewsPage(
        articles: [
            .init(title: "Fixture hero headline", url: "https://example.com/1"),
            .init(title: "Fixture side story A", url: "https://example.com/2"),
            .init(title: "Fixture side story B", url: "https://example.com/3"),
            .init(title: "Fixture landscape story", url: "https://example.com/4"),
            .init(title: "Fixture grid five", url: "https://example.com/5"),
            .init(title: "Fixture grid six", url: "https://example.com/6"),
        ],
        totalResults: 6
    )
}
