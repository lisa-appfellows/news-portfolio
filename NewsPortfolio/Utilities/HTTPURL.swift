//
//  HTTPURL.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import Foundation

enum HTTPURL {
    /// Returns an http(s) URL, or nil when the loader should be skipped.
    static func parse(_ string: String?) -> URL? {
        guard let string,
              let url = URL(string: string),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return nil
        }
        return url
    }
}
