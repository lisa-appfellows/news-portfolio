//
//  ArticleUnavailableView.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import SwiftUI

struct ArticleUnavailableView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Text(ArticleLocalKey.unavailableTitle)
            } description: {
                Text(ArticleLocalKey.unavailableMessage)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(ArticleLocalKey.unavailableDismiss)
                    }
                }
            }
        }
    }
}
