//
//  WelcomeStep.swift
//  Heft
//
//  Onboarding Step 1: Welcome & introduction.
//

import SwiftUI

struct WelcomeStep: View {
    let onStart: () -> Void

    @Environment(\.heftAccent) private var accent
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 110

    var body: some View {
        OnboardingStepContainer(
            currentStep: 1,
            totalSteps: 5,
            buttonTitle: "Başla",
            isButtonEnabled: true,
            onButtonTap: onStart
        ) {
            VStack(spacing: 24) {
                Spacer()

                // Welcome Icon
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: circleSize, height: circleSize)

                    Image(systemName: "scalemass.fill")
                        .font(.largeTitle.weight(.semibold))
                        .imageScale(.large)
                        .foregroundStyle(accent)
                }
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Heft")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(accent)

                    Text("Kişisel kilo takip asistanınız.\nHedefinize adım adım, sağlıklı biçimde ulaşın.")
                        .font(.heftBody)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary)
                        .scenePadding(.horizontal)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    WelcomeStep(onStart: {})
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    WelcomeStep(onStart: {})
}
