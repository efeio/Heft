//
//  AllSetStep.swift
//  Heft
//
//  Onboarding Step 5: Summary review and initial SwiftData commit.
//

import SwiftUI
import SwiftData

struct AllSetStep: View {
    let name: String
    let height: Double
    let age: Int
    let gender: Gender
    let currentWeight: Double
    let targetWeight: Double
    let goalType: GoalType
    let weighInFrequency: WeighInFrequency
    let weighInDays: [Int]
    let weighInDay: Int
    let weighInTime: Date
    let wantsNotifications: Bool
    var onBack: (() -> Void)? = nil
    let onFinish: () -> Void

    init(
        name: String,
        height: Double,
        age: Int,
        gender: Gender,
        currentWeight: Double,
        targetWeight: Double,
        goalType: GoalType,
        weighInFrequency: WeighInFrequency = .weekly,
        weighInDays: [Int]? = nil,
        weighInDay: Int = 2,
        weighInTime: Date,
        wantsNotifications: Bool = false,
        onBack: (() -> Void)? = nil,
        onFinish: @escaping () -> Void
    ) {
        self.name = name
        self.height = height
        self.age = age
        self.gender = gender
        self.currentWeight = currentWeight
        self.targetWeight = targetWeight
        self.goalType = goalType
        self.weighInFrequency = weighInFrequency
        self.weighInDays = weighInDays ?? [weighInDay]
        self.weighInDay = weighInDay
        self.weighInTime = weighInTime
        self.wantsNotifications = wantsNotifications
        self.onBack = onBack
        self.onFinish = onFinish
    }

    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 72
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 18

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    @Environment(\.modelContext) private var modelContext
    @State private var isSaving = false
    @State private var showSaveError = false

    private var scheduleSummaryText: String {
        switch weighInFrequency {
        case .daily:
            return "\(String(localized: "Her Gün")) • \(timeString)"
        case .weekly:
            let dayName = WeighInSchedule.days.first(where: { $0.weekday == (weighInDays.first ?? weighInDay) })?.label ?? String(localized: "Pazartesi")
            return "\(dayName) • \(timeString)"
        case .custom:
            let dayNames = weighInDays.compactMap { d in
                WeighInSchedule.shortDayName(for: d)
            }.joined(separator: ", ")
            return "\(dayNames.isEmpty ? String(localized: "Pazartesi") : dayNames) • \(timeString)"
        }
    }

    private var timeString: String {
        Self.timeFormatter.string(from: weighInTime)
    }

    private var bmiValueText: String {
        guard let bmi = BMICalculator.calculate(weightKg: currentWeight, heightCm: height) else { return "—" }
        return HeftFormat.weight(bmi)
    }

    private var bmiCategoryText: String {
        guard let bmi = BMICalculator.calculate(weightKg: currentWeight, heightCm: height) else { return "" }
        return "(\(BMICalculator.category(for: bmi)))"
    }

