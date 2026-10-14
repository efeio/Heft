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
            return isMaintainGoal ? "Formunuzu koruyorsunuz" : "Hedefe ulaşıldı"
        }
        if isMaintainGoal {
            let diff = latestWeight - targetWeight
            if diff > 0 {
                return String(format: "+%.1f kg fark", diff)
            } else {
                return String(format: "−%.1f kg fark", abs(diff))
            }
        } else if isGainGoal {
            if diffToTarget > 0 {
                return String(format: "+%.1f kg kaldı", diffToTarget)
            } else {
                return String(format: "+%.1f kg hedef üstü", abs(diffToTarget))
            }
        } else {
            if diffToTarget > 0 {
                return String(format: "−%.1f kg kaldı", diffToTarget)
            } else {
                return String(format: "−%.1f kg hedef altı", abs(diffToTarget))
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
            return "Bu hafta: —"
        }
        if abs(diff) < 0.05 {
            return "Bu hafta: 0.0 kg"
        } else if diff < 0 {
            return String(format: "Bu hafta: −%.1f kg", abs(diff))
        } else {
            return String(format: "Bu hafta: +%.1f kg", diff)
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
            weeklyStr = String(format: "%@%.1f kg", (diff >= 0 ? "+" : "−"), abs(diff))
        } else {
            weeklyStr = "değişim yok"
        }
        return "Mevcut kilo \(String(format: "%.1f", latestWeight)) kg, hedef \(String(format: "%.1f", targetWeight)) kg, \(remainingPillText), bu hafta \(weeklyStr)."
    }

    // MARK: - Pill Views
    @ViewBuilder
    private var remainingPill: some View {
        Text(remainingPillText)
            .font(.heftMetaSemibold)
            .foregroundStyle(remainingPillColor)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(remainingPillColor.opacity(0.15))
            }
    }

    @ViewBuilder
    private var weeklyPill: some View {
        HStack(spacing: 4) {
            Image(systemName: weeklyTrendIcon)
                .font(.footnote.weight(.bold))
            Text(weeklyChangeText)
                .font(.heftMetaSemibold)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(weeklyTrendColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(weeklyTrendColor.opacity(0.10))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top Row
            HStack(alignment: .lastTextBaseline) {
                // Left: Current Weight
                VStack(alignment: .leading, spacing: 2) {
                    Text("MEVCUT")
                        .heftEyebrowStyle()
                        .foregroundStyle(Color.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", latestWeight))
                            .font(.heftHeroStat)
                            .foregroundStyle(Color.primary)
                            .minimumScaleFactor(0.7)

                        Text("kg")
                            .font(.heftMetaSemibold)
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer()

                // Right: Target Weight
                VStack(alignment: .trailing, spacing: 2) {
                    Text("HEDEF")
                        .heftEyebrowStyle()
                        .foregroundStyle(Color.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", targetWeight))
                            .font(.heftCardTitle)
                            .foregroundStyle(Color.primary)

                        Text("kg")
                            .font(.heftMetaSemibold)
                            .foregroundStyle(Color.secondary)
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
                    remainingPill
                    weeklyPill
                    Spacer()
                }

                // Priority 2: Stack vertically on narrow screens (iPhone SE / large Dynamic Type)
                VStack(alignment: .leading, spacing: 6) {
                    remainingPill
                    weeklyPill
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
