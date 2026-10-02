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
    @State private var mainHomeModel = AppComposition.makeMainHomeModel()
    var body: some Scene {
        WindowGroup {
            MainHomeView(model: mainHomeModel)
        }
    }
}
