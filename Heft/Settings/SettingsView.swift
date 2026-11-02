//
//  SettingsView.swift
//  Heft
//
//  Settings screen to adjust profile, weight targets (lose vs gain), HealthKit sync, and weigh-in schedule.
//

import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.heftAccent) private var accent
    @Environment(\.heftAccentFill) private var accentFill
    @Query private var profiles: [UserProfile]
    @Query(sort: \WeightEntry.date, order: .reverse) private var existingEntries: [WeightEntry]

    @ScaledMetric(relativeTo: .body) private var inputFieldMinWidth: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var inputFieldMaxWidth: CGFloat = 85

    @AppStorage("heft_notifications_enabled") private var notificationsEnabled = false

    @State private var nameText = ""
    @State private var heightText = ""
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 10
    @State private var ageText = ""
    @State private var gender: Gender = .male
    @State private var goalType: GoalType = .lose
    @State private var targetWeightText = ""
    @State private var weightUnit: WeightUnit = .kg
    @State private var heightUnit: HeightUnit = .cm
    @State private var weighInFrequency: WeighInFrequency = .weekly
    @State private var weighInDays: [Int] = [2]
    @State private var weighInDay = 2
    @State private var weighInTime = Date()
    @State private var isRemindersOn = false
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var isHandlingReminderToggle = false
    @State private var isHealthKitSyncEnabled = HealthKitService.shared.isSyncEnabled
    @State private var isImportingHealthKit = false
    @State private var importResultAlert = false
    @State private var importCount = 0
    @State private var isExportingHealthKit = false
    @State private var exportResultAlert = false
    @State private var exportCount = 0
    @State private var showPrivacyPolicy = false
    @State private var showSaveError = false
    @State private var showDeleteAllDataAlert = false
    @State private var isLoaded = false
    @State private var saveSuccessTrigger = false
    @State private var deleteAllTrigger = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, height, age, targetWeight
    }

    private var profile: UserProfile? {
        profiles.first
    }

    private var heightValue: Double? {
        HeftFormat.parseDouble(heightText)
    }

    private var isHeightValid: Bool {
        if heightUnit == .ftIn {
            return heightFeet >= 3 && heightFeet <= 8
        }
        guard let h = heightValue else { return false }
        return h >= 50 && h <= 300
    }

    private var ageValue: Int? {
        Int(ageText)
    }

    private var isAgeValid: Bool {
        guard let a = ageValue else { return false }
        return a >= 1 && a <= 120
    }

    private var targetWeightValue: Double? {
        HeftFormat.parseDouble(targetWeightText)
    }

    private var isTargetWeightValid: Bool {
        guard let w = targetWeightValue else { return false }
        let kg = (weightUnit == .lbs) ? UnitConverter.lbsToKg(w) : w
        return kg >= 20 && kg <= 500
    }

    private var isValid: Bool {
        isHeightValid && isAgeValid && isTargetWeightValid
    }

    var body: some View {
        ScrollViewReader { proxy in
            Form {
                profileSection
                unitsSection
                goalSection
                healthKitSection
                scheduleSection
                    .id("scheduleSection")
                legalAndPrivacySection
                dangerZoneSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.heftAdaptiveCanvas(colorScheme).ignoresSafeArea())
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDismissToolbar(isFocused: Binding(
                get: { focusedField != nil },
                set: { if !$0 { focusedField = nil } }
            ))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveSettings()
                    }
                    .disabled(!isValid)
                    .font(.heftBodySemibold)
                    .foregroundStyle(isValid ? accent : Color.secondary)
                }
            }
            .onAppear {
                loadCurrentProfile()
                refreshNotificationStatus()
                #if DEBUG
                if CommandLine.arguments.contains("--scroll-schedule") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo("scheduleSection", anchor: .top)
                        }
                    }
                }
                #endif
            }
            .onDisappear {
                focusedField = nil
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshNotificationStatus()
                }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("Hata", isPresented: $showSaveError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("İşlem sırasında bir hata oluştu. Lütfen tekrar dene.")
        }
        .alert("İçe Aktarma Tamamlandı", isPresented: $importResultAlert) {
            Button("Tamam") {}
        } message: {
            if importCount > 0 {
                Text("\(importCount) adet yeni tartım Apple Sağlık'tan Heft'e aktarıldı.")
            } else {
                Text("Apple Sağlık'ta içe aktarılacak yeni bir tartım bulunamadı.")
            }
        }
        .alert("Dışa Aktarma Tamamlandı", isPresented: $exportResultAlert) {
            Button("Tamam") {}
        } message: {
            Text("\(exportCount) adet tartım kaydı Apple Sağlık'a başarıyla aktarıldı.")
        }
        .sensoryFeedback(.success, trigger: saveSuccessTrigger)
        .sensoryFeedback(.warning, trigger: deleteAllTrigger)
        .alert("Tüm Verileri Sil", isPresented: $showDeleteAllDataAlert) {
            Button("Tüm Verileri Sil", role: .destructive) {
                deleteAllData()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Tüm kilo kayıtların, profil bilgilerin, ayarların ve Heft tarafından Apple Sağlık'a yazılan tartım kayıtları kalıcı olarak silinecek. Bu işlem geri alınamaz.")
        }
    }

    @ViewBuilder
    private func rowLabel(_ title: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(accent)
            Text(title)
                .font(.heftBody)
                .foregroundStyle(Color.primary)
        }
    }

    @ViewBuilder
    private var profileSection: some View {
        Section {
            // Name
            ViewThatFits(in: .horizontal) {
                HStack {
                    rowLabel("İsim", systemImage: "person.crop.circle")
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                    TextField("Adın", text: $nameText)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.trailing)
                        .font(.heftListItem)
                        .frame(minWidth: 100, maxWidth: 180)
                        .focused($focusedField, equals: .name)
                }

                VStack(alignment: .leading, spacing: 6) {
                    rowLabel("İsim", systemImage: "person.crop.circle")
                    TextField("Adın", text: $nameText)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .font(.heftListItem)
                        .focused($focusedField, equals: .name)
                }
            }

            // Height
            ViewThatFits(in: .horizontal) {
                HStack {
                    rowLabel("Boy", systemImage: "ruler")
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                    if heightUnit == .cm {
                        TextField("175", text: $heightText)
                            .textFieldStyle(.plain)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.heftListItem)
                            .frame(minWidth: inputFieldMinWidth, maxWidth: inputFieldMaxWidth)
                            .padding(.vertical, 4)
                            .focused($focusedField, equals: .height)
                        Text("cm")
                            .font(.heftMeta)
                            .foregroundStyle(Color.secondary)
                    } else {
                        HStack(spacing: 8) {
                            Picker("", selection: $heightFeet) {
                                ForEach(3...8, id: \.self) { ft in
                                    Text("\(ft) ft").tag(ft)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accent)

                            Picker("", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch) in").tag(inch)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accent)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    rowLabel("Boy", systemImage: "ruler")
                    if heightUnit == .cm {
                        HStack {
                            TextField("175", text: $heightText)
                                .textFieldStyle(.plain)
                                .keyboardType(.numberPad)
                                .font(.heftListItem)
                                .focused($focusedField, equals: .height)
                            Text("cm")
                                .font(.heftMeta)
                                .foregroundStyle(Color.secondary)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Picker("", selection: $heightFeet) {
                                ForEach(3...8, id: \.self) { ft in
                                    Text("\(ft) ft").tag(ft)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accent)

                            Picker("", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch) in").tag(inch)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accent)
                        }
                    }
                }
            }

            if heightUnit == .cm && !heightText.isEmpty && !isHeightValid {
                Label("Boy 50 ile 300 cm arasında olmalıdır.", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.heftError)
            }

            // Age
            ViewThatFits(in: .horizontal) {
                HStack {
                    rowLabel("Yaş", systemImage: "calendar")
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                    TextField("28", text: $ageText)
                        .textFieldStyle(.plain)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.heftListItem)
                        .frame(minWidth: inputFieldMinWidth, maxWidth: inputFieldMaxWidth)
                        .padding(.vertical, 4)
                        .focused($focusedField, equals: .age)
                }

                VStack(alignment: .leading, spacing: 6) {
                    rowLabel("Yaş", systemImage: "calendar")
                    TextField("28", text: $ageText)
                        .textFieldStyle(.plain)
                        .keyboardType(.numberPad)
                        .font(.heftListItem)
                        .focused($focusedField, equals: .age)
                }
            }

            if !ageText.isEmpty && !isAgeValid {
                Label("Yaş 1 ile 120 arasında olmalıdır.", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.heftError)
            }

            // Gender
            Picker(selection: $gender) {
                Label(Gender.male.label, systemImage: "figure.stand").tag(Gender.male)
                Label(Gender.female.label, systemImage: "figure.stand.dress").tag(Gender.female)
            } label: {
                rowLabel("Cinsiyet", systemImage: "person.fill")
            }
        } header: {
            Text("PROFİL")
                .heftEyebrowStyle()
        }
    }

    @ViewBuilder
    private var unitsSection: some View {
        Section {
            // Weight Unit
            HStack {
                rowLabel("Ağırlık Birimi", systemImage: "scalemass")
                Spacer()
                Picker("", selection: $weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.localizedName).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .tint(accent)
            }
            .onChange(of: weightUnit) { oldUnit, newUnit in
                if oldUnit != newUnit, let currentVal = targetWeightValue {
                    let kg = (oldUnit == .lbs) ? UnitConverter.lbsToKg(currentVal) : currentVal
                    let converted = (newUnit == .lbs) ? UnitConverter.kgToLbs(kg) : kg
                    targetWeightText = HeftFormat.weight(converted)
                }
            }

            // Height Unit
            HStack {
                rowLabel("Boy Birimi", systemImage: "ruler")
                Spacer()
                Picker("", selection: $heightUnit) {
                    ForEach(HeightUnit.allCases) { unit in
                        Text(unit.localizedName).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .tint(accent)
            }
            .onChange(of: heightUnit) { oldUnit, newUnit in
                if oldUnit != newUnit {
                    if newUnit == .ftIn, let cm = heightValue {
                        let (ft, inch) = UnitConverter.cmToFtIn(cm)
                        heightFeet = ft
                        heightInches = Int(inch.rounded())
                    } else if newUnit == .cm {
                        let cm = UnitConverter.ftInToCm(feet: heightFeet, inches: Double(heightInches))
                        heightText = HeftFormat.integer(cm)
                    }
                }
            }
        } header: {
            Text("BİRİMLER")
                .heftEyebrowStyle()
        }
    }

    @ViewBuilder
    private var goalSection: some View {
        Section {
            Picker(selection: $goalType) {
                Label(GoalType.lose.fullLabel, systemImage: "flame.fill").tag(GoalType.lose)
                Label(GoalType.maintain.fullLabel, systemImage: "equal.circle.fill").tag(GoalType.maintain)
                Label(GoalType.gain.fullLabel, systemImage: "figure.strengthtraining.traditional").tag(GoalType.gain)
            } label: {
                rowLabel("Hedef Türü", systemImage: "flag.fill")
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    rowLabel("Hedef Kilo", systemImage: "target")
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                    TextField("70,0", text: $targetWeightText)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.heftListItem)
                        .frame(minWidth: inputFieldMinWidth, maxWidth: inputFieldMaxWidth)
                        .padding(.vertical, 4)
                        .focused($focusedField, equals: .targetWeight)
                    Text(weightUnit.label)
                        .font(.heftMeta)
                        .foregroundStyle(Color.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    rowLabel("Hedef Kilo", systemImage: "target")
                    HStack {
                        TextField("70,0", text: $targetWeightText)
                            .textFieldStyle(.plain)
                            .keyboardType(.decimalPad)
                            .font(.heftListItem)
                            .focused($focusedField, equals: .targetWeight)
                        Text(weightUnit.label)
                            .font(.heftMeta)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }

            if !targetWeightText.isEmpty && !isTargetWeightValid {
                let rangeStr = weightUnit == .lbs ? "44 - 1100 lbs" : "20 - 500 kg"
                Label(String(localized: "Hedef kilo \(rangeStr) arasında olmalıdır.", comment: "Target weight bounds error"), systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.heftError)
            }
        } header: {
            Text("HEDEF")
                .heftEyebrowStyle()
        } footer: {
            Text(goalType.explanation)
                .font(.heftMeta)
                .foregroundStyle(Color.secondary)
        }
    }

    @ViewBuilder
    private var healthKitSection: some View {
        Section {
            Toggle(isOn: $isHealthKitSyncEnabled) {
                Label("Sağlık ile Eşzamanla", systemImage: "heart.fill")
                    .font(.heftBody)
            }
            .tint(accent)
            .onChange(of: isHealthKitSyncEnabled) { _, newValue in
                if newValue {
                    Task {
                        let authorized = await HealthKitService.shared.requestAuthorization()
                        await MainActor.run {
                            HealthKitService.shared.isSyncEnabled = authorized
                            if !authorized {
                                isHealthKitSyncEnabled = false
                            }
                        }
                    }
                } else {
                    HealthKitService.shared.isSyncEnabled = false
                }
            }

            Button {
                importFromHealthKit()
            } label: {
                HStack {
                    Label("Sağlık Verilerini İçe Aktar", systemImage: "arrow.down.doc")
                        .font(.heftBody)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if isImportingHealthKit {
                        ProgressView()
                    }
                }
            }
            .disabled(isImportingHealthKit)

            Button {
                exportToHealthKit()
            } label: {
                HStack {
                    Label("Heft Verilerini Apple Sağlık'a Aktar", systemImage: "arrow.up.doc")
                        .font(.heftBody)
                        .foregroundStyle(isHealthKitSyncEnabled ? Color.primary : Color.secondary)
                    Spacer()
                    if isExportingHealthKit {
                        ProgressView()
                    }
                }
            }
            .disabled(isExportingHealthKit || !isHealthKitSyncEnabled)
        } header: {
            Text("APPLE SAĞLIK (HEALTHKIT)")
                .heftEyebrowStyle()
        } footer: {
            Text("Heft'e kaydedilen tartımlar Apple Sağlık'a aktarılır. Dilersen geçmiş Apple Sağlık tartımlarını Heft'e aktarabilir veya Heft kayıtlarını Apple Sağlık'a gönderebilirsin.")
                .font(.heftMeta)
                .foregroundStyle(Color.secondary)
        }
    }

    @ViewBuilder
    private var legalAndPrivacySection: some View {
        Section {
            Button {
                showPrivacyPolicy = true
            } label: {
                HStack {
                    Label("Gizlilik Politikası", systemImage: "hand.raised.fill")
                        .font(.heftBody)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                }
            }

            Link(destination: URL(string: "https://efekoc.github.io/heft/privacy")!) {
                HStack {
                    Label("Web Sitesi Gizlilik Politikası", systemImage: "safari")
                        .font(.heftBody)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                }
            }
        } header: {
            Text("GİZLİLİK VE YASAL")
                .heftEyebrowStyle()
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tıbbi Sorumluluk Reddi:")
                    .font(.heftMetaSemibold)
                    .foregroundStyle(Color.primary)
                Text("Heft tıbbi bir teşhis veya tedavi cihazı değildir. Uygulamadaki BMI hesaplamaları ve hedef projeksiyonları genel bilgilendirme amaçlıdır. Herhangi bir beslenme veya kilo kontrol programına başlamadan önce mutlaka bir hekime danış.")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        Section {
            Toggle(isOn: $isRemindersOn) {
                rowLabel("Tartım Hatırlatıcısı", systemImage: isRemindersOn ? "bell.badge.fill" : "bell")
            }
            .tint(accent)
            .onChange(of: isRemindersOn) { _, newValue in
                guard isLoaded && !isHandlingReminderToggle else { return }
                handleReminderToggleChange(newValue)
            }

            if notificationAuthStatus == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.heftWarning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bildirim Ayarlarını Aç")
                                .font(.heftBodySemibold)
                                .foregroundStyle(Color.primary)
                            Text("Hatırlatıcı alabilmek için sistem ayarlarından Heft bildirimlerine izin ver.")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(accent)
                    }
                    .frame(minHeight: 44)
                }
            }

            Picker("Sıklık", selection: $weighInFrequency) {
                ForEach(WeighInFrequency.allCases) { freq in
                    Text(freq.label).tag(freq)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 2)

            switch weighInFrequency {
            case .daily:
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(accent)
                    Text("Her sabah seçtiğin saatte hatırlatıcı alacaksın.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                .padding(.vertical, 2)

            case .weekly:
                Picker(selection: Binding(
                    get: { weighInDays.first ?? weighInDay },
                    set: {
                        weighInDay = $0
                        weighInDays = [$0]
                    }
                )) {
                    ForEach(WeighInSchedule.days) { day in
                        Text(day.label).tag(day.weekday)
                    }
                } label: {
                    Label("Tartım Günü", systemImage: "calendar.badge.clock")
                        .font(.heftBody)
                }

            case .custom:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tartılacağın Günler")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) {
                            ForEach(WeighInSchedule.days) { day in
                                settingsDayButton(day: day, fixedHorizontal: true)
                            }
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 6)], spacing: 6) {
                            ForEach(WeighInSchedule.days) { day in
                                settingsDayButton(day: day, fixedHorizontal: false)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            DatePicker(selection: $weighInTime, displayedComponents: .hourAndMinute) {
                Label("Tartım Saati", systemImage: "clock")
                    .font(.heftBody)
            }
        } header: {
            Text("TARTIM TAKVİMİ")
                .heftEyebrowStyle()
        } footer: {
            Text("Tartım sıklığı ve saati değiştirildiğinde hatırlatıcılar otomatik olarak güncellenir.")
                .font(.heftMeta)
                .foregroundStyle(Color.secondary)
        }
    }

    private func refreshNotificationStatus() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            let pending = await center.pendingNotificationRequests()
            let hasPending = pending.contains { $0.identifier.hasPrefix(NotificationService.notificationPrefix) }

            await MainActor.run {
                isHandlingReminderToggle = true
                notificationAuthStatus = settings.authorizationStatus
                let isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
                if isAuthorized {
                    if !UserDefaults.standard.bool(forKey: "heft_notifications_pref_initialized") {
                        notificationsEnabled = hasPending
                        UserDefaults.standard.set(true, forKey: "heft_notifications_pref_initialized")
                    }
                    isRemindersOn = notificationsEnabled
                } else {
                    isRemindersOn = false
                }
                isHandlingReminderToggle = false
            }
        }
    }

    private func handleReminderToggleChange(_ enabled: Bool) {
        if enabled {
            Task {
                let center = UNUserNotificationCenter.current()
                let settings = await center.notificationSettings()
                switch settings.authorizationStatus {
                case .notDetermined:
                    let granted = await NotificationService.requestPermission()
                    let updated = await center.notificationSettings()
                    await MainActor.run {
                        isHandlingReminderToggle = true
                        notificationAuthStatus = updated.authorizationStatus
                        if granted {
                            isRemindersOn = true
                        } else {
                            isRemindersOn = false
                        }
                        isHandlingReminderToggle = false
                    }
                case .authorized, .provisional, .ephemeral:
                    await MainActor.run {
                        notificationAuthStatus = settings.authorizationStatus
                    }
                case .denied:
                    await MainActor.run {
                        isHandlingReminderToggle = true
                        notificationAuthStatus = .denied
                        isRemindersOn = false
                        isHandlingReminderToggle = false
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    @ViewBuilder
    private func settingsDayButton(day: ScheduleDayItem, fixedHorizontal: Bool) -> some View {
        let isSelected = weighInDays.contains(day.weekday)
        Button {
            toggleSettingsDay(day.weekday)
        } label: {
            Text(day.shortLabel)
                .font(.caption.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .fixedSize(horizontal: fixedHorizontal, vertical: false)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? accentFill : Color.heftSurfaceSub)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func toggleSettingsDay(_ day: Int) {
        if weighInDays.contains(day) {
            if weighInDays.count > 1 {
                weighInDays.removeAll { $0 == day }
            }
        } else {
            weighInDays.append(day)
            weighInDays.sort { a, b in
                let orderA = a == 1 ? 8 : a
                let orderB = b == 1 ? 8 : b
                return orderA < orderB
            }
        }
        weighInDay = weighInDays.first ?? 2
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @ViewBuilder
    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAllDataAlert = true
            } label: {
                HStack {
                    Label("Tüm Verileri Sil", systemImage: "trash.fill")
                        .font(.heftBody)
                        .foregroundStyle(Color.heftError)
                    Spacer()
                }
            }
        } header: {
            Text("VERİ YÖNETİMİ")
                .heftEyebrowStyle()
        } footer: {
            Text("Tüm kilo kayıtların, profil bilgilerin, bildirim ayarların ve Heft tarafından Apple Sağlık'a yazılan tartım kayıtları kalıcı olarak silinir. Bu işlem geri alınamaz.")
                .font(.heftMeta)
                .foregroundStyle(Color.secondary)
        }
    }

    private func loadCurrentProfile() {
        guard let p = profile else {
            isLoaded = true
            return
        }
        nameText = p.name
        weightUnit = p.weightUnit
        heightUnit = p.heightUnit
        heightText = "\(Int(p.height))"
        let (ft, inch) = UnitConverter.cmToFtIn(p.height)
        heightFeet = ft
        heightInches = Int(inch.rounded())
        ageText = "\(p.age)"
        gender = p.gender
        goalType = p.goalType
        let displayTarget = (p.weightUnit == .lbs) ? UnitConverter.kgToLbs(p.targetWeight) : p.targetWeight
        targetWeightText = HeftFormat.weight(displayTarget)
        weighInFrequency = p.weighInFrequency
        weighInDays = p.weighInDaysList
        weighInDay = p.weighInDay

        var comps = DateComponents()
        comps.hour = p.weighInHour
        comps.minute = p.weighInMinute
        weighInTime = Calendar.current.date(from: comps) ?? Date()

        DispatchQueue.main.async {
            isLoaded = true
        }
    }

    private func saveSettings() {
        let effectiveHeight: Double = {
            if heightUnit == .ftIn {
                return UnitConverter.ftInToCm(feet: heightFeet, inches: Double(heightInches))
            }
            return heightValue ?? 175.0
        }()

        guard let tw = targetWeightValue else { return }
        let effectiveTargetWeight: Double = (weightUnit == .lbs) ? UnitConverter.lbsToKg(tw) : tw

        guard let a = ageValue, isHeightValid && isTargetWeightValid else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: weighInTime)
        let minute = calendar.component(.minute, from: weighInTime)
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let p = profile {
            p.name = trimmedName
            p.height = effectiveHeight
            p.age = a
            p.gender = gender
            p.goalType = goalType
            p.targetWeight = effectiveTargetWeight
            p.weightUnit = weightUnit
            p.heightUnit = heightUnit
            p.weighInFrequency = weighInFrequency
            p.weighInDaysList = weighInDays
            p.weighInDay = weighInDays.first ?? weighInDay
            p.weighInHour = hour
            p.weighInMinute = minute
        } else {
            for existing in profiles {
                modelContext.delete(existing)
            }
            let newProfile = UserProfile(
                name: trimmedName,
                height: effectiveHeight,
                age: a,
                gender: gender,
                initialWeight: effectiveTargetWeight,
                targetWeight: effectiveTargetWeight,
                goalType: goalType,
                weighInDay: weighInDays.first ?? weighInDay,
                weighInHour: hour,
                weighInMinute: minute,
                rawWeighInFrequency: weighInFrequency.rawValue,
                rawWeighInDays: weighInDays.map(String.init).joined(separator: ","),
                rawWeightUnit: weightUnit.rawValue,
                rawHeightUnit: heightUnit.rawValue,
                onboardingCompleted: true
            )
            modelContext.insert(newProfile)
        }

        do {
            try modelContext.save()
            saveSuccessTrigger.toggle()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            let shouldSchedule = isRemindersOn
            UserDefaults.standard.set(true, forKey: "heft_notifications_pref_initialized")
            notificationsEnabled = shouldSchedule

            Task {
                if shouldSchedule {
                    await NotificationService.scheduleNotifications(
                        frequency: weighInFrequency,
                        days: weighInDays,
                        hour: hour,
                        minute: minute,
                        userName: trimmedName
                    )
                } else {
                    await NotificationService.removeAllWeighInNotifications()
                }
            }
            focusedField = nil
            dismiss()
        } catch {
            showSaveError = true
        }
    }

    private func importFromHealthKit() {
        guard !isImportingHealthKit else { return }
        isImportingHealthKit = true

        Task {
            let authorized = await HealthKitService.shared.requestAuthorization()
            guard authorized else {
                await MainActor.run {
                    isImportingHealthKit = false
                }
                return
            }

            await MainActor.run {
                HealthKitService.shared.isSyncEnabled = true
                isHealthKitSyncEnabled = true
            }

            let records = await HealthKitService.shared.fetchHistoricalWeights()
            let calendar = Calendar.current
            var newCount = 0

            await MainActor.run {
                for record in records {
                    let exists = existingEntries.contains { calendar.isDate($0.date, inSameDayAs: record.date) }
                    if !exists {
                        let entry = WeightEntry(date: record.date, weight: record.weightKg, healthKitUUID: record.uuid)
                        modelContext.insert(entry)
                        newCount += 1
                    }
                }

                if newCount > 0 {
                    do {
                        try modelContext.save()
                    } catch {
                        showSaveError = true
                    }
                }

                importCount = newCount
                isImportingHealthKit = false
                importResultAlert = true
            }
        }
    }

    private func exportToHealthKit() {
        guard !isExportingHealthKit else { return }
        isExportingHealthKit = true

        Task {
            let data = existingEntries.map { (date: $0.date, weightKg: $0.weight) }
            let count = await HealthKitService.shared.exportWeights(entries: data)
            await MainActor.run {
                exportCount = count
                isExportingHealthKit = false
                exportResultAlert = true
            }
        }
    }

    private func deleteAllData() {
        let allEntries = (try? modelContext.fetch(FetchDescriptor<WeightEntry>())) ?? []
        let samplesToDelete: [(uuid: UUID?, date: Date)] = allEntries.map { (uuid: $0.healthKitUUID, date: $0.date) }

        for entry in allEntries {
            modelContext.delete(entry)
        }

        let allProfiles = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
        for profile in allProfiles {
            modelContext.delete(profile)
        }

        do {
            try modelContext.save()
        } catch {
            showSaveError = true
            return
        }

        deleteAllTrigger.toggle()
        notificationsEnabled = false
        isRemindersOn = false
        isHealthKitSyncEnabled = false

        Task {
            await NotificationService.removeAllWeighInNotifications()
            if !samplesToDelete.isEmpty {
                HealthKitService.shared.isSyncEnabled = true
                for sample in samplesToDelete {
                    await HealthKitService.shared.deleteWeight(uuid: sample.uuid, on: sample.date)
                }
            }
            HealthKitService.shared.isSyncEnabled = false
        }

        dismiss()
    }
}

// MARK: - In-App Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.heftAccent) private var accent

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.title2)
                                .foregroundStyle(accent)
                            Text("Gizlilik ve Güvenlik İlkelerimiz")
                                .font(.heftCardTitle)
                        }

                        Text("Heft, kişisel sağlık verilerinin gizliliğine ve güvenliğine en üst düzeyde önem verir.")
                            .font(.heftBody)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                    // Policy Sections
                    policyCard(
                        icon: "iphone.gen3",
                        title: "1. Tamamen Cihaz İçi (On-Device) Depolama",
                        content: "Heft'e kaydettiğin tüm bilgiler (kilo geçmişi, boy, yaş, hedefler ve hatırlatıcı saatleri) yalnızca cihazının yerel depolama alanında SwiftData kullanılarak saklanır. Verilerin hiçbir harici sunucuya veya bulut veritabanına aktarılmaz."
                    )

                    policyCard(
                        icon: "heart.fill",
                        title: "2. Apple Sağlık (HealthKit) Kullanımı",
                        content: "Sağlık izinlerini onayladığında, Heft yalnızca vücut ağırlığı (Body Mass) verilerini Apple Sağlık uygulaması ile iki yönlü eşzamanlar. Sağlık verilerin reklam, pazarlama veya veri madenciliği amacıyla asla kullanılmaz ve üçüncü taraflarla paylaşılmaz."
                    )

                    policyCard(
                        icon: "nosign",
                        title: "3. Takip ve Reklam Bulunmaz",
                        content: "Uygulama içerisinde kullanıcı davranışlarını izleyen hiçbir üçüncü taraf analiz (analytics) aracı veya reklam ağı bulunmamaktadır. Verilerin takip edilmez (NSPrivacyTracking: false)."
                    )

                    policyCard(
                        icon: "trash.fill",
                        title: "4. Verileri Silme ve Kontrol Hakkı",
                        content: "Dilediğin anda tüm kilo kayıtlarını tek tek silebilir veya Ayarlar > Veri Yönetimi üzerinden profilini ve tüm kayıtlarını kalıcı olarak sıfırlayabilirsin."
                    )

                    policyCard(
                        icon: "cross.case.fill",
                        title: "5. Tıbbi Feragatname (Medical Disclaimer)",
                        content: "Heft tıbbi bir teşhis, klinik tedavi veya profesyonel sağlık tavsiyesi aracı değildir. BMI değerleri ve hedef tahminleri genel bilgilendirme amaçlıdır. Herhangi bir kilo verme, alma veya beslenme programına başlamadan önce mutlaka bir doktora danış."
                    )

                    Link(destination: URL(string: "https://efekoc.github.io/heft/privacy")!) {
                        HStack {
                            Text("Web Sitemizdeki Gizlilik Politikasını İncele")
                                .font(.heftBodySemibold)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .foregroundStyle(accent)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .background(Color.heftAdaptiveCanvas(colorScheme).ignoresSafeArea())
            .navigationTitle("Gizlilik Politikası")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .font(.heftBodySemibold)
                    .foregroundStyle(accent)
                }
            }
        }
    }

    @ViewBuilder
    private func policyCard(icon: String, title: LocalizedStringKey, content: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(accent)
                Text(title)
                    .font(.heftBodySemibold)
                    .foregroundStyle(Color.primary)
            }

            Text(content)
                .font(.heftMeta)
                .foregroundStyle(Color.secondary)
                .lineSpacing(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [UserProfile.self, WeightEntry.self], inMemory: true)
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [UserProfile.self, WeightEntry.self], inMemory: true)
}
