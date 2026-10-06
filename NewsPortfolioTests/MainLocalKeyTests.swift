//
//  MainLocalKeyTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-05.
//

import XCTest
import NewsFeedClient
@testable import NewsPortfolio

final class MainLocalKeyTests: XCTestCase {
    func testSeeAllResolvesEnglish() {
        XCTAssertEqual(String(localized: MainLocalKey.seeAll), "See all")
    }

    func testSeeAllResolvesSpanish() {
        var resource = MainLocalKey.seeAll
        resource.locale = Locale(identifier: "es")
        XCTAssertEqual(String(localized: resource), "Ver todo")
    }

    func testCategoryResolvesConcreteKeyNotFormatStub() {
        XCTAssertEqual(
            String(localized: MainLocalKey.category(.technology)),
            "Technology"
        )
        XCTAssertNotEqual(
            String(localized: MainLocalKey.category(.technology)),
            "main.category.technology"
        )
    }

    func testCategoryResolvesSpanish() {
        var resource = MainLocalKey.category(.business)
        resource.locale = Locale(identifier: "es")
        XCTAssertEqual(String(localized: resource), "Negocios")
    }
}
