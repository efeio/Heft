//
//  BMIChartView.swift
//  Heft
//
//  Apple Health style BMI chart with scalable time range filters (1A, 3A, 6A, 1Y, Tümü).
//

import SwiftUI
import Charts
import UIKit

struct BMIChartView: View {
    let entries: [WeightEntry]
    let height: Double
    var targetWeight: Double? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.heftAccent) private var accent
    @Environment(\.heftAccentFill) private var accentFill
    @ScaledMetric(relativeTo: .body) private var insightIconSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var singleChartHeight: CGFloat = 160
    @ScaledMetric(relativeTo: .body) private var fullChartHeight: CGFloat = 200

    @State private var selectedRange: ChartTimeRange = {
        #if DEBUG
        if let idx = CommandLine.arguments.firstIndex(of: "--chart-range"), idx + 1 < CommandLine.arguments.count {
            return ChartTimeRange(rawValue: CommandLine.arguments[idx + 1]) ?? .oneMonth
        }
        #endif
        return .oneMonth
    }()
    @State private var selectedPoint: BMIPoint?
    @State private var rawSelectedDate: Date?
    @State private var cachedBmiPoints: [BMIPoint] = []
    @GestureState private var isScrubbing: Bool = false

    private struct BMIPoint: Identifiable {
        var id: Date { date }
        let date: Date
        let bmi: Double
        let weight: Double
    }

    private static func computeBmiPoints(entries: [WeightEntry], height: Double) -> [BMIPoint] {
        entries
            .sorted { $0.date < $1.date }
            .compactMap { entry in
                guard let val = BMICalculator.calculate(weightKg: entry.weight, heightCm: height) else { return nil }
                return BMIPoint(date: entry.date, bmi: val, weight: entry.weight)
            }
    }

    private var allBmiPoints: [BMIPoint] {
        if cachedBmiPoints.isEmpty && !entries.isEmpty {
            return Self.computeBmiPoints(entries: entries, height: height)
        }
        return cachedBmiPoints
    }

    private var activeBmiPoints: [BMIPoint] {
        let allPoints = allBmiPoints
        guard let days = selectedRange.days else {
            return allPoints
        }
        let ref = max(Date(), allPoints.last?.date ?? Date())
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: ref) ?? ref.addingTimeInterval(-Double(days) * 86400)
        return allPoints.filter { $0.date >= cutoff }
    }

    private static let fullDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateFormat = "d MMMM yyyy, EEEE"
        return df
    }()

    // MARK: - BMI Health Insight
    private struct BMIInsight {
        let icon: String
        let color: Color
        let title: String
        let message: String
    }

    private var healthInsight: BMIInsight {
        let heightM = height / 100.0
        let normalMinWeight = 18.5 * (heightM * heightM)
        let normalMaxWeight = 24.9 * (heightM * heightM)

        if let target = targetWeight, let targetBMI = BMICalculator.calculate(weightKg: target, heightCm: height) {
            let targetCategory = BMICalculator.category(for: targetBMI)
            return BMIInsight(
                icon: "heart.text.square.fill",
                color: BMICalculator.color(for: targetBMI),
                title: "Hedef BMI: \(HeftFormat.weight(targetBMI))",
                message: "\(HeftFormat.integer(target)) kg hedefine ulaştığında BMI değerin \(HeftFormat.weight(targetBMI)) (\(targetCategory)) olacak. Boyun için sağlıklı kilo aralığı \(HeftFormat.integer(normalMinWeight)) - \(HeftFormat.integer(normalMaxWeight)) kg'dır."
            )
        }

        return BMIInsight(
            icon: "figure.walk",
            color: accent,
            title: "Sağlıklı Kilo Aralığı",
            message: "\(HeftFormat.integer(height)) cm boy için normal BMI (18,5 - 24,9) aralığı \(HeftFormat.integer(normalMinWeight)) - \(HeftFormat.integer(normalMaxWeight)) kg arasındadır."
        )
    }

    @ViewBuilder
    private func bmiHeaderBadges(active: BMIPoint?, activePoints: [BMIPoint]) -> some View {
        HStack(spacing: 6) {
            if let active = active {
                let cat = BMICalculator.category(for: active.bmi)
                let catColor = BMICalculator.color(for: active.bmi)

                Text(cat)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(catColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(catColor.opacity(0.14), in: Capsule())
            }

            if let selected = selectedPoint, selected.id != activePoints.last?.id {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedPoint = activePoints.last
                        rawSelectedDate = activePoints.last?.date
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
                .accessibilityLabel("Güncel ölçüme dön")
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func bmiRangeButton(range: ChartTimeRange, fixedHorizontal: Bool, allDates: [Date]) -> some View {
        let isSelected = selectedRange == range
        let isAvailable = range.isAvailable(for: allDates)
        Button {
            guard isAvailable else { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.75)) {
                selectedRange = range
                selectedPoint = nil
                rawSelectedDate = nil
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(range.rawValue)
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
        let allPoints = allBmiPoints
        let allDates = allPoints.map(\.date)
        let refDate = max(Date(), allPoints.last?.date ?? Date())
        let currentActivePoints: [BMIPoint] = {
            guard let days = selectedRange.days else { return allPoints }
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: refDate) ?? refDate.addingTimeInterval(-Double(days) * 86400)
            return allPoints.filter { $0.date >= cutoff }
        }()
        let currentActivePoint: BMIPoint? = {
            if let selected = selectedPoint, currentActivePoints.contains(where: { $0.id == selected.id }) {
                return selected
            }
            return currentActivePoints.last ?? allPoints.last
        }()
        let activeId = currentActivePoint?.id
        let activeBmis = currentActivePoints.map(\.bmi)
        let allBmis = allPoints.map(\.bmi)
        let currentYMin = max(10.0, (activeBmis.min() ?? allBmis.min() ?? 20.0) - 1.5)
        let currentYMax = max(currentYMin + 2.0, min(45.0, (activeBmis.max() ?? allBmis.max() ?? 25.0) + 1.5))
        let currentXDomain = selectedRange.dateRange(relativeTo: refDate, allDates: allDates)
        let currentXAxisDates = selectedRange.xAxisDates(referenceDate: refDate, allDates: allDates)

        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Header (Apple Health Clean Stat)
            VStack(alignment: .leading, spacing: 4) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center) {
                        Text("VÜCUT KİTLE İNDEKSİ")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.secondary)
                            .tracking(0.6)
                            .fixedSize(horizontal: true, vertical: false)

                        Spacer()

                        bmiHeaderBadges(active: currentActivePoint, activePoints: currentActivePoints)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("VÜCUT KİTLE İNDEKSİ")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.secondary)
                            .tracking(0.6)

                        bmiHeaderBadges(active: currentActivePoint, activePoints: currentActivePoints)
                    }
                }

                if let active = currentActivePoint {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(HeftFormat.weight(active.bmi))
                                .font(.title.weight(.bold))
                                .foregroundStyle(Color.primary)

                            Text("BMI")
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
                        bmiRangeButton(range: range, fixedHorizontal: true, allDates: allDates)
                    }
                }
                .padding(4)
                .background {
                    Capsule()
                        .fill(Color.heftSurfaceSub)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 6)], spacing: 6) {
                    ForEach(ChartTimeRange.allCases) { range in
                        bmiRangeButton(range: range, fixedHorizontal: false, allDates: allDates)
                    }
                }
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.heftSurfaceSub)
                }
            }

            // MARK: - Pure, Clean Chart Canvas (Proportional Height)
            if allPoints.count == 1, let single = allPoints.first {
                // MARK: - First Measurement Milestone Card (BMI)
                let cat = BMICalculator.category(for: single.bmi)
                let catColor = BMICalculator.color(for: single.bmi)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(catColor.opacity(0.12))
                            .frame(width: 52, height: 52)

                        Image(systemName: "heart.text.square.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(catColor)
                    }

                    VStack(spacing: 4) {
                        Text("Mevcut BMI: \(HeftFormat.weight(single.bmi)) (\(cat))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.primary)

                        Text("Vücut kitle indeksi trendin ve değişim grafiğin ikinci kilo ölçümünü kaydettiğinde burada şekillenecek.")
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
                    .foregroundStyle(catColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(catColor.opacity(0.10), in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if currentActivePoints.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.title)
                        .foregroundStyle(Color.secondary)

                    Text(allPoints.isEmpty ? "Grafik için henüz kilo kaydı yok" : "Son \(selectedRange.rawValue) içinde ölçüm bulunamadı")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(2.0, contentMode: .fit)
                .frame(minHeight: 130, maxHeight: 220)
            } else {
                Chart {
                    // Vertical Guideline on Selected Point (only while actively touching/scrubbing)
                    if isScrubbing, let active = selectedPoint ?? currentActivePoint {
                        RuleMark(x: .value("Seçilen Tarih", active.date))
                            .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.35))
                            .zIndex(5)
                    }

                    // Subtle Reference Line for Normal BMI Threshold (25.0) if in range
                    if currentYMin <= 25.0 && currentYMax >= 24.5 {
                        RuleMark(y: .value("Normal Sınır", 25.0))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Color.heftBMINormal.opacity(0.55))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Normal Sınırı (\(HeftFormat.weight(25.0)))")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Color.heftBMINormal)
                            }
                    }

                    // AreaMark subtle gradient fill (when 2 or more entries)
                    if currentActivePoints.count >= 2 {
                        ForEach(currentActivePoints) { point in
                            AreaMark(
                                x: .value("Tarih", point.date),
                                yStart: .value("Taban", currentYMin),
                                yEnd: .value("BMI", point.bmi)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [accent.opacity(0.16), accent.opacity(0.01)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }

                    // Line & Data Points (LineMark when 2 or more entries)
                    if currentActivePoints.count >= 2 {
                        ForEach(currentActivePoints) { point in
                            LineMark(
                                x: .value("Tarih", point.date),
                                y: .value("BMI", point.bmi)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(accent)
                            .lineStyle(StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                        }
                    }

                    // PointMarks for each entry (1 or more)
                    ForEach(currentActivePoints) { point in
                        let isSelected = activeId == point.id
                        let pointColor = BMICalculator.color(for: point.bmi)

                        PointMark(
                            x: .value("Tarih", point.date),
                            y: .value("BMI", point.bmi)
                        )
                        .accessibilityLabel(Self.fullDateFormatter.string(from: point.date))
                        .accessibilityValue("BMI \(HeftFormat.weight(point.bmi)), \(BMICalculator.category(for: point.bmi))")
                        .symbol {
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(pointColor.opacity(0.20))
                                        .frame(width: 22, height: 22)

                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 2)
                                        .background(Circle().fill(pointColor))
                                        .frame(width: 12, height: 12)
                                        .shadow(color: pointColor.opacity(0.35), radius: 3, x: 0, y: 1)
                                } else {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 1.5)
                                        .background(Circle().fill(pointColor))
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
                        if let bmi = value.as(Double.self) {
                            AxisValueLabel(anchor: .leading) {
                                Text(HeftFormat.weight(bmi))
                                    .font(.caption2)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: currentXAxisDates) { value in
                        if let date = value.as(Date.self) {
                            let isSelected = currentActivePoint.map { Calendar.current.isDate(date, inSameDayAs: $0.date) } ?? false
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
                .frame(minHeight: currentActivePoints.count <= 1 ? singleChartHeight : fullChartHeight)
                .accessibilityLabel({
                    let minBMI = activeBmis.min() ?? 0
                    let maxBMI = activeBmis.max() ?? 0
                    let currentBMI = currentActivePoint?.bmi ?? 0
                    let currentCategory = BMICalculator.category(for: currentBMI)
                    return "Vücut kitle indeksi grafiği, \(selectedRange.accessibilityTitle). \(currentActivePoints.count) kayıt. Mevcut BMI: \(HeftFormat.weight(currentBMI)) (\(currentCategory)). En düşük \(HeftFormat.weight(minBMI)), en yüksek \(HeftFormat.weight(maxBMI))."
                }())

                if currentActivePoints.count == 1 {
                    Text("Bu aralıkta tek ölçüm var. Tüm zamanlar için 'Tümü' seçebilirsin.")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                        .padding(.bottom, 6)
                }
            }

            // MARK: - BMI Health Insight Banner
            if allPoints.count >= 2 {
                let insight = healthInsight
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
            if cachedBmiPoints.count != entries.count || cachedBmiPoints.last?.date != entries.first?.date {
                cachedBmiPoints = Self.computeBmiPoints(entries: entries, height: height)
            }
            if selectedPoint == nil {
                selectedPoint = activeBmiPoints.last
            }
        }
        .onChange(of: entries) { _, newEntries in
            cachedBmiPoints = Self.computeBmiPoints(entries: newEntries, height: height)
            selectedPoint = activeBmiPoints.last
        }
        .onChange(of: height) { _, newHeight in
            cachedBmiPoints = Self.computeBmiPoints(entries: entries, height: newHeight)
            selectedPoint = activeBmiPoints.last
        }
        .onChange(of: rawSelectedDate) { _, newDate in
            if let newDate {
                selectClosest(to: newDate, playHaptic: true)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: selectedPoint?.id)
    }

    // MARK: - Gesture Handling
    private func selectClosest(to date: Date, playHaptic: Bool) {
        guard !activeBmiPoints.isEmpty else { return }
        let closest = activeBmiPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
        guard let closest else { return }

        if selectedPoint?.id != closest.id {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)) {
                selectedPoint = closest
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
    BMIChartView(entries: sample, height: 178, targetWeight: 72.0)
        .padding()
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    let now = Date()
    let sample = [
        WeightEntry(date: now.addingTimeInterval(-86400 * 30), weight: 80.0),
        WeightEntry(date: now.addingTimeInterval(-86400 * 15), weight: 78.5),
        WeightEntry(date: now, weight: 77.2)
    ]
    BMIChartView(entries: sample, height: 178, targetWeight: 72.0)
        .padding()
}

#Preview("Tek Ölçüm (Milestone)", traits: .fixedLayout(width: 390, height: 400)) {
    BMIChartView(
        entries: [WeightEntry(date: Date(), weight: 59.7)],
        height: 170,
        targetWeight: 53.7
    )
    .padding()
}
