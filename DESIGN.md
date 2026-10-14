# Heft — SwiftUI Design System

Adapted from Noom's design language. Simplified for a personal weight-tracking app. SF Pro only — no custom font bundling.

---

## 1. Color Tokens

All defined as `extension Color` using `Color(red:green:blue:)`.

### Brand

| Token | Hex | RGB | Usage |
|---|---|---|---|
| `heftBlue` | `#2A5DF6` | (0.165, 0.365, 0.965) | Primary action, active tab, chart line |
| `heftBluePressed` | `#1E47C8` | (0.118, 0.278, 0.784) | Button pressed state |
| `heftTeal` | `#1FC29B` | (0.122, 0.761, 0.608) | Positive trend, target line, success |
| `heftNavy` | `#0C1B4D` | (0.047, 0.106, 0.302) | Shadow tint (light mode) |

### Canvas & Surfaces (Light)

| Token | Hex | RGB |
|---|---|---|
| `heftCanvas` | `#FBFBFD` | (0.984, 0.984, 0.992) |
| `heftSurface` | `#FFFFFF` | (1.0, 1.0, 1.0) |
| `heftSurfaceSub` | `#F2F3F7` | (0.949, 0.953, 0.969) |
| `heftDivider` | `#E6E7EC` | (0.902, 0.906, 0.925) |

### Canvas & Surfaces (Dark)

| Token | Hex | RGB |
|---|---|---|
| `heftDarkCanvas` | `#121212` | (0.071, 0.071, 0.071) |
| `heftDarkSurface1` | `#1C1C1E` | (0.110, 0.110, 0.118) |
| `heftDarkSurface2` | `#262629` | (0.149, 0.149, 0.161) |
| `heftDarkDivider` | `#2E2E31` | (0.180, 0.180, 0.192) |

### Text

| Token | Hex | RGB | Mode |
|---|---|---|---|
| `heftTextPrimary` | `#1A1A1F` | (0.102, 0.102, 0.122) | Light |
| `heftTextSecondary` | `#6A6A70` | (0.416, 0.416, 0.439) | Light |
| `heftTextPrimaryDark` | `#F0F0F2` | (0.941, 0.941, 0.949) | Dark |
| `heftTextSecondaryDark` | `#9A9AA0` | (0.604, 0.604, 0.627) | Dark |

### BMI Band Colors

Used as `RectangleMark` background fills in the BMI chart at 0.15 opacity:

| Token | Hex | RGB | Range |
|---|---|---|---|
| `heftBMIUnder` | `#2A5DF6` | (0.165, 0.365, 0.965) | < 18.5 |
| `heftBMINormal` | `#1FC29B` | (0.122, 0.761, 0.608) | 18.5–24.9 |
| `heftBMIOver` | `#FFC531` | (1.000, 0.773, 0.192) | 25–29.9 |
| `heftBMIObese` | `#FF5A52` | (1.000, 0.353, 0.322) | ≥ 30 |

### Semantic

| Token | Hex | Usage |
|---|---|---|
| `heftSuccess` | `#1FC29B` | Weight loss (toward goal), positive trend |
| `heftWarning` | `#FFC531` | Approaching limit, caution |
| `heftError` | `#FF5A52` | Weight gain (away from goal), negative trend |
| `heftNeutral` | `#6A6A70` | No change, single entry |

---

## 2. Typography

**SF Pro** system font throughout. No custom fonts to bundle. Numeric values use `.monospacedDigit()` for aligned columns.

Define as `extension Font`:

| Token | Size | Weight | Monospaced Digits |
|---|---|---|---|
| `heftHeroStat` | 36 | bold | yes |
| `heftScreenTitle` | 28 | bold | no |
| `heftSection` | 22 | bold | no |
| `heftCardTitle` | 18 | bold | no |
| `heftBody` | 16 | regular | no |
| `heftBodySemibold` | 16 | semibold | no |
| `heftListItem` | 15 | semibold | no |
| `heftMeta` | 14 | regular | no |
| `heftMetaSemibold` | 14 | semibold | yes |
| `heftEyebrow` | 12 | semibold | no |
| `heftButton` | 16 | bold | no |
| `heftTab` | 10 | semibold | no |
| `heftChartAxis` | 9 | bold | no |

Eyebrow text uses 1.0 letter spacing (`.tracking(1.0)`) and uppercased.

---

## 3. Signature Components

### SummaryCard

The main dashboard hero card. A `VStack(alignment: .leading, spacing: 16)` containing:

