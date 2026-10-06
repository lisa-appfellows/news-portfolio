//
//  ArticleImageURLTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-05.
//

import XCTest
@testable import NewsPortfolio

final class ArticleImageURLTests: XCTestCase {
    func testNilAndEmptySkipped() {
        XCTAssertNil(ArticleImageURL.parse(nil))
        XCTAssertNil(ArticleImageURL.parse(""))
    }

    func testNonHTTPSkipped() {
        XCTAssertNil(ArticleImageURL.parse("ftp://example.com/a.jpg"))
        XCTAssertNil(ArticleImageURL.parse("/local/path.jpg"))
        XCTAssertNil(ArticleImageURL.parse("not a url"))
    }

    func testHTTPAccepted() {
        XCTAssertEqual(
            ArticleImageURL.parse("https://example.com/a.jpg"),
            URL(string: "https://example.com/a.jpg")
        )
        XCTAssertEqual(
            ArticleImageURL.parse("http://example.com/a.jpg"),
            URL(string: "http://example.com/a.jpg")
        )
    }
}
