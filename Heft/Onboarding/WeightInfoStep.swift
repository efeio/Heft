//
//  WeightInfoStep.swift
//  Heft
//
//  Onboarding Step 3: Current and target weight input.
//

import SwiftUI

struct WeightInfoStep: View {
    @Binding var currentWeight: Double
    @Binding var targetWeight: Double
    @Binding var goalType: GoalType
    @Binding var weightUnit: WeightUnit

    var onBack: (() -> Void)? = nil
    let onNext: () -> Void

    @ScaledMetric(relativeTo: .body) private var sectionSpacing: CGFloat = 22

    private var isCurrentValid: Bool {
        currentWeight >= 20.0 && currentWeight <= 500.0
    }

    private var isTargetRangeValid: Bool {
        targetWeight >= 20.0 && targetWeight <= 500.0
    }

    private var isTargetDirectionValid: Bool {
        switch goalType {
        case .gain:
            return targetWeight > currentWeight
        case .lose:
            return targetWeight < currentWeight
        case .maintain:
            return true
        }
    }

    private var isTargetValid: Bool {
        isTargetRangeValid && isTargetDirectionValid
    }

    private var displayCurrentWeightBinding: Binding<Double> {
        Binding(
            get: { weightUnit == .lbs ? UnitConverter.kgToLbs(currentWeight) : currentWeight },
            set: { currentWeight = (weightUnit == .lbs ? UnitConverter.lbsToKg($0) : $0) }
        )
    }

    private var displayTargetWeightBinding: Binding<Double> {
        Binding(
            get: { weightUnit == .lbs ? UnitConverter.kgToLbs(targetWeight) : targetWeight },
            set: { targetWeight = (weightUnit == .lbs ? UnitConverter.lbsToKg($0) : $0) }
        )
    }

    private var targetErrorMessage: String {
        if !isTargetRangeValid {
            if weightUnit == .lbs {
                return String(localized: "Hedef kilo 44 ile 1100 lbs arasında olmalıdır.", comment: "Target weight out of bounds lbs")
            }
            return String(localized: "Hedef kilo 20 ile 500 kg arasında olmalıdır.", comment: "Target weight out of bounds")
        }
        if goalType == .gain && targetWeight <= currentWeight {
            return String(localized: "Kilo alma hedefi için hedef kilon mevcut kilondan yüksek olmalıdır.", comment: "Target weight must be higher for gain")
        }
        if goalType == .lose && targetWeight >= currentWeight {
            return String(localized: "Kilo verme hedefi için hedef kilon mevcut kilondan düşük olmalıdır.", comment: "Target weight must be lower for lose")
        }
        return String(localized: "Geçersiz hedef kilo.", comment: "Invalid target weight")
    }

    private var isValid: Bool {
        isCurrentValid && isTargetValid
    }

    var body: some View {
        OnboardingStepContainer(
            currentStep: 3,
            totalSteps: 5,
            buttonTitle: String(localized: "İleri", comment: "Next button"),
            isButtonEnabled: isValid,
            onBack: onBack,
            onButtonTap: onNext
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: sectionSpacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kilo Hedeflerin")
                            .font(.heftScreenTitle)

                        Text("Hedefini ve ulaşmak istediğin kilonu belirle.")
                            .font(.heftBody)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.top, 8)

                    // Goal Type Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AMACIN NEDİR?")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)

                        HeftGoalSelector(selectedGoal: $goalType)
                    }

                    // Current Weight
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("MEVCUT KİLO")
                                .heftEyebrowStyle()
                                .foregroundStyle(Color.secondary)

                            Spacer()

                            Picker("", selection: $weightUnit) {
                                ForEach(WeightUnit.allCases) { u in
                                    Text(u.label).tag(u)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 120)
                        }

                        HeftTickPicker(
                            value: displayCurrentWeightBinding,
                            range: weightUnit == .kg ? 40...300 : 88...660,
                            step: weightUnit == .kg ? 0.1 : 0.2,
                            unit: weightUnit.label,
                            formatStyle: .decimal,
                            accessibilityTitle: String(localized: "Mevcut Kilo", comment: "Current weight accessibility title")
                        )
                    }

                    // Target Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HEDEF KİLO")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)

                        HeftTickPicker(
                            value: displayTargetWeightBinding,
                            range: weightUnit == .kg ? 40...300 : 88...660,
                            step: weightUnit == .kg ? 0.1 : 0.2,
                            unit: weightUnit.label,
                            formatStyle: .decimal,
                            accessibilityTitle: String(localized: "Hedef Kilo", comment: "Target weight accessibility title")
                        )

                        if !isTargetDirectionValid {
                            Text(targetErrorMessage)
                                .font(.heftMeta)
                                .foregroundStyle(Color.heftError)
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    WeightInfoStep(
        currentWeight: .constant(78.5),
        targetWeight: .constant(70.0),
        goalType: .constant(.lose),
        weightUnit: .constant(.kg),
        onNext: {}
    )
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    WeightInfoStep(
        currentWeight: .constant(78.5),
        targetWeight: .constant(70.0),
        goalType: .constant(.lose),
        weightUnit: .constant(.kg),
        onNext: {}
    )
}
