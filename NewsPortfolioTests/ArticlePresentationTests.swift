//
//  ArticlePresentationTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-05.
//

import XCTest
@testable import NewsPortfolio

final class ArticlePresentationTests: XCTestCase {
    func testResolveSafari() {
        XCTAssertEqual(
            ArticlePresentation.resolve("https://example.com/story"),
            .safari(URL(string: "https://example.com/story")!)
        )
    }

    func testResolveUnavailable() {
        XCTAssertEqual(ArticlePresentation.resolve(""), .unavailable)
        XCTAssertEqual(ArticlePresentation.resolve("ftp://example.com"), .unavailable)
        XCTAssertEqual(ArticlePresentation.resolve("not a url"), .unavailable)
    }
}
