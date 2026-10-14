//
//  BodyInfoStep.swift
//  Heft
//
//  Onboarding Step 2: Height, age, and gender input.
//

import SwiftUI

struct BodyInfoStep: View {
    @Binding var nameText: String
    @Binding var height: Double
    @Binding var age: Double
    @Binding var gender: Gender

    var onBack: (() -> Void)? = nil
    let onNext: () -> Void

    @ScaledMetric(relativeTo: .body) private var sectionSpacing: CGFloat = 22

    @State private var hasInteractedName = false

    private var isNameValid: Bool {
        !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isHeightValid: Bool {
        height >= 50 && height <= 300
    }

    private var isAgeValid: Bool {
        age >= 1 && age <= 120
    }

    private var isValid: Bool {
        isNameValid && isHeightValid && isAgeValid
    }

    var body: some View {
        OnboardingStepContainer(
            currentStep: 2,
            totalSteps: 5,
            buttonTitle: "İleri",
            isButtonEnabled: isValid,
            onBack: onBack,
            onButtonTap: onNext
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: sectionSpacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kişisel Bilgiler")
                            .font(.heftScreenTitle)

                        Text("Seni daha iyi tanımamız ve doğru analizler için temel bilgilerinizi girin.")
                            .font(.heftBody)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.top, 8)

                    // Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("İSİM")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)

                        HeftTextInputCard(
                            icon: "person.fill",
                            title: "Adınız",
                            subtitle: "Hitap ve bildirimler için",
                            placeholder: "Örn: Efe",
                            text: $nameText,
                            isError: hasInteractedName && !isNameValid,
                            errorMessage: "Lütfen adınızı girin.",
                            onTextChange: { hasInteractedName = true }
                        )
                    }

                    // Gender Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CİNSİYET")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)

                        HeftGenderSelector(selectedGender: $gender)
                    }

                    // Height Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BOY")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)

                        HeftTickPicker(value: $height, range: 120...250, step: 1, unit: "cm", formatStyle: .integer)
                    }

                    // Age Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YAŞ")
                            .heftEyebrowStyle()
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)

                        HeftTickPicker(value: $age, range: 13...100, step: 1, unit: "yıl", formatStyle: .integer)
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
    BodyInfoStep(
        nameText: .constant("Efe"),
        height: .constant(178),
        age: .constant(26),
        gender: .constant(.male),
        onNext: {}
    )
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    BodyInfoStep(
        nameText: .constant("Efe"),
        height: .constant(178),
        age: .constant(26),
        gender: .constant(.male),
        onNext: {}
    )
}
