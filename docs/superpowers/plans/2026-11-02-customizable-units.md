# Independent Unit System (kg/lbs, cm/ft-in) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to choose their preferred Weight Unit (`kg` vs `lbs`) and Height Unit (`cm` vs `ft / in`) independently in an unobtrusive, lightweight manner during Onboarding, and switch them anytime in Settings, while preserving canonical metric data storage and full Apple HealthKit compatibility.

**Architecture:** 
- Canonical storage: `UserProfile` and `WeightEntry` persist all measurements in standard metric (`kg` and `cm`). HealthKit sync continues using `kg`.
- `WeightUnit` (`.kg`, `.lbs`) and `HeightUnit` (`.cm`, `.ftIn`) enums define unit metadata and accurate conversion logic.
- `HeftFormat` provides unit-aware formatters throughout the app.
- Onboarding presents subtle, inline unit toggles directly on the relevant input steps (no extra screens or friction).
- Settings provides a dedicated "UNITS" section with real-time updates across the app.

**Tech Stack:** Swift 5.0, SwiftUI, SwiftData, HealthKit, Xcode 16.

**Spec:** User approved independent units design with zero friction onboarding.

## Global Constraints

- Never mutate underlying raw weight/height data destructively; canonical data in `WeightEntry` and `UserProfile` must remain in `kg` and `cm`.
- 100% translation coverage in `Localizable.xcstrings` (`tr` and `en`) with state `translated`.
- Zero compiler warnings or errors in both Debug and Release.
- High-efficiency UI: Keep Onboarding fluid, swift, and friction-free.

## Review Focus

1. Precision drift: ensure converting `kg -> lbs -> kg` doesn't accumulate rounding errors on save.
2. Tick picker bounds: when switching units (e.g. `kg` to `lbs`), tick picker ranges must map correctly (e.g. 40-300 kg vs 88-660 lbs).
3. Number input decimal separator: respect locale (`.` vs `,`) when parsing imperial or metric numbers.
4. Backwards compatibility: existing `UserProfile` records without explicit unit fields default gracefully to `.kg` and `.cm`.
5. HealthKit synchronization: HealthKit must receive correct kilogram samples regardless of UI display unit.

---

### Task 1: Unit Models, Conversions & Formatter Extension

**Files:**
- Create: `Heft/Models/Units.swift`
- Modify: `Heft/Models/UserProfile.swift`
- Modify: `Heft/Theme/HeftTheme.swift`

- [x] Create `Heft/Models/Units.swift` defining `WeightUnit` (`kg`, `lbs`) and `HeightUnit` (`cm`, `ftIn`), with conversion functions `kgToLbs`, `lbsToKg`, `cmToInches`, `inchesToCm`, `cmToFtIn`, `ftInToCm`.
- [x] Add `weightUnitRaw` and `heightUnitRaw` properties with default values to `UserProfile`, along with computed properties `weightUnit: WeightUnit` and `heightUnit: HeightUnit`.
- [x] Extend `HeftFormat` with unit-aware formatting helpers: `formatWeight`, `formatWeightWithUnit`, `formatSignedWeightWithUnit`, `formatHeight`, `formatHeightWithUnit`.
- [x] Verify build and test conversion math.
- [x] Commit as `feat(units): add WeightUnit, HeightUnit models, conversions, and unit-aware formatters`.

---

### Task 2: Onboarding Unit Selectors (Inline & Frictionless)

**Files:**
- Modify: `Heft/Onboarding/BodyInfoStep.swift`
- Modify: `Heft/Onboarding/WeightInfoStep.swift`
- Modify: `Heft/Onboarding/AllSetStep.swift`
- Modify: `Heft/Onboarding/OnboardingContainerView.swift`

- [x] In `BodyInfoStep.swift`, add an inline segmented toggle `[ cm | ft ]` next to the Height section header. Adapt tick picker range and values to display either `cm` or `ft & in`.
- [x] In `WeightInfoStep.swift`, add an inline segmented toggle `[ kg | lbs ]` next to the Weight section header. Adapt tick picker range and values to display either `kg` or `lbs`.
- [x] In `AllSetStep.swift`, update summary rows to format height and weight according to selected `heightUnit` and `weightUnit`.
- [x] In `OnboardingContainerView.swift`, track `@State private var weightUnit: WeightUnit` and `@State private var heightUnit: HeightUnit`, passing them to steps and persisting to `UserProfile`.
- [x] Verify build and test onboarding transitions.
- [x] Commit as `feat(onboarding): add inline unit selectors to body info and weight info steps`.

---

### Task 3: Settings Screen Units Configuration

**Files:**
- Modify: `Heft/Settings/SettingsView.swift`

- [x] Add a new "BİRİMLER" / "UNITS" section in `SettingsView`.
- [x] Add segmented controls for `WeightUnit` (`kg` / `lbs`) and `HeightUnit` (`cm` / `ft / in`).
- [x] Ensure `targetWeightText` and validation dynamically display in the user's selected unit and convert to `kg` upon saving.
- [x] Commit as `feat(settings): add units configuration section for weight and height`.

---

### Task 4: Unit Awareness in Dashboard, Charts, History, and Sheets

**Files:**
- Modify: `Heft/Dashboard/AddWeightSheet.swift`
- Modify: `Heft/History/EditWeightSheet.swift`
- Modify: `Heft/Dashboard/SummaryCardView.swift`
- Modify: `Heft/Dashboard/TargetProjectionCard.swift`
- Modify: `Heft/Dashboard/WeightChartView.swift`
- Modify: `Heft/Dashboard/BMIChartView.swift`
- Modify: `Heft/History/HistoryRow.swift`
- Modify: `Heft/History/HistoryView.swift`

- [x] In `AddWeightSheet.swift` & `EditWeightSheet.swift`, adapt keypad and stepper to input in user's `weightUnit`, converting to canonical `kg` before saving.
- [x] In `SummaryCardView.swift` & `TargetProjectionCard.swift`, display weights and deltas in user's `weightUnit`.
- [x] In `WeightChartView.swift`, render Y-axis labels, tooltips, and motivation banner in user's `weightUnit`.
- [x] In `BMIChartView.swift`, keep BMI metric formula intact while displaying reference weight ranges in user's `weightUnit`.
- [x] In `HistoryRow.swift` & `HistoryView.swift`, format logged weights and stat pills in user's `weightUnit`.
- [x] Commit as `feat(units): propagate unit preferences across dashboard, charts, history, and log sheets`.

---

### Task 5: Localization, String Catalog & Verification

**Files:**
- Modify: `Heft/Localizable.xcstrings`
- Run: `scripts/verify_localization.py`
- Run: `xcodebuild -scheme Heft -destination 'generic/platform=iOS Simulator' build`

- [x] Add all unit-related strings to `Localizable.xcstrings` with 100% `tr` and `en` translations.
- [x] Run `scripts/verify_localization.py` and confirm 100% completeness and zero hardcoded locales.
- [x] Run both Debug and Release builds to verify clean compilation.
- [x] Commit as `feat(i18n): localize unit selectors, labels, and settings options`.

