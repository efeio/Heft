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
    @State private var ageText = ""
    @State private var gender: Gender = .male
    @State private var goalType: GoalType = .lose
    @State private var targetWeightText = ""
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
    @State private var showDiscardAlert = false
    @State private var showDeleteAllDataAlert = false
    @State private var hasUnsavedChanges = false
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
        Double(heightText.replacingOccurrences(of: ",", with: "."))
    }

    private var isHeightValid: Bool {
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
        Double(targetWeightText.replacingOccurrences(of: ",", with: "."))
    }

    private var isTargetWeightValid: Bool {
        guard let w = targetWeightValue else { return false }
        return w >= 20 && w <= 500
    }

    private var isValid: Bool {
        isHeightValid && isAgeValid && isTargetWeightValid
    }

    var body: some View {
        ScrollViewReader { proxy in
            Form {
                profileSection
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
            .navigationBarBackButtonHidden(hasUnsavedChanges)
            .toolbar {
                if hasUnsavedChanges {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Vazgeç") {
                            showDiscardAlert = true
                        }
                        .font(.heftBody)
                        .foregroundStyle(Color.secondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveSettings()
                    }
                    .disabled(!isValid)
                    .font(.heftBodySemibold)
                    .foregroundStyle(isValid ? accent : Color.secondary)
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .interactiveDismissDisabled(hasUnsavedChanges)
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
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshNotificationStatus()
                }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("Kaydedilmemiş Değişiklikler", isPresented: $showDiscardAlert) {
            Button("Değişiklikleri Sil", role: .destructive) {
                dismiss()
            }
            Button("Düzenlemeye Devam Et", role: .cancel) {}
        } message: {
            Text("Yaptığınız değişiklikler kaybolacak. Çıkmak istiyor musunuz?")
        }
        .alert("Hata", isPresented: $showSaveError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("İşlem sırasında bir hata oluştu. Lütfen tekrar deneyin.")
        }
        .alert("İçe Aktarma Tamamlandı", isPresented: $importResultAlert) {
            Button("Harika") {}
        } message: {
            Text(importCount > 0 ? "\(importCount) adet yeni tartım Apple Sağlık'tan Heft'e aktarıldı." : "Apple Sağlık'ta içe aktarılacak yeni bir tartım bulunamadı.")
        }
        .alert("Dışa Aktarma Tamamlandı", isPresented: $exportResultAlert) {
            Button("Harika") {}
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

    private func markDirty() {
        if isLoaded {
            hasUnsavedChanges = true
        }
    }

    @ViewBuilder
    private func rowLabel(_ title: String, systemImage: String) -> some View {
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
                    TextField("Adınız", text: $nameText)
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
                    TextField("Adınız", text: $nameText)
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
                }

                VStack(alignment: .leading, spacing: 6) {
                    rowLabel("Boy", systemImage: "ruler")
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
                }
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

            // Gender
            Picker(selection: $gender) {
                Label("Erkek", systemImage: "figure.stand").tag(Gender.male)
                Label("Kadın", systemImage: "figure.stand.dress").tag(Gender.female)
            } label: {
                rowLabel("Cinsiyet", systemImage: "person.fill")
            }
        } header: {
            Text("PROFİL")
                .heftEyebrowStyle()
        }
        .onChange(of: nameText) { markDirty() }
        .onChange(of: heightText) { markDirty() }
        .onChange(of: ageText) { markDirty() }
        .onChange(of: gender) { markDirty() }
    }

    @ViewBuilder
    private var goalSection: some View {
        Section {
            Picker(selection: $goalType) {
                Label("Kilo Vermek", systemImage: "flame.fill").tag(GoalType.lose)
                Label("Kilo Korumak", systemImage: "equal.circle.fill").tag(GoalType.maintain)
                Label("Kilo Almak", systemImage: "figure.strengthtraining.traditional").tag(GoalType.gain)
            } label: {
                rowLabel("Hedef Türü", systemImage: "flag.fill")
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    rowLabel("Hedef Kilo", systemImage: "target")
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                    TextField("70.0", text: $targetWeightText)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.heftListItem)
                        .frame(minWidth: inputFieldMinWidth, maxWidth: inputFieldMaxWidth)
                        .padding(.vertical, 4)
                        .focused($focusedField, equals: .targetWeight)
                    Text("kg")
                        .font(.heftMeta)
                        .foregroundStyle(Color.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    rowLabel("Hedef Kilo", systemImage: "target")
                    HStack {
                        TextField("70.0", text: $targetWeightText)
                            .textFieldStyle(.plain)
                            .keyboardType(.decimalPad)
                            .font(.heftListItem)
                            .focused($focusedField, equals: .targetWeight)
                        Text("kg")
                            .font(.heftMeta)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        } header: {
            Text("HEDEF")
                .heftEyebrowStyle()
        } footer: {
            Text(goalType == .gain ? "Kilo alma modunda artışlar pozitif olarak değerlendirilir." : (goalType == .maintain ? "Kilo koruma modunda mevcut kilonuzu dengede tutmanız hedeflenir." : "Kilo verme modunda azalışlar başarı olarak değerlendirilir."))
                .font(.heftMeta)
                .foregroundStyle(Color.secondary)
        }
        .onChange(of: goalType) { markDirty() }
        .onChange(of: targetWeightText) { markDirty() }
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
            Text("Heft'e kaydedilen tartımlar Apple Sağlık'a aktarılır. Dilerseniz geçmiş Apple Sağlık tartımlarınızı Heft'e aktarabilir veya Heft kayıtlarınızı Apple Sağlık'a gönderebilirsiniz.")
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
                Text("Heft tıbbi bir teşhis veya tedavi cihazı değildir. Uygulamadaki BMI hesaplamaları ve hedef projeksiyonları genel bilgilendirme amaçlıdır. Herhangi bir beslenme veya kilo kontrol programına başlamadan önce mutlaka bir hekime danışınız.")
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
                    Text("Her sabah seçtiğiniz saatte hatırlatıcı alacaksınız.")
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
                    Text("Tartılacağınız Günler")
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
        .onChange(of: weighInFrequency) { markDirty() }
        .onChange(of: weighInDays) { markDirty() }
        .onChange(of: weighInDay) { markDirty() }
        .onChange(of: weighInTime) { markDirty() }
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
                            markDirty()
                        } else {
                            isRemindersOn = false
                        }
                        isHandlingReminderToggle = false
                    }
                case .authorized, .provisional, .ephemeral:
                    await MainActor.run {
                        notificationAuthStatus = settings.authorizationStatus
                        markDirty()
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
        } else {
            markDirty()
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
        markDirty()
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
        heightText = "\(Int(p.height))"
        ageText = "\(p.age)"
        gender = p.gender
        goalType = p.goalType
        targetWeightText = String(format: "%.1f", p.targetWeight)
        weighInFrequency = p.weighInFrequency
        weighInDays = p.weighInDaysList
        weighInDay = p.weighInDay

        var comps = DateComponents()
        comps.hour = p.weighInHour
        comps.minute = p.weighInMinute
        weighInTime = Calendar.current.date(from: comps) ?? Date()

        DispatchQueue.main.async {
            isLoaded = true
            hasUnsavedChanges = false
        }
    }

    private func saveSettings() {
        guard let h = heightValue, let a = ageValue, let tw = targetWeightValue else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: weighInTime)
        let minute = calendar.component(.minute, from: weighInTime)
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let p = profile {
            p.name = trimmedName
            p.height = h
            p.age = a
            p.gender = gender
            p.goalType = goalType
            p.targetWeight = tw
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
                height: h,
                age: a,
                gender: gender,
                initialWeight: tw,
                targetWeight: tw,
                goalType: goalType,
                weighInDay: weighInDays.first ?? weighInDay,
                weighInHour: hour,
                weighInMinute: minute,
                rawWeighInFrequency: weighInFrequency.rawValue,
                rawWeighInDays: weighInDays.map(String.init).joined(separator: ","),
                onboardingCompleted: true
            )
            modelContext.insert(newProfile)
        }

        do {
            try modelContext.save()
            hasUnsavedChanges = false
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
        hasUnsavedChanges = false
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

                        Text("Heft, kişisel sağlık verilerinizin gizliliğine ve güvenliğine en üst düzeyde önem verir.")
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
                        content: "Heft'e kaydettiğiniz tüm bilgiler (kilo geçmişi, boy, yaş, hedefler ve hatırlatıcı saatleri) yalnızca cihazınızın yerel depolama alanında SwiftData kullanılarak saklanır. Verileriniz hiçbir harici sunucuya veya bulut veritabanına aktarılmaz."
                    )

                    policyCard(
                        icon: "heart.fill",
                        title: "2. Apple Sağlık (HealthKit) Kullanımı",
                        content: "Sağlık izinlerini onayladığınızda, Heft yalnızca vücut ağırlığı (Body Mass) verilerini Apple Sağlık uygulaması ile iki yönlü senkronize eder. Sağlık verileriniz reklam, pazarlama veya veri madenciliği amacıyla asla kullanılmaz ve üçüncü taraflarla paylaşılmaz."
                    )

                    policyCard(
                        icon: "nosign",
                        title: "3. Takip ve Reklam Bulunmaz",
                        content: "Uygulama içerisinde kullanıcı davranışlarını izleyen hiçbir üçüncü taraf analiz (analytics) aracı veya reklam ağı bulunmamaktadır. Verileriniz takip edilmez (NSPrivacyTracking: false)."
                    )

                    policyCard(
                        icon: "trash.fill",
                        title: "4. Verileri Silme ve Kontrol Hakkı",
                        content: "Kullanıcılar diledikleri anda tüm kilo kayıtlarını tek tek silebilir veya Ayarlar > Veri Yönetimi üzerinden tüm profillerini ve kayıtlarını kalıcı olarak sıfırlayabilirler."
                    )

                    policyCard(
                        icon: "cross.case.fill",
                        title: "5. Tıbbi Feragatname (Medical Disclaimer)",
                        content: "Heft tıbbi bir teşhis, klinik tedavi veya profesyonel sağlık tavsiyesi aracı değildir. BMI değerleri ve hedef tahminleri genel bilgilendirme amaçlıdır. Herhangi bir kilo verme, alma veya beslenme programına başlamadan önce mutlaka bir doktora danışınız."
                    )

                    Link(destination: URL(string: "https://efekoc.github.io/heft/privacy")!) {
                        HStack {
                            Text("Web Sitemizdeki Gizlilik Politikasını Ziyaret Edin")
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
    private func policyCard(icon: String, title: String, content: String) -> some View {
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
