//
//  TestSupport.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-01.
//

import NewsFeedClient
import UIKit
@testable import NewsPortfolio

protocol TestFeedProbing {
    func topHeadlines(_ request: TopHeadlinesRequest) async throws -> NewsPage
    func everything(_ request: EverythingRequest) async throws -> NewsPage
}

enum TestSupport {
    static let staticDate = Date(timeIntervalSince1970: 1_718_000_000)
    static let rawFeedCacheDay = "2026-06-01"
    static let feedCacheDay = FeedCacheDay(rawValue: rawFeedCacheDay)!

    static let yesterday = FeedCacheDay(rawValue: "2026-06-01")!
    static let today = FeedCacheDay(rawValue: "2026-06-02")!

    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    static func sleep(_ nano: UInt64 = 50_000_000) async {
        try? await Task.sleep(nanoseconds: nano)
    }

    static func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000, // 1s
        pollNanoseconds: UInt64 = 5_000_000, // 5ms
        _ condition: () async -> Bool
    ) async -> Bool {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if await condition() { return true }
            try? await Task.sleep(nanoseconds: pollNanoseconds)
        }
        return await condition()
    }

    static func newsPage1Article(
        title: String,
        url: String,
        publishedDate: Date? = nil
    ) -> NewsPage {
        NewsPage(
            articles: [
                .init(title: title, url: url, publishedDate: publishedDate)
            ],
            totalResults: 1
        )
    }

    static func newsPageEmpty() -> NewsPage {
        NewsPage(articles: [], totalResults: 0)
    }

    static func createNow(
        year: Int,
        month: Int,
        day: Int,
        hour: Int? = nil,
        minute: Int? = nil
    ) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        if let hour { comps.hour = hour }
        if let minute { comps.minute = minute }
        return calendar.date(from: comps)!
    }

    static func createFeed<Probe: TestFeedProbing>(
        store: InMemoryFeedCacheStore = .init(),
        probe: Probe
    ) -> FeedFetching {
        FeedFetching(
            loader: .init(store: store),
            fetchTopHeadlines: { try await probe.topHeadlines($0) },
            fetchEverything: { try await probe.everything($0) }
        )
    }

    static func createImageURL(_ path: String) -> URL {
        URL(string: "https://example.com/\(path).jpg")!
    }

    static func sampleImage(seed: CGFloat = 1) -> UIImage {
        UIGraphicsImageRenderer(size: .init(width: 64, height: 64)).image { context in
            UIColor(red: seed, green: 0.2, blue: 0.5, alpha: 1).setFill()
            context.fill(.init(x: 0, y: 0, width: 64, height: 64))
        }
    }
}
