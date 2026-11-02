//
//  WeightChartView.swift
//  Heft
//
//  Weight history chart supporting multiple time ranges and trend tracking.
//

import SwiftUI
import Charts

struct WeightChartView: View {
    let entries: [WeightEntry]
    let targetWeight: Double
    var goalType: GoalType = .lose

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.heftAccent) private var accent
    @Environment(\.heftAccentFill) private var accentFill
    @ScaledMetric(relativeTo: .body) private var insightIconSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var singleChartHeight: CGFloat = 160
    @ScaledMetric(relativeTo: .body) private var fullChartHeight: CGFloat = 200

    @State private var selectedRange: ChartTimeRange = {
        #if DEBUG
        if let idx = CommandLine.arguments.firstIndex(of: "--chart-range"), idx + 1 < CommandLine.arguments.count {
            return ChartTimeRange(rawValue: CommandLine.arguments[idx + 1]) ?? .all
        }
        #endif
        return .all
    }()
    @State private var selectedEntry: WeightEntry?
    @State private var rawSelectedDate: Date?
    @State private var sortedEntries: [WeightEntry] = []
    @GestureState private var isScrubbing: Bool = false

    private var isGainGoal: Bool {
        goalType == .gain
    }

    private var isMaintainGoal: Bool {
        goalType == .maintain
    }

    private var allSortedEntries: [WeightEntry] {
        if sortedEntries.isEmpty && !entries.isEmpty {
            return entries.sorted { $0.date < $1.date }
        }
        return sortedEntries
    }

    private var referenceDate: Date {
        max(Date(), allSortedEntries.last?.date ?? Date())
    }

    private var activeEntries: [WeightEntry] {
        selectedRange.filter(entries: allSortedEntries, relativeTo: referenceDate)
    }

    private static var fullDateFormatter: DateFormatter {
        let df = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        df.locale = loc
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "d MMMM yyyy, EEEE", options: 0, locale: loc)
        return df
    }

    // MARK: - Selected Entry Delta
    private func computeActiveDeltaText(active: WeightEntry?, activeEntries: [WeightEntry], allSortedEntries: [WeightEntry]) -> (text: String, isSuccess: Bool)? {
        guard let active = active, let first = activeEntries.first ?? allSortedEntries.first else { return nil }
        guard (activeEntries.count >= 2 || allSortedEntries.count >= 2) else { return nil }

        let delta = active.weight - first.weight
        if active.id == first.id {
            return (String(localized: "Başlangıç", comment: "Starting weight badge"), false)
        }

        let isSuccess: Bool
        if isMaintainGoal {
            isSuccess = abs(delta) <= 0.5
        } else if isGainGoal {
            isSuccess = delta > 0
        } else {
            isSuccess = delta < 0
        }
        return (HeftFormat.signedWeightKg(delta), isSuccess)
    }

    // MARK: - Motivational Insight
    private struct MotivationInsight {
        let icon: String
        let color: Color
        let title: String
        let message: String
    }

    private func currentInsight(for allSortedEntries: [WeightEntry]) -> MotivationInsight {
        guard let current = allSortedEntries.last?.weight else {
            return MotivationInsight(
                icon: "chart.line.uptrend.xyaxis",
                color: accent,
                title: String(localized: "Yolculuk Başlıyor", comment: "Insight journey begins title"),
                message: String(localized: "Düzenli kilo kaydı yaparak eğilimini keşfetmeye başla.", comment: "Insight journey begins message")
            )
        }

        let allWeights = allSortedEntries.map(\.weight)
        let initialWeight = allSortedEntries.first?.weight ?? current

        if isMaintainGoal {
            let diff = abs(current - targetWeight)
            if diff <= 0.5 {
                return MotivationInsight(
                    icon: "checkmark.seal.fill",
                    color: .heftSuccess,
                    title: String(localized: "Formunu Koruyorsun", comment: "Insight maintain title"),
                    message: String(localized: "Hedef kilon olan \(HeftFormat.weightKg(targetWeight)) seviyesini başarıyla koruyorsun. İstikrarını sürdür.", comment: "Insight maintain success msg")
                )
            } else {
                let status = current > targetWeight ? "+\(HeftFormat.weightKg(diff)) " + String(localized: "fazla", comment: "above target") : "−\(HeftFormat.weightKg(diff)) " + String(localized: "eksik", comment: "below target")
                return MotivationInsight(
                    icon: "equal.circle.fill",
                    color: accent,
                    title: String(localized: "Kilo Koruma Takibi", comment: "Insight maintain tracking title"),
                    message: String(localized: "Hedef kilondan (\(status)) bir fark var. Dengeli beslenme ve düzenli tartımla hedefini koru.", comment: "Insight maintain tracking msg")
                )
            }
        } else if isGainGoal {
            let maxWeight = allWeights.max() ?? current
            let distanceToTarget = targetWeight - current

            if current >= targetWeight {
                return MotivationInsight(
                    icon: "trophy.fill",
                    color: .heftSuccess,
                    title: String(localized: "Hedefine Ulaştın", comment: "Insight goal reached title"),
                    message: String(localized: "\(HeftFormat.weightKg(targetWeight)) hedefine başarıyla ulaştın. Formunu korumak için aynı kararlılıkla devam et.", comment: "Insight goal reached gain msg")
                )
            }

            if current == maxWeight && allSortedEntries.count >= 2 && current > initialWeight {
                return MotivationInsight(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .heftSuccess,
                    title: String(localized: "En Yüksek Kilo Kaydı", comment: "Insight highest weight title"),
                    message: String(localized: "Heft'teki en yüksek kilona ulaştın. Hedefe yalnızca \(HeftFormat.weightKg(distanceToTarget)) kaldı.", comment: "Insight highest weight msg")
                )
            }

            if allSortedEntries.count >= 2 {
                let prev = allSortedEntries[allSortedEntries.count - 2].weight
                if current > prev {
                    let gained = current - prev
                    return MotivationInsight(
                        icon: "arrow.up.right.circle.fill",
                        color: .heftSuccess,
                        title: String(localized: "İlerleme Devam Ediyor", comment: "Insight progress continues title"),
                        message: String(localized: "Son tartıma göre +\(HeftFormat.weightKg(gained)) kaydettin. Hedefe \(HeftFormat.weightKg(distanceToTarget)) kaldı.", comment: "Insight gained progress msg")
                    )
                } else if current < prev {
                    return MotivationInsight(
                        icon: "flame.fill",
                        color: .heftWarning,
                        title: String(localized: "İstikrarını Koru", comment: "Insight stay consistent title"),
                        message: String(localized: "Hedefe \(HeftFormat.weightKg(distanceToTarget)) kaldı. Günlük kalori ve su dalgalanmaları doğaldır.", comment: "Insight fluctuations msg")
                    )
                }
            }

            return MotivationInsight(
                icon: "target",
                color: accent,
                title: String(localized: "Hedefe Doğru", comment: "Insight towards goal title"),
                message: String(localized: "Kilo alma hedefine ulaşmak için \(HeftFormat.weightKg(distanceToTarget)) mesafe var. Düzenli tartılarak ilerlemeni takip et.", comment: "Insight towards goal gain msg")
            )
        } else {
            let minWeight = allWeights.min() ?? current
            let distanceToTarget = current - targetWeight

            if current <= targetWeight {
                return MotivationInsight(
                    icon: "trophy.fill",
                    color: .heftSuccess,
                    title: String(localized: "Hedefine Ulaştın", comment: "Insight goal reached title"),
                    message: String(localized: "\(HeftFormat.weightKg(targetWeight)) hedefine ulaştın. Sağlıklı kilonu korumak için aynı kararlılıkla devam et.", comment: "Insight goal reached lose msg")
                )
            }

            if current == minWeight && allSortedEntries.count >= 2 && current < initialWeight {
                return MotivationInsight(
                    icon: "chart.line.downtrend.xyaxis",
                    color: .heftSuccess,
                    title: String(localized: "En Düşük Kilo Kaydı", comment: "Insight lowest weight title"),
                    message: String(localized: "Heft'teki en düşük kilonu kaydettin. Hedefine yalnızca \(HeftFormat.weightKg(distanceToTarget)) kaldı.", comment: "Insight lowest weight msg")
                )
            }

            if allSortedEntries.count >= 2 {
                let prev = allSortedEntries[allSortedEntries.count - 2].weight
                if current < prev {
                    let lost = prev - current
                    return MotivationInsight(
                        icon: "arrow.down.right.circle.fill",
                        color: .heftSuccess,
                        title: String(localized: "İlerleme Devam Ediyor", comment: "Insight progress continues title"),
                        message: String(localized: "Son tartıma göre \(HeftFormat.weightKg(lost)) kaydettin. Hedefe \(HeftFormat.weightKg(distanceToTarget)) kaldı.", comment: "Insight lost progress msg")
                    )
                } else if current > prev {
                    return MotivationInsight(
                        icon: "flame.fill",
                        color: .heftWarning,
                        title: String(localized: "İstikrarını Koru", comment: "Insight stay consistent title"),
                        message: String(localized: "Hedefine \(HeftFormat.weightKg(distanceToTarget)) kaldı. Günlük su ve tuz dalgalanmaları oldukça doğaldır.", comment: "Insight water retention msg")
                    )
                }
            }

            return MotivationInsight(
                icon: "target",
                color: accent,
                title: String(localized: "Hedefe Doğru", comment: "Insight towards goal title"),
                message: String(localized: "Hedefine ulaşmak için \(HeftFormat.weightKg(distanceToTarget)) mesafe var. Düzenli tartılarak ilerlemeni izle.", comment: "Insight towards goal lose msg")
            )
        }
    }

    @ViewBuilder
    private func headerBadges(active: WeightEntry?, activeEntries: [WeightEntry], allSortedEntries: [WeightEntry]) -> some View {
        HStack(spacing: 6) {
            if let delta = computeActiveDeltaText(active: active, activeEntries: activeEntries, allSortedEntries: allSortedEntries) {
                let isStart = delta.text == String(localized: "Başlangıç")
                let badgeColor = isStart ? Color.secondary : (delta.isSuccess ? Color.heftSuccess : Color.heftError)

                Text(delta.text)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        badgeColor.opacity(0.12),
                        in: Capsule()
                    )
            }

            if let selected = selectedEntry, selected.id != activeEntries.last?.id {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedEntry = activeEntries.last
                        rawSelectedDate = activeEntries.last?.date
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2.weight(.bold))
                        Text("Güncel")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.12), in: Capsule())
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Güncel ölçüme dön", comment: "Reset to latest entry a11y label"))
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func rangeButton(range: ChartTimeRange, fixedHorizontal: Bool, allDates: [Date]) -> some View {
        let isSelected = selectedRange == range
        let isAvailable = range.isAvailable(for: allDates)
        Button {
            guard isAvailable else { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.75)) {
                selectedRange = range
                selectedEntry = nil
                rawSelectedDate = nil
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(range.localizedLabel)
                .font(.caption.weight(isSelected ? .bold : .semibold))
                .foregroundStyle(isSelected ? Color.white : (isAvailable ? Color.secondary : Color.secondary.opacity(0.35)))
                .fixedSize(horizontal: fixedHorizontal, vertical: false)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 36)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(accentFill)
                    }
                }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(minHeight: 44)
        .disabled(!isAvailable)
        .accessibilityLabel(range.accessibilityTitle)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    var body: some View {
        let allSorted = allSortedEntries
        let allDates = allSorted.map(\.date)
        let refDate = max(Date(), allSorted.last?.date ?? Date())
        let currentActiveEntries = selectedRange.filter(entries: allSorted, relativeTo: refDate)
        let currentActiveEntry: WeightEntry? = {
            if let selected = selectedEntry, currentActiveEntries.contains(where: { $0.id == selected.id }) {
                return selected
            }
            return currentActiveEntries.last ?? allSorted.last
        }()
        let activeId = currentActiveEntry?.id
        let activeWeights = currentActiveEntries.map(\.weight)
        let allWeights = allSorted.map(\.weight)
        let currentYMin = (activeWeights.min() ?? allWeights.min() ?? 50.0) - 1.5
        let currentYMax = max(currentYMin + 2.0, (activeWeights.max() ?? allWeights.max() ?? 100.0) + 1.5)
        let currentXDomain = selectedRange.dateRange(relativeTo: refDate, allDates: allDates)
        let currentXAxisDates = selectedRange.xAxisDates(referenceDate: refDate, allDates: allDates)

        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Header (Apple Health Clean Stat)
            VStack(alignment: .leading, spacing: 4) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center) {
                        Text("KİLO DEĞİŞİMİ")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.secondary)
                            .tracking(0.6)
                            .fixedSize(horizontal: true, vertical: false)

                        Spacer()

                        headerBadges(active: currentActiveEntry, activeEntries: currentActiveEntries, allSortedEntries: allSorted)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("KİLO DEĞİŞİMİ")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.secondary)
                            .tracking(0.6)

                        headerBadges(active: currentActiveEntry, activeEntries: currentActiveEntries, allSortedEntries: allSorted)
                    }
                }

                if let active = currentActiveEntry {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(HeftFormat.weight(active.weight))
                                .font(.title.weight(.bold))
                                .foregroundStyle(Color.primary)

                            Text("kg")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                        }

                        Text(Self.fullDateFormatter.string(from: active.date))
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            // MARK: - Scalable Time Range Picker
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    ForEach(ChartTimeRange.allCases) { range in
                        rangeButton(range: range, fixedHorizontal: true, allDates: allDates)
                    }
                }
                .padding(4)
                .background {
                    Capsule()
                        .fill(Color.heftSurfaceSub)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 6)], spacing: 6) {
                    ForEach(ChartTimeRange.allCases) { range in
                        rangeButton(range: range, fixedHorizontal: false, allDates: allDates)
                    }
                }
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.heftSurfaceSub)
                }
            }

            // MARK: - Pure, Clean Chart Canvas (Proportional Height)
            if allSorted.count == 1 {
                // MARK: - First Measurement Milestone Card
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.12))
                            .frame(width: 52, height: 52)

                        Image(systemName: "flag.checkered")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(accent)
                    }

                    VStack(spacing: 4) {
                        Text("İlk Ölçümün Kaydedildi")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.primary)

                        Text("Kilo trendini ve değişim grafiğini görebilmek için en az 2 ölçüm gerekiyor. Bir sonraki tartında ilerlemen burada canlanacak.")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption.weight(.bold))
                        Text("Bir sonraki tartını eklediğinde grafik hazır")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accent.opacity(0.10), in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if currentActiveEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundStyle(Color.secondary)

                    if allSorted.isEmpty {
                        Text("Grafik için henüz kilo kaydı yok")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.secondary)
                    } else {
                        Text("Son \(selectedRange.localizedLabel) içinde ölçüm bulunamadı")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(2.0, contentMode: .fit)
                .frame(minHeight: 130, maxHeight: 220)
            } else {
                Chart {
                    // Target Weight RuleMark (Item 11)
                    if targetWeight >= currentYMin && targetWeight <= currentYMax {
                        RuleMark(y: .value("Hedef", targetWeight))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .foregroundStyle(Color.heftTeal)
                            .annotation(position: .trailing, alignment: .trailing) {
                                Text("Hedef")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.heftTeal)
                            }
                    }

                    // Vertical Guideline for Selected Point (only while actively touching/scrubbing)
                    if isScrubbing, let selected = selectedEntry ?? currentActiveEntry {
                        RuleMark(x: .value("Seçilen", selected.date))
                            .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.35))
                            .zIndex(5)
                    }

                    // AreaMark subtle gradient fill (when 2 or more entries)
                    if currentActiveEntries.count >= 2 {
                        ForEach(currentActiveEntries) { entry in
                            AreaMark(
                                x: .value("Tarih", entry.date),
                                yStart: .value("Taban", currentYMin),
                                yEnd: .value("Kilo", entry.weight)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [accent.opacity(0.18), accent.opacity(0.01)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }

                    // Line & Data Points (LineMark when 2 or more entries)
                    if currentActiveEntries.count >= 2 {
                        ForEach(currentActiveEntries) { entry in
                            LineMark(
                                x: .value("Tarih", entry.date),
                                y: .value("Kilo", entry.weight)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(accent)
                            .lineStyle(StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                        }
                    }

                    // PointMarks for each entry (1 or more)
                    ForEach(currentActiveEntries) { entry in
                        let isSelected = activeId == entry.id

                        PointMark(
                            x: .value("Tarih", entry.date),
                            y: .value("Kilo", entry.weight)
                        )
                        .accessibilityLabel(Self.fullDateFormatter.string(from: entry.date))
                        .accessibilityValue("\(HeftFormat.weight(entry.weight)) kilogram")
                        .symbol {
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(accent.opacity(0.20))
                                        .frame(width: 22, height: 22)

                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 2)
                                        .background(Circle().fill(accent))
                                        .frame(width: 12, height: 12)
                                        .shadow(color: accent.opacity(0.35), radius: 3, x: 0, y: 1)
                                } else {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 1.5)
                                        .background(Circle().fill(accent))
                                        .frame(width: 8, height: 8)
                                        .shadow(color: Color.black.opacity(0.10), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                    }
                }
                .chartXScale(domain: currentXDomain)
                .chartYScale(domain: currentYMin...max(currentYMin + 1.0, currentYMax))
                .chartPlotStyle { plotArea in
                    plotArea.clipped()
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.12))
                        if let weight = value.as(Double.self) {
                            AxisValueLabel(anchor: .leading) {
                                Text(HeftFormat.weight(weight))
                                    .font(.caption2)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: currentXAxisDates) { value in
                        if let date = value.as(Date.self) {
                            let isSelected = currentActiveEntry.map { Calendar.current.isDate(date, inSameDayAs: $0.date) } ?? false
                            AxisValueLabel(anchor: .top) {
                                Text(selectedRange.format(date: date, relativeTo: refDate))
                                    .font(.caption2.weight(isSelected ? .bold : .semibold))
                                    .foregroundStyle(isSelected ? accent : Color.secondary)
                            }
                        }
                    }
                }
                .chartGesture { proxy in
                    DragGesture(minimumDistance: 0)
                        .updating($isScrubbing) { _, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            if let date: Date = proxy.value(atX: value.location.x) {
                                selectClosest(to: date, playHaptic: true)
                            }
                        }
                }
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: selectedRange)
                .frame(minHeight: currentActiveEntries.count <= 1 ? singleChartHeight : fullChartHeight)
                .accessibilityLabel(String(localized: "Kilo grafiği, \(selectedRange.accessibilityTitle). \(currentActiveEntries.count) kayıt. En düşük \(HeftFormat.weightKg(activeWeights.min() ?? 0)), en yüksek \(HeftFormat.weightKg(activeWeights.max() ?? 0)).", comment: "Weight chart summary accessibility label"))

                if currentActiveEntries.count == 1 {
                    Text("Bu aralıkta tek ölçüm var. Tüm zamanlar için 'Tümü' seçebilirsin.")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                        .padding(.bottom, 6)
                }
            }

            // MARK: - Motivational Insight Banner
            if allSorted.count >= 2 {
                let insight = currentInsight(for: allSorted)
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(insight.color)
                        .frame(width: insightIconSize, height: insightIconSize)
                        .background(insight.color.opacity(0.14), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.primary)

                        Text(insight.message)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.heftSurfaceSub)
                )
                .accessibilityElement(children: .combine)
            }
        }
        .heftCard()
        .onAppear {
            if sortedEntries.count != entries.count || sortedEntries.last?.id != entries.first?.id {
                sortedEntries = entries.sorted { $0.date < $1.date }
            }
            if selectedEntry == nil {
                selectedEntry = activeEntries.last
            }
        }
        .onChange(of: entries) { _, newEntries in
            let sorted = newEntries.sorted { $0.date < $1.date }
            sortedEntries = sorted
            if selectedEntry == nil || !sorted.contains(where: { $0.id == selectedEntry?.id }) {
                selectedEntry = sorted.last
            }
        }
        .onChange(of: rawSelectedDate) { _, newDate in
            if let newDate {
                selectClosest(to: newDate, playHaptic: true)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: selectedEntry?.id)
    }

    // MARK: - Gesture Handling
    private func selectClosest(to date: Date, playHaptic: Bool) {
        guard !activeEntries.isEmpty else { return }
        let closest = activeEntries.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
        guard let closest else { return }

        if selectedEntry?.id != closest.id {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)) {
                selectedEntry = closest
                rawSelectedDate = closest.date
            }
            if playHaptic {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    let now = Date()
    let sample = [
        WeightEntry(date: now.addingTimeInterval(-86400 * 30), weight: 80.0),
        WeightEntry(date: now.addingTimeInterval(-86400 * 15), weight: 78.5),
        WeightEntry(date: now, weight: 77.2)
    ]
    WeightChartView(entries: sample, targetWeight: 72.0, goalType: .lose)
        .padding()
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    let now = Date()
    let sample = [
        WeightEntry(date: now.addingTimeInterval(-86400 * 30), weight: 80.0),
        WeightEntry(date: now.addingTimeInterval(-86400 * 15), weight: 78.5),
        WeightEntry(date: now, weight: 77.2)
    ]
    WeightChartView(entries: sample, targetWeight: 72.0, goalType: .lose)
        .padding()
}

#Preview("Tek Ölçüm (Milestone)", traits: .fixedLayout(width: 390, height: 400)) {
    WeightChartView(
        entries: [WeightEntry(date: Date(), weight: 59.7)],
        targetWeight: 53.7,
        goalType: .lose
    )
    .padding()
}
