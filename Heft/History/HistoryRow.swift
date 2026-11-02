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
    var weightUnit: WeightUnit = .kg

    @ScaledMetric(relativeTo: .body) private var minRowHeight: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var rowSpacing: CGFloat = 2

    private var displayWeight: Double {
        weightUnit == .lbs ? UnitConverter.kgToLbs(weight) : weight
    }

    private var displayDelta: Double? {
        delta.map { weightUnit == .lbs ? UnitConverter.kgToLbs($0) : $0 }
    }

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        formatter.locale = loc
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "dd MMM yyyy", options: 0, locale: loc)
        return formatter
    }

    private var formattedDate: String {
        Self.dateFormatter.string(from: date)
    }

    private var bmiText: String {
        if let bmi = BMICalculator.calculate(weightKg: weight, heightCm: height) {
            return "BMI: \(HeftFormat.weight(bmi))"
        }
        return "BMI: —"
    }

    private var accessibilityLabel: String {
        let deltaPart: String
        if let d = displayDelta {
            if abs(d) < 0.05 {
                deltaPart = String(localized: "değişim yok", comment: "No weight change delta a11y")
            } else {
                let formattedDelta = HeftFormat.signedWeight(d)
                deltaPart = String(localized: "değişim \(formattedDelta) \(weightUnit.symbol)", comment: "Weight change delta a11y")
            }
        } else {
            deltaPart = String(localized: "başlangıç kaydı", comment: "Initial record a11y")
        }
        let formattedWeight = HeftFormat.weight(displayWeight)
        return "\(formattedDate), \(formattedWeight) \(weightUnit.symbol), \(bmiText), \(deltaPart)"
    }

    @ViewBuilder
    private var deltaBadge: some View {
        if let d = displayDelta {
            let isPositive = d > 0.001
            let isNegative = d < -0.001
            let isGood = isGainGoal ? isPositive : isNegative
            let badgeColor = (isPositive || isNegative) ? (isGood ? Color.heftSuccess : Color.heftError) : Color.secondary

            let text: String = {
                if abs(d) < 0.05 {
                    return HeftFormat.weightWithUnit(0, unit: weightUnit)
                }
                return HeftFormat.signedWeightWithUnit(d, unit: weightUnit)
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
                        .fixedSize(horizontal: true, vertical: false)

                    Text(bmiText)
                        .font(.heftMeta)
                        .foregroundStyle(Color.secondary)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: rowSpacing) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(HeftFormat.weight(displayWeight))
                            .font(.heftCardTitle)
                            .foregroundStyle(Color.primary)

                        Text(weightUnit.symbol)
                            .font(.heftMeta)
                            .foregroundStyle(Color.secondary)
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    deltaBadge
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            // Fallback stacked layout for huge Dynamic Type sizes
            VStack(alignment: .leading, spacing: rowSpacing * 2) {
                Text(formattedDate)
                    .font(.heftListItem)
                    .foregroundStyle(Color.primary)

                HStack {
                    Text(HeftFormat.weightWithUnit(displayWeight, unit: weightUnit))
                        .font(.heftCardTitle)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    deltaBadge
                }

                Text(bmiText)
                    .font(.heftMeta)
                    .foregroundStyle(Color.secondary)
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
