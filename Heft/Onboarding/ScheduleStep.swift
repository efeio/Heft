//
//  ScheduleStep.swift
//  Heft
//
//  Onboarding Step 4: Weekly weigh-in schedule and notification request.
//

import SwiftUI

struct ScheduleDayItem: Identifiable, Hashable {
    let id: Int
    let label: String
    let shortLabel: String
    let weekday: Int // iOS Calendar weekday: 1 = Sunday, 2 = Monday, ...
}

enum WeighInSchedule {
    static let days: [ScheduleDayItem] = [
        ScheduleDayItem(id: 2, label: "Pazartesi", shortLabel: "Pzt", weekday: 2),
        ScheduleDayItem(id: 3, label: "Salı", shortLabel: "Sal", weekday: 3),
        ScheduleDayItem(id: 4, label: "Çarşamba", shortLabel: "Çar", weekday: 4),
        ScheduleDayItem(id: 5, label: "Perşembe", shortLabel: "Per", weekday: 5),
        ScheduleDayItem(id: 6, label: "Cuma", shortLabel: "Cum", weekday: 6),
        ScheduleDayItem(id: 7, label: "Cumartesi", shortLabel: "Cmt", weekday: 7),
        ScheduleDayItem(id: 1, label: "Pazar", shortLabel: "Paz", weekday: 1)
    ]

    static func shortDayName(for weekday: Int) -> String {
        days.first(where: { $0.weekday == weekday })?.shortLabel ?? ""
    }
}

struct ScheduleStep: View {
    @Binding var weighInFrequency: WeighInFrequency
    @Binding var weighInDays: [Int]
    @Binding var weighInTime: Date
    @Binding var wantsNotifications: Bool

    var onBack: (() -> Void)? = nil
    let onNext: () -> Void

    @Environment(\.heftAccent) private var accent
    @Environment(\.heftAccentFill) private var accentFill
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 54
    @ScaledMetric(relativeTo: .body) private var sectionSpacing: CGFloat = 20

    // Designated init
    init(
        weighInFrequency: Binding<WeighInFrequency>,
        weighInDays: Binding<[Int]>,
        weighInTime: Binding<Date>,
        wantsNotifications: Binding<Bool> = .constant(false),
        onBack: (() -> Void)? = nil,
        onNext: @escaping () -> Void
    ) {
        self._weighInFrequency = weighInFrequency
        self._weighInDays = weighInDays
        self._weighInTime = weighInTime
        self._wantsNotifications = wantsNotifications
        self.onBack = onBack
        self.onNext = onNext
    }

    // Backwards-compatible convenience init
    init(
        weighInDay: Binding<Int>,
        weighInTime: Binding<Date>,
        wantsNotifications: Binding<Bool> = .constant(false),
        onBack: (() -> Void)? = nil,
        onNext: @escaping () -> Void
    ) {
        self._weighInFrequency = .constant(.weekly)
        self._weighInDays = Binding(
            get: { [weighInDay.wrappedValue] },
            set: { weighInDay.wrappedValue = $0.first ?? 2 }
        )
        self._weighInTime = weighInTime
        self._wantsNotifications = wantsNotifications
        self.onBack = onBack
        self.onNext = onNext
    }

    private var reminderSubtitle: String {
        guard wantsNotifications else {
            return "Bildirimler kapalı. Dilediğinizde açabilirsiniz."
        }
        switch weighInFrequency {
        case .daily:
            return "Her sabah seçtiğiniz saatte nazik bir bildirim alacaksınız."
        case .weekly:
            return "Seçtiğiniz günde ve saatte nazik bir bildirim alacaksınız."
        case .custom:
            return "Seçtiğiniz günlerde ve saatte nazik bir bildirim alacaksınız."
        }
    }

