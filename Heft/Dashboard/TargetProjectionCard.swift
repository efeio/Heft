//
//  TargetProjectionCard.swift
//  Heft
//
//  Adaptive target projection card estimating goal completion date,
//  confidence intervals, milestone progress, and behavioral intelligence.
//

import SwiftUI
import UIKit

struct TargetProjectionCard: View {
    let entries: [WeightEntry]
    let targetWeight: Double
    var initialWeight: Double? = nil
    var goalType: GoalType = .lose
    var targetWeeklyPace: Double = 0.5

    @Environment(\.heftAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showFeedbackBadge = false
    @State private var feedbackBadgeText: String? = nil
    @State private var feedbackBadgeIsPositive = true

    @AppStorage("heft_last_projected_timestamp") private var lastProjectedTimestamp: Double = 0.0

    private var effectiveInitialWeight: Double {
        initialWeight ?? entries.sorted(by: { $0.date < $1.date }).first?.weight ?? targetWeight
    }

    private var projectionInput: ProjectionInput {
        ProjectionInput(
            entries: entries,
            targetWeight: targetWeight,
            initialWeight: effectiveInitialWeight,
            goalType: goalType,
            onboardingWeeklyPace: targetWeeklyPace,
            referenceDate: Date()
        )
    }

    private var output: ProjectionOutput {
        ProjectionEngine.calculate(input: projectionInput)
    }

    private var weeksBadgeText: String {
        let weeks = output.primaryWeeksRemaining
        if weeks <= 0 {
            return "Tebrikler"
        }
        let rounded = Int(ceil(weeks))
        return "~\(rounded) Hafta"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: - Header Row (Title & Pace Indicator)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: output.isGoalReached ? "checkmark.seal.fill" : (output.isMaintainGoal ? "equal.circle.fill" : "target"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(output.isGoalReached ? Color.heftSuccess : accent)

                        Text(output.isGoalReached ? "HEDEFE ULAŞILDI" : (output.isMaintainGoal ? "KİLO KORUMA" : "TAHMİNİ BİTİŞ"))
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(Color.secondary)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    Spacer()

                    if !output.isGoalReached && !output.isMaintainGoal {
                        paceIndicatorView
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: output.isGoalReached ? "checkmark.seal.fill" : (output.isMaintainGoal ? "equal.circle.fill" : "target"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(output.isGoalReached ? Color.heftSuccess : accent)

                        Text(output.isGoalReached ? "HEDEFE ULAŞILDI" : (output.isMaintainGoal ? "KİLO KORUMA" : "TAHMİNİ BİTİŞ"))
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(Color.secondary)
                    }

                    if !output.isGoalReached && !output.isMaintainGoal {
                        paceIndicatorView
                    }
                }
            }

            // MARK: - Micro-Feedback Badge (On Weight Save)
            if showFeedbackBadge, let badgeText = feedbackBadgeText {
                HStack(spacing: 6) {
                    Image(systemName: feedbackBadgeIsPositive ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                        .font(.caption.weight(.bold))

                    Text(badgeText)
                        .font(.caption.weight(.semibold))

                    Spacer()
                }
                .foregroundStyle(feedbackBadgeIsPositive ? Color.heftSuccess : Color.heftWarning)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(feedbackBadgeIsPositive ? Color.heftSuccess.opacity(0.12) : Color.heftWarning.opacity(0.12))
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95)))
            }

            // MARK: - Hero Date Range & Remaining Weeks
            if !output.isGoalReached && !output.isMaintainGoal {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(output.primaryDateRangeString)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.primary)
                            .fixedSize(horizontal: true, vertical: false)

                        Spacer()