**Top row** — `HStack`:
- Left: "Mevcut" eyebrow label (`.heftEyebrow`, secondary color, uppercased, 1.0 tracking), below it the latest weight in `.heftHeroStat` + "kg" unit suffix in `.heftMeta` semibold, baseline-aligned with 4pt spacing.
- Right (trailing): "Hedef" eyebrow label, below it target weight in `.heftCardTitle` + "kg" suffix.

**Divider** — 0.5pt `heftDivider` line.

**Bottom row** — `HStack(spacing: 12)`:
- **Remaining pill**: difference between current and target, displayed as "−3.2 kg kaldı" or "+1.5 kg fazla" in `.heftMetaSemibold` on a capsule background (`heftTeal.opacity(0.15)` if under target, `heftError.opacity(0.15)` if over).
- **Weekly change pill**: "Bu hafta: −0.8 kg" with trend icon:
  - Decreased → `arrow.down.right` in `heftSuccess`
  - Increased → `arrow.up.right` in `heftError`
  - No change or single entry → `arrow.right` in `heftNeutral`
  - Capsule background at 0.10 opacity of the trend color.

Card container: 20pt padding, full width, `RoundedRectangle(cornerRadius: 20)` filled with surface color, 1pt `heftDivider` stroke border, shadow using `heftNavy.opacity(0.06)` radius 18 y-offset 6 (light mode only — dark mode drops shadow, uses border only).

### WeightChartCard

Adapted from Noom's WeightGraphCard. Uses **Swift Charts** instead of raw Path drawing.

Container card with 16pt padding, 18pt corner radius, same surface/border/shadow pattern as SummaryCard.

**Header row**: "Kilo Değişimi" in `.heftCardTitle` left-aligned.

**Chart** (200pt height):
- `LineMark` connecting all WeightEntry points sorted by date. Foreground: `heftBlue`. Line width: 2.5pt, interpolation: `.catmullRom`.
- `AreaMark` beneath the line: linear gradient from `heftBlue.opacity(0.25)` (top) to `heftBlue.opacity(0.02)` (bottom).
- `RuleMark(y:)` at targetWeight: dashed stroke (`heftTeal`, line dash [5, 4], 1.5pt width), annotated with "Hedef" label in `.heftChartAxis` positioned trailing.
- `PointMark` on each data point: 5pt circle, `heftBlue`.
- X axis: `.value("Tarih", entry.date)` with date formatting.
- Y axis: `.value("Kilo", entry.weight)` with "kg" suffix.
- `.chartYScale(domain:)` with padding above and below min/max values.
- Animate on appear: `.opacity` from 0 to 1 over 0.5s easeOut.

**Empty state** (fewer than 2 entries): centered `VStack` with `scale.3d` SF Symbol (40pt, secondary color) and "Grafiği görmek için en az 2 kayıt gerekli" text in `.heftMeta`, secondary color.

### BMIChartCard

Same card container pattern as WeightChartCard.

**Header row**: "Vücut Kütle İndeksi" in `.heftCardTitle` left-aligned.

**Chart** (200pt height):
- `RectangleMark` background bands (each spanning the full X range):
  - yStart: 0, yEnd: 18.5 → `heftBMIUnder.opacity(0.15)`
  - yStart: 18.5, yEnd: 25 → `heftBMINormal.opacity(0.15)`
  - yStart: 25, yEnd: 30 → `heftBMIOver.opacity(0.15)`
  - yStart: 30, yEnd: 45 → `heftBMIObese.opacity(0.15)`
- `LineMark` for BMI values: `heftBlue`, 2.5pt, `.catmullRom`.
- `PointMark` on each data point: 5pt circle.
- Y axis domain: calculated from data with reasonable padding, labeled with BMI values.
- Same empty state as weight chart.

### AddWeightSheet

Presented as a `.sheet`. A `VStack(spacing: 24)` with:

- Handle bar: 36×5 capsule in `heftDivider`, centered, 8pt top padding.
- Title: "Kilo Ekle" in `.heftSection`.
- Weight input: large centered `TextField` with `.heftHeroStat` font, "0.0" placeholder, `.decimalPad` keyboard. Below it, "kg" label in `.heftMeta`.
- Date picker: `DatePicker` with `.datePickerStyle(.compact)`, label "Tarih" in `.heftBodySemibold`.
- Save button: `HeftPrimaryButton` labeled "Kaydet", disabled until weight is valid (20–500).

Container: 24pt horizontal padding, surface background.

### HeftPrimaryButton

Full-width capsule button. `.heftButton` font, white text, 15pt vertical + 30pt horizontal padding, `heftBlue` capsule fill. On press: `heftBluePressed` fill + 0.98 scale effect with 0.12s easeOut. Disabled state: 0.4 opacity.

### OnboardingStepContainer

