//
//  SummaryCardView.swift
//  Heft
//
//  Overview card displaying current weight, remaining delta, and weekly trend.
//

import SwiftUI

struct SummaryCardView: View {
    let latestWeight: Double
    let targetWeight: Double
    let weekAgoWeight: Double?
    var goalType: GoalType = .lose

    @Environment(\.heftAccent) private var accent

    private var isGainGoal: Bool {
        goalType == .gain
    }

    private var isMaintainGoal: Bool {
        goalType == .maintain
    }

    private var diffToTarget: Double {
        if isGainGoal {
            return targetWeight - latestWeight
        } else {
            return latestWeight - targetWeight
        }
    }

    private var isGoalReached: Bool {
        if isGainGoal {
            return latestWeight >= (targetWeight - 0.05)
        } else if isMaintainGoal {
            return abs(latestWeight - targetWeight) <= 0.5
        } else {
            return latestWeight <= (targetWeight + 0.05)
        }
    }

    private var remainingPillText: String {
        if isGoalReached {
            return isMaintainGoal ? String(localized: "Formunu koruyorsun", comment: "Pill maintain success") : String(localized: "Hedefe ulaşıldı", comment: "Pill goal reached")
        }
        if isMaintainGoal {
            let diff = latestWeight - targetWeight
            if diff > 0 {
                return "+\(HeftFormat.weightKg(diff)) " + String(localized: "fark", comment: "difference suffix")
            } else {
                return "−\(HeftFormat.weightKg(abs(diff))) " + String(localized: "fark", comment: "difference suffix")
            }
        } else if isGainGoal {
            if diffToTarget > 0 {
                return "+\(HeftFormat.weightKg(diffToTarget)) " + String(localized: "kaldı", comment: "remaining to gain")
            } else {
                return "+\(HeftFormat.weightKg(abs(diffToTarget))) " + String(localized: "hedef üstü", comment: "above target")
            }
        } else {
            if diffToTarget > 0 {
                return "−\(HeftFormat.weightKg(diffToTarget)) " + String(localized: "kaldı", comment: "remaining to lose")
            } else {
                return "−\(HeftFormat.weightKg(abs(diffToTarget))) " + String(localized: "hedef altı", comment: "below target")
            }
        }
    }

    private var remainingPillColor: Color {
        isGoalReached ? Color.heftTeal : (isGainGoal ? accent : (diffToTarget > 0 ? accent : Color.heftTeal))
    }

    private var weeklyDiff: Double? {
        guard let prev = weekAgoWeight else { return nil }
        return latestWeight - prev
    }

    private var weeklyChangeText: String {
        guard let diff = weeklyDiff else {
            return String(localized: "Bu hafta: —", comment: "Weekly change empty")
        }
        if abs(diff) < 0.05 {
            return String(localized: "Bu hafta: \(HeftFormat.weightKg(0))", comment: "Weekly change zero")
        } else if diff < 0 {
            return String(localized: "Bu hafta: −\(HeftFormat.weightKg(abs(diff)))", comment: "Weekly change loss")
        } else {
            return String(localized: "Bu hafta: +\(HeftFormat.weightKg(diff))", comment: "Weekly change gain")
        }
    }

    private var weeklyTrendIcon: String {
        guard let diff = weeklyDiff else { return "arrow.right" }
        if abs(diff) < 0.05 {
            return "arrow.right"
        } else if diff < 0 {
            return "arrow.down.right"
        } else {
            return "arrow.up.right"
        }
    }

    private var weeklyTrendColor: Color {
        guard let diff = weeklyDiff else { return Color.heftNeutral }
        if abs(diff) < 0.05 {
            return Color.heftNeutral
        }

        if isMaintainGoal {
            return abs(diff) <= 0.5 ? Color.heftSuccess : Color.heftWarning
        } else if isGainGoal {
            return diff > 0 ? Color.heftSuccess : Color.heftError
        } else {
            return diff < 0 ? Color.heftSuccess : Color.heftError
        }
    }

    private var accessibilityAnnouncement: String {
        let weeklyStr: String
        if let diff = weeklyDiff {
            weeklyStr = "\(diff >= 0 ? "+" : "−")\(HeftFormat.weightKg(abs(diff)))"
        } else {
            weeklyStr = "değişim yok"
        }
        return "Mevcut kilo \(HeftFormat.weightKg(latestWeight)), hedef \(HeftFormat.weightKg(targetWeight)), \(remainingPillText), bu hafta \(weeklyStr)."
    }

    // MARK: - Pill Views
    @ViewBuilder
    private func remainingPill(fixedHorizontal: Bool) -> some View {
        Text(remainingPillText)
            .font(.heftMetaSemibold)
            .foregroundStyle(remainingPillColor)
            .fixedSize(horizontal: fixedHorizontal, vertical: false)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(remainingPillColor.opacity(0.15))
            }
    }

    @ViewBuilder
    private func weeklyPill(fixedHorizontal: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: weeklyTrendIcon)
                .font(.footnote.weight(.bold))
            Text(weeklyChangeText)
                .font(.heftMetaSemibold)
                .fixedSize(horizontal: fixedHorizontal, vertical: false)
        }
        .foregroundStyle(weeklyTrendColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(weeklyTrendColor.opacity(0.10))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top Row
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline) {
                    // Left: Current Weight
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MEVCUT")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)
                            .fixedSize(horizontal: true, vertical: false)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(HeftFormat.weight(latestWeight))
                                .font(.heftHeroStat)
                                .foregroundStyle(Color.primary)

                            Text("kg")
                                .font(.heftMetaSemibold)
                                .foregroundStyle(Color.secondary)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }

                    Spacer(minLength: 12)

                    // Right: Target Weight
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("HEDEF")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)
                            .fixedSize(horizontal: true, vertical: false)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(HeftFormat.weight(targetWeight))
                                .font(.heftCardTitle)
                                .foregroundStyle(Color.primary)

                            Text("kg")
                                .font(.heftMetaSemibold)
                                .foregroundStyle(Color.secondary)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MEVCUT")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(HeftFormat.weight(latestWeight))
                                .font(.heftHeroStat)
                                .foregroundStyle(Color.primary)
                                .minimumScaleFactor(0.8)

                            Text("kg")
                                .font(.heftMetaSemibold)
                                .foregroundStyle(Color.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("HEDEF")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(HeftFormat.weight(targetWeight))
                                .font(.heftCardTitle)
                                .foregroundStyle(Color.primary)

                            Text("kg")
                                .font(.heftMetaSemibold)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }

            // Divider Line
            Divider()
                .overlay(Color.heftDivider)

            // Bottom Row: Responsive Pills with ViewThatFits
            ViewThatFits(in: .horizontal) {
                // Priority 1: Side by side if it fits
                HStack(spacing: 8) {
                    remainingPill(fixedHorizontal: true)
                    weeklyPill(fixedHorizontal: true)
                    Spacer()
                }

                // Priority 2: Stack vertically on narrow screens (iPhone SE / large Dynamic Type)
                VStack(alignment: .leading, spacing: 6) {
                    remainingPill(fixedHorizontal: false)
                    weeklyPill(fixedHorizontal: false)
                }
            }
        }
        .heftCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityAnnouncement)
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    VStack {
        SummaryCardView(latestWeight: 137.0, targetWeight: 90.0, weekAgoWeight: 140.0, goalType: .lose)
    }
    .padding()
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    VStack {
        SummaryCardView(latestWeight: 137.0, targetWeight: 90.0, weekAgoWeight: 140.0, goalType: .lose)
    }
    .padding()
}
