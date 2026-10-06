//
//  AppTabTests.swift
//  NewsPortfolioTests
//
//  Created by Lisa Fellows on 2026-10-05.
//

import XCTest
@testable import NewsPortfolio

final class AppTabTests: XCTestCase {
    func testThreeTabsInOrder() {
        XCTAssertEqual(AppTab.allCases, [.main, .discover, .bookmarks])
    }
}
