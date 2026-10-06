//
//  ImageDiskCaching.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import CryptoKit
import UIKit

protocol ImageDiskCaching: Sendable {
    func image(for url: URL) async -> UIImage?
    func store(_ image: UIImage, for url: URL) async
}

struct NoImageDiskCache: ImageDiskCaching {
    func image(for url: URL) async -> UIImage? { nil }
    func store(_ image: UIImage, for url: URL) async {}
}

/// File-backed URL: image cache with ~50MB LRU eviction (by file modification date).
actor ImageDiskCache: ImageDiskCaching {
    private let directoryURL: URL
    private let maxByteCount: Int
    
    init(
        directoryURL: URL,
        maxByteCount: Int = 50 * 1024 * 1024
    ) {
        self.directoryURL = directoryURL
        self.maxByteCount = max(1, maxByteCount)
    }
    
    static func makeDefault() throws -> ImageDiskCache {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = root.appending(path: "ImageCache", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        return .init(directoryURL: directory)
    }
    
    
    func image(for url: URL) async -> UIImage? {
        let fileURL = fileURL(for: url)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data)
        else {
            return nil
        }

        // Touch mtime so this entry is treated as most recently used
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )

        return image
    }
    
    func store(_ image: UIImage, for url: URL) async {
        guard let data = image.jpegData(compressionQuality: 0.85) ?? image.pngData() else {
            return
        }

        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let fileURL = fileURL(for: url)
        let temp = fileURL.appendingPathExtension("tmp")
        do {
            try data.write(to: temp, options: .atomic)
            _ = try? FileManager.default.removeItem(at: fileURL)
            try? FileManager.default.moveItem(at: temp, to: fileURL)
            try? FileManager.default.setAttributes(
                [.modificationDate: Date()],
                ofItemAtPath: fileURL.path
            )
        } catch {
            try? FileManager.default.removeItem(at: temp)
            return
        }

        evictIfNeeded()
    }

    // Test seam
    func totalByteCount() throws -> Int {
        try listedEntries().reduce(0) { $0 + $1.byteCount }
    }
}

extension ImageDiskCache {
    private struct Entry {
        let url: URL
        let byteCount: Int
        let modificationDate: Date
    }

    private func evictIfNeeded() {
        guard var entries = try? listedEntries() else { return }
        var total = entries.reduce(0) { $0 + $1.byteCount }
        guard total > maxByteCount else { return }

        entries.sort { $0.modificationDate < $1.modificationDate } // oldest first
        for entry in entries {
            guard total > maxByteCount else { break }
            try? FileManager.default.removeItem(at: entry.url)
            total -= entry.byteCount
        }
    }

    private func listedEntries() throws -> [Entry] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        return urls.compactMap { url -> Entry? in
            guard url.pathExtension != "tmp" else { return nil }
            let values = try? url.resourceValues(
                forKeys: [.fileSizeKey, .contentModificationDateKey]
            )

            guard let size = values?.fileSize,
                  let date = values?.contentModificationDate
            else {
                return nil
            }
    
            return Entry(url: url, byteCount: size, modificationDate: date)
        }
    }
    
    private func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directoryURL
            .appending(path: name, directoryHint: .notDirectory)
            .appendingPathExtension("jpg")
    }
}
