//
//  BookmarksPlaceholderView.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import SwiftUI

struct BookmarksPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Text(BookmarksLocalKey.emptyTitle)
        } description: {
            Text(BookmarksLocalKey.emptyMessage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MainPalette.background.ignoresSafeArea())
    }
}
