//
//  MainDrillInModel.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import Foundation
import NewsFeedClient

@MainActor
@Observable
final class MainDrillInModel {
    enum Phase: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(NewsFeedError)
    }

    let category: NewsCategory

    private(set) var articles: [Article] = []
    private(set) var phase: Phase = .idle
    private(set) var isLoadingMore = false
    private(set) var canLoadMore = true
    private(set) var loadMoreFailed = false

    private let feeds: FeedFetching
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    private var nextPage = 1
    private var totalResults = 0
    private var inFlightPage: Int?

    init(
        category: NewsCategory,
        feeds: FeedFetching,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.category = category
        self.feeds = feeds
        self.calendar = calendar
        self.now = now
    }

    func loadInitial() async {
        await loadPage(1, isMore: false)
    }

    func loadMore() async {
        guard canLoadMore, phase == .loaded, inFlightPage == nil else { return }
        await loadPage(nextPage, isMore: true)
    }

    private func loadPage(_ page: Int, isMore: Bool) async {
        guard inFlightPage == nil else { return }
        inFlightPage = page
        defer { inFlightPage = nil }

        if isMore {
            isLoadingMore = true
            loadMoreFailed = false
        } else if articles.isEmpty {
            phase = .loading
        }

        let query = MainFeedQuery(category: category, kind: .drillIn(page: page))
        let feeds = self.feeds
        let calendar = self.calendar
        let now = self.now()

        let stream = feeds.load(query, calendar: calendar, now: now)
        for await event in stream {
            apply(event, page: page, isMore: isMore)
        }

        if isMore {
            isLoadingMore = false
        }
    }

    private func apply(_ event: FeedLoadEvent, page: Int, isMore: Bool) {
        switch event {
        case .loading:
            if !isMore, articles.isEmpty {
                phase = .loading
            }

        case .page(let newsPage, _):
            if isMore {
                appendUnique(newsPage.articles)
            } else {
                articles = newsPage.articles
                phase = .loaded
            }
            totalResults = newsPage.totalResults
            nextPage = page + 1
            updateCanLoadMore(after: newsPage)
            loadMoreFailed = false

        case .failure(let newsFeedError):
            if isMore {
                // Keep existing rows; surface a quiet/retryable flag for the view later
                loadMoreFailed = true
            } else if articles.isEmpty {
                phase = .failed(newsFeedError)
                canLoadMore = false
            }
            // Initial SWR with stale already painted: stay quiet
        }
    }

    private func appendUnique(_ newsArticles: [Article]) {
        let existing = Set(articles.map(\.url))
        let fresh = newsArticles.filter { !existing.contains($0.url) }
        articles.append(contentsOf: fresh)
    }

    private func updateCanLoadMore(after page: NewsPage) {
        let pageSize = MainFeedKind.drillIn().pageSize(for: category)
        canLoadMore = !page.articles.isEmpty &&
        page.articles.count >= pageSize &&
        articles.count < totalResults
    }
}
