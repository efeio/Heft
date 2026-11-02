//
//  AddWeightSheet.swift
//  Heft
//
//  Apple Health-grade weight logging sheet with smart prefill,
//  micro-steppers, live delta context, integrated numpad, and minimal date selection.
//

import SwiftUI
import SwiftData

struct AddWeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.heftAccent) private var accent
    @Environment(\.heftAccentFill) private var accentFill
    @Query(sort: \WeightEntry.date, order: .reverse) private var existingEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 20

    @State private var weightText = ""
    @State private var hasUserTyped = false
    @State private var selectedDate = Date()
    @State private var todayAnchor: Date = Calendar.current.startOfDay(for: Date())
    @State private var showCustomDatePicker = false
    @State private var showOverwriteAlert = false
    @State private var conflictingEntry: WeightEntry? = nil
    @State private var saveSuccessTrigger = false
    @State private var showSaveError = false

    private let calendar = Calendar.current

    private static var dayMonthFormatter: DateFormatter {
        let df = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        df.locale = loc
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMMMM", options: 0, locale: loc)
        return df
    }

    private var profile: UserProfile? {
        profiles.first
    }

    private var parsedWeight: Double? {
        HeftFormat.parseDouble(weightText)
    }

    private var isWeightValid: Bool {
        guard let w = parsedWeight else { return false }
        return w >= 20.0 && w <= 500.0
    }

    private var isDateValid: Bool {
        calendar.startOfDay(for: selectedDate) <= anchorDate
    }

    private var isSaveEnabled: Bool {
        isWeightValid && isDateValid
    }

    private var anchorDate: Date {
        calendar.startOfDay(for: todayAnchor)
    }

    private var isTodaySelected: Bool {
        calendar.isDateInToday(selectedDate)
    }

    private var isYesterdaySelected: Bool {
        calendar.isDateInYesterday(selectedDate)
    }

    private var selectedDayEntry: WeightEntry? {
        existingEntries.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    /// The latest weight entry strictly before the selected date, used for live delta calculation
    private var comparisonEntry: WeightEntry? {
        let selectedStart = calendar.startOfDay(for: selectedDate)
        return existingEntries.first { entry in
            calendar.startOfDay(for: entry.date) < selectedStart
        }
    }

    /// Live delta between current input weight and previous record
    private var liveDeltaFromPrevious: Double? {
        guard let current = parsedWeight, let prev = comparisonEntry else { return nil }
        return current - prev.weight
    }

    private func effectiveHealthKitDate(for date: Date) -> Date {
        if calendar.isDateInToday(date) {
            return Date()
        }
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // MARK: - Minimal Date Selector Segment
                    dateSegmentRow
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 8)

                    if showCustomDatePicker {
                        inlineDatePickerCard
                            .padding(.horizontal, horizontalPadding)
                    }

                    // MARK: - Hero Weight Display & Steppers
                    heroWeightSection
                        .padding(.horizontal, horizontalPadding)

                    // MARK: - Live Context / Delta Badge
                    liveDeltaBadge
                        .padding(.horizontal, horizontalPadding)

                    // MARK: - Integrated Numeric Keypad
                    WeightKeypadView(
                        onDigit: handleDigit,
                        onDecimal: handleDecimal,
                        onDelete: handleDelete,
                        onClear: handleClear
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 2)

                    // MARK: - Primary Save Button
                    HeftPrimaryButton(
                        title: saveButtonTitle,
                        isEnabled: isSaveEnabled,
                        action: handleSave
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                }
            }
            .background(Color.heftCanvas)
            .navigationTitle(String(localized: "Kilo Ekle", comment: "Add weight sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
            }
            .sensoryFeedback(.success, trigger: saveSuccessTrigger)
            .onAppear {
                initializePrefill()
            }
            .alert("Kayıt Güncellensin mi?", isPresented: $showOverwriteAlert) {
                Button("Güncelle", role: .destructive) {
                    commitSave(overwrite: true)
                }
                Button("Vazgeç", role: .cancel) {
                    conflictingEntry = nil
                }
            } message: {
                if let conflict = conflictingEntry, let weight = parsedWeight {
                    Text("\(Self.dayMonthFormatter.string(from: selectedDate)) tarihine ait mevcut kayıt (\(HeftFormat.weightKg(conflict.weight))), yeni değer olan \(HeftFormat.weightKg(weight)) ile güncellenecektir.")
                } else {
                    Text("Bu tarihteki mevcut kayıt güncellenecektir.")
                }
            }
            .alert("Hata", isPresented: $showSaveError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Kayıt sırasında bir hata oluştu. Lütfen tekrar dene.")
            }
        }
    }

    // MARK: - Date Segment Row
    private var dateSegmentRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                dateButtons(fixedHorizontal: true)
                Spacer()
                customDateButton(fixedHorizontal: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    dateButtons(fixedHorizontal: false)
                }
                customDateButton(fixedHorizontal: false)
            }
        }
    }

    @ViewBuilder
    private func dateButtons(fixedHorizontal: Bool) -> some View {
        // Bugün
        Button {
            showCustomDatePicker = false
            selectDate(todayAnchor)
        } label: {
            Text("Bugün")
                .font(.caption.weight(isTodaySelected ? .bold : .medium))
                .foregroundStyle(isTodaySelected ? Color.white : Color.primary)
                .fixedSize(horizontal: fixedHorizontal, vertical: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(isTodaySelected ? accentFill : Color.heftSurface)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isTodaySelected ? .isSelected : [])

        // Dün
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: todayAnchor) {
            Button {
                showCustomDatePicker = false
                selectDate(yesterday)
            } label: {
                Text("Dün")
                    .font(.caption.weight(isYesterdaySelected ? .bold : .medium))
                    .foregroundStyle(isYesterdaySelected ? Color.white : Color.primary)
                    .fixedSize(horizontal: fixedHorizontal, vertical: false)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(isYesterdaySelected ? accentFill : Color.heftSurface)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isYesterdaySelected ? .isSelected : [])
        }
    }

    @ViewBuilder
    private func customDateButton(fixedHorizontal: Bool) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                showCustomDatePicker.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(isTodaySelected || isYesterdaySelected ? String(localized: "Diğer", comment: "Other date button") : Self.dayMonthFormatter.string(from: selectedDate))
                    .font(.caption.weight(!isTodaySelected && !isYesterdaySelected ? .bold : .medium))
                    .fixedSize(horizontal: fixedHorizontal, vertical: false)
                Image(systemName: showCustomDatePicker ? "chevron.up" : "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(!isTodaySelected && !isYesterdaySelected ? Color.white : accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(!isTodaySelected && !isYesterdaySelected ? accentFill : accent.opacity(0.12))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isTodaySelected || isYesterdaySelected ? String(localized: "Diğer tarih seç", comment: "Other date select a11y") : String(localized: "Seçili tarih: \(Self.dayMonthFormatter.string(from: selectedDate))", comment: "Selected date a11y"))
        .accessibilityAddTraits(!isTodaySelected && !isYesterdaySelected ? .isSelected : [])
    }

    // MARK: - Inline Date Picker Card
    private var inlineDatePickerCard: some View {
        VStack(spacing: 12) {
            DatePicker(
                "Tarih Seç",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(accent)
            .onChange(of: selectedDate) { _, newValue in
                onDateChanged(newValue)
            }

            HStack {
                Spacer()
                Button("Tamam") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        showCustomDatePicker = false
                    }
                    onDateChanged(selectedDate)
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accent)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
        }
        .padding(14)
        .heftCard(cornerRadius: 16)
    }

    // MARK: - Hero Weight Section
    private var heroWeightSection: some View {
        VStack(spacing: 6) {
            HeftScaleMotifView(weight: parsedWeight ?? existingEntries.first?.weight ?? 70.0)
                .padding(.bottom, 2)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(weightText.isEmpty ? HeftFormat.weight(0) : weightText)
                    .font(.heftHeroStat)
                    .foregroundStyle(weightText.isEmpty ? Color.secondary : Color.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .contentTransition(reduceMotion ? .identity : .numericText())

                Text("kg")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Girilen kilo: \(weightText.isEmpty ? "0,0" : weightText) kilogram")

            // Micro Steppers (-0,1 / +0,1)
            HStack(spacing: 16) {
                Button {
                    stepWeight(by: -0.1)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "minus")
                            .font(.caption.weight(.bold))
                        Text("0,1")
                            .font(.subheadline.weight(.semibold))
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(KeypadPressStyle())
                .accessibilityLabel("0,1 kilogram azalt")

                Button {
                    stepWeight(by: 0.1)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                        Text("0,1")
                            .font(.subheadline.weight(.semibold))
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(KeypadPressStyle())
                .accessibilityLabel("0,1 kilogram artır")
            }
        }
    }

    // MARK: - Live Delta / Motivation Badge
    @ViewBuilder
    private var liveDeltaBadge: some View {
        if let current = parsedWeight {
            if let delta = liveDeltaFromPrevious {
                let isLoss = delta < -0.05
                let isGain = delta > 0.05
                let isGoalGain = profile?.isGainGoal ?? false
                let isPositiveDirection = isGoalGain ? isGain : isLoss

                HStack(spacing: 6) {
                    Image(systemName: isLoss ? "arrow.down.right" : (isGain ? "arrow.up.right" : "equal"))
                        .font(.caption2.weight(.bold))

                    if isGain {
                        Text("Son tartıma göre \(HeftFormat.signedWeightKg(delta))")
                            .font(.caption.weight(.semibold))
                    } else if isLoss {
                        Text("Son tartıma göre -\(HeftFormat.weightKg(abs(delta)))")
                            .font(.caption.weight(.semibold))
                    } else {
                        Text("Son tartımla aynı")
                            .font(.caption.weight(.semibold))
                    }
                }
                .foregroundStyle(isPositiveDirection ? Color.heftSuccess : (isGain || isLoss ? Color.heftWarning : Color.secondary))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isPositiveDirection ? Color.heftSuccess.opacity(0.12) : (isGain || isLoss ? Color.heftWarning.opacity(0.12) : Color.heftSurfaceSub))
                }
            } else if let target = profile?.targetWeight {
                let diff = current - target
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.caption2.weight(.bold))
                    Text(String(localized: "Hedefe \(HeftFormat.weightKg(abs(diff))) kaldı", comment: "Remaining to goal badge"))
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accent.opacity(0.12))
                }
            }
        } else {
            // Subtle guidance placeholder
            Text("Tartıdaki kilonu gir")
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .frame(height: 24)
        }
    }

    // MARK: - Save Button Title
    private var saveButtonTitle: String {
        if let weight = parsedWeight, isWeightValid {
            if selectedDayEntry != nil {
                return String(localized: "Kayıt Güncelle (\(HeftFormat.weightKg(weight)))", comment: "Update weight button with weight")
            }
            return String(localized: "Kaydet (\(HeftFormat.weightKg(weight)))", comment: "Save weight button with weight")
        }
        return selectedDayEntry != nil ? String(localized: "Kayıt Güncelle", comment: "Update weight button") : String(localized: "Kaydet", comment: "Save weight button")
    }

    // MARK: - Keypad Handlers
    private func handleDigit(_ digit: String) {
        if !hasUserTyped {
            weightText = digit
            hasUserTyped = true
            return
        }

        // Limit to reasonable weight length (e.g. max 5 chars: "123,4")
        guard weightText.count < 5 else { return }

        // Prevent multiple decimals
        let sep = Character(HeftFormat.decimalSeparator)
        if let dotIndex = weightText.firstIndex(of: sep) {
            let decimals = weightText[weightText.index(after: dotIndex)...]
            if decimals.count >= 1 {
                return // allow only 1 decimal place
            }
        }

        // Prevent leading zeros like "00"
        if weightText == "0" {
            weightText = digit
        } else {
            weightText += digit
        }
    }

    private func handleDecimal() {
        let sep = HeftFormat.decimalSeparator
        if !hasUserTyped {
            weightText = "0" + sep
            hasUserTyped = true
            return
        }
        if !weightText.contains(",") && !weightText.contains(".") {
            weightText += weightText.isEmpty ? "0" + sep : sep
        }
    }

    private func handleDelete() {
        if !hasUserTyped {
            weightText = ""
            hasUserTyped = true
            return
        }
        if !weightText.isEmpty {
            weightText.removeLast()
        }
    }

    private func handleClear() {
        weightText = ""
        hasUserTyped = true
    }

    private func stepWeight(by delta: Double) {
        let current = parsedWeight ?? existingEntries.first?.weight ?? 70.0
        let newWeight = max(20.0, min(350.0, current + delta))
        weightText = HeftFormat.weight(newWeight)
        hasUserTyped = true
        if !reduceMotion {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    // MARK: - Date Selection & Prefill
    private func initializePrefill() {
        let today = calendar.startOfDay(for: Date())
        todayAnchor = today
        selectedDate = today

        if let existing = existingEntries.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            weightText = HeftFormat.weight(existing.weight)
            hasUserTyped = true
        } else if let latest = existingEntries.first {
            // Smart suggestion: prefill with latest weight so user can easily adjust with stepper
            weightText = HeftFormat.weight(latest.weight)
            hasUserTyped = false // next keypad digit will replace it
        }
    }

    private func selectDate(_ date: Date) {
        let normalized = calendar.startOfDay(for: date)
        guard normalized <= anchorDate else { return }
        selectedDate = normalized
        onDateChanged(normalized)
        if !reduceMotion {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    private func onDateChanged(_ date: Date) {
        if let existing = existingEntries.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            weightText = HeftFormat.weight(existing.weight)
            hasUserTyped = true
        }
    }

    // MARK: - Save Action
    private func handleSave() {
        guard let _ = parsedWeight, isSaveEnabled else { return }

        if let existing = selectedDayEntry {
            conflictingEntry = existing
            showOverwriteAlert = true
        } else {
            commitSave(overwrite: false)
        }
    }

    private func commitSave(overwrite: Bool) {
        guard let weight = parsedWeight else { return }
        let targetDate = effectiveHealthKitDate(for: selectedDate)

        let targetEntry: WeightEntry
        let oldUUID: UUID?
        if overwrite, let existing = conflictingEntry {
            oldUUID = existing.healthKitUUID
            existing.date = targetDate
            existing.weight = weight
            targetEntry = existing
        } else {
            oldUUID = nil
            let newEntry = WeightEntry(date: targetDate, weight: weight)
            modelContext.insert(newEntry)
            targetEntry = newEntry
        }

        do {
            try modelContext.save()
            saveSuccessTrigger.toggle()
            Task {
                if overwrite {
                    await HealthKitService.shared.deleteWeight(uuid: oldUUID, on: targetDate)
                }
                let newUUID = await HealthKitService.shared.saveWeight(weightKg: weight, date: targetDate)
                if let uuid = newUUID {
                    await MainActor.run {
                        targetEntry.healthKitUUID = uuid
                        try? modelContext.save()
                    }
                }
            }
            dismiss()
        } catch {
            showSaveError = true
        }
    }
}

// MARK: - Signature Scale Motif View
struct HeftScaleMotifView: View {
    let weight: Double

    @Environment(\.heftAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tenthStepOffset: Int {
        Int((weight * 10).rounded())
    }

    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                ForEach(-9...9, id: \.self) { offset in
                    let tickIndex = tenthStepOffset + offset
                    let isMajor = tickIndex % 5 == 0
                    let isCenter = offset == 0
                    Capsule()
                        .fill(isCenter ? Color.clear : Color.secondary.opacity(isMajor ? 0.42 : 0.22))
                        .frame(width: isMajor ? 2 : 1.5, height: isMajor ? 12 : 7)
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8), value: tenthStepOffset)

            // Center indicator needle echoing HeftTickPicker
            VStack(spacing: 2) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 7, y: 0))
                    path.addLine(to: CGPoint(x: 3.5, y: 5))
                    path.closeSubpath()
                }
                .fill(accent)
                .frame(width: 7, height: 5)

                Capsule()
                    .fill(accent)
                    .frame(width: 2.5, height: 14)
            }
        }
        .frame(height: 24)
        .frame(maxWidth: 240)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.18),
                    .init(color: .black, location: 0.82),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .accessibilityHidden(true)
    }
}

