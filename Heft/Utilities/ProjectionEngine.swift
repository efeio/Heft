//
//  ProjectionEngine.swift
//  Heft
//
//  Adaptive calculation engine for target weight projections, momentum analysis,
//  confidence intervals, and behavioral intelligence.
//

import Foundation

struct ProjectionInput {
    let entries: [WeightEntry]
    let targetWeight: Double
    let initialWeight: Double
    let goalType: GoalType
    let onboardingWeeklyPace: Double
    let referenceDate: Date

    init(
        entries: [WeightEntry],
        targetWeight: Double,
        initialWeight: Double,
        goalType: GoalType = .lose,
        onboardingWeeklyPace: Double = 0.5,
        referenceDate: Date = Date()
    ) {
        self.entries = entries
        self.targetWeight = targetWeight
        self.initialWeight = initialWeight
        self.goalType = goalType
        self.onboardingWeeklyPace = onboardingWeeklyPace
        self.referenceDate = referenceDate
    }
}

enum ProjectionScenario: String, CaseIterable, Identifiable {
    case adaptive = "adaptive"
    case shortTerm = "shortTerm"
    case longTerm = "longTerm"
    case planned = "planned"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .adaptive: return String(localized: "Adaptif", comment: "Projection scenario adaptive")
        case .shortTerm: return String(localized: "Son 14 Gün", comment: "Projection scenario last 14 days")
        case .longTerm: return String(localized: "Genel", comment: "Projection scenario overall")
        case .planned: return String(localized: "Hedef Plan", comment: "Projection scenario planned")
        }
    }

    var icon: String {
        switch self {
        case .adaptive: return "chart.xyaxis.line"
        case .shortTerm: return "bolt.fill"
        case .longTerm: return "scale.3d"
        case .planned: return "target"
        }
    }
}

struct ScenarioDetail: Identifiable, Equatable {
    var id: String { scenario.rawValue }
    let scenario: ProjectionScenario
    let icon: String
    let title: String
    let weeklyRate: Double
    let projectedDate: Date
    let dateRangeString: String
    let weeksRemaining: Double
}

enum PaceStatus: Equatable {
    case ideal
    case slow
    case tooFast
    case moderate
    case notApplicable

    var label: String {
        switch self {
        case .ideal: return String(localized: "İdeal", comment: "Pace status ideal")
        case .slow: return String(localized: "Yavaş", comment: "Pace status slow")
        case .tooFast: return String(localized: "Çok Hızlı", comment: "Pace status too fast")
        case .moderate: return String(localized: "Dengeli", comment: "Pace status moderate")
        case .notApplicable: return String(localized: "Sabit", comment: "Pace status stable")
        }
    }

    var iconName: String {
        switch self {
        case .ideal: return "checkmark.circle.fill"
        case .slow: return "exclamationmark.circle.fill"
        case .tooFast: return "flame.fill"
        case .moderate: return "arrow.right.circle.fill"
        case .notApplicable: return "equal.circle.fill"
        }
    }
}

enum BehavioralCondition: Equatable {
    case normal
    case plateau(days: Int, averageWeight: Double)
    case weightGainAnomaly(days: Int, gainKg: Double)
    case goalReached
    case maintainActive
}

struct MilestoneData: Equatable {
    let startWeight: Double
    let currentWeight: Double
    let intermediateMilestoneWeight: Double
    let targetWeight: Double
    let progressFraction: Double
}

struct CatchUpInfo: Equatable {
    let isBehind: Bool
    let originalTargetDate: Date
    let requiredWeeklyPace: Double
    let projectedDate: Date
    let message: String
}

struct ProjectionOutput: Equatable {
    let isGoalReached: Bool
    let isMaintainGoal: Bool
    let currentWeight: Double
    let targetWeight: Double
    let remainingKg: Double

    let primaryDateRangeString: String
    let primaryProjectedDate: Date
    let primaryWeeksRemaining: Double

    let confidenceScore: Int
    let confidenceIntervalDays: Int

