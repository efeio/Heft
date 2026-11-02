//
//  DashboardView.swift
//  Heft
//
//  Tab 1: Dashboard with SummaryCard, Quick-add weight action, Swift Charts, and Settings navigation.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ScaledMetric(relativeTo: .body) private var verticalSpacing: CGFloat = 20

    @State private var showingAddWeight: Bool = {
        #if DEBUG
        return CommandLine.arguments.contains("--add-weight")
        #else
        return false
        #endif
    }()
    @State private var showingSettings: Bool = {
        #if DEBUG
        return CommandLine.arguments.contains("--settings")
        #else
        return false
        #endif
    }()
    @State private var showSaveError = false

    private var profile: UserProfile? {
        profiles.first
    }

    private var latestWeight: Double {
        entries.first?.weight ?? profile?.initialWeight ?? 70.0
    }

    private var weekAgoWeight: Double? {
        guard let latest = entries.first else { return nil }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: latest.date) ?? latest.date
        let candidate = entries.first { $0.date <= sevenDaysAgo }
        return candidate?.weight
    }

    private var targetWeight: Double {
        profile?.targetWeight ?? 65.0
    }

    private var userHeight: Double {
        profile?.height ?? 175.0
    }

    private var userGoalType: GoalType {
        profile?.goalType ?? .lose
    }

    private var userWeightUnit: WeightUnit {
        profile?.weightUnit ?? .kg
    }

    private var userHeightUnit: HeightUnit {
        profile?.heightUnit ?? .cm
    }

    private var greetingTitle: String {
        guard let name = profile?.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return String(localized: "Ana Sayfa", comment: "Home navigation title")
        }
        return String(localized: "Merhaba, \(name)", comment: "Greeting with user name")
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: verticalSpacing) {
                        if horizontalSizeClass == .regular {
                            HStack(alignment: .top, spacing: verticalSpacing) {
                                SummaryCardView(
                                    latestWeight: latestWeight,
                                    targetWeight: targetWeight,
                                    weekAgoWeight: weekAgoWeight,
                                    goalType: userGoalType,
                                    weightUnit: userWeightUnit
                                )
                                .frame(maxWidth: .infinity, alignment: .top)

                                TargetProjectionCard(
                                    entries: entries,
                                    targetWeight: targetWeight,
                                    initialWeight: profile?.initialWeight ?? entries.last?.weight ?? latestWeight,
                                    goalType: userGoalType,
                                    weightUnit: userWeightUnit
                                )
                                .frame(maxWidth: .infinity, alignment: .top)
                            }
                        } else {
                            // Hero Summary Card
                            SummaryCardView(
                                latestWeight: latestWeight,
                                targetWeight: targetWeight,
                                weekAgoWeight: weekAgoWeight,
                                goalType: userGoalType,
                                weightUnit: userWeightUnit
                            )

                            // Target Projection Card
                            TargetProjectionCard(
                                entries: entries,
                                targetWeight: targetWeight,
                                initialWeight: profile?.initialWeight ?? entries.last?.weight ?? latestWeight,
                                goalType: userGoalType,
                                weightUnit: userWeightUnit
                            )
                        }

                        // Quick Log Button
                        HeftPrimaryButton(
                            title: "Kilo Ekle",
                            icon: "plus.circle.fill",
                            isEnabled: true
                        ) {
                            showingAddWeight = true
                        }

                        // Charts Stack / Grid
                        if horizontalSizeClass == .regular {
                            HStack(alignment: .top, spacing: verticalSpacing) {
                                WeightChartView(
                                    entries: entries,
                                    targetWeight: targetWeight,
                                    goalType: userGoalType,
                                    weightUnit: userWeightUnit
                                )
                                .frame(maxWidth: .infinity, alignment: .top)
                                .id("weightChart")

                                BMIChartView(
                                    entries: entries,
                                    height: userHeight,
                                    targetWeight: targetWeight,
                                    weightUnit: userWeightUnit,
                                    heightUnit: userHeightUnit
                                )
                                .frame(maxWidth: .infinity, alignment: .top)
                                .id("bmiChart")
                            }
                        } else {
                            WeightChartView(
                                entries: entries,
                                targetWeight: targetWeight,
                                goalType: userGoalType,
                                weightUnit: userWeightUnit
                            )
                            .id("weightChart")

                            BMIChartView(
                                entries: entries,
                                height: userHeight,
                                targetWeight: targetWeight,
                                weightUnit: userWeightUnit,
                                heightUnit: userHeightUnit
                            )
                            .id("bmiChart")
                        }

                        // Consolidated Medical Disclaimer Footer
                        Text("Bilgilendirme amaçlıdır; tıbbi teşhis veya klinik tavsiye niteliği taşımaz.")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .scenePadding(.horizontal)
                    .padding(.vertical, 16)
                }
                .onAppear {
                    #if DEBUG
                    if CommandLine.arguments.contains("--scroll-charts") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation {
                                proxy.scrollTo("weightChart", anchor: .top)
                            }
                        }
                    }
                    if CommandLine.arguments.contains("--scroll-bmi") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation {
                                proxy.scrollTo("bmiChart", anchor: .top)
                            }
                        }
                    }
                    #endif
                }
            }
            .background(Color.heftAdaptiveCanvas(colorScheme).ignoresSafeArea())
            .navigationTitle(greetingTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Ayarlar", systemImage: "gearshape")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                    }
                    .accessibilityLabel("Ayarlar")
                }
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAddWeight) {
                AddWeightSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .alert("Hata", isPresented: $showSaveError) {
                Button("Tamam") {}
            } message: {
                Text("Kayıt sırasında bir hata oluştu. Lütfen tekrar dene.")
            }
            .onAppear {
                #if DEBUG
                if CommandLine.arguments.contains("--open-add-weight") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingAddWeight = true
                    }
                }
                if CommandLine.arguments.contains("--open-settings") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingSettings = true
                    }
                }
                if let idx = CommandLine.arguments.firstIndex(of: "--set-name"), idx + 1 < CommandLine.arguments.count {
                    let testName = CommandLine.arguments[idx + 1]
                    if let p = profile, p.name != testName {
                        p.name = testName
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save profile name: \(error)")
                            showSaveError = true
                        }
                    }
                }
                #endif
            }
        }
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    DashboardView()
        .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    DashboardView()
        .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
}
