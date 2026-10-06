//
//  ArticlePresentation.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import Foundation

enum ArticlePresentation: Identifiable, Equatable {
    case safari(URL)
    case unavailable

    var id: String {
        switch self {
        case .safari(let url):
            return "safari:\(url.absoluteString)"
        case .unavailable:
            return "unavailable"
        }
    }

    static func resolve(_ rawURL: String) -> ArticlePresentation {
        if let url = HTTPURL.parse(rawURL) {
            return .safari(url)
        }
        return .unavailable
    }
}
