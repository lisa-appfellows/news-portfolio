//
//  ImageMemoryCache.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import UIKit

protocol ImageMemoryCaching: Sendable {
    func image(for url: URL) -> UIImage?
    func store(_ image: UIImage, for url: URL)
}

final class ImageMemoryCache: ImageMemoryCaching, @unchecked Sendable {
    private let cache = NSCache<NSURL, UIImage>()

    init(
        countLimit: Int = 150,
        totalCostLimit: Int = 50 * 1024 * 1024
    ) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func store(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL, cost: Self.cost(for: image))
    }

    private static func cost(for image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 1 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
