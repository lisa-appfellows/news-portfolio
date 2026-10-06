//
//  DiscoverPlaceholderView.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import SwiftUI

struct DiscoverPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Text(DiscoverLocalKey.idleTitle)
        } description: {
            Text(DiscoverLocalKey.idleMessage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MainPalette.background.ignoresSafeArea())
    }
}
