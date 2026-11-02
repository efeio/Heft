//
//  EditWeightSheet.swift
//  Heft
//
//  Single entry row in the History tab showing date, BMI, and logged weight.
//

import SwiftUI
import SwiftData

struct EditWeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.heftAccent) private var accent

    let entry: WeightEntry

    @Query(sort: \WeightEntry.date, order: .reverse) private var existingEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var heroMinHeight: CGFloat = 58

    @State private var weightText: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showDeleteConfirmation = false
    @State private var showOverwriteAlert = false
    @State private var conflictingEntry: WeightEntry? = nil
    @State private var showSaveError = false
    @State private var saveSuccessTrigger = false
    @FocusState private var isWeightFocused: Bool

    private var profile: UserProfile? {
        profiles.first
    }

    private var weightUnit: WeightUnit {
        profile?.weightUnit ?? .kg
    }

    private var parsedWeight: Double? {
        HeftFormat.parseDouble(weightText)
    }

    private var isWeightValid: Bool {
        guard let w = parsedWeight else { return false }
        if weightUnit == .lbs {
            return w >= 44.0 && w <= 1100.0
        }
        return w >= 20.0 && w <= 500.0
    }

    private var isDateValid: Bool {
        Calendar.current.startOfDay(for: selectedDate) <= Calendar.current.startOfDay(for: Date())
    }

    private var isSaveEnabled: Bool {
        isWeightValid && isDateValid
    }

    private func effectiveHealthKitDate(for date: Date) -> Date {
        if Calendar.current.isDateInToday(date) {
            return Date()
        }
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Weight Input Card (Dynamic Height)
                    VStack(spacing: 6) {
                        HStack {
                            TextField("0,0", text: $weightText)
                                .textFieldStyle(.plain)
                                .keyboardType(.decimalPad)
                                .focused($isWeightFocused)
                                .font(.heftHeroStat)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                        }
                        .keyboardDismissToolbar(isFocused: $isWeightFocused)
                        .frame(minHeight: heroMinHeight)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemGroupedBackground))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isWeightFocused ? accent : Color.clear, lineWidth: 1.5)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture {
                            isWeightFocused = true
                        }

                        Text(weightUnit.symbol)
                            .font(.heftMeta)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 16)

                    // Date Picker (past/today only)
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Label("Tartım Tarihi", systemImage: "calendar")
                                .font(.heftBodySemibold)
                                .foregroundStyle(Color.primary)
                                .fixedSize(horizontal: true, vertical: false)

                            Spacer()

                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Tartım Tarihi", systemImage: "calendar")
                                .font(.heftBodySemibold)
                                .foregroundStyle(Color.primary)

                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                    .padding(.horizontal, horizontalPadding)

                    // Action Buttons
                    VStack(spacing: 12) {
                        HeftPrimaryButton(
                            title: "Güncellemeyi Kaydet",
                            isEnabled: isSaveEnabled,
                            action: handleUpdate
                        )

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Bu Kaydı Sil")
                            }
                            .font(.heftBodySemibold)
                            .foregroundStyle(Color.heftError)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.heftCanvas)
            .navigationTitle("Tartımı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .frame(minHeight: 44)
                }
            }
            .onAppear {
                let displayWeight = (weightUnit == .lbs) ? UnitConverter.kgToLbs(entry.weight) : entry.weight
                weightText = HeftFormat.weight(displayWeight)
                selectedDate = entry.date
            }
            .confirmationDialog(
                "Bu kaydı silmek istediğinden emin misin?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Kaydı Sil", role: .destructive) {
                    let dateToDelete = entry.date
                    let uuidToDelete = entry.healthKitUUID
                    modelContext.delete(entry)
                    do {
                        try modelContext.save()
                        Task {
                            await HealthKitService.shared.deleteWeight(uuid: uuidToDelete, on: dateToDelete)
                        }
                        dismiss()
                    } catch {
                        showSaveError = true
                    }
                }
                Button("Vazgeç", role: .cancel) {}
            }
            .alert("Kayıt Güncellensin mi?", isPresented: $showOverwriteAlert) {
                Button("Üzerine Yaz", role: .destructive) {
                    if let w = parsedWeight {
                        applyUpdate(weight: w)
                    }
                }
                Button("Vazgeç", role: .cancel) {
                    conflictingEntry = nil
                }
            } message: {
                if let conflict = conflictingEntry, let weight = parsedWeight {
                    let conflictDisplay = (weightUnit == .lbs) ? UnitConverter.kgToLbs(conflict.weight) : conflict.weight
                    Text("Bu tarihe ait mevcut kayıt (\(HeftFormat.weightWithUnit(conflictDisplay, unit: weightUnit))), yeni değer olan \(HeftFormat.weightWithUnit(weight, unit: weightUnit)) ile güncellenecek.")
                } else {
                    Text("Bu tarihteki mevcut kayıt güncellenecek.")
                }
            }
            .alert("Hata", isPresented: $showSaveError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("İşlem sırasında bir hata oluştu. Lütfen tekrar dene.")
            }
            .sensoryFeedback(.success, trigger: saveSuccessTrigger)
        }
    }

    private func handleUpdate() {
        guard let w = parsedWeight, isSaveEnabled else { return }

        let calendar = Calendar.current
        let dateChanged = !calendar.isDate(selectedDate, inSameDayAs: entry.date)

        if dateChanged {
            let match = existingEntries.first { other in
                other.id != entry.id && calendar.isDate(other.date, inSameDayAs: selectedDate)
            }
            if let existing = match {
                conflictingEntry = existing
                showOverwriteAlert = true
                return
            }
        }

        applyUpdate(weight: w)
    }

    private func applyUpdate(weight: Double) {
        let weightInKg = (weightUnit == .lbs) ? UnitConverter.lbsToKg(weight) : weight
        let oldDate = entry.date
        let oldUUID = entry.healthKitUUID
        let targetDate = effectiveHealthKitDate(for: selectedDate)

        entry.weight = weightInKg
        entry.date = targetDate

        var conflictUUID: UUID? = nil
        var conflictDate: Date? = nil
        if let conflict = conflictingEntry {
            conflictUUID = conflict.healthKitUUID
            conflictDate = conflict.date
            modelContext.delete(conflict)
            conflictingEntry = nil
        }

        do {
            try modelContext.save()
            saveSuccessTrigger.toggle()

            Task {
                await HealthKitService.shared.deleteWeight(uuid: oldUUID, on: oldDate)
                if let cUUID = conflictUUID, let cDate = conflictDate {
                    await HealthKitService.shared.deleteWeight(uuid: cUUID, on: cDate)
                }
                let newUUID = await HealthKitService.shared.saveWeight(weightKg: weightInKg, date: targetDate)
                if let uuid = newUUID {
                    await MainActor.run {
                        entry.healthKitUUID = uuid
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

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    let sample = WeightEntry(date: Date(), weight: 75.0)
    EditWeightSheet(entry: sample)
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    let sample = WeightEntry(date: Date(), weight: 75.0)
    EditWeightSheet(entry: sample)
}
