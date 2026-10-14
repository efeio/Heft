You are an expert iOS developer. Build a complete, production-ready iOS app called "Heft" — a personal weight tracker. Use SwiftUI and SwiftData (iOS 17+). Local storage only, no CloudKit.

---

## SwiftData Models

**UserProfile** (single record)
- height: Double (cm)
- age: Int
- gender: String ("male" or "female")
- initialWeight: Double (kg)
- targetWeight: Double (kg)
- weighInDay: Int (1=Sunday … 7=Saturday, matching iOS Calendar weekday)
- weighInHour: Int
- weighInMinute: Int
- onboardingCompleted: Bool

**WeightEntry**
- date: Date
- weight: Double (kg)
- **No computed BMI property on the model.** BMI is calculated at the view layer via `BMICalculator.calculate(weightKg:heightCm:)`.

---

## BMICalculator (Utility)

A simple enum with a static method:

```swift
enum BMICalculator {
    static func calculate(weightKg: Double, heightCm: Double) -> Double? {
        guard heightCm > 0 else { return nil }
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }
}
```

Returns `nil` when height is zero or negative (division-by-zero guard).

---

## Onboarding (shown once, when onboardingCompleted == false)

Full-screen paged flow with a top progress bar (5 steps):

### Step 1 – Welcome
App name "Heft", short tagline, "Başla" button.

### Step 2 – Body Info
- TextField for height (cm) — numeric keyboard, must be > 0
- Stepper or TextField for age — must be > 0
- Picker segmented for gender (Erkek / Kadın)

### Step 3 – Weight Info
- TextField for current weight (kg) — decimal keyboard, must be > 0
- TextField for target weight (kg) — decimal keyboard, must be > 0

### Step 4 – Schedule
- Picker for weigh-in day: **display order Pazartesi → Pazar**, but store the correct iOS Calendar weekday Int:

| Display Label | Stored Value (iOS weekday) |
|---|---|
| Pazartesi | 2 |
| Salı | 3 |
| Çarşamba | 4 |
| Perşembe | 5 |
| Cuma | 6 |
| Cumartesi | 7 |
| Pazar | 1 |

- DatePicker (.hourAndMinute) for time.
- Request `UNUserNotificationCenter` permission here.

### Step 5 – All Set
Summary card displaying all entered info. "Hadi Başlayalım" button → saves UserProfile + first WeightEntry (initialWeight, date = today) to SwiftData, schedules weekly notification, sets onboardingCompleted = true, dismisses onboarding.

### Validation Rules (Onboarding)
- "İleri" / "Başla" button is **disabled** until all fields in the current step are valid.
- Height must be 50–300 cm.
- Age must be 1–120.
- Weight (current and target) must be 20–500 kg.
- Show inline error text under invalid fields only after the user has interacted with them.

---

## Main App — TabView with 2 tabs

### Tab 1: Dashboard (house.fill SF Symbol)

#### Summary Card (top)
- Current weight (latest entry)
- Target weight
- Remaining difference (current − target, formatted with sign: "+2.3 kg" or "−2.3 kg")
- **Weekly change**: difference between the latest entry and the entry before it. Display as "Bu hafta: ±X.X kg" with a trend icon:
  - Weight decreased → `arrow.down.right` (green)
  - Weight increased → `arrow.up.right` (red)
  - No change or only 1 entry → `arrow.right` (secondary color), text "—"

#### "Kilo Ekle" button (plus.circle.fill SF Symbol) → sheet:
- Weight TextField (decimal keyboard, must be 20–500 kg)
- DatePicker (defaults to today)
- "Kaydet" button disabled until weight is valid
- **Same-day handling**: if an entry already exists for the selected date, show an alert: "Bu tarihe zaten bir kayıt var. Üzerine yazılsın mı?" — confirm overwrites, cancel dismisses.

