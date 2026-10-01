//
//  FileFeedCacheStore.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import CryptoKit
import Foundation
import NewsFeedClient

actor FileFeedCacheStore: FeedCacheStoring {
    static let lastCacheDayDefaultsKey = "lastFeedCacheDay"

    private let directoryURL: URL
    private let defaultsSuiteName: String?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        directoryURL: URL,
        defaultsSuiteName: String? = nil
    ) {
        self.directoryURL = directoryURL
        self.defaultsSuiteName = defaultsSuiteName

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    /// Production convenience: `Application Support/FeedCache`
    static func makeDefault(
        fileManager: FileManager = .default,
        defaults: UserDefaults = .standard
    ) throws -> FileFeedCacheStore {
        let fileManager = FileManager.default
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = root.appending(path: "FeedCache", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return .init(directoryURL: directory)
    }

    private var defaults: UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    func lastCacheDay() async -> FeedCacheDay? {
        guard let raw = defaults.string(forKey: Self.lastCacheDayDefaultsKey) else { return nil }
        return FeedCacheDay(rawValue: raw)
    }

    func setLastCacheDay(_ day: FeedCacheDay) async {
        defaults.set(day.rawValue, forKey: Self.lastCacheDayDefaultsKey)
    }

    func payload(for key: FeedCacheKey) async -> NewsPage? {
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let dto = try? decoder.decode(CachedNewsPageDTO.self, from: data) else { return nil }
        return dto.asNewsPage()
    }

    func save(_ page: NewsPage, for key: FeedCacheKey, day: FeedCacheDay) async {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let dto = CachedNewsPageDTO(page)
        guard let data = try? encoder.encode(dto) else { return }

        let url = fileURL(for: key)
        // Atomic replace so readers never see a half-written file
        let temp = url.appendingPathExtension("tmp")
        do {
            try data.write(to: temp, options: .atomic)
            _ = try? FileManager.default.removeItem(at: url)
            try FileManager.default.moveItem(at: temp, to: url)
            defaults.set(day.rawValue, forKey: Self.lastCacheDayDefaultsKey)
        } catch {
            try? FileManager.default.removeItem(at: temp)
        }
    }

    func removePayload(for key: FeedCacheKey) async {
        let url = fileURL(for: key)
        try? FileManager.default.removeItem(at: url)
    }

    private func fileURL(for key: FeedCacheKey) -> URL {
        let digest = SHA256.hash(data: Data(key.rawValue.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directoryURL
            .appending(path: name, directoryHint: .notDirectory)
            .appendingPathExtension("json")
    }
}

// MARK: - Disk DTOs
private struct CachedNewsPageDTO: Codable {
    var articles: [CachedArticleDTO]
    var totalResults: Int

    init(_ page: NewsPage) {
        articles = page.articles.map(CachedArticleDTO.init)
        totalResults = page.totalResults
    }

    func asNewsPage() -> NewsPage {
        .init(articles: articles.map { $0.asArticle() }, totalResults: totalResults)
    }
}

private struct CachedArticleDTO: Codable {
    var title: String
    var url: String
    var urlToImage: String?
    var description: String?
    var author: String?
    var publishedDate: Date?
    var sourceName: String?

    init(_ article: Article) {
        title = article.title
        url = article.url
        urlToImage = article.urlToImage
        description = article.description
        author = article.author
        publishedDate = article.publishedDate
        sourceName = article.sourceName
    }

    func asArticle() -> Article {
        .init(
            title: title,
            url: url,
            urlToImage: urlToImage,
            description: description,
            author: author,
            publishedDate: publishedDate,
            sourceName: sourceName
        )
    }
}
