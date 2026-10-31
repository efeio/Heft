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
    @State private var lastEvaluatedCount: Int = -1

    @AppStorage("heft_last_projected_timestamp") private var lastProjectedTimestamp: Double = 0.0

    private var effectiveInitialWeight: Double {
        initialWeight ?? entries.min(by: { $0.date < $1.date })?.weight ?? targetWeight
    }

    private func computeOutput() -> ProjectionOutput {
        ProjectionEngine.calculate(
            input: ProjectionInput(
                entries: entries,
                targetWeight: targetWeight,
                initialWeight: effectiveInitialWeight,
                goalType: goalType,
                onboardingWeeklyPace: targetWeeklyPace,
                referenceDate: Date()
            )
        )
    }

    private func weeksBadgeText(for output: ProjectionOutput) -> String {
        let weeks = output.primaryWeeksRemaining
        if weeks <= 0 {
            return "Tebrikler"
        }
        let rounded = Int(ceil(weeks))
        return "~\(rounded) Hafta"
    }

    private func informalPrimaryDateRangeString(for output: ProjectionOutput) -> String {
        if output.isMaintainGoal {
            let diff = abs(output.currentWeight - output.targetWeight)
            if diff <= 0.5 {
                return "Formunu Koruyorsun"
            }
            return "\(output.currentWeight > output.targetWeight ? "+" : "−")\(HeftFormat.weightKg(diff)) fark"
        }
        return output.primaryDateRangeString
    }

    private func informalGeneralMessage(for output: ProjectionOutput) -> String {
        switch output.condition {
        case .plateau(let days, let avgW):
            return "Kilon \(days) gündür \(HeftFormat.weight(avgW)) ± 0,4 kg bandında dengeleniyor. Bu normal bir adaptasyon evresidir; metabolizman alıştığında tempon yeniden hareketlenecektir."
        case .weightGainAnomaly(let days, let gainKg):
            return "Son \(days) günde +\(HeftFormat.weightKg(gainKg)) artış var — muhtemelen geçici su tutulumu. Genel temponla hedefin hâlâ koruma altında."
        case .goalReached:
            return "Harika bir disiplin gösterdin. Şimdi mevcut formunu koruma zamanı."
        case .maintainActive:
            let isWithinBand = abs(output.currentWeight - output.targetWeight) <= 0.5
            return isWithinBand
                ? "Tebrikler! Kilonu başarıyla dengede tutuyorsun. Düzenli tartılmaya devam et."
                : "Hedef kilonu dengede tutmak için beslenmene dikkat et ve tartımları aksatma."
        case .normal:
            if let catchUp = output.catchUpInfo {
                return "Hedef tarihine yetişmek için haftalık \(HeftFormat.weightKg(catchUp.requiredWeeklyPace)) tempoya ihtiyacın var. Mevcut temponla bitiş ileri bir tarihe sarkıyor."
            }
            if output.generalMessage.contains("hafta daha erken") || output.generalMessage.contains("gün daha erken") {
                return output.generalMessage
                    .replacingOccurrences(of: "temponuzla hedefinize", with: "temponla hedefine")
                    .replacingOccurrences(of: "ulaşacaksınız", with: "ulaşacaksın")
            }
            let actionWord = goalType == .gain ? "kilo alarak" : "kilo vererek"
            return "Mevcut temponla (haftada ortalama \(HeftFormat.weightKg(output.currentWeeklyPace)) \(actionWord)) bu aralıkta hedefine ulaşman öngörülüyor."
        }
    }

    var body: some View {
        let output = computeOutput()
        let primaryRangeText = informalPrimaryDateRangeString(for: output)
        let weeksBadge = weeksBadgeText(for: output)

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
                        paceIndicatorView(for: output)
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
                        paceIndicatorView(for: output)
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
                        Text(primaryRangeText)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.primary)
                            .fixedSize(horizontal: true, vertical: false)

                        Spacer()

                        badgeView(badge: weeksBadge, color: accent)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(primaryRangeText)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.primary)

                        badgeView(badge: weeksBadge, color: accent)
                    }
                }
            } else {
                Text(primaryRangeText)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.primary)
            }

            // MARK: - Milestone Progress Bar
            if !output.isGoalReached && !output.isMaintainGoal {
                milestoneProgressBar(for: output)
                    .padding(.vertical, 2)
            }

            // MARK: - Dynamic Context Insight (Single Smart Message)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: insightIcon(for: output))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(insightIconColor(for: output))
                    .padding(.top, 1)

                Text(informalGeneralMessage(for: output))
                    .font(.heftMeta)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                Spacer(minLength: 0)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(insightBackgroundColor(for: output))
            }
        }
        .heftCard()
        .onAppear {
            guard lastEvaluatedCount != entries.count else { return }
            lastEvaluatedCount = entries.count
            evaluateMicroFeedback(with: computeOutput())
        }
        .onChange(of: entries.count) { _, newCount in
            guard lastEvaluatedCount != newCount else { return }
            lastEvaluatedCount = newCount
            evaluateMicroFeedback(with: computeOutput())
        }
    }

    // MARK: - Pace Indicator
    @ViewBuilder
    private func paceIndicatorView(for output: ProjectionOutput) -> some View {
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
    private func milestoneProgressBar(for output: ProjectionOutput) -> some View {
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
    private func insightIcon(for output: ProjectionOutput) -> String {
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

    private func insightIconColor(for output: ProjectionOutput) -> Color {
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

    private func insightBackgroundColor(for output: ProjectionOutput) -> Color {
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
    private func evaluateMicroFeedback(with output: ProjectionOutput) {
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
