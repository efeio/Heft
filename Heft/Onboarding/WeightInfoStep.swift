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

    private var targetErrorMessage: String {
        if !isTargetRangeValid {
            return "Hedef kilo 20 ile 500 kg arasında olmalıdır."
        }
        if goalType == .gain && targetWeight <= currentWeight {
            return "Kilo alma hedefi için hedef kilonuz mevcut kilonuzdan yüksek olmalıdır."
        }
        if goalType == .lose && targetWeight >= currentWeight {
            return "Kilo verme hedefi için hedef kilonuz mevcut kilonuzdan düşük olmalıdır."
        }
        return "Geçersiz hedef kilo."
    }

    private var isValid: Bool {
        isCurrentValid && isTargetValid
    }

    var body: some View {
        OnboardingStepContainer(
            currentStep: 3,
            totalSteps: 5,
            buttonTitle: "İleri",
            isButtonEnabled: isValid,
            onBack: onBack,
            onButtonTap: onNext
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: sectionSpacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kilo Hedefleriniz")
                            .font(.heftScreenTitle)

                        Text("Hedefinizi ve ulaşmak istediğiniz kilonuzu belirleyin.")
                            .font(.heftBody)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.top, 8)

                    // Goal Type Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AMACINIZ NEDİR?")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)

                        HeftGoalSelector(selectedGoal: $goalType)
                    }

                    // Current Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MEVCUT KİLO")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)

                        HeftTickPicker(
                            value: $currentWeight,
                            range: 40...300,
                            step: 0.1,
                            unit: "kg",
                            formatStyle: .decimal,
                            accessibilityTitle: "Mevcut Kilo"
                        )
                    }

                    // Target Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HEDEF KİLO")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)

                        HeftTickPicker(
                            value: $targetWeight,
                            range: 40...300,
                            step: 0.1,
                            unit: "kg",
                            formatStyle: .decimal,
                            accessibilityTitle: "Hedef Kilo"
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
        onNext: {}
    )
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    WeightInfoStep(
        currentWeight: .constant(78.5),
        targetWeight: .constant(70.0),
        goalType: .constant(.lose),
        onNext: {}
    )
}
