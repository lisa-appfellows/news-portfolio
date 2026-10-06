//
//  ImageLoaderTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-05.
//

import XCTest
import UIKit
@testable import NewsPortfolio

final class ImageLoaderTests: XCTestCase {
    private let urlA = TestSupport.createImageURL("a")
    private let urlB = TestSupport.createImageURL("b")

    private var sampleImage: UIImage {
        TestSupport.sampleImage()
    }

    private func collect(
        _ stream: AsyncStream<ImageLoadPhase>
    ) async -> [ImageLoadPhase] {
        var phases: [ImageLoadPhase] = []
        for await phase in stream {
            phases.append(phase)
        }
        return phases
    }

    private func isLoading(_ phase: ImageLoadPhase) -> Bool {
        if case .loading = phase { return true }
        return false
    }

    private func isSuccess(_ phase: ImageLoadPhase) -> Bool {
        if case .success = phase { return true }
        return false
    }

    private func isError(_ phase: ImageLoadPhase) -> Bool {
        if case .error = phase { return true }
        return false
    }
}

// MARK: - Happy path / failure
extension ImageLoaderTests {
    func testSuccessEmitsLoadingThenSuccess() async {
        let image = sampleImage
        let probe = ImageFetchProbe(result: .success(image))
        let loader = ImageLoader { url in try await probe.fetch(url) }

        let phases = await collect(loader.load(urlA))

        let started = await probe.startedCount
        XCTAssertEqual(started, 1)
        XCTAssertEqual(phases.count, 2)
        XCTAssertTrue(isLoading(phases[0]))
        XCTAssertTrue(isSuccess(phases[1]))
    }

    func testFailureEmitsLoadingThenError() async {
        let probe = ImageFetchProbe(result: .failure(URLError(.badServerResponse)))
        let loader = ImageLoader { url in try await probe.fetch(url) }

        let phases = await collect(loader.load(urlA))

        XCTAssertEqual(phases.count, 2)
        XCTAssertTrue(isLoading(phases[0]))
        XCTAssertTrue(isError(phases[1]))
    }
}

// MARK: - Coalesce
extension ImageLoaderTests {
    func testSameURLCoalescesToOneFetch() async {
        let image = sampleImage
        let probe = ImageFetchProbe(result: .success(image), gateUntilReleased: true)
        let loader = ImageLoader { url in try await probe.fetch(url) }

        async let phasesA = collect(loader.load(urlA))
        async let phasesB = collect(loader.load(urlA))

        // Both should be waiting on the same in-flight fetch.
        let started = await TestSupport.waitUntil {
            await probe.startedCount >= 1
        }
        XCTAssertTrue(started, "fetch should have started before release")

        let startedBeforeRelease = await probe.startedCount
        await probe.release()

        let a = await phasesA
        let b = await phasesB
        let startedCount = await probe.startedCount

        XCTAssertEqual(startedBeforeRelease, 1)
        XCTAssertEqual(startedCount, 1)
        XCTAssertTrue(isLoading(a[0]) && isSuccess(a[1]))
        XCTAssertTrue(isLoading(b[0]) && isSuccess(b[1]))
    }

    func testDifferentURLsFetchSeparately() async {
        let image = sampleImage
        let probe = ImageFetchProbe(result: .success(image))
        let loader = ImageLoader { url in try await probe.fetch(url) }

        async let a = collect(loader.load(urlA))
        async let b = collect(loader.load(urlB))
        _ = await (a, b)

        let started = await probe.startedCount
        XCTAssertEqual(started, 2)
    }
}

