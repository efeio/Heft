# English & Turkish Full Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement comprehensive English and Turkish localization across Heft, utilizing modern Apple String Catalogs (`Localizable.xcstrings` and `InfoPlist.xcstrings`), locale-aware number/date formatting, and localized domain models and system permissions.

**Architecture:**
- **String Catalogs (`Localizable.xcstrings` & `InfoPlist.xcstrings`):** Native Xcode 15+ / iOS 17+ string catalogs containing all UI text, accessibility labels, and Info.plist privacy strings with 100% translations in Turkish (`tr`) and English (`en`).
- **Dynamic Locale Engine (`HeftFormat` & `ChartTimeRange`):** Replace all 14 hardcoded `Locale(identifier: "tr_TR")` instances with `Locale.autoupdatingCurrent` so numbers (comma in TR vs period in EN) and dates automatically adapt to the user's active device language or per-app language setting.
- **Localized Domain Models:** Add localized display properties to `Gender`, `GoalType`, `WeighInFrequency`, `ScheduleDayItem`, `BMICalculator`, `ProjectionEngine`, and `NotificationService`.

**Tech Stack:** Swift 5.10, SwiftUI, iOS 17+, SwiftData, String Catalogs (`.xcstrings`), UserNotifications, HealthKit.

---

## File Structure & Responsibilities

| File | Responsibility |
| :--- | :--- |
| `Heft/Localizable.xcstrings` | Main UI & engine string catalog (TR + EN keys and translations) |
| `Heft/InfoPlist.xcstrings` | System permission descriptions (HealthKit usage strings in TR + EN) |
| `Heft.xcodeproj/project.pbxproj` | Project file referencing `Localizable.xcstrings` and `InfoPlist.xcstrings` in resources |
| `Heft/Theme/HeftTheme.swift` | `HeftFormat` with `Locale.autoupdatingCurrent`, decimal separator, number/weight formatters |
| `Heft/Dashboard/ChartTimeRange.swift` | Localized range titles (`1A` vs `1M`), a11y labels, locale-aware date formatters |
| `Heft/Models/Gender.swift` | Localized gender labels (`Erkek`/`Male`, `Kadın`/`Female`) |
| `Heft/Models/GoalType.swift` | Localized goal titles and descriptions |
| `Heft/Models/UserProfile.swift` | Localized `WeighInFrequency` labels and schedule helpers |
| `Heft/Onboarding/ScheduleStep.swift` | `WeighInSchedule` localized day names (`Pzt`/`Mon`, `Pazartesi`/`Monday`) |
| `Heft/Utilities/BMICalculator.swift` | Localized BMI category strings (`Underweight`, `Normal`, `Overweight`, `Obese`) |
| `Heft/Utilities/ProjectionEngine.swift` | Localized scenarios, condition insights, plateau/anomaly messages, date range |
| `Heft/Services/NotificationService.swift` | Localized notification titles and body strings |
| `Heft/Services/HealthKitService.swift` | Localized HealthKit sync and error strings |
| `Heft/MainTabView.swift` | Localized tab labels (`Home`/`Ana Sayfa`, `History`/`Geçmiş`) |
| `Heft/Onboarding/*.swift` (5 files) | Localized onboarding copy, inputs, tick pickers, headers, buttons |
| `Heft/Dashboard/*.swift` (6 files) | Localized greetings, summary stats, charts, projection cards, sheets |
| `Heft/History/*.swift` (3 files) | Localized history headers, rows, edit sheet, deletion confirmation alerts |
| `Heft/Settings/SettingsView.swift` | Localized settings sections, toggles, disclaimer, danger zone, alerts |
| `Heft/Theme/HeftComponents.swift` | Localized keyboard toolbar (`Done`/`Bitti`), tick picker units and a11y labels |

---

## Tasks

### Task 1: String Catalog Setup (`Localizable.xcstrings` & `InfoPlist.xcstrings`)

- [ ] **Step 1:** Create `Heft/InfoPlist.xcstrings` containing `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` in Turkish and English.
- [ ] **Step 2:** Create initial `Heft/Localizable.xcstrings` with JSON schema `1.0`, `sourceLanguage: "tr"`.
- [ ] **Step 3:** Update `Heft.xcodeproj/project.pbxproj` to include both files in the PBXFileReference, PBXBuildFile, PBXGroup (`Heft`), and PBXResourcesBuildPhase sections.
- [ ] **Step 4:** Run `xcodebuild -project Heft.xcodeproj -scheme Heft -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build` to verify the project builds cleanly with the new catalogs.
- [ ] **Step 5:** Commit: `git commit -m "feat(i18n): initialize Localizable and InfoPlist string catalogs"`