A generic container for onboarding steps. `VStack` with:

- Progress bar at top: `GeometryReader`-based capsule, 4pt height, `heftSurfaceSub` background track, `heftBlue` fill proportional to `currentStep / totalSteps`, animated with 0.3s easeOut.
- Step content: `@ViewBuilder` slot, centered, flexible.
- Bottom action button: `HeftPrimaryButton`.

Container: `heftCanvas` background, 24pt horizontal padding.

### HistoryRow

An `HStack` with:
- Left `VStack(alignment: .leading, spacing: 2)`: date in `.heftListItem` / primary color (formatted "dd MMM yyyy"), BMI value in `.heftMeta` / secondary color (formatted "BMI: 24.3").
- Right: weight in `.heftCardTitle` + "kg" in `.heftMeta` / secondary, baseline-aligned.

Minimum height 56pt, 16pt horizontal padding.

### SettingsSection

Standard `Form` / `List` using `.insetGrouped` style. Section headers in `.heftEyebrow` with 1.0 tracking, uppercased.

---

## 4. Tab Bar

`TabView` with `.tint(.heftBlue)`, 2 tabs:

| Tab | Label | SF Symbol (inactive/active) |
|---|---|---|
| Ana Sayfa | "Ana Sayfa" | `house` / `house.fill` |
| Geçmiş | "Geçmiş" | `list.bullet` / `list.bullet` |

Settings is accessed via toolbar gear icon in Dashboard, not a tab.

---

## 5. Motion & Haptics

| Context | Specification |
|---|---|
| Chart appear | 0.5s easeOut opacity 0→1 |
| Weight line draw | 0.7s easeOut via animated trim (if using custom path overlay) |
| Onboarding step transition | 0.3s easeOut slide + opacity |
| Progress bar fill | 0.3s easeOut |
| Primary button press | 0.12s easeOut scale 1→0.98 |
| Save weight | `.sensoryFeedback(.success, trigger:)` |
| Delete entry | `.sensoryFeedback(.warning, trigger:)` |
| Tab switch | `.sensoryFeedback(.selection, trigger:)` |

All haptics use `.sensoryFeedback` (iOS 17+).

---

## 6. SF Symbols Used

| Component | Symbol | Size |
|---|---|---|
| Dashboard tab | `house` / `house.fill` | 22pt |
| History tab | `list.bullet` | 22pt |
| Settings | `gearshape` | 18pt |
| Add weight | `plus.circle.fill` | 22pt |
| Trend down (good) | `arrow.down.right` | 14pt |
| Trend up (bad) | `arrow.up.right` | 14pt |
| Trend neutral | `arrow.right` | 14pt |
| Empty state | `scale.3d` | 40pt |
| Onboarding welcome | `scalemass.fill` | 60pt |
| Onboarding schedule | `bell.badge` | 40pt |
| Onboarding complete | `checkmark.circle.fill` | 48pt |
| Gender male | `figure.stand` | 24pt |
| Gender female | `figure.stand.dress` | 24pt |
| Target | `target` | 18pt |
| Calendar | `calendar` | 18pt |
| Back / dismiss | `xmark` | 18pt |

---

## 7. Dark Mode

A `HeftTheme` ViewModifier reads `@Environment(\.colorScheme)`:

- **Light**: `heftCanvas` background, `heftTextPrimary` foreground, cards use `heftSurface` fill + `heftDivider` border + navy-tinted shadow.
- **Dark**: `heftDarkCanvas` background, `heftTextPrimaryDark` foreground, cards use `heftDarkSurface1` fill + `heftDarkDivider` border + no shadow.

Brand colors (`heftBlue`, `heftTeal`) and BMI band colors remain identical across both modes.

Use adaptive system colors where possible (e.g., `Color(.secondarySystemGroupedBackground)` for form backgrounds). Apply `HeftTheme` modifier at the root view.

---

## 8. Accessibility Notes

**Minimum target: iOS 17.**

**Dynamic Type**: Screen title, section, card title, body, list item, and meta all scale. Hero stat scales one step then uses `minimumScaleFactor(0.7)`. Eyebrow, chart axis, and tab labels remain fixed.

**VoiceOver**:
- SummaryCard announces: "Mevcut kilo [X] kg, hedef [Y] kg, [Z] kg kaldı, bu hafta [±W] kg."
- Charts announce summary trend rather than individual points.
- History rows are grouped as single accessibility elements.

**Contrast**: Primary text on canvas passes WCAG AA in both modes. White text on `heftBlue` passes AA at all sizes.

**Reduce Motion**: Chart appear animation replaced with instant render. Button press scale effect disabled. Onboarding transitions become cross-fades at 200ms.
