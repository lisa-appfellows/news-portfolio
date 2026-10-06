//
//  ImageDiskCacheTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-05.
//

import XCTest
import UIKit
@testable import NewsPortfolio

final class ImageDiskCacheTests: XCTestCase {
    private var directoryURL: URL!
    private let urlA = TestSupport.createImageURL("a")
    private let urlB = TestSupport.createImageURL("b")
    private let urlC = TestSupport.createImageURL("c")

    override func setUp() {
        super.setUp()
        directoryURL = FileManager.default.temporaryDirectory
            .appending(
                path: "ImageDiskCacheTests-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
        try? FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directoryURL)
        directoryURL = nil
        super.tearDown()
    }

    func testStoreThenLoadReturnsImage() async throws {
        let cache = ImageDiskCache(directoryURL: directoryURL)
        let image = TestSupport.sampleImage(seed: 0.9)

        await cache.store(image, for: urlA)
        let loaded = await cache.image(for: urlA)
        let byteCount = try await cache.totalByteCount()

        XCTAssertNotNil(loaded)
        XCTAssertGreaterThan(byteCount, 0)
    }

    func testLRUEvictsOldestWhenOverBudget() async throws {
        // Budget fits roughly one compressed tile; second store should evict the older file
        let imageA = TestSupport.sampleImage(seed: 0.1)
        let imageB = TestSupport.sampleImage(seed: 0.8)

        let sizeA = try await cacheBudget(image: imageA, url: urlA)
        XCTAssertGreaterThan(sizeA, 0)

        // Fresh cache on same directory with budget = one image.
        let cache = ImageDiskCache(directoryURL: directoryURL, maxByteCount: sizeA)
        // Re-store A at budget limit, then B should evict A.
        await cache.store(imageA, for: urlA)
        await sleep()
        await cache.store(imageB, for: urlB)

        let loadedA = await cache.image(for: urlA)
        let loadedB = await cache.image(for: urlB)
        let totalByteCount = try await cache.totalByteCount()
        XCTAssertNil(loadedA)
        XCTAssertNotNil(loadedB)
        XCTAssertLessThanOrEqual(totalByteCount, sizeA)
    }

    func testReadTouchesLRUSoOlderUnreadIsEvictedFirst() async throws {
        let imageA = TestSupport.sampleImage(seed: 0.2)
        let imageB = TestSupport.sampleImage(seed: 0.4)
        let imageC = TestSupport.sampleImage(seed: 0.6)

        let oneImageBudget = try await cacheBudget(image: imageA, url: urlA)

        let cache = ImageDiskCache(
            directoryURL: directoryURL,
            maxByteCount: oneImageBudget * 2 // fits two
        )
        await cache.store(imageA, for: urlA)
        await sleep()
        await cache.store(imageB, for: urlB)

        // Touch A so B is older
        _ = await cache.image(for: urlA)
        await sleep()

        await cache.store(imageC, for: urlC) // needs room, evicts B

        let a = await cache.image(for: urlA)
        let b = await cache.image(for: urlB)
        let c = await cache.image(for: urlC)
        XCTAssertNotNil(a)
        XCTAssertNil(b)
        XCTAssertNotNil(c)
    }

    private func cacheBudget(
        image: UIImage,
        url: URL
    ) async throws -> Int {
        let sizing = ImageDiskCache(directoryURL: directoryURL, maxByteCount: .max)
        await sizing.store(image, for: url)
        return try await sizing.totalByteCount()
    }

    private func sleep() async {
        await TestSupport.sleep(10_000_000)
    }
    
}