    let currentWeeklyPace: Double
    let paceStatus: PaceStatus

    let adaptiveScenario: ScenarioDetail
    let shortTermScenario: ScenarioDetail
    let longTermScenario: ScenarioDetail
    let plannedScenario: ScenarioDetail

    let condition: BehavioralCondition
    let conditionMessage: String?

    let catchUpInfo: CatchUpInfo?
    let milestone: MilestoneData
    let generalMessage: String
}

enum ProjectionEngine {

    private static var dayMonthFormatter: DateFormatter {
        let df = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        df.locale = loc
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMMMM", options: 0, locale: loc)
        return df
    }

    private static var fullDateFormatter: DateFormatter {
        let df = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        df.locale = loc
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMMMyyyy", options: 0, locale: loc)
        return df
    }

    private static var monthYearFormatter: DateFormatter {
        let df = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        df.locale = loc
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMMyyyy", options: 0, locale: loc)
        return df
    }

    // MARK: - Main Calculation Function
    static func calculate(input: ProjectionInput) -> ProjectionOutput {
        let calendar = Calendar.current
        let refDate = input.referenceDate
        let sortedEntries = input.entries.sorted { $0.date < $1.date }

        // Deduplicate to 1 entry per day (latest entry per day)
        var dailyDict: [Date: WeightEntry] = [:]
        for entry in sortedEntries {
            let day = calendar.startOfDay(for: entry.date)
            dailyDict[day] = entry
        }
        let cleanDailyEntries = dailyDict.values.sorted { $0.date < $1.date }

        let currentWeight = cleanDailyEntries.last?.weight ?? input.initialWeight
        let targetWeight = input.targetWeight
        let initialWeight = input.initialWeight
        let isGain = input.goalType == .gain
        let isMaintain = input.goalType == .maintain

        // Check goal reached
        let isGoalReached: Bool
        if isGain {
            isGoalReached = currentWeight >= (targetWeight - 0.05)
        } else if isMaintain {
            isGoalReached = abs(currentWeight - targetWeight) <= 0.5
        } else {
            isGoalReached = currentWeight <= (targetWeight + 0.05)
        }

        let remainingKg = isGain ? max(0, targetWeight - currentWeight) : (isMaintain ? abs(currentWeight - targetWeight) : max(0, currentWeight - targetWeight))

        // Milestone data
        let totalDistance = abs(initialWeight - targetWeight)
        let coveredDistance = isGain ? (currentWeight - initialWeight) : (initialWeight - currentWeight)
        let progressFraction = totalDistance > 0.1 ? min(1.0, max(0.0, coveredDistance / totalDistance)) : 1.0
        let intermediateWeight: Double
        if isGain {
            intermediateWeight = currentWeight + (remainingKg * 0.5)
        } else {
            intermediateWeight = currentWeight - (remainingKg * 0.5)
        }
        let milestone = MilestoneData(
            startWeight: initialWeight,
            currentWeight: currentWeight,
            intermediateMilestoneWeight: intermediateWeight,
            targetWeight: targetWeight,
            progressFraction: progressFraction
        )

        // Confidence Score: min(90, entryCount * 6)
        let count = cleanDailyEntries.count
        let confidenceScore = min(90, max(10, count * 6))

        // Confidence Interval margin in days (inversely proportional to entry count)
        let intervalMarginDays = max(3, min(21, Int(round(24.0 / sqrt(Double(max(1, count)))))))

        // Handle Maintain Goal
        if isMaintain {
            return maintainOutput(
                currentWeight: currentWeight,
                targetWeight: targetWeight,
                initialWeight: initialWeight,
                isGoalReached: isGoalReached,
                confidenceScore: confidenceScore,
                refDate: refDate,
                milestone: milestone
            )
        }

        // Handle Goal Reached
        if isGoalReached {
            return goalReachedOutput(
                currentWeight: currentWeight,
                targetWeight: targetWeight,
                confidenceScore: confidenceScore,
                refDate: refDate,
                milestone: milestone
            )
        }

        // 1. Linear Regression + Outlier Rejection
        let allTimeRate = calculateLinearRegressionRate(entries: cleanDailyEntries, refDate: refDate)

        // 2. Dual-Window Momentum
        let shortTermWindowEntries = cleanDailyEntries.filter {
            refDate.timeIntervalSince($0.date) <= 14 * 86400
        }
        let shortTermRateRaw = calculateWindowRate(entries: shortTermWindowEntries, refDate: refDate)

        // 3. Cold Start (Bayesian Prior)
        let onboardingPace = max(0.15, input.onboardingWeeklyPace)
        let (effectiveShortRate, effectiveLongRate) = applyBayesianPrior(
            shortTermRateRaw: shortTermRateRaw,
            allTimeRateRaw: allTimeRate,
            entryCount: count,
            firstDate: cleanDailyEntries.first?.date ?? refDate,
            refDate: refDate,
            onboardingPace: onboardingPace,
            isGain: isGain
        )

        // 4. EMA Speed: 65% short term + 35% long term
        let emaRate = max(0.1, (0.65 * effectiveShortRate) + (0.35 * effectiveLongRate))

        // 5. Metabolic Slowdown Curve
        let adaptiveWeeks = calculateWeeksWithMetabolicSlowdown(remainingKg: remainingKg, baseWeeklyRate: emaRate)
        let shortWeeks = calculateWeeksWithMetabolicSlowdown(remainingKg: remainingKg, baseWeeklyRate: max(0.1, effectiveShortRate))
        let longWeeks = calculateWeeksWithMetabolicSlowdown(remainingKg: remainingKg, baseWeeklyRate: max(0.1, effectiveLongRate))
        let plannedWeeks = calculateWeeksWithMetabolicSlowdown(remainingKg: remainingKg, baseWeeklyRate: onboardingPace)

        // Generate Dates & Ranges
        let adaptiveDate = calendar.date(byAdding: .day, value: Int(round(adaptiveWeeks * 7)), to: refDate) ?? refDate
        let shortDate = calendar.date(byAdding: .day, value: Int(round(shortWeeks * 7)), to: refDate) ?? refDate
        let longDate = calendar.date(byAdding: .day, value: Int(round(longWeeks * 7)), to: refDate) ?? refDate
        let plannedDate = calendar.date(byAdding: .day, value: Int(round(plannedWeeks * 7)), to: refDate) ?? refDate

        let adaptiveRange = formatDateRange(centerDate: adaptiveDate, marginDays: intervalMarginDays)
        let shortRange = formatDateRange(centerDate: shortDate, marginDays: intervalMarginDays)
        let longRange = formatDateRange(centerDate: longDate, marginDays: intervalMarginDays)
        let plannedRange = formatDateRange(centerDate: plannedDate, marginDays: intervalMarginDays)

        // Scenarios
        let adaptiveScenario = ScenarioDetail(
            scenario: .adaptive,
            icon: "chart.xyaxis.line",
            title: "Adaptif",
            weeklyRate: emaRate,
            projectedDate: adaptiveDate,
            dateRangeString: adaptiveRange,
            weeksRemaining: adaptiveWeeks
        )

        let shortTermScenario = ScenarioDetail(
            scenario: .shortTerm,
            icon: "bolt.fill",
            title: "Son 14 Gün",
            weeklyRate: effectiveShortRate,
            projectedDate: shortDate,
            dateRangeString: shortRange,
            weeksRemaining: shortWeeks
        )

        let longTermScenario = ScenarioDetail(
            scenario: .longTerm,
            icon: "scale.3d",
            title: "Genel Ortalama",
            weeklyRate: effectiveLongRate,
            projectedDate: longDate,
            dateRangeString: longRange,
            weeksRemaining: longWeeks
        )

        let plannedScenario = ScenarioDetail(
            scenario: .planned,
            icon: "target",
            title: "Hedef Plan",
            weeklyRate: onboardingPace,
            projectedDate: plannedDate,
            dateRangeString: plannedRange,
            weeksRemaining: plannedWeeks
        )

        // Pace Status
        let paceRatio = emaRate / onboardingPace
        let paceStatus: PaceStatus
        if paceRatio >= 0.8 && paceRatio <= 1.2 {
            paceStatus = .ideal
        } else if paceRatio < 0.5 {
            paceStatus = .slow
        } else if paceRatio > 2.0 {
            paceStatus = .tooFast
        } else {
            paceStatus = .moderate
        }

        // 6. Behavioral Intelligence (Plateau & Weight Gain Handling)
        var condition: BehavioralCondition = .normal
        var conditionMessage: String? = nil

        // Check Plateau (Variance in last 16+ days < 0.5 kg with >= 3 entries)
        let plateauWindowEntries = cleanDailyEntries.filter {
            refDate.timeIntervalSince($0.date) <= 21 * 86400
        }
        if plateauWindowEntries.count >= 3,
           let oldestInPlateau = plateauWindowEntries.first,
           refDate.timeIntervalSince(oldestInPlateau.date) >= 14 * 86400 {
            let weights = plateauWindowEntries.map(\.weight)
            let minW = weights.min() ?? currentWeight
            let maxW = weights.max() ?? currentWeight
            if (maxW - minW) <= 0.55 {
                let plateauDays = max(14, Int(refDate.timeIntervalSince(oldestInPlateau.date) / 86400))
                let avgW = weights.reduce(0, +) / Double(weights.count)
                condition = .plateau(days: plateauDays, averageWeight: avgW)
                conditionMessage = "Kilonuz \(plateauDays) gündür \(String(format: "%.1f", avgW)) ± 0.4 kg bandında dengeleniyor. Bu normal bir adaptasyon evresidir; metabolizma alıştığında temponuz yeniden hareketlenecektir."
            }
        }

        // Check Weight Gain Anomaly (if not plateau, check recent gain during lose goal)
        if condition == .normal && !isGain {
            let recentWindow = cleanDailyEntries.filter {
                refDate.timeIntervalSince($0.date) <= 6 * 86400
            }
            if recentWindow.count >= 2,
               let minRecent = recentWindow.map(\.weight).min(),
               currentWeight - minRecent >= 0.4 {
                let gain = currentWeight - minRecent
                let days = max(2, Int(refDate.timeIntervalSince(recentWindow.first?.date ?? refDate) / 86400))
                condition = .weightGainAnomaly(days: days, gainKg: gain)
                let dateStr = Self.monthYearFormatter.string(from: longDate)
                conditionMessage = "Son \(days) günde +\(String(format: "%.1f", gain)) kg artış var — muhtemelen geçici su tutulumu. Genel temponuzla hedefiniz hâlâ \(dateStr) civarında."
            }
        }

        // 7. Catch-up Calculator
        var catchUpInfo: CatchUpInfo? = nil
        let originalTotalWeeks = calculateWeeksWithMetabolicSlowdown(remainingKg: totalDistance, baseWeeklyRate: onboardingPace)
        let startDate = cleanDailyEntries.first?.date ?? refDate
        let originalTargetDate = calendar.date(byAdding: .day, value: Int(round(originalTotalWeeks * 7)), to: startDate) ?? refDate

        let daysRemainingToPlan = calendar.dateComponents([.day], from: refDate, to: originalTargetDate).day ?? 0
        let daysDiffFromPlan = calendar.dateComponents([.day], from: adaptiveDate, to: originalTargetDate).day ?? 0

        if adaptiveDate > originalTargetDate && daysRemainingToPlan >= 7 {
            let requiredRate = remainingKg / (Double(daysRemainingToPlan) / 7.0)
            let formattedDate = Self.fullDateFormatter.string(from: adaptiveDate)
            let msg = "Hedef tarihinize (\(Self.dayMonthFormatter.string(from: originalTargetDate))) yetişmek için haftalık \(String(format: "%.1f", requiredRate)) kg tempoya ihtiyacınız var. Mevcut temponuzla bitiş \(formattedDate) tarihine sarkıyor."
            catchUpInfo = CatchUpInfo(
                isBehind: true,
                originalTargetDate: originalTargetDate,
                requiredWeeklyPace: requiredRate,
                projectedDate: adaptiveDate,
                message: msg
            )
        }

        // Smart Adaptive Insight Message
        let generalMsg: String
        if let cond = conditionMessage {
            generalMsg = cond
        } else if let catchUp = catchUpInfo {
            generalMsg = catchUp.message
        } else if daysDiffFromPlan >= 7 {
            let weeksAhead = max(1, Int(round(Double(daysDiffFromPlan) / 7.0)))
            generalMsg = "Mevcut temponuzla hedefinize planlanandan \(weeksAhead) hafta daha erken ulaşacaksınız."
        } else if daysDiffFromPlan >= 3 {
            generalMsg = "Mevcut temponuzla hedefinize planlanandan \(daysDiffFromPlan) gün daha erken ulaşacaksınız."
        } else {
            let actionWord = isGain ? "kilo alarak" : "kilo vererek"
            let rateStr = String(format: "%.1f", emaRate)
            generalMsg = "Mevcut temponuzla (haftada ortalama \(rateStr) kg \(actionWord)) bu aralıkta hedefinize ulaşmanız öngörülüyor."
        }

        return ProjectionOutput(
            isGoalReached: false,
            isMaintainGoal: false,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            remainingKg: remainingKg,
            primaryDateRangeString: adaptiveRange,
            primaryProjectedDate: adaptiveDate,
            primaryWeeksRemaining: adaptiveWeeks,
            confidenceScore: confidenceScore,
            confidenceIntervalDays: intervalMarginDays,
            currentWeeklyPace: emaRate,
            paceStatus: paceStatus,
            adaptiveScenario: adaptiveScenario,
            shortTermScenario: shortTermScenario,
            longTermScenario: longTermScenario,
            plannedScenario: plannedScenario,
            condition: condition,
            conditionMessage: conditionMessage,
            catchUpInfo: catchUpInfo,
            milestone: milestone,
            generalMessage: generalMsg
        )
    }

