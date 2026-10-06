//
//  ImageLoader.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import UIKit

/// Shared image load coordinator.
/// - Coalesces in-flight work per URL
/// - Cancelling a stream drops that UI subscription only; the fetch may finish (continue-to-cache)
actor ImageLoader {
    typealias Fetch = @Sendable (URL) async throws -> UIImage

    private let memory: any ImageMemoryCaching
    private let disk: any ImageDiskCaching
    private let fetch: Fetch
    private let maxConcurrent: Int

    private var sessions: [URL: Session] = [:]
    private var queue: [URL] = []
    private var inFlightCount = 0

    private struct Session {
        var subscribers: [UUID: AsyncStream<ImageLoadPhase>.Continuation] = [:]
        var task: Task<Void, Never>?
    }

    init(
        memory: any ImageMemoryCaching = ImageMemoryCache(),
        disk: any ImageDiskCaching = NoImageDiskCache(),
        maxConcurrent: Int = 4,
        fetch: @escaping Fetch
    ) {
        self.memory = memory
        self.disk = disk
        self.maxConcurrent = maxConcurrent
        self.fetch = fetch
    }

    /// Subscribe to load phases for `url`. Finishes after `success` or `error`.
    nonisolated func load(_ url: URL) -> AsyncStream<ImageLoadPhase> {
        AsyncStream { continuation in
            let id = UUID()
            Task {
                await self.subscribe(id: id, url: url, continuation: continuation)
            }
            continuation.onTermination = { _ in
                Task { await self.unsubscribe(id: id, url: url) }
            }
        }
    }

    private func subscribe(
        id: UUID,
        url: URL,
        continuation: AsyncStream<ImageLoadPhase>.Continuation
    ) {
        if let cached = memory.image(for: url) {
            continuation.yield(.success(cached))
            continuation.finish()
            return
        }

        var session = sessions[url] ?? Session()
        session.subscribers[id] = continuation
        continuation.yield(.loading)

        let shouldEnqueue = session.task == nil && !queue.contains(url)
        sessions[url] = session // subscribers visible before fetch can finish

        if shouldEnqueue {
            queue.append(url)
            startNextIfNeeded()
        }
    }

    private func unsubscribe(id: UUID, url: URL) {
        guard var session = sessions[url] else { return }
        session.subscribers.removeValue(forKey: id)

        if session.subscribers.isEmpty, session.task == nil {
            // still queued- drop; do not start a fetch for cache.
            queue.removeAll { $0 == url }
            sessions.removeValue(forKey: url)
        } else {
            // in-flight - keep session so finish can store to memory
            sessions[url] = session
        }
    }

    private func startNextIfNeeded() {
        while inFlightCount < maxConcurrent, !queue.isEmpty {
            let url = queue.removeFirst()
            guard sessions[url] != nil else { continue }

            inFlightCount += 1
            let task = Task {
                await self.runFetch(url: url)
            }
            sessions[url]?.task = task
        }
    }

    private func runFetch(url: URL) async {
        let phase: ImageLoadPhase

        if let diskImage = await disk.image(for: url) {
            phase = .success(diskImage)
        } else {
            do {
                let image = try await fetch(url)
                await disk.store(image, for: url)
                phase = .success(image)
            } catch {
                phase = .error
            }
        }

        finish(url: url, phase: phase)
        inFlightCount -= 1
        startNextIfNeeded()
    }

    private func finish(url: URL, phase: ImageLoadPhase) {
        if case .success(let image) = phase {
            memory.store(image, for: url)
        }

        guard let session = sessions.removeValue(forKey: url) else { return }
        for continuation in session.subscribers.values {
            continuation.yield(phase)
            continuation.finish()
        }
    }
}
