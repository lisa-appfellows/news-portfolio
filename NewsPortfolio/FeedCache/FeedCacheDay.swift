//
//  FeedCacheDay.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-09-30.
//

import Foundation

/// Local calendar day used for day-boundary cache validity (`yyyy-MM-dd`)
struct FeedCacheDay: RawRepresentable, Hashable, Sendable, Comparable {
    let rawValue: String

    init?(rawValue: String) {
        let parts = rawValue.split(separator: "-")
        guard parts.count == 3,
              parts[0].count == 4,
              parts[1].count == 2,
              parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy(\.isNumber) })
        else {
            return nil
        }
        self.rawValue = rawValue
    }

    init(date: Date, calendar: Calendar = .current) {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        self.rawValue = String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func today(calendar: Calendar = .current, now: Date = Date()) -> FeedCacheDay {
        .init(date: now, calendar: calendar)
    }

    static func < (lhs: FeedCacheDay, rhs: FeedCacheDay) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
