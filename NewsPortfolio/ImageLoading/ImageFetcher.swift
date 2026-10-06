//
//  ImageFetcher.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import UIKit

enum ImageFetcher {
    static func urlSession(_ session: URLSession = .shared) -> ImageLoader.Fetch {
        { url in
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let image = UIImage(data: data)
            else {
                throw URLError(.badServerResponse)
            }
            return image
        }
    }
}