    // MARK: - Helper: Linear Regression with Outlier Rejection
    private static func calculateLinearRegressionRate(entries: [WeightEntry], refDate: Date) -> Double? {
        guard entries.count >= 2, let first = entries.first else { return nil }

        // Map to (x in days, y in kg)
        let points: [(x: Double, y: Double)] = entries.map {
            let days = $0.date.timeIntervalSince(first.date) / 86400.0
            return (x: days, y: $0.weight)
        }

        guard let initialFit = linearRegression(points: points) else { return nil }

        // Filter outliers (|residual| > 1.5 kg)
        let inliers = points.filter { point in
            let predicted = initialFit.slope * point.x + initialFit.intercept
            return abs(point.y - predicted) <= 1.5
        }

        let finalFit = (inliers.count >= 2 ? linearRegression(points: inliers) : nil) ?? initialFit
        // Slope is kg / day -> multiply by 7 for weekly rate
        let weeklySlope = finalFit.slope * 7.0
        return abs(weeklySlope)
    }

    private static func linearRegression(points: [(x: Double, y: Double)]) -> (slope: Double, intercept: Double)? {
        guard points.count >= 2 else { return nil }
        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + ($1.x * $1.y) }
        let sumXX = points.reduce(0) { $0 + ($1.x * $1.x) }