// MARK: - Cancel subscription / continue-to-cache
extension ImageLoaderTests {
    func testCancelDropsSubscriptionButFetchContinues() async {
        let image = sampleImage
        let probe = ImageFetchProbe(result: .success(image), gateUntilReleased: true)
        let loader = ImageLoader { url in try await probe.fetch(url) }

        let stream = loader.load(urlA)
        let collectTask = Task {
            await collect(stream)
        }

        // Wait until fetch has started (subscriber got `.loading`).
        let started = await TestSupport.waitUntil {
            await probe.startedCount >= 1
        }
        let startedCount = await probe.startedCount
        XCTAssertTrue(started)
        XCTAssertEqual(startedCount, 1)

        // Cancel UI subscrition before bytes finish.
        collectTask.cancel()
        _ = await collectTask.result

        // Shared work still completes
        await probe.release()

        let finished = await TestSupport.waitUntil {
            await probe.finishedCount >= 1
        }
        let finishedCount = await probe.finishedCount
        XCTAssertTrue(finished, "fetch should complete after release")
        XCTAssertEqual(finishedCount, 1)
    }
}

// MARK: - Cancel subscription / continue-to-cache
extension ImageLoaderTests {
    func testSecondLoadHitsMemoryWithoutFetching() async {
        let image = sampleImage
        let probe = ImageFetchProbe(result: .success(image))
        let loader = ImageLoader { url in try await probe.fetch(url) }

        let first = await collect(loader.load(urlA))
        let second = await collect(loader.load(urlA))

        let started = await probe.startedCount
        XCTAssertEqual(started, 1)
        XCTAssertTrue(isLoading(first[0]) && isSuccess(first[1]))
        XCTAssertEqual(second.count, 1)
        XCTAssertTrue(isSuccess(second[0]))
    }

    func testCancelThenResubscribeHitsMemory() async {
        let image = sampleImage
        let probe = ImageFetchProbe(result: .success(image), gateUntilReleased: true)
        let loader = ImageLoader { url in try await probe.fetch(url) }

        let collectTask = Task {
            await collect(loader.load(urlA))
        }

        let started = await TestSupport.waitUntil {
            await probe.startedCount >= 1
        }
        let startCount = await probe.startedCount
        XCTAssertTrue(started)
        XCTAssertEqual(startCount, 1)

        collectTask.cancel()
        _ = await collectTask.result

        await probe.release()

        let finished = await TestSupport.waitUntil {
            await probe.finishedCount >= 1
        }
        let finishCount = await probe.finishedCount
        XCTAssertTrue(finished, "fetch should complete after release")
        XCTAssertEqual(finishCount, 1)

        // No UI was listening when fetch finished, but memory should be filled
        let phases = await collect(loader.load(urlA))
        let secondStartCount = await probe.startedCount // still one fetch
        XCTAssertEqual(secondStartCount, 1)
        XCTAssertEqual(phases.count, 1)
        XCTAssertTrue(isSuccess(phases[0]))
    }
}

// MARK: - Concurrency cap
extension ImageLoaderTests {
    func testMaxConcurrentCapsInFlightFetches() async {
        let image = sampleImage
        let probe = ImageFetchProbe(result: .success(image), gateUntilReleased: true)
        let loader = ImageLoader(maxConcurrent: 2) { url in
            try await probe.fetch(url)
        }

        let urls = (0..<5).map { URL(string: "https://example.com/\($0).jpg")! }
        let tasks = urls.map { url in
            Task { await collect(loader.load(url)) }
        }

        let started = await TestSupport.waitUntil {
            await probe.startedCount >= 2
        }
        let startedCount = await probe.startedCount
        var maxSeen = await probe.maxSeenInFlight
        XCTAssertTrue(started)
        XCTAssertEqual(startedCount, 2)
        XCTAssertEqual(maxSeen, 2)

        while await probe.finishedCount < 5 {
            let before = await probe.finishedCount
            await probe.release()
            let progressed = await TestSupport.waitUntil {
                await probe.finishedCount > before
            }
            XCTAssertTrue(progressed, "release should complete at least one in-flight fetch")
        }

        for task in tasks { _ = await task.value }

        let finishedCount = await probe.finishedCount
        maxSeen = await probe.maxSeenInFlight
        XCTAssertEqual(finishedCount, 5)
        XCTAssertEqual(maxSeen, 2)
    }

