//
//  NewsPortfolioApp.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-09-30.
//

import SwiftUI

@MainActor
@main
struct NewsPortfolioApp: App {
    private let feeds: FeedFetching
    @State private var mainHomeModel: MainHomeModel

    init() {
        let feeds = AppComposition.makeFeedFetching()
        self.feeds = feeds
        let mainHome = AppComposition.makeMainHomeModel(feeds: feeds)
        _mainHomeModel = State(initialValue: mainHome)
    }
    
    var body: some Scene {
        WindowGroup {
            MainHomeView(model: mainHomeModel, feeds: feeds)
        }
    }
}
