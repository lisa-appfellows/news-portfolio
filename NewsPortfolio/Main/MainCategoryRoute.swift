//
//  MainCategoryRoute.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import Foundation
import NewsFeedClient

struct MainCategoryRoute: Hashable, Sendable {
    let category: NewsCategory

    func hash(into hasher: inout Hasher) {
        hasher.combine(category.rawValue)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.category == rhs.category
    }
}
