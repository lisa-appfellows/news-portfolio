//
//  ArticleOpenModifier.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import SwiftUI

extension View {
    func opensArticle(urlString: String) -> some View {
        modifier(ArticleOpenModifier(urlString: urlString))
    }
}

private struct ArticleOpenModifier: ViewModifier {
    let urlString: String
    @State private var presentation: ArticlePresentation?

    func body(content: Content) -> some View {
        Button {
            presentation = .resolve(urlString)
        } label: {
            content
        }
        .buttonStyle(.plain)
        .sheet(item: $presentation) { item in
            switch item {
            case .safari(let url):
                SafariView(url: url)
                    .ignoresSafeArea()
            case .unavailable:
                ArticleUnavailableView()
            }
        }
    }
}