    var body: some View {
        OnboardingStepContainer(
            currentStep: 5,
            totalSteps: 5,
            buttonTitle: String(localized: "Hadi Başlayalım", comment: "Let's start button"),
            isButtonEnabled: !isSaving,
            onBack: onBack,
            onButtonTap: completeOnboarding
        ) {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(Color.heftTeal.opacity(0.12))
                            .frame(width: circleSize, height: circleSize)

                        Image(systemName: "checkmark")
                            .font(.title.weight(.bold))
                            .foregroundStyle(Color.heftTeal)
                    }
                    .padding(.top, 16)
                    .accessibilityHidden(true)

                    // Title & Subtitle
                    VStack(spacing: 8) {
                        Text("Her Şey Hazır!")
                            .font(.heftScreenTitle)

                        Text("Bilgilerin kaydedildi. Yolculuğun şimdi başlıyor.")
                            .font(.heftBody)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Summary Card
                    VStack(spacing: 16) {
                        SummaryRow(label: String(localized: "İSİM"), value: name.isEmpty ? "—" : name)
                        Divider().overlay(Color.heftDivider)
                        SummaryRow(label: String(localized: "HEDEF TÜRÜ"), value: goalType == .gain ? String(localized: "Kilo Almak (Bulk/Kas)") : (goalType == .maintain ? String(localized: "Kilo Korumak (Mevcut Form)") : String(localized: "Kilo Vermek (Fit/Yağ Yakımı)")))
                        Divider().overlay(Color.heftDivider)
                        SummaryRow(label: String(localized: "BOY & YAŞ"), value: "\(HeftFormat.integer(height)) cm • \(age) \(String(localized: "yaş"))")
                        Divider().overlay(Color.heftDivider)
                        SummaryRow(label: String(localized: "CİNSİYET"), value: gender.label)
                        Divider().overlay(Color.heftDivider)
                        SummaryRow(label: String(localized: "BAŞLANGIÇ KİLOSU"), value: HeftFormat.weightKg(currentWeight))
                        Divider().overlay(Color.heftDivider)
                        SummaryRow(label: String(localized: "HEDEF KİLO"), value: HeftFormat.weightKg(targetWeight))
                        Divider().overlay(Color.heftDivider)
                        SummaryRow(label: String(localized: "BAŞLANGIÇ BMI"), value: "\(bmiValueText) \(bmiCategoryText)")
                        Divider().overlay(Color.heftDivider)
                        SummaryRow(label: String(localized: "TARTIM TAKVİMİ"), value: scheduleSummaryText)
                    }
                    .heftCard(padding: cardPadding)

                    Spacer(minLength: 16)
                }
            }
        }
        .alert("Hata", isPresented: $showSaveError) {
            Button("Tamam") {}
        } message: {
            Text("Kayıt sırasında bir hata oluştu. Lütfen tekrar dene.")
        }
    }

    private func completeOnboarding() {
        guard !isSaving else { return }
        isSaving = true

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: weighInTime)
        let minute = calendar.component(.minute, from: weighInTime)

        // 1. Delete any existing UserProfile to enforce singleton
        let existing = try? modelContext.fetch(FetchDescriptor<UserProfile>())
        existing?.forEach { modelContext.delete($0) }

        // 2. Create and insert UserProfile
        let profile = UserProfile(
            name: name,
            height: height,
            age: age,
            gender: gender,
            initialWeight: currentWeight,
            targetWeight: targetWeight,
            goalType: goalType,
            weighInDay: weighInDays.first ?? weighInDay,
            weighInHour: hour,
            weighInMinute: minute,
            rawWeighInFrequency: weighInFrequency.rawValue,
            rawWeighInDays: weighInDays.map(String.init).joined(separator: ","),
            onboardingCompleted: true
        )
        modelContext.insert(profile)

        // 3. Create and insert first WeightEntry
        let initialEntry = WeightEntry(date: Date(), weight: currentWeight)
        modelContext.insert(initialEntry)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save initial context: \(error)")
            showSaveError = true
            isSaving = false
            return
        }

        // 4. Schedule repeating notifications only if opted in during ScheduleStep
        UserDefaults.standard.set(true, forKey: "heft_notifications_pref_initialized")
        UserDefaults.standard.set(wantsNotifications, forKey: "heft_notifications_enabled")
        Task {
            if wantsNotifications {
                await NotificationService.scheduleNotifications(
                    frequency: weighInFrequency,
                    days: weighInDays,
                    hour: hour,
                    minute: minute,
                    userName: name
                )
            } else {
                await NotificationService.removeAllWeighInNotifications()
            }
            await MainActor.run {
                onFinish()
            }
        }
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(label)
                    .heftEyebrowStyle()
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 8)
                Text(value)
                    .font(.heftListItem)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: true, vertical: false)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .heftEyebrowStyle()
                    .foregroundStyle(Color.secondary)
                Text(value)
                    .font(.heftListItem)
                    .foregroundStyle(Color.primary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    AllSetStep(
        name: "Efe",
        height: 178,
        age: 26,
        gender: .male,
        currentWeight: 78.5,
        targetWeight: 72.0,
        goalType: .lose,
        weighInDay: 2,
        weighInTime: Date(),
        onFinish: {}
    )
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    AllSetStep(
        name: "Efe",
        height: 178,
        age: 26,
        gender: .male,
        currentWeight: 78.5,
        targetWeight: 72.0,
        goalType: .lose,
        weighInDay: 2,
        weighInTime: Date(),
        onFinish: {}
    )
}
