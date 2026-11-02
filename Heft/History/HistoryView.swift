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
    @State private var showAddWeightSheet = false

    private static var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        formatter.locale = loc
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "LLLL yyyy", options: 0, locale: loc)
        return formatter
    }

    private var userHeight: Double {
        profiles.first?.height ?? 175.0
    }

    private var userWeightUnit: WeightUnit {
        profiles.first?.weightUnit ?? .kg
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
        let label = isGainGoal ? String(localized: "En Yüksek", comment: "Highest weight stat") : String(localized: "En Düşük", comment: "Lowest weight stat")
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
    private func statColumn(title: String, value: String, unit: String, highlightColor: Color? = nil, fixedHorizontal: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.secondary)
                .fixedSize(horizontal: fixedHorizontal, vertical: false)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(highlightColor ?? Color.primary)
                Text(unit)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.secondary)
            }
            .fixedSize(horizontal: fixedHorizontal, vertical: false)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func statRow(title: String, value: String, unit: String, highlightColor: Color? = nil) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(highlightColor ?? Color.primary)
                    Text(unit)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
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
        }
        .accessibilityElement(children: .combine)
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView {
                        Label("Henüz Tartım Kaydı Yok", systemImage: "scalemass")
                    } description: {
                        Text("Kilo geçmişini ve değişim istatistiklerini görmek için ilk tartımını ekle.")
                    } actions: {
                        Button("Kilo Ekle") {
                            showAddWeightSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        // Summary Stats Header Card
                        if let stats = summaryStats {
                            let deltaColor: Color? = stats.delta == 0 ? nil : (isGainGoal ? (stats.delta > 0 ? .heftSuccess : .heftError) : (stats.delta < 0 ? .heftSuccess : .heftError))
                            let displayInitial = (userWeightUnit == .lbs) ? UnitConverter.kgToLbs(stats.initial) : stats.initial
                            let displayExtreme = (userWeightUnit == .lbs) ? UnitConverter.kgToLbs(stats.extreme) : stats.extreme
                            let displayDelta = (userWeightUnit == .lbs) ? UnitConverter.kgToLbs(stats.delta) : stats.delta
                            let unitSymbol = userWeightUnit.symbol

                            Section {
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: 0) {
                                        statColumn(title: String(localized: "Başlangıç", comment: "Initial weight stat"), value: HeftFormat.weight(displayInitial), unit: unitSymbol, fixedHorizontal: true)
                                        Divider().frame(height: 28)
                                        statColumn(title: stats.extremeLabel, value: HeftFormat.weight(displayExtreme), unit: unitSymbol, fixedHorizontal: true)
                                        Divider().frame(height: 28)
                                        statColumn(
                                            title: String(localized: "Toplam Değişim", comment: "Total change stat"),
                                            value: HeftFormat.signedWeight(displayDelta),
                                            unit: unitSymbol,
                                            highlightColor: deltaColor,
                                            fixedHorizontal: true
                                        )
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        statRow(title: String(localized: "Başlangıç", comment: "Initial weight stat"), value: HeftFormat.weight(displayInitial), unit: unitSymbol)
                                        Divider()
                                        statRow(title: stats.extremeLabel, value: HeftFormat.weight(displayExtreme), unit: unitSymbol)
                                        Divider()
                                        statRow(
                                            title: String(localized: "Toplam Değişim", comment: "Total change stat"),
                                            value: HeftFormat.signedWeight(displayDelta),
                                            unit: unitSymbol,
                                            highlightColor: deltaColor
                                        )
                                    }
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
                                            isGainGoal: isGainGoal,
                                            weightUnit: userWeightUnit
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
                }
            }
            .background(Color.heftAdaptiveCanvas(colorScheme).ignoresSafeArea())
            .navigationTitle("Geçmiş")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddWeightSheet) {
                AddWeightSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedEntryForEdit) { entry in
                EditWeightSheet(entry: entry)
                    .presentationDetents([.fraction(0.60), .large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Bu kaydı silmek istediğinden emin misin?",
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
                Text("Kayıt silinirken bir hata oluştu. Lütfen tekrar dene.")
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
