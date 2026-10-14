//
//  HistoryView.swift
//  Heft
//
//  Tab 2: Chronological weight history grouped by month, with tap-to-edit and swipe-to-delete.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedEntryForEdit: WeightEntry?
    @State private var entryToDelete: WeightEntry?
    @State private var deleteTrigger = false
    @State private var showSaveError = false

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    private var userHeight: Double {
        profiles.first?.height ?? 175.0
    }

    private struct MonthGroup: Identifiable {
        var id: String { title }
        let title: String
        let entries: [WeightEntry]
    }

    private var groupedEntries: [MonthGroup] {
        let sorted = entries.sorted { $0.date > $1.date }
        var groups: [MonthGroup] = []
        var currentTitle = ""
        var currentList: [WeightEntry] = []

        for entry in sorted {
            let title = Self.monthFormatter.string(from: entry.date).capitalized
            if title != currentTitle {
                if !currentList.isEmpty {
                    groups.append(MonthGroup(title: currentTitle, entries: currentList))
                }
                currentTitle = title
                currentList = [entry]
            } else {
                currentList.append(entry)
            }
        }
        if !currentList.isEmpty {
            groups.append(MonthGroup(title: currentTitle, entries: currentList))
        }
        return groups
    }

    private var isGainGoal: Bool {
        profiles.first?.goalType == .gain
    }

    private var summaryStats: (initial: Double, extreme: Double, extremeLabel: String, delta: Double)? {
        guard entries.count >= 2 else { return nil }
        let sorted = entries.sorted { $0.date < $1.date }
        guard let first = sorted.first, let latest = sorted.last else { return nil }
        let weights = sorted.map(\.weight)
        let extreme = isGainGoal ? (weights.max() ?? latest.weight) : (weights.min() ?? latest.weight)
        let label = isGainGoal ? "En Yüksek" : "En Düşük"
        let totalDelta = latest.weight - first.weight
        return (initial: first.weight, extreme: extreme, extremeLabel: label, delta: totalDelta)
    }

    private func delta(for entry: WeightEntry) -> Double? {
        let sorted = entries.sorted { $0.date < $1.date }
        guard let idx = sorted.firstIndex(where: { $0.id == entry.id }), idx > 0 else {
            return nil
        }
        return entry.weight - sorted[idx - 1].weight
    }

    @ViewBuilder
    private func statColumn(title: String, value: String, unit: String, highlightColor: Color? = nil) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(highlightColor ?? Color.primary)
                Text(unit)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "scale.3d")
                            .font(.largeTitle)
                            .foregroundStyle(Color.secondary)

                        Text("Henüz kayıt yok")
                            .font(.heftMeta)
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Summary Stats Header Card
                        if let stats = summaryStats {
                            Section {
                                HStack(spacing: 0) {
                                    statColumn(title: "Başlangıç", value: String(format: "%.1f", stats.initial), unit: "kg")
                                    Divider().frame(height: 28)
                                    statColumn(title: stats.extremeLabel, value: String(format: "%.1f", stats.extreme), unit: "kg")
                                    Divider().frame(height: 28)
                                    statColumn(
                                        title: "Toplam Değişim",
                                        value: String(format: "%@%.1f", stats.delta > 0 ? "+" : "", stats.delta),
                                        unit: "kg",
                                        highlightColor: stats.delta == 0 ? nil : (isGainGoal ? (stats.delta > 0 ? .heftSuccess : .heftError) : (stats.delta < 0 ? .heftSuccess : .heftError))
                                    )
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color(.secondarySystemGroupedBackground))
                        }

                        ForEach(groupedEntries) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    Button {
                                        selectedEntryForEdit = entry
                                    } label: {
                                        HistoryRow(
                                            date: entry.date,
                                            weight: entry.weight,
                                            height: userHeight,
                                            delta: delta(for: entry),
                                            isGainGoal: isGainGoal
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            entryToDelete = entry
                                        } label: {
                                            Label("Sil", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Text(group.title)
                                    .heftEyebrowStyle()
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 60)
                    }
                }
            }
            .background(Color.heftAdaptiveCanvas(colorScheme).ignoresSafeArea())
            .navigationTitle("Geçmiş")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedEntryForEdit) { entry in
                EditWeightSheet(entry: entry)
                    .presentationDetents([.fraction(0.60), .large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Bu kaydı silmek istediğinizden emin misiniz?",
                isPresented: Binding(
                    get: { entryToDelete != nil },
                    set: { if !$0 { entryToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Sil", role: .destructive) {
                    if let entry = entryToDelete {
                        deleteEntry(entry)
                        entryToDelete = nil
                    }
                }
                Button("Vazgeç", role: .cancel) {
                    entryToDelete = nil
                }
            }
            .alert("Hata", isPresented: $showSaveError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Kayıt silinirken bir hata oluştu. Lütfen tekrar deneyin.")
            }
            .sensoryFeedback(.warning, trigger: deleteTrigger)
        }
    }

    private func deleteEntry(_ entry: WeightEntry) {
        let entryDate = entry.date
        let entryUUID = entry.healthKitUUID
        modelContext.delete(entry)
        do {
            try modelContext.save()
            deleteTrigger.toggle()
            Task {
                await HealthKitService.shared.deleteWeight(uuid: entryUUID, on: entryDate)
            }
        } catch {
            showSaveError = true
        }
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    HistoryView()
        .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    HistoryView()
        .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}
