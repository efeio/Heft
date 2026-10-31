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

    private static let dayMonthFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateFormat = "d MMMM"
        return df
    }()

    private var profile: UserProfile? {
        profiles.first
    }

    private var parsedWeight: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
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
            VStack(spacing: 0) {
                // MARK: - Header Bar
                HStack {
                    Text("Kilo Ekle")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.secondary)
                            .padding(8)
                            .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Kapat")
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // MARK: - Minimal Date Selector Segment
                        dateSegmentRow
                            .padding(.horizontal, horizontalPadding)

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
            }
            .background(Color.heftCanvas)
            .sheet(isPresented: $showCustomDatePicker) {
                customDatePickerSheet
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
                    Text("\(Self.dayMonthFormatter.string(from: selectedDate)) tarihine ait mevcut kayıt (\(String(format: "%.1f kg", conflict.weight))), yeni değer olan \(String(format: "%.1f kg", weight)) ile güncellenecektir.")
                } else {
                    Text("Bu tarihteki mevcut kayıt güncellenecektir.")
                }
            }
            .alert("Hata", isPresented: $showSaveError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyin.")
            }
        }
    }

    // MARK: - Date Segment Row
    private var dateSegmentRow: some View {
        HStack(spacing: 8) {
            // Bugün
            Button {
                selectDate(todayAnchor)
            } label: {
                Text("Bugün")
                    .font(.caption.weight(isTodaySelected ? .bold : .medium))
                    .foregroundStyle(isTodaySelected ? Color.white : Color.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(isTodaySelected ? accentFill : Color.heftSurface)
                    }
            }
            .buttonStyle(.plain)

            // Dün
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: todayAnchor) {
                Button {
                    selectDate(yesterday)
                } label: {
                    Text("Dün")
                        .font(.caption.weight(isYesterdaySelected ? .bold : .medium))
                        .foregroundStyle(isYesterdaySelected ? Color.white : Color.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(isYesterdaySelected ? accentFill : Color.heftSurface)
                        }
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Diğer / Özel Tarih
            Button {
                showCustomDatePicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(isTodaySelected || isYesterdaySelected ? "Diğer" : Self.dayMonthFormatter.string(from: selectedDate))
                        .font(.caption.weight(!isTodaySelected && !isYesterdaySelected ? .bold : .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(!isTodaySelected && !isYesterdaySelected ? Color.white : accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(!isTodaySelected && !isYesterdaySelected ? accentFill : accent.opacity(0.12))
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hero Weight Section
    private var heroWeightSection: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(weightText.isEmpty ? "0.0" : weightText)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(weightText.isEmpty ? Color.secondary : Color.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .contentTransition(.numericText())

                Text("kg")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)

            // Micro Steppers (-0.1 / +0.1)
            HStack(spacing: 16) {
                Button {
                    stepWeight(by: -0.1)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "minus")
                            .font(.caption.weight(.bold))
                        Text("0.1")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                }
                .buttonStyle(KeypadPressStyle())

                Button {
                    stepWeight(by: 0.1)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                        Text("0.1")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                }
                .buttonStyle(KeypadPressStyle())
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

                    Text(isGain ? String(format: "Son tartıma göre +%.1f kg", delta) : (isLoss ? String(format: "Son tartıma göre -%.1f kg", abs(delta)) : "Son tartımla aynı"))
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(isPositiveDirection ? Color.heftSuccess : (isGain || isLoss ? Color.heftWarning : Color.secondary))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(isPositiveDirection ? Color.heftSuccess.opacity(0.12) : (isGain || isLoss ? Color.heftWarning.opacity(0.12) : Color.heftSurfaceSub))
                }
            } else if let target = profile?.targetWeight {
                let diff = current - target
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.caption2.weight(.bold))
                    Text(String(format: "Hedefe %.1f kg kaldı", abs(diff)))
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(accent.opacity(0.12))
                }
            }
        } else {
            // Subtle guidance placeholder
            Text("Tartıdaki kilonuzu girin")
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .frame(height: 24)
        }
    }

    // MARK: - Custom Date Picker Sheet
    private var customDatePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Tarih Seç",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(accent)
                .padding()

                Spacer()
            }
            .navigationTitle("Tartım Tarihi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        showCustomDatePicker = false
                        onDateChanged(selectedDate)
                    }
                    .font(.body.weight(.bold))
                    .foregroundStyle(accent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Save Button Title
    private var saveButtonTitle: String {
        if let weight = parsedWeight, isWeightValid {
            if selectedDayEntry != nil {
                return String(format: "Kayıt Güncelle (%.1f kg)", weight)
            }
            return String(format: "Kaydet (%.1f kg)", weight)
        }
        return selectedDayEntry != nil ? "Kayıt Güncelle" : "Kaydet"
    }

    // MARK: - Keypad Handlers
    private func handleDigit(_ digit: String) {
        if !hasUserTyped {
            weightText = digit
            hasUserTyped = true
            return
        }

        // Limit to reasonable weight length (e.g. max 5 chars: "123.4")
        guard weightText.count < 5 else { return }

        // Prevent multiple decimals
        if let dotIndex = weightText.firstIndex(of: ",") {
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
        if !hasUserTyped {
            weightText = "0,"
            hasUserTyped = true
            return
        }
        if !weightText.contains(",") && !weightText.contains(".") {
            weightText += weightText.isEmpty ? "0," : ","
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
        weightText = String(format: "%.1f", newWeight).replacingOccurrences(of: ".", with: ",")
        hasUserTyped = true
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Date Selection & Prefill
    private func initializePrefill() {
        let today = calendar.startOfDay(for: Date())
        todayAnchor = today
        selectedDate = today

        if let existing = existingEntries.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            weightText = String(format: "%.1f", existing.weight).replacingOccurrences(of: ".", with: ",")
            hasUserTyped = true
        } else if let latest = existingEntries.first {
            // Smart suggestion: prefill with latest weight so user can easily adjust with stepper
            weightText = String(format: "%.1f", latest.weight).replacingOccurrences(of: ".", with: ",")
            hasUserTyped = false // next keypad digit will replace it
        }
    }

    private func selectDate(_ date: Date) {
        let normalized = calendar.startOfDay(for: date)
        guard normalized <= anchorDate else { return }
        selectedDate = normalized
        onDateChanged(normalized)
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func onDateChanged(_ date: Date) {
        if let existing = existingEntries.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            weightText = String(format: "%.1f", existing.weight).replacingOccurrences(of: ".", with: ",")
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

// MARK: - Weight Keypad View
struct WeightKeypadView: View {
    let onDigit: (String) -> Void
    let onDecimal: () -> Void
    let onDelete: () -> Void
    let onClear: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.heftAccent) private var accent

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

            keypadButton(title: ",") {
                onDecimal()
            }

            keypadButton(title: "0") {
                onDigit("0")
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onDelete()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(height: 48)
                    Image(systemName: "delete.left.fill")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(Color.secondary)
                }
            }
            .buttonStyle(KeypadPressStyle())
        }
    }

    private func keypadButton(title: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 48)
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.primary)
            }
        }
        .buttonStyle(KeypadPressStyle())
    }
}

struct KeypadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
