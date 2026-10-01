//
//  AppConfiguration.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-09-30.
//

import Foundation

enum AppConfiguration {
    static var newsAPIKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "NewsAPIKey") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static var hasNewsAPIKey: Bool {
        !newsAPIKey.isEmpty
    }
}
