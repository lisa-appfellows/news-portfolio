//
//  FeedLoader.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation
import NewsFeedClient

struct FeedLoader: Sendable {
    private let store: any FeedCacheStoring

    init(store: any FeedCacheStoring) {
        self.store = store
    }

    /// Loads one feed key through day-boundary cache policy.
    /// - Parameters:
    ///   - makeKey: builds the cache key for a given local day (today vs last marker).
    ///   - fetch: network (or test double). Only called when policy allows.
    func load(
        calendar: Calendar = .current,
        now: Date = Date(),
        makeKey: @escaping @Sendable (FeedCacheDay) -> FeedCacheKey,
        fetch: @escaping @Sendable () async throws -> NewsPage
    ) -> AsyncStream<FeedLoadEvent> {
        let store = self.store
        return AsyncStream { continuation in
            let task = Task {
                await Self.run(
                    store: store,
                    calendar: calendar,
                    now: now,
                    makeKey: makeKey,
                    fetch: fetch,
                    yield: { continuation.yield($0) }
                )
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func run(
        store: any FeedCacheStoring,
        calendar: Calendar,
        now: Date,
        makeKey: (FeedCacheDay) -> FeedCacheKey,
        fetch: () async throws -> NewsPage,
        yield: (FeedLoadEvent) -> Void
    ) async {
        let today = FeedCacheDay.today(calendar: calendar, now: now)
        let lastDay = await store.lastCacheDay()
        let todayKey = makeKey(today)

        // Same calendar day: serve cache only when present.
        if lastDay == today {
            if let cached = await store.payload(for: todayKey) {
                yield(.page(cached, freshness: .cached))
                return
            }
            await fetchAndStore(
                store: store,
                today: today,
                todayKey: todayKey,
                previousDay: nil,
                hadStale: false,
                makeKey: makeKey,
                fetch: fetch,
                yield: yield
            )
            return
        }

        // Day roll / never written: optional stale from last marker day, then revalidate.
        var hadStale = false
        if let lastDay {
            let staleKey = makeKey(lastDay)
            if let stale = await store.payload(for: staleKey) {
                hadStale = true
                yield(.page(stale, freshness: .stale))
            }
        }

        await fetchAndStore(
            store: store,
            today: today,
            todayKey: todayKey,
            previousDay: lastDay,
            hadStale: hadStale,
            makeKey: makeKey,
            fetch: fetch,
            yield: yield
        )
    }

    private static func fetchAndStore(
        store: any FeedCacheStoring,
        today: FeedCacheDay,
        todayKey: FeedCacheKey,
        previousDay: FeedCacheDay?,
        hadStale: Bool,
        makeKey: (FeedCacheDay) -> FeedCacheKey,
        fetch: () async throws -> NewsPage,
        yield: (FeedLoadEvent) -> Void
    ) async {
        if !hadStale {
            yield(.loading)
        }

        do {
            let page = try await fetch()
            guard !Task.isCancelled else { return }
            await store.save(page, for: todayKey, day: today)
            if let previousDay, previousDay != today {
                await store.removePayload(for: makeKey(previousDay))
            }
            yield(.page(page, freshness: .network))
        } catch is CancellationError {
            return
        } catch let error as NewsFeedError {
            if !hadStale {
                yield(.failure(error))
            }
        } catch {
            if !hadStale {
                yield(.failure(.transport(error.localizedDescription)))
            }
        }
    }
}