---

### Task 2: Locale & Formatters Refactoring (`HeftFormat`, `ChartTimeRange`, DateFormatters)

- [ ] **Step 1:** In `Heft/Theme/HeftTheme.swift`:
  - Change `static let locale = Locale(identifier: "tr_TR")` to `static var locale: Locale { Locale.autoupdatingCurrent }`.
  - Update `decimalSeparator` to compute from `locale.decimalSeparator ?? "."`.
  - Make `oneDecimalFormatter` and `integerFormatter` use `Locale.autoupdatingCurrent`.
- [ ] **Step 2:** In `Heft/Dashboard/ChartTimeRange.swift`:
  - Add `var localizedLabel: String` returning `"1A"`, `"3A"`, `"6A"`, `"1Y"`, `"Tümü"` in TR and `"1M"`, `"3M"`, `"6M"`, `"1Y"`, `"All"` in EN.
  - Update `accessibilityTitle` to use `String(localized: ...)` for localized titles.
  - Change static formatters (`dayMonthFormatter`, `monthFormatter`, `monthYearFormatter`) to use `Locale.autoupdatingCurrent`.
- [ ] **Step 3:** In `WeightChartView.swift`, `BMIChartView.swift`, `AddWeightSheet.swift`, `HistoryView.swift`, `HistoryRow.swift`:
  - Replace static `Locale(identifier: "tr_TR")` with `Locale.autoupdatingCurrent`.
- [ ] **Step 4:** Build project and verify compilation: `xcodebuild -project Heft.xcodeproj -scheme Heft build`.
- [ ] **Step 5:** Commit: `git commit -m "refactor(i18n): adopt Locale.autoupdatingCurrent across formatters and chart ranges"`

---

### Task 3: Domain Models & Logic Localization (`Gender`, `GoalType`, `UserProfile`, `BMICalculator`, `ProjectionEngine`)

- [ ] **Step 1:** In `Heft/Models/Gender.swift`:
  - Add `var label: String` returning localized `"Erkek"` / `"Male"` and `"Kadın"` / `"Female"`.
- [ ] **Step 2:** In `Heft/Models/GoalType.swift`:
  - Add `var label: String` returning localized `"Kilo Vermek"` / `"Lose Weight"`, `"Korumak"` / `"Maintain"`, `"Kilo Almak"` / `"Gain Weight"`.
  - Add `var description: String` returning localized goal descriptions.
- [ ] **Step 3:** In `Heft/Models/UserProfile.swift` and `Heft/Onboarding/ScheduleStep.swift`:
  - Localize `WeighInFrequency.label`.
  - In `WeighInSchedule`: Localize `ScheduleDayItem` labels and shortLabels (Monday/Pzt, etc.).
- [ ] **Step 4:** In `Heft/Utilities/BMICalculator.swift`:
  - Localize `category(for bmi: Double)` (`Underweight`, `Normal`, `Overweight`, `Obese`).
- [ ] **Step 5:** In `Heft/Utilities/ProjectionEngine.swift`:
  - Localize `ProjectionScenario` titles (`Adaptive`, `Last 14 Days`, `Overall`, `Target Plan`).
  - Localize `PaceStatus` labels (`Ideal`, `Slow`, `Too Fast`, `Moderate`, `Stable`).
  - Update date formatters to use `Locale.autoupdatingCurrent`.
  - Localize condition messages, plateau messages, anomaly messages, and catch-up messages.
- [ ] **Step 6:** Build project to verify type-check and compilation.
- [ ] **Step 7:** Commit: `git commit -m "feat(i18n): localize domain models, BMI categories, and ProjectionEngine"`

---

### Task 4: Services Localization (`NotificationService`, `HealthKitService`)

- [ ] **Step 1:** In `Heft/Services/NotificationService.swift`:
  - Localize reminder notification titles and bodies for daily, weekly, and specific days triggers.
  - Handle optional user name placeholders cleanly in both languages.
- [ ] **Step 2:** In `Heft/Services/HealthKitService.swift`:
  - Localize user-facing HealthKit alert messages.
- [ ] **Step 3:** Build project to verify compilation.
- [ ] **Step 4:** Commit: `git commit -m "feat(i18n): localize local notifications and HealthKit messages"`

---

### Task 5: Onboarding UI Localization (Steps 1–5 & Container)

