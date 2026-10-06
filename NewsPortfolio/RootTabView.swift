//
//  RootTabView.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import SwiftUI

struct RootTabView: View {
    let feeds: FeedFetching
    @State private var mainHomeModel: MainHomeModel
    @State private var selectedTab: AppTab = .main

    init(feeds: FeedFetching, mainHomeModel: MainHomeModel) {
        self.feeds = feeds
        _mainHomeModel = State(initialValue: mainHomeModel)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MainHomeView(model: mainHomeModel, feeds: feeds)
                .tabItem {
                    Label {
                        Text(MainLocalKey.tabTitle)
                    } icon: {
                        Image(systemName: "newspaper")
                    }
                }
                .tag(AppTab.main)

            DiscoverPlaceholderView()
                .tabItem {
                    Label {
                        Text(DiscoverLocalKey.tabTitle)
                    } icon: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .tag(AppTab.discover)

            BookmarksPlaceholderView()
                .tabItem {
                    Label {
                        Text(BookmarksLocalKey.tabTitle)
                    } icon: {
                        Image(systemName: "bookmark")
                    }
                }
                .tag(AppTab.bookmarks)
        }
    }
}
