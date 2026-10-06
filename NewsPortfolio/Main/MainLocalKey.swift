//
//  MainLocalKey.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation
import NewsFeedClient

enum MainLocalKey {
    static let seeAll = LocalizedStringResource("main.seeAll")
    static let sectionError = LocalizedStringResource("main.section.error")
    static let emptyTitle = LocalizedStringResource("main.empty.title")
    static let emptyMessage = LocalizedStringResource("main.empty.message")
    static let loadMoreError = LocalizedStringResource("main.drillIn.loadMoreError")
    static let loadMoreRetry = LocalizedStringResource("main.drillIn.loadMoreRetry")

    static func category(_ category: NewsCategory) -> LocalizedStringResource {
        let key = "main.category.\(category.rawValue)"
        return .init(String.LocalizationValue(stringLiteral: key))
    }
}
