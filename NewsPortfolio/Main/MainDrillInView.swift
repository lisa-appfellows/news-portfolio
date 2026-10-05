//
//  MainDrillInView.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import NewsFeedClient
import SwiftUI

@MainActor
struct MainDrillInView: View {
    @Bindable var model: MainDrillInModel

    var body: some View {
        Group {
            switch model.phase {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .failed:
                ContentUnavailableView {
                    Text(MainLocalKey.emptyTitle)
                } description: {
                    Text(MainLocalKey.emptyMessage)
                }
                
            case .loaded:
                if model.articles.isEmpty {
                    ContentUnavailableView {
                        Text(MainLocalKey.emptyTitle)
                    } description: {
                        Text(MainLocalKey.emptyMessage)
                    }
                } else {
                    articleList
                }
            }
        }
        .background(MainPalette.background.ignoresSafeArea())
        .navigationTitle(Text(MainLocalKey.category(model.category)))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.loadInitial()
        }
    }

    private var articleList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(model.articles, id: \.url) { article in
                    DrillInArticleCard(article: article)
                        .onAppear {
                            guard article.url == model.articles.last?.url else { return }
                            Task { await model.loadMore() }
                        }
                }

                if model.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }

                if model.loadMoreFailed {
                    VStack(spacing: 8) {
                        Text(MainLocalKey.loadMoreError)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            Task { await model.loadMore() }
                        } label: {
                            Text(MainLocalKey.loadMoreRetry)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(MainPalette.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Image-top card
// text fallback until image loader
private struct DrillInArticleCard: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            ZStack(alignment: .bottomLeading) {
                MainPalette.slotFill
                if article.urlToImage == nil {
                    Text(article.title)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(MainPalette.ink)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 4,
                    topTrailingRadius: 4,
                    style: .continuous
                )
            )

            VStack(alignment: .leading, spacing: 6) {
                if article.urlToImage != nil {
                    Text(article.title)
                        .font(.headline)
                        .foregroundStyle(MainPalette.ink)
                        .multilineTextAlignment(.leading)
                }

                if let description = article.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                if let sourceName = article.sourceName, !sourceName.isEmpty {
                    Text(sourceName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.55))
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        MainDrillInView(
            model: MainDrillInModel(
                category: .technology,
                feeds: MainHomeModel.previewFeeds
            )
        )
    }
}
