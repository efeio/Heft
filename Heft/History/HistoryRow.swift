//
//  HistoryRow.swift
//  Heft
//
//  Single entry row in the History tab showing date, BMI, and logged weight.
//

import SwiftUI

struct HistoryRow: View {
    let date: Date
    let weight: Double
    let height: Double
    var delta: Double? = nil
    var isGainGoal: Bool = false

    @ScaledMetric(relativeTo: .body) private var minRowHeight: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var rowSpacing: CGFloat = 2

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()

    private var formattedDate: String {
        Self.dateFormatter.string(from: date)
    }

    private var bmiText: String {
        if let bmi = BMICalculator.calculate(weightKg: weight, heightCm: height) {
            return String(format: "BMI: %.1f", bmi)
        }
        return "BMI: —"
    }

    private var accessibilityLabel: String {
        "\(formattedDate), \(String(format: "%.1f", weight)) kilogram, \(bmiText)"
    }

    @ViewBuilder
    private var deltaBadge: some View {
        if let delta = delta {
            let isPositive = delta > 0.001
            let isNegative = delta < -0.001
            let isGood = isGainGoal ? isPositive : isNegative
            let badgeColor = (isPositive || isNegative) ? (isGood ? Color.heftSuccess : Color.heftError) : Color.secondary

            let text: String = {
                if abs(delta) < 0.05 {
                    return "0.0 kg"
                }
                return String(format: "%@%.1f kg", delta > 0 ? "+" : "", delta)
            }()

            Text(text)
                .font(.caption2.weight(.bold))
                .foregroundStyle(badgeColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(badgeColor.opacity(0.12), in: Capsule())
        } else {
            Text("Başlangıç")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.10), in: Capsule())
        }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Standard HStack layout
            HStack {
                VStack(alignment: .leading, spacing: rowSpacing) {
                    Text(formattedDate)
                        .font(.heftListItem)
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Text(bmiText)
                        .font(.heftMeta)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: rowSpacing) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", weight))
                            .font(.heftCardTitle)
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)

                        Text("kg")
                            .font(.heftMeta)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }

                    deltaBadge
                }
            }

            // Fallback stacked layout for huge Dynamic Type sizes
            VStack(alignment: .leading, spacing: rowSpacing * 2) {
                HStack {
                    Text(formattedDate)
                        .font(.heftListItem)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Text(String(format: "%.1f kg", weight))
                        .font(.heftCardTitle)
                        .foregroundStyle(Color.primary)
                }
                HStack {
                    Text(bmiText)
                        .font(.heftMeta)
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    deltaBadge
                }
            }
        }
        .frame(minHeight: minRowHeight)
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    List {
        HistoryRow(date: Date(), weight: 74.5, height: 178)
    }
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    List {
        HistoryRow(date: Date(), weight: 74.5, height: 178)
    }
}