    func testQueuedURLDroppedWhenAllSubscribersCancel() async {
        let image = sampleImage
        let probe = ImageFetchProbe(result: .success(image), gateUntilReleased: true)
        let loader = ImageLoader(maxConcurrent: 1) { url in
            try await probe.fetch(url)
        }

        let collectA = Task { await collect(loader.load(urlA)) }
        let startedA = await TestSupport.waitUntil { await probe.startedCount >= 1 }
        XCTAssertTrue(startedA)

        let collectB = Task { await collect(loader.load(urlB)) }
        await TestSupport.sleep() // B should be queued, not started

        var startedCount = await probe.startedCount
        XCTAssertEqual(startedCount, 1)

        collectB.cancel()
        _ = await collectB.result

        await probe.release()
        _ = await collectA.value

        let finished = await TestSupport.waitUntil { await probe.finishedCount >= 1 }
        startedCount = await probe.startedCount
        let finishedCount = await probe.finishedCount
        XCTAssertTrue(finished)
        XCTAssertEqual(startedCount, 1) // B never fetched
        XCTAssertEqual(finishedCount, 1)
    }
}

// MARK: - Disk cache
extension ImageLoaderTests {
    func testDiskHitSkipsNetworkandFillsMemory() async throws {
        let directory = try directory()
        defer { removeDirectory(directory) }

        let image = sampleImage
        let disk = ImageDiskCache(directoryURL: directory)
        await disk.store(image, for: urlA)

        let probe = ImageFetchProbe(result: .success(image))
        let loader = ImageLoader(disk: disk) { url in
            try await probe.fetch(url)
        }

        let first = await collect(loader.load(urlA))
        var startedCount = await probe.startedCount
        XCTAssertEqual(startedCount, 0)
        XCTAssertTrue(isLoading(first[0]) && isSuccess(first[1]))

        // Promoted to memory: second load does not enqueue work.
        let second = await collect(loader.load(urlA))
        startedCount = await probe.startedCount
        XCTAssertEqual(second.count, 1)
        XCTAssertTrue(isSuccess(second[0]))
        XCTAssertEqual(startedCount, 0)
    }

    func testNetworkSuccessWritesDisk() async throws {
        let directory = try directory()
        defer { removeDirectory(directory) }

        let image = sampleImage
        let disk = ImageDiskCache(directoryURL: directory)
        let probe = ImageFetchProbe(result: .success(image))
        let loader = ImageLoader(
            memory: ImageMemoryCache(),
            disk: disk
        ) { url in
            try await probe.fetch(url)
        }

        _ = await collect(loader.load(urlA))
        let startedCount = await probe.startedCount
        XCTAssertEqual(startedCount, 1)

        // New loader, empty memory, same disk -> disk hit, no fetch.
        let probe2 = ImageFetchProbe(result: .success(image))
        let loader2 = ImageLoader(
            memory: ImageMemoryCache(),
            disk: disk
        ) { url in
            try await probe2.fetch(url)
        }
        let phases = await collect(loader2.load(urlA))
        let startedCount2 = await probe2.startedCount
        XCTAssertEqual(startedCount2, 0)
        XCTAssertTrue(isSuccess(phases[1]))
    }

    private func directory() throws -> URL {
        let id = UUID().uuidString
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "ImageLoader-\(id)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private func removeDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Helper
private actor ImageFetchProbe {
    enum Result {
        case success(UIImage)
        case failure(Error)
    }

    private let result: Result
    private let gateUntilReleased: Bool
    private var waiters: [CheckedContinuation<Void, Never>] = []

    private(set) var startedCount = 0
    private(set) var finishedCount = 0
    private(set) var inFlightCount = 0
    private(set) var maxSeenInFlight = 0

    init(result: Result, gateUntilReleased: Bool = false) {
        self.result = result
        self.gateUntilReleased = gateUntilReleased
    }

    func release() {
        let waiters = self.waiters
        self.waiters = []
        for waiter in waiters {
            waiter.resume()
        }
    }

    func fetch(_ url: URL) async throws -> UIImage {
        startedCount += 1
        inFlightCount += 1
        maxSeenInFlight = max(maxSeenInFlight, inFlightCount)
        defer {
            inFlightCount -= 1
            finishedCount += 1
        }

        if gateUntilReleased {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }

        switch result {
        case .success(let image):
            return image
        case .failure(let error):
            throw error
        }
    }
}