// MARK: - Weight Keypad View
struct WeightKeypadView: View {
    let onDigit: (String) -> Void
    let onDecimal: () -> Void
    let onDelete: () -> Void
    let onClear: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.heftAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title2) private var keyHeight: CGFloat = 48

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9"], id: \.self) { digit in
                keypadButton(title: digit) {
                    onDigit(digit)
                }
            }

            keypadButton(title: HeftFormat.decimalSeparator, accessibilityLabel: String(localized: "Ondalık ayırıcı", comment: "Decimal separator keypad button")) {
                onDecimal()
            }

            keypadButton(title: "0") {
                onDigit("0")
            }

            Button {
                if !reduceMotion {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                onDelete()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(minHeight: max(44, keyHeight))
                    Image(systemName: "delete.left.fill")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(Color.secondary)
                }
            }
            .buttonStyle(KeypadPressStyle())
            .accessibilityLabel(String(localized: "Sil", comment: "Keypad delete button"))
        }
    }

    private func keypadButton(title: String, accessibilityLabel: String? = nil, action: @escaping () -> Void) -> some View {
        Button {
            if !reduceMotion {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(minHeight: max(44, keyHeight))
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.primary)
            }
        }
        .buttonStyle(KeypadPressStyle())
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

struct KeypadPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    AddWeightSheet()
        .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    AddWeightSheet()
        .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}
