//
//  DiscoverTimeFrame.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-01.
//

import Foundation

typealias QueryDateRange = (from: Date?, to: Date?)

enum DiscoverTimeFrame: Equatable, Sendable {
    case today
    case yesterday
    case lastTwoWeeks
    case thisMonth

    /// Local-calendar `from`/`to` for `/everything`. End of 'today' windows uses `now`.
    func dateRange(
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> QueryDateRange {
        let startOfDay = calendar.startOfDay(for: now)

        switch self {
        case .today:
            return (startOfDay, now)

        case .yesterday:
            let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay)
            let endOfYesterday = calendar.date(byAdding: .second, value: -1, to: startOfDay)
            return (startOfYesterday, endOfYesterday)

        case .lastTwoWeeks:
            let from = calendar.date(byAdding: .day, value: -14, to: now)!
            return (from, now)

        case .thisMonth:
            let comps = calendar.dateComponents([.year,  .month], from: now)
            let startOfMonth = calendar.date(from: comps)!
            return (startOfMonth, now)
        }
    }
}
