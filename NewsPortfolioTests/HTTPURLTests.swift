//
//  HTTPURLTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-05.
//

import XCTest
@testable import NewsPortfolio

final class HTTPURLTests: XCTestCase {
    func testNilAndEmptySkipped() {
        XCTAssertNil(HTTPURL.parse(nil))
        XCTAssertNil(HTTPURL.parse(""))
    }

    func testNonHTTPSkipped() {
        XCTAssertNil(HTTPURL.parse("ftp://example.com/a.jpg"))
        XCTAssertNil(HTTPURL.parse("/local/path.jpg"))
        XCTAssertNil(HTTPURL.parse("not a url"))
    }

    func testHTTPAccepted() {
        XCTAssertEqual(
            HTTPURL.parse("https://example.com/a.jpg"),
            URL(string: "https://example.com/a.jpg")
        )
        XCTAssertEqual(
            HTTPURL.parse("http://example.com/a.jpg"),
            URL(string: "http://example.com/a.jpg")
        )
    }
}