    private func toggleDay(_ day: Int) {
        if weighInDays.contains(day) {
            // Prevent removing all days
            if weighInDays.count > 1 {
                weighInDays.removeAll { $0 == day }
            }
        } else {
            weighInDays.append(day)
            // Sort by standard week order starting Monday (2..7, 1)
            weighInDays.sort { a, b in
                let orderA = a == 1 ? 8 : a
                let orderB = b == 1 ? 8 : b
                return orderA < orderB
            }
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    var body: some View {
        OnboardingStepContainer(
            currentStep: 4,
            totalSteps: 5,
            buttonTitle: "İleri",
            isButtonEnabled: true,
            onBack: onBack,
            onButtonTap: onNext
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: sectionSpacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tartım Rutini")
                            .font(.heftScreenTitle)

                        Text("Düzenli tartılmak tutarlılık sağlar. Size en uygun tartım sıklığını ve saatini seçin.")
                            .font(.heftBody)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.top, 8)

                    // Schedule Toggle Card
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(accent.opacity(0.12))
                                    .frame(width: circleSize, height: circleSize)

                                Image(systemName: wantsNotifications ? "bell.badge.fill" : "bell")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(accent)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Tartım Hatırlatıcısı")
                                    .font(.heftCardTitle)

                                Text(reminderSubtitle)
                                    .font(.heftMeta)
                                    .foregroundStyle(Color.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $wantsNotifications)
                                .labelsHidden()
                                .tint(accent)
                                .onChange(of: wantsNotifications) { _, newValue in
                                    if newValue {
                                        Task {
                                            let granted = await NotificationService.requestPermission()
                                            if !granted {
                                                wantsNotifications = false
                                            }
                                        }
                                    }
                                }
                        }
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }

                    // Frequency Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TARTIM SIKLIĞI")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)

                        Picker("Sıklık", selection: $weighInFrequency) {
                            ForEach(WeighInFrequency.allCases) { freq in
                                Text(freq.label).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Dynamic Sub-section based on Frequency
                    switch weighInFrequency {
                    case .daily:
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(accent)
                                .padding(.top, 2)

                            Text("Öneri: Her sabah aç karnına tartılmak, vücudun günlük su dalgalanmalarını filtreler ve en gerçekçi kilo trendini sunar.")
                                .font(.heftMeta)
                                .foregroundStyle(Color.secondary)
                                .lineSpacing(2)

                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(accent.opacity(0.08))
                        }

                    case .weekly:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TARTIM GÜNÜ")
                                .heftEyebrowStyle()
                                .foregroundStyle(Color.secondary)

                            Picker("Tartım Günü", selection: Binding(
                                get: { weighInDays.first ?? 2 },
                                set: { weighInDays = [$0] }
                            )) {
                                ForEach(WeighInSchedule.days) { dayItem in
                                    Text(dayItem.label).tag(dayItem.weekday)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accent)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            }
                        }

                    case .custom:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TARTILACAĞINIZ GÜNLER")
                                .heftEyebrowStyle()
                                .foregroundStyle(Color.secondary)

                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 6) {
                                    ForEach(WeighInSchedule.days) { day in
                                        dayButton(day: day, fixedHorizontal: true)
                                    }
                                }

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 6)], spacing: 6) {
                                    ForEach(WeighInSchedule.days) { day in
                                        dayButton(day: day, fixedHorizontal: false)
                                    }
                                }
                            }
                        }
                    }

                    // Time Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TARTIM SAATİ")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)

                        DatePicker("", selection: $weighInTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 16)
            }
        }
    }

    @ViewBuilder
    private func dayButton(day: ScheduleDayItem, fixedHorizontal: Bool) -> some View {
        let isSelected = weighInDays.contains(day.weekday)
        Button {
            toggleDay(day.weekday)
        } label: {
            Text(day.shortLabel)
                .font(.caption.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .fixedSize(horizontal: fixedHorizontal, vertical: false)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? accentFill : Color.heftSurface)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}


// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    ScheduleStep(
        weighInDay: .constant(2),
        weighInTime: .constant(Date()),
        onNext: {}
    )
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    ScheduleStep(
        weighInDay: .constant(2),
        weighInTime: .constant(Date()),
        onNext: {}
    )
}
