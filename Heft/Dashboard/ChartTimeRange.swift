//
//  ChartTimeRange.swift
//  Heft
//
//  Shared time range model for Weight and BMI charts.
//

import SwiftUI

enum ChartTimeRange: String, CaseIterable, Identifiable {
    case oneMonth = "1A"
    case threeMonths = "3A"
    case sixMonths = "6A"
    case oneYear = "1Y"
    case all = "Tümü"

    var id: String { rawValue }

    var accessibilityTitle: String {
        switch self {
        case .oneMonth: return "1 Ay"
        case .threeMonths: return "3 Ay"
        case .sixMonths: return "6 Ay"
        case .oneYear: return "1 Yıl"
        case .all: return "Tüm Zamanlar"
        }
    }

    var days: Int? {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .all: return nil
        }
    }

    func isAvailable(for allDates: [Date]) -> Bool {
        guard let minDate = allDates.min(), let maxDate = allDates.max() else { return true }
        let spanDays = max(1, Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 1)
        switch self {
        case .oneMonth, .all:
            return true
        case .threeMonths:
            return spanDays >= 14
        case .sixMonths:
            return spanDays >= 60
        case .oneYear:
            return spanDays >= 120
        }
    }

    func dateRange(relativeTo referenceDate: Date, allDates: [Date]) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let endOfToday = calendar.startOfDay(for: referenceDate).addingTimeInterval(86399)

        var start: Date
        let end: Date = endOfToday

        if let days = days {
            start = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: referenceDate))
                ?? referenceDate.addingTimeInterval(-Double(days) * 86400)
        } else {
            if let earliest = allDates.min() {
                let earliestStart = calendar.startOfDay(for: earliest)
                let spanDays = calendar.dateComponents([.day], from: earliestStart, to: calendar.startOfDay(for: referenceDate)).day ?? 0
                if spanDays < 14 {
                    start = calendar.date(byAdding: .day, value: -14, to: calendar.startOfDay(for: referenceDate))
                        ?? referenceDate.addingTimeInterval(-14 * 86400)
                } else {
                    start = earliestStart
                }
            } else {
                start = calendar.date(byAdding: .day, value: -14, to: calendar.startOfDay(for: referenceDate))
                    ?? referenceDate.addingTimeInterval(-14 * 86400)
            }
        }

        let trailingBufferDays: Double
        let leadingBufferDays: Double
        switch self {
        case .oneMonth:
            trailingBufferDays = 2.5
            leadingBufferDays = 1.0
        case .threeMonths:
            trailingBufferDays = 5.0
            leadingBufferDays = 2.0
        case .sixMonths:
            trailingBufferDays = 8.0
            leadingBufferDays = 4.0
        case .oneYear:
            trailingBufferDays = 14.0
            leadingBufferDays = 7.0
        case .all:
            trailingBufferDays = 2.5
            leadingBufferDays = 1.0
        }

        let bufferedStart = start.addingTimeInterval(-leadingBufferDays * 86400)
        let bufferedEnd = end.addingTimeInterval(trailingBufferDays * 86400)
        let safeEnd = max(bufferedStart.addingTimeInterval(86400), bufferedEnd)
        return bufferedStart...safeEnd
    }

    private static let dayMonthFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateFormat = "d MMM"
        return df
    }()

    private static let monthFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateFormat = "MMM"
        return df
    }()

    private static let monthYearFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateFormat = "MMM ''yy"
        return df
    }()

    func filter(entries: [WeightEntry], relativeTo referenceDate: Date) -> [WeightEntry] {
        let isAlreadySorted = zip(entries, entries.dropFirst()).allSatisfy { $0.date <= $1.date }
        guard let days = days else {
            return isAlreadySorted ? entries : entries.sorted { $0.date < $1.date }
        }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: referenceDate) ?? referenceDate.addingTimeInterval(-Double(days) * 86400)
        let filtered = entries.filter { $0.date >= cutoff }
        return isAlreadySorted ? filtered : filtered.sorted { $0.date < $1.date }
    }

    func xAxisDates(referenceDate: Date, allDates: [Date]) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        switch self {
        case .oneMonth:
            let d1 = calendar.date(byAdding: .day, value: -20, to: today) ?? today.addingTimeInterval(-20 * 86400)
            let d2 = calendar.date(byAdding: .day, value: -10, to: today) ?? today.addingTimeInterval(-10 * 86400)
            return [d1, d2, today]

        case .threeMonths:
            let m2 = calendar.date(byAdding: .month, value: -2, to: today) ?? today.addingTimeInterval(-60 * 86400)
            let m1 = calendar.date(byAdding: .month, value: -1, to: today) ?? today.addingTimeInterval(-30 * 86400)
            return [m2, m1, today]

        case .sixMonths:
            let m5 = calendar.date(byAdding: .month, value: -5, to: today) ?? today.addingTimeInterval(-150 * 86400)
            let m3 = calendar.date(byAdding: .month, value: -3, to: today) ?? today.addingTimeInterval(-90 * 86400)
            let m1 = calendar.date(byAdding: .month, value: -1, to: today) ?? today.addingTimeInterval(-30 * 86400)
            return [m5, m3, m1, today]

        case .oneYear:
            let m9 = calendar.date(byAdding: .month, value: -9, to: today) ?? today.addingTimeInterval(-270 * 86400)
            let m6 = calendar.date(byAdding: .month, value: -6, to: today) ?? today.addingTimeInterval(-180 * 86400)
            let m3 = calendar.date(byAdding: .month, value: -3, to: today) ?? today.addingTimeInterval(-90 * 86400)
            return [m9, m6, m3, today]

        case .all:
            let earliest = allDates.min() ?? today.addingTimeInterval(-14 * 86400)
            let spanDays = max(14, calendar.dateComponents([.day], from: earliest, to: today).day ?? 14)

            if spanDays <= 30 {
                let d1 = calendar.date(byAdding: .day, value: -spanDays, to: today) ?? today.addingTimeInterval(-Double(spanDays) * 86400)
                let d2 = calendar.date(byAdding: .day, value: -(spanDays / 2), to: today) ?? today.addingTimeInterval(-Double(spanDays / 2) * 86400)
                return [d1, d2, today]
            } else if spanDays <= 90 {
                let d1 = calendar.date(byAdding: .day, value: -spanDays, to: today) ?? today.addingTimeInterval(-Double(spanDays) * 86400)
                let d2 = calendar.date(byAdding: .day, value: -(spanDays * 2 / 3), to: today) ?? today
                let d3 = calendar.date(byAdding: .day, value: -(spanDays / 3), to: today) ?? today
                return [d1, d2, d3, today]
            } else {
                let m3 = calendar.date(byAdding: .month, value: -max(1, spanDays / 90), to: today) ?? today
                let m2 = calendar.date(byAdding: .month, value: -max(2, spanDays * 2 / 90), to: today) ?? today
                let m1 = calendar.date(byAdding: .month, value: -max(3, spanDays / 30), to: today) ?? today
                return [m1, m2, m3, today]
            }
        }
    }

    func format(date: Date, relativeTo referenceDate: Date) -> String {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: referenceDate)
        let dateYear = calendar.component(.year, from: date)

        switch self {
        case .oneMonth:
            return Self.dayMonthFormatter.string(from: date)

        case .threeMonths, .sixMonths, .oneYear:
            if dateYear != currentYear {
                return Self.monthYearFormatter.string(from: date)
            } else {
                return Self.monthFormatter.string(from: date)
            }

        case .all:
            let spanDays = calendar.dateComponents([.day], from: date, to: referenceDate).day ?? 1
            if spanDays <= 45 {
                return Self.dayMonthFormatter.string(from: date)
            } else if dateYear != currentYear {
                return Self.monthYearFormatter.string(from: date)
            } else {
                return Self.monthFormatter.string(from: date)
            }
        }
    }
}
