//
//  MainHomeView.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import NewsFeedClient
import SwiftUI

struct MainHomeView: View {
    @Bindable var model: MainHomeModel
    let feeds: FeedFetching

    var body: some View {
        NavigationStack {
            Group {
                if model.isFullyFailed {
                    fullTabEmpty
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 28) {
                            ForEach(model.sections) { section in
                                MainHomeSectionView(section: section)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
            .background(MainPalette.background.ignoresSafeArea())
            .navigationDestination(for: MainCategoryRoute.self) { route in
                MainDrillInView(
                    model: MainDrillInModel(category: route.category, feeds: feeds)
                )
            }
            .task {
                await model.loadHome()
            }
        }
    }

    private var fullTabEmpty: some View {
        ContentUnavailableView {
            Text(MainLocalKey.emptyTitle)
        } description: {
            Text(MainLocalKey.emptyMessage)
        }
    }
}

// MARK: - Section
struct MainHomeSectionView: View {
    let section: MainHomeModel.Section

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            switch section.phase {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

            case .failed:
                Text(MainLocalKey.sectionError)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

            case .loaded(let newsPage, _):
                if section.category == .technology {
                    TechnologyMosaicView(articles: Array(newsPage.articles.prefix(4)))
                } else {
                    CategoryGridView(articles: Array(newsPage.articles.prefix(6)))
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(MainLocalKey.category(section.category))
                .font(.system(.title2))
                .tracking(1.8)
            Spacer()
            NavigationLink(value: MainCategoryRoute(category: section.category)) {
                Text(MainLocalKey.seeAll)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MainPalette.accent)
        }
    }
}

// MARK: - Tech Mosiac
// (hero -> pair -> landscape)
private struct TechnologyMosaicView: View {
    let articles: [Article]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if articles.indices.contains(0) {
                ArticleSlotView(article: articles[0], style: .hero)
            }
            if articles.count >= 3 {
                HStack(spacing: 8) {
                    ArticleSlotView(article: articles[1], style: .half)
                    ArticleSlotView(article: articles[2], style: .half)
                }
            }
            if articles.indices.contains(3) {
                ArticleSlotView(article: articles[3], style: .landscape)
            }
        }
    }
}

// MARK: - 2x3 Grid
private struct CategoryGridView: View {
    let articles: [Article]

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(articles, id: \.url) { article in
                ArticleSlotView(article: article, style: .grid)
            }
        }
    }
}

// MARK: - Slot
// text fallback until image loader exists
private struct ArticleSlotView: View {
    enum Style {
        case hero
        case half
        case landscape
        case grid
    }

    let article: Article
    let style: Style

    var body: some View {
        Text(article.title)
            .font(titleFont)
            .foregroundStyle(MainPalette.ink)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(10)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(MainPalette.slotFill)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var height: CGFloat {
        switch style {
        case .hero: return 200
        case .half: return 140
        case .landscape: return 96
        case .grid: return 120
        }
    }

    private var titleFont: Font {
        switch style {
        case .hero:
            return .system(.title3, design: .serif, weight: .semibold)
        default:
            return .system(.subheadline, design: .default, weight: .medium)
        }
    }
}

// MARK: - Palette
// TODO: Replace with Asset Catalog colors
enum MainPalette {
    static let background = Color(red: 0.933, green: 0.945, blue: 0.957) // #EEF1F4
    static let slotFill = Color(red: 0.969, green: 0.973, blue: 0.980)   // #F7F8FA
    static let ink = Color.primary
    static let accent = Color(red: 0.28, green: 0.45, blue: 0.62)        // steel blue
}

// MARK: - Preview
#Preview {
    MainHomeView(model: .preview, feeds: MainHomeModel.previewFeeds)
}

#if DEBUG
extension MainHomeModel {
    @MainActor
    static var preview: MainHomeModel { .init(feeds: previewFeeds) }

    @MainActor
    static var previewFeeds: FeedFetching {
        let page = NewsPage(
            articles: [
                .init(title: "Preview hero headline", url: "https://example.com/1"),
                .init(title: "Preview side A", url: "https://example.com/2"),
                .init(title: "Preview side B", url: "https://example.com/3"),
                .init(title: "Preview landscape", url: "https://example.com/4"),
                .init(title: "Preview grid five", url: "https://example.com/5"),
                .init(title: "Preview grid six", url: "https://example.com/6")
            ],
            totalResults: 6
        )
        return FeedFetching(
            loader: FeedLoader(store: InMemoryFeedCacheStore()),
            fetchTopHeadlines: { _ in page },
            fetchEverything: { _ in page }
        )
    }
}
#endif
