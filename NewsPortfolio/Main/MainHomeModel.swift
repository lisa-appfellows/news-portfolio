//
//  MainHomeModel.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation
import NewsFeedClient

@MainActor
@Observable
final class MainHomeModel {
    enum Phase: Equatable, Sendable {
        case idle
        case loading
        case loaded(NewsPage, freshness: FeedFreshness)
        case failed(NewsFeedError)
    }

    struct Section: Identifiable, Equatable, Sendable {
        var id: NewsCategory { category }
        let category: NewsCategory
        var phase: Phase
    }

    static let homeOrder: [NewsCategory] = [
        .technology,
        .business,
        .entertainment,
        .general,
        .health,
        .science,
        .sports
    ]

    private(set) var sections: [Section]
    private let feeds: FeedFetching
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        feeds: FeedFetching,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.feeds = feeds
        self.calendar = calendar
        self.now = now
        self.sections = Self.homeOrder.map {
            Section(category: $0, phase: .idle)
        }
    }

    /// True when every section failed with nothing to show (full-tab empty/error)
    var isFullyFailed: Bool {
        sections.allSatisfy {
            if case .failed = $0.phase { return true }
            return false
        }
    }

    func loadHome() async {
        await withTaskGroup(of: Void.self) { group in
            for category in Self.homeOrder {
                let feeds = self.feeds
                let calendar = self.calendar
                let now = self.now()
                group.addTask {
                    let query = MainFeedQuery(category: category, kind: .home)
                    let stream = feeds.load(query, calendar: calendar, now: now)
                    for await event in stream {
                        await self.apply(event, to: category)
                    }
                }
            }
        }
    }

    private func apply(_ event: FeedLoadEvent, to category: NewsCategory) {
        guard let index = sections.firstIndex(where: { $0.category == category }) else {
            return
        }

        switch event {
        case .loading:
            if case .loaded = sections[index].phase {
                break
            }
            sections[index].phase = .loading

        case .page(let newsPage, let freshness):
            sections[index].phase = .loaded(newsPage, freshness: freshness)

        case .failure(let newsFeedError):
            // Quiet if we already have stale/cached content
            if case .loaded = sections[index].phase {
                break
            }
            sections[index].phase = .failed(newsFeedError)
        }
    }
}