                        badgeView(badge: weeksBadgeText, color: accent)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(output.primaryDateRangeString)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.primary)

                        badgeView(badge: weeksBadgeText, color: accent)
                    }
                }
            } else {
                Text(output.primaryDateRangeString)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.primary)
            }

            // MARK: - Milestone Progress Bar
            if !output.isGoalReached && !output.isMaintainGoal {
                milestoneProgressBar
                    .padding(.vertical, 2)
            }

            // MARK: - Dynamic Context Insight (Single Smart Message)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: insightIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(insightIconColor)
                    .padding(.top, 1)

                Text(output.generalMessage)
                    .font(.heftMeta)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                Spacer(minLength: 0)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(insightBackgroundColor)
            }

            // Medical Disclaimer
            Text("Bilgilendirme amaçlıdır; tıbbi teşhis veya klinik tavsiye niteliği taşımaz.")
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .heftCard()
        .onAppear {
            evaluateMicroFeedback()
        }
        .onChange(of: entries.count) { _, _ in
            evaluateMicroFeedback()
        }
    }

    // MARK: - Pace Indicator
    @ViewBuilder
    private var paceIndicatorView: some View {
        let status = output.paceStatus
        if status != .notApplicable {
            let statusColor: Color = {
                switch status {
                case .ideal: return Color.heftSuccess
                case .slow: return Color.heftWarning
                case .tooFast: return Color.heftWarning
                case .moderate: return accent
                case .notApplicable: return Color.secondary
                }
            }()

            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)

                Text(status.label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(statusColor)
            }
        }
    }

    // MARK: - Minimal Milestone Progress Bar
    @ViewBuilder
    private var milestoneProgressBar: some View {
        let milestone = output.milestone
        let hasCoveredProgress = abs(milestone.startWeight - milestone.currentWeight) >= 0.2

        VStack(spacing: 8) {
            // Visual Track
            GeometryReader { geo in
                let width = geo.size.width
                let currentX = width * CGFloat(milestone.progressFraction)

                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.secondary.opacity(0.16))
                        .frame(height: 5)

                    // Active progress line
                    Capsule()
                        .fill(accent)
                        .frame(width: max(6, currentX), height: 5)

                    // Current position dot
                    Circle()
                        .fill(accent)
                        .overlay {
                            Circle().stroke(Color.white, lineWidth: 2)
                        }
                        .shadow(color: accent.opacity(0.35), radius: 3, x: 0, y: 1)
                        .frame(width: 12, height: 12)
                        .offset(x: min(width - 6, max(0, currentX - 6)))

                    // Target indicator dot at the end
                    Circle()
                        .fill(currentX >= width - 1 ? Color.heftSuccess : Color(.tertiarySystemGroupedBackground))
                        .overlay {
                            Circle().stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                        }
                        .frame(width: 9, height: 9)
                        .offset(x: width - 4.5)
                }
            }
            .frame(height: 12)

            // Milestone Labels
            ViewThatFits(in: .horizontal) {
                HStack {
                    if hasCoveredProgress {
                        HStack(spacing: 2) {
                            Text("Başlangıç:")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.secondary)
                            Text(HeftFormat.weight(milestone.startWeight))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.secondary)
                        }
                        .fixedSize(horizontal: true, vertical: false)

                        Spacer()

                        HStack(spacing: 2) {
                            Text("Bugün:")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.secondary)
                            Text(HeftFormat.weight(milestone.currentWeight))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.primary)
                        }
                        .fixedSize(horizontal: true, vertical: false)

                        Spacer()
                    } else {
                        HStack(spacing: 2) {
                            Text("Bugün:")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.secondary)
                            Text(HeftFormat.weight(milestone.currentWeight))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.primary)
                        }
                        .fixedSize(horizontal: true, vertical: false)

                        Spacer()
                    }

                    HStack(spacing: 2) {
                        Text("Hedef:")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.secondary)
                        Text(HeftFormat.weight(milestone.targetWeight))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if hasCoveredProgress {
                        HStack(spacing: 4) {
                            Text("Başlangıç:")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.secondary)
                            Text(HeftFormat.weight(milestone.startWeight))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.secondary)
                        }
                    }

                    HStack(spacing: 4) {
                        Text("Bugün:")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.secondary)
                        Text(HeftFormat.weight(milestone.currentWeight))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.primary)
                    }

                    HStack(spacing: 4) {
                        Text("Hedef:")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.secondary)
                        Text(HeftFormat.weight(milestone.targetWeight))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hedef ilerlemesi")
        .accessibilityValue(
            "Başlangıç \(HeftFormat.weight(milestone.startWeight)) kilogram, güncel \(HeftFormat.weight(milestone.currentWeight)) kilogram, hedef \(HeftFormat.weight(milestone.targetWeight)) kilogram, yüzde \(HeftFormat.integer(milestone.progressFraction * 100)) tamamlandı"
        )
    }

    // MARK: - Insight Styling Helpers
    private var insightIcon: String {
        switch output.condition {
        case .plateau:
            return "figure.cooldown"
        case .weightGainAnomaly:
            return "drop.fill"
        case .goalReached:
            return "checkmark.seal.fill"
        case .maintainActive:
            return "checkmark.shield.fill"
        case .normal:
            if output.catchUpInfo != nil {
                return "exclamationmark.triangle.fill"
            }
            return goalType == .gain ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis"
        }
    }

    private var insightIconColor: Color {
        switch output.condition {
        case .plateau:
            return accent
        case .weightGainAnomaly:
            return Color.heftWarning
        case .goalReached:
            return Color.heftSuccess
        case .maintainActive:
            return Color.heftSuccess
        case .normal:
            if output.catchUpInfo != nil {
                return Color.heftWarning
            }
            return accent
        }
    }

    private var insightBackgroundColor: Color {
        switch output.condition {
        case .plateau:
            return Color.heftSurfaceSub
        case .weightGainAnomaly:
            return Color.heftWarning.opacity(0.10)
        case .goalReached:
            return Color.heftSuccess.opacity(0.10)
        case .maintainActive:
            return Color.heftSuccess.opacity(0.10)
        case .normal:
            if output.catchUpInfo != nil {
                return Color.heftWarning.opacity(0.10)
            }
            return Color.heftSurfaceSub
        }
    }

    // MARK: - Badge View
    @ViewBuilder
    private func badgeView(badge: String, color: Color) -> some View {
        Text(badge)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }

    // MARK: - Micro-Feedback Evaluation
    private func evaluateMicroFeedback() {
        guard !output.isGoalReached && !output.isMaintainGoal else { return }

        let currentTargetTimestamp = output.primaryProjectedDate.timeIntervalSince1970

        if lastProjectedTimestamp > 0 {
            let oldDate = Date(timeIntervalSince1970: lastProjectedTimestamp)
            let newDate = output.primaryProjectedDate

            let deltaDays = Calendar.current.dateComponents([.day], from: oldDate, to: newDate).day ?? 0

            // Delta < 0 means newDate is earlier than oldDate -> positive progress!
            if deltaDays <= -1 {
                let text = "Hedef \(abs(deltaDays)) gün öne çekildi"
                feedbackBadgeText = text
                feedbackBadgeIsPositive = true
                if reduceMotion {
                    showFeedbackBadge = true
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showFeedbackBadge = true
                    }
                }
                AccessibilityNotification.Announcement(text).post()
            } else if deltaDays >= 1 {
                let text = "Hedef \(deltaDays) gün ötelendi"
                feedbackBadgeText = text
                feedbackBadgeIsPositive = false
                if reduceMotion {
                    showFeedbackBadge = true
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showFeedbackBadge = true
                    }
                }
                AccessibilityNotification.Announcement(text).post()
            }
        }

        lastProjectedTimestamp = currentTargetTimestamp
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    VStack {
        TargetProjectionCard(
            entries: [
                WeightEntry(date: Date().addingTimeInterval(-86400 * 21), weight: 145.0),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 7), weight: 140.0),
                WeightEntry(date: Date(), weight: 137.0)
            ],
            targetWeight: 90.0,
            initialWeight: 145.0,
            goalType: .lose
        )
    }
    .padding()
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    VStack {
        TargetProjectionCard(
            entries: [
                WeightEntry(date: Date().addingTimeInterval(-86400 * 21), weight: 145.0),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 7), weight: 140.0),
                WeightEntry(date: Date(), weight: 137.0)
            ],
            targetWeight: 90.0,
            initialWeight: 145.0,
            goalType: .lose
        )
    }
    .padding()
}