- [ ] **Step 1:** Localize `Heft/Onboarding/WelcomeStep.swift` (headline, subtitle, "Başla"/"Get Started").
- [ ] **Step 2:** Localize `Heft/Onboarding/BodyInfoStep.swift` (labels, validation errors, accessibility titles).
- [ ] **Step 3:** Localize `Heft/Onboarding/WeightInfoStep.swift` (current weight, target weight, pace slider descriptions, warning labels).
- [ ] **Step 4:** Localize `Heft/Onboarding/ScheduleStep.swift` (schedule options, days grid, notification prompt).
- [ ] **Step 5:** Localize `Heft/Onboarding/AllSetStep.swift` (summary rows, notifications toggle, finish button, error alerts).
- [ ] **Step 6:** Localize `Heft/Onboarding/OnboardingContainerView.swift` & `HeftComponents.swift` (step progress a11y label, back button a11y, "Devam Et"/"Continue").
- [ ] **Step 7:** Build project to verify compilation.
- [ ] **Step 8:** Commit: `git commit -m "feat(i18n): localize complete onboarding flow"`

---

### Task 6: Dashboard & Sheets UI Localization

- [ ] **Step 1:** Localize `Heft/MainTabView.swift` (tab titles: "Ana Sayfa"/"Home", "Geçmiş"/"History").
- [ ] **Step 2:** Localize `Heft/Dashboard/DashboardView.swift` (greeting titles, gear icon accessibility label, error alert).
- [ ] **Step 3:** Localize `Heft/Dashboard/SummaryCardView.swift` (stat headers: Current Weight, Goal, BMI, Weekly Pace).
- [ ] **Step 4:** Localize `Heft/Dashboard/TargetProjectionCard.swift` (headers, week badges, micro-feedback badges, milestone bar, insight cards).
- [ ] **Step 5:** Localize `Heft/Dashboard/WeightChartView.swift` (chart title, Current button, delta badges, first entry milestone card, empty states, target rule mark, insight cards, Audio Graphs/VoiceOver labels).
- [ ] **Step 6:** Localize `Heft/Dashboard/BMIChartView.swift` (chart title, Current button, category badge, normal threshold rule mark, milestone card, insight cards, VoiceOver labels).
- [ ] **Step 7:** Localize `Heft/Dashboard/AddWeightSheet.swift` (title, date picker, numeric pad, save button, overwrite confirmation alert).
- [ ] **Step 8:** Build project to verify compilation.
- [ ] **Step 9:** Commit: `git commit -m "feat(i18n): localize dashboard views, charts, and add-weight sheet"`

---

### Task 7: History & Settings UI Localization

- [ ] **Step 1:** Localize `Heft/History/HistoryView.swift` (title, empty state, month/year section headers, delete entry confirmation alert).
- [ ] **Step 2:** Localize `Heft/History/HistoryRow.swift` (VoiceOver accessibility label, date presentation).
- [ ] **Step 3:** Localize `Heft/History/EditWeightSheet.swift` (title, save button, overwrite alert).
- [ ] **Step 4:** Localize `Heft/Settings/SettingsView.swift`:
  - Profile section (İsim/Name, Boy/Height, Yaş/Age, Cinsiyet/Gender, validation alerts).
  - Goal section (Hedef Türü/Goal Type, Hedef Kilo/Target Weight, footer explanations).
  - Apple Health section (Sync toggle, Import, Export, progress indicators, result alerts).
  - Schedule section (Tartım Hatırlatıcısı/Weigh-in Reminder, frequency picker, settings deep-link).
  - Privacy & Legal section (Gizlilik Politikası/Privacy Policy, Web link, Medical Disclaimer).
  - Danger Zone (Tüm Verileri Sil/Delete All Data confirmation alert, warning messages).
- [ ] **Step 5:** Localize `Heft/Theme/HeftComponents.swift` (keyboard toolbar "Bitti"/"Done", goal selectors, tick picker unit and accessibility labels).
- [ ] **Step 6:** Build project to verify compilation.
- [ ] **Step 7:** Commit: `git commit -m "feat(i18n): localize history and settings views"`

---

### Task 8: Translation Completeness Verification & Build Validation

- [ ] **Step 1:** Write verification script `scripts/verify_localization.py` that parses `Heft/Localizable.xcstrings` and `Heft/InfoPlist.xcstrings` and asserts:
  - Every string key has both `"tr"` and `"en"` localizations.
  - No translation value is empty.
  - Valid JSON syntax.
- [ ] **Step 2:** Run script and verify 100% pass: `python3 scripts/verify_localization.py`.
- [ ] **Step 3:** Grep codebase to ensure no remaining `Locale(identifier: "tr_TR")`.
- [ ] **Step 4:** Build project in `Release` and `Debug` configurations with zero warnings or errors.
- [ ] **Step 5:** Commit: `git commit -m "test(i18n): verify 100% string catalog translation coverage and locale autonomy"`