#### Weight Line Chart (Swift Charts)
- All WeightEntry records sorted by date. X = date, Y = weight in kg.
- Dashed horizontal `RuleMark` at targetWeight, labeled "Hedef".
- **Empty state**: if fewer than 2 entries, show a placeholder message "Grafiği görmek için en az 2 kayıt gerekli" instead of the chart.
- Animate on appear with `.chartYScale` and animation modifier.
- Axis labels and grid lines.

#### BMI Line Chart (Swift Charts)
- Same entries, Y = `BMICalculator.calculate(weightKg:heightCm:)`.
- Colored `RectangleMark` background bands:
  - BMI < 18.5 → blue tint (0.15 opacity)
  - 18.5–24.9 → green tint (0.15 opacity)
  - 25–29.9 → yellow tint (0.15 opacity)
  - ≥ 30 → red tint (0.15 opacity)
- Same empty-state rule as weight chart.
- Animate on appear.

Both charts stacked vertically in a ScrollView.

### Tab 2: History (list.bullet SF Symbol)

- All WeightEntry records, sorted newest first.
- Each row: formatted date (dd MMM yyyy), weight with "kg" suffix, BMI value rounded to 1 decimal (via `BMICalculator`).
- Swipe-to-delete.
- **Empty state**: if no entries, show "Henüz kayıt yok" centered with a `scale.3d` SF Symbol.

---

## Settings (gear SF Symbol in Dashboard toolbar — NavigationLink)

Form-based view with sections:

- **Profil**: height (validated 50–300), age (validated 1–120), gender picker
- **Hedef**: target weight (validated 20–500)
- **Tartım Takvimi**: weigh-in day picker (Pazartesi–Pazar with correct weekday mapping) + time picker — on save, call `NotificationService.scheduleWeeklyNotification` to reschedule.

---

## NotificationService.swift

Standalone enum with static methods:

```swift
enum NotificationService {
    static func requestPermission() async -> Bool
    static func scheduleWeeklyNotification(day: Int, hour: Int, minute: Int) async
}
```

- `requestPermission()` — requests `UNUserNotificationCenter` authorization for `.alert, .sound`. Returns whether granted.
- `scheduleWeeklyNotification(day:hour:minute:)` — removes any existing notification with identifier `"weekly-weigh-in"`, then schedules a new `UNCalendarNotificationTrigger` (repeating weekly) with:
  - Title: `"Tartılma zamanı! ⚖️"`
  - Body: `"Bugün haftalık tartılma günün. Heft'i aç ve kilonu gir."`
  - Identifier: `"weekly-weigh-in"`

---

## Design

- SF Symbols only, no custom assets.
- System colors throughout — automatic dark mode support via semantic colors.
- Cards use `.background(Color(.secondarySystemGroupedBackground))` with `.clipShape(RoundedRectangle(cornerRadius: 16))`.
- Charts animate on appear.
- All user-facing text in Turkish.

---

## File Structure

Create all files. Implement every view and function fully — no TODOs, no placeholder comments.

```
Heft/
├── HeftApp.swift
├── Models/
│   ├── UserProfile.swift
│   └── WeightEntry.swift
├── Utilities/
│   └── BMICalculator.swift
├── Onboarding/
│   ├── OnboardingContainerView.swift
│   ├── WelcomeStep.swift
│   ├── BodyInfoStep.swift
│   ├── WeightInfoStep.swift
│   ├── ScheduleStep.swift
│   └── AllSetStep.swift
├── Dashboard/
│   ├── DashboardView.swift
│   ├── SummaryCardView.swift
│   ├── AddWeightSheet.swift
│   ├── WeightChartView.swift
│   └── BMIChartView.swift
├── History/
│   └── HistoryView.swift
├── Settings/
│   └── SettingsView.swift
└── Services/
    └── NotificationService.swift
```

Note: `SummaryCardView.swift` is extracted as its own file because it contains weekly diff/trend logic.