        let denominator = (n * sumXX) - (sumX * sumX)
        guard abs(denominator) > 0.0001 else { return nil }

        let slope = ((n * sumXY) - (sumX * sumY)) / denominator
        let intercept = (sumY - (slope * sumX)) / n
        return (slope, intercept)
    }

    // MARK: - Helper: Short Term Window Rate
    private static func calculateWindowRate(entries: [WeightEntry], refDate: Date) -> Double? {
        guard entries.count >= 2,
              let first = entries.first,
              let last = entries.last else { return nil }

        let elapsedDays = last.date.timeIntervalSince(first.date) / 86400.0
        guard elapsedDays >= 2.0 else { return nil }

        // Use linear regression if 3+ points, otherwise delta / weeks
        if entries.count >= 3, let fit = linearRegressionRateFromRaw(entries: entries) {
            return fit
        }
        let delta = abs(last.weight - first.weight)
        let weeks = elapsedDays / 7.0
        return delta / weeks
    }

    private static func linearRegressionRateFromRaw(entries: [WeightEntry]) -> Double? {
        guard let first = entries.first else { return nil }
        let pts = entries.map { (x: $0.date.timeIntervalSince(first.date) / 86400.0, y: $0.weight) }
        guard let fit = linearRegression(points: pts) else { return nil }
        return abs(fit.slope * 7.0)
    }

    // MARK: - Helper: Cold Start / Bayesian Prior
    private static func applyBayesianPrior(
        shortTermRateRaw: Double?,
        allTimeRateRaw: Double?,
        entryCount: Int,
        firstDate: Date,
        refDate: Date,
        onboardingPace: Double,
        isGain: Bool
    ) -> (shortRate: Double, longRate: Double) {
        let elapsedDays = max(0, Int(refDate.timeIntervalSince(firstDate) / 86400.0))

        if entryCount < 2 || elapsedDays < 2 {
            // Day 1: 100% prior
            return (onboardingPace, onboardingPace)
        }

        // Weight given to real data: 0.0 at day 1 up to 1.0 at day 7+
        let dataWeight = min(1.0, max(0.15, Double(elapsedDays) / 7.0))
        let priorWeight = 1.0 - dataWeight

        let rawShort = shortTermRateRaw ?? allTimeRateRaw ?? onboardingPace
        let rawLong = allTimeRateRaw ?? onboardingPace

        // Clamp individual data rates between reasonable bounds (0.05 to 2.5 kg/week)
        let clampedShort = min(2.5, max(0.05, rawShort))
        let clampedLong = min(2.5, max(0.05, rawLong))

        let blendedShort = (clampedShort * dataWeight) + (onboardingPace * priorWeight)
        let blendedLong = (clampedLong * dataWeight) + (onboardingPace * priorWeight)

        return (blendedShort, blendedLong)
    }

    // MARK: - Helper: Metabolic Slowdown Curve (Piecewise Integration)
    static func calculateWeeksWithMetabolicSlowdown(remainingKg: Double, baseWeeklyRate: Double) -> Double {
        guard baseWeeklyRate > 0.02, remainingKg > 0 else { return 1.0 }

        var weeks: Double = 0.0
        var remaining = remainingKg

        // Tier 1: > 15 kg remaining (1.0x multiplier)
        if remaining > 15.0 {
            let chunk = remaining - 15.0
            weeks += chunk / (baseWeeklyRate * 1.0)
            remaining = 15.0
        }

        // Tier 2: 8 to 15 kg remaining (0.85x multiplier)
        if remaining > 8.0 {
            let chunk = remaining - 8.0
            weeks += chunk / (baseWeeklyRate * 0.85)
            remaining = 8.0
        }

        // Tier 3: < 8 kg remaining (0.70x multiplier)
        if remaining > 0.0 {
            weeks += remaining / (baseWeeklyRate * 0.70)
        }

        return max(0.5, weeks)
    }

    // MARK: - Helper: Date Range Formatting
    static func formatDateRange(centerDate: Date, marginDays: Int) -> String {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -marginDays, to: centerDate) ?? centerDate
        let endDate = calendar.date(byAdding: .day, value: marginDays, to: centerDate) ?? centerDate

        let startMonth = calendar.component(.month, from: startDate)
        let endMonth = calendar.component(.month, from: endDate)
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)

        if startYear == endYear {
            if startMonth == endMonth {
                let startDay = calendar.component(.day, from: startDate)
                let endDayStr = Self.fullDateFormatter.string(from: endDate)
                return "\(startDay) — \(endDayStr)"
            } else {
                let startStr = Self.dayMonthFormatter.string(from: startDate)
                let endStr = Self.fullDateFormatter.string(from: endDate)
                return "\(startStr) — \(endStr)"
            }
        } else {
            let startStr = Self.fullDateFormatter.string(from: startDate)
            let endStr = Self.fullDateFormatter.string(from: endDate)
            return "\(startStr) — \(endStr)"
        }
    }

    // MARK: - Helper: Goal Reached & Maintain Presets
    private static func goalReachedOutput(
        currentWeight: Double,
        targetWeight: Double,
        confidenceScore: Int,
        refDate: Date,
        milestone: MilestoneData
    ) -> ProjectionOutput {
        let reachedText = String(localized: "Hedefe Ulaşıldı", comment: "Goal reached title")
        let dummyScenario = ScenarioDetail(
            scenario: .adaptive,
            icon: "checkmark.seal.fill",
            title: reachedText,
            weeklyRate: 0.0,
            projectedDate: refDate,
            dateRangeString: Self.fullDateFormatter.string(from: refDate),
            weeksRemaining: 0.0
        )

        return ProjectionOutput(
            isGoalReached: true,
            isMaintainGoal: false,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            remainingKg: 0.0,
            primaryDateRangeString: reachedText,
            primaryProjectedDate: refDate,
            primaryWeeksRemaining: 0.0,
            confidenceScore: confidenceScore,
            confidenceIntervalDays: 0,
            currentWeeklyPace: 0.0,
            paceStatus: .notApplicable,
            adaptiveScenario: dummyScenario,
            shortTermScenario: dummyScenario,
            longTermScenario: dummyScenario,
            plannedScenario: dummyScenario,
            condition: .goalReached,
            conditionMessage: String(localized: "Tebrikler! Belirlediğin hedef kiloya başarıyla ulaştın.", comment: "Goal reached condition message"),
            catchUpInfo: nil,
            milestone: milestone,
            generalMessage: String(localized: "Harika bir disiplin gösterdin. Şimdi mevcut formunu koruma zamanı.", comment: "Goal reached general message")
        )
    }

    private static func maintainOutput(
        currentWeight: Double,
        targetWeight: Double,
        initialWeight: Double,
        isGoalReached: Bool,
        confidenceScore: Int,
        refDate: Date,
        milestone: MilestoneData
    ) -> ProjectionOutput {
        let diff = abs(currentWeight - targetWeight)
        let badge = isGoalReached
            ? String(localized: "Formunu Koruyorsun", comment: "Maintain form badge")
            : "\(currentWeight > targetWeight ? "+" : "−")\(HeftFormat.weightKg(diff)) " + String(localized: "fark", comment: "weight difference suffix")

        let dummyScenario = ScenarioDetail(
            scenario: .adaptive,
            icon: "equal.circle.fill",
            title: String(localized: "Kilo Koruma", comment: "Maintain weight title"),
            weeklyRate: 0.0,
            projectedDate: refDate,
            dateRangeString: badge,
            weeksRemaining: 0.0
        )

        let msg = isGoalReached
            ? String(localized: "Tebrikler! Kilonu başarıyla dengede tutuyorsun. Düzenli tartılmaya devam et.", comment: "Maintain balanced msg")
            : String(localized: "Hedef kilonu dengede tutmak için beslenmene dikkat et ve tartımları aksatma.", comment: "Maintain attention msg")

        return ProjectionOutput(
            isGoalReached: false,
            isMaintainGoal: true,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            remainingKg: diff,
            primaryDateRangeString: badge,
            primaryProjectedDate: refDate,
            primaryWeeksRemaining: 0.0,
            confidenceScore: confidenceScore,
            confidenceIntervalDays: 0,
            currentWeeklyPace: 0.0,
            paceStatus: .notApplicable,
            adaptiveScenario: dummyScenario,
            shortTermScenario: dummyScenario,
            longTermScenario: dummyScenario,
            plannedScenario: dummyScenario,
            condition: .maintainActive,
            conditionMessage: nil,
            catchUpInfo: nil,
            milestone: milestone,
            generalMessage: msg
        )
    }
}
