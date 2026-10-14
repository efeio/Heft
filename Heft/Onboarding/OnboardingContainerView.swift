//
//  OnboardingContainerView.swift
//  Heft
//
//  Full-screen paged container managing the 5-step onboarding flow.
//

import SwiftUI

struct OnboardingContainerView: View {
    let onCompleted: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentStep = 1
    @State private var nameText = ""
    @State private var height: Double = 170
    @State private var age: Double = 25
    @State private var gender: Gender = .male
    @State private var currentWeight: Double = 75
    @State private var targetWeight: Double = 65
    @State private var goalType: GoalType = .lose
    @State private var weighInFrequency: WeighInFrequency = .daily
    @State private var weighInDays: [Int] = [2]
    @State private var weighInDay = 2 // Pazartesi = 2
    @State private var weighInTime: Date = {
        var comps = DateComponents()
        comps.hour = 8
        comps.minute = 30
        return Calendar.current.date(from: comps) ?? Date()
    }()

    var body: some View {
        ZStack {
            switch currentStep {
            case 1:
                WelcomeStep {
                    goToStep(2)
                }
                .transition(stepTransition)

            case 2:
                BodyInfoStep(
                    nameText: $nameText,
                    height: $height,
                    age: $age,
                    gender: $gender,
                    onBack: goBack,
                    onNext: { goToStep(3) }
                )
                .transition(stepTransition)

            case 3:
                WeightInfoStep(
                    currentWeight: $currentWeight,
                    targetWeight: $targetWeight,
                    goalType: $goalType,
                    onBack: goBack,
                    onNext: { goToStep(4) }
                )
                .transition(stepTransition)

            case 4:
                ScheduleStep(
                    weighInFrequency: $weighInFrequency,
                    weighInDays: $weighInDays,
                    weighInTime: $weighInTime,
                    onBack: goBack,
                    onNext: { goToStep(5) }
                )
                .transition(stepTransition)

            case 5:
                AllSetStep(
                    name: nameText.trimmingCharacters(in: .whitespacesAndNewlines),
                    height: parsedHeight,
                    age: parsedAge,
                    gender: gender,
                    currentWeight: parsedCurrentWeight,
                    targetWeight: parsedTargetWeight,
                    goalType: goalType,
                    weighInFrequency: weighInFrequency,
                    weighInDays: weighInDays,
                    weighInDay: weighInDays.first ?? weighInDay,
                    weighInTime: weighInTime,
                    onBack: goBack,
                    onFinish: onCompleted
                )
                .transition(stepTransition)


            default:
                EmptyView()
            }
        }
        .environment(\.heftAccent, gender == .female ? .heftPink : .heftBlue)
        .environment(\.heftAccentPressed, gender == .female ? .heftPinkPressed : .heftBluePressed)
        .animation(reduceMotion ? .linear(duration: 0.2) : .easeOut(duration: 0.3), value: currentStep)
    }

    private var stepTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        } else {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }

    private func goToStep(_ step: Int) {
        currentStep = step
    }

    private func goBack() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }

    private var parsedHeight: Double { height }
    private var parsedAge: Int { Int(age) }
    private var parsedCurrentWeight: Double { currentWeight }
    private var parsedTargetWeight: Double { targetWeight }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    OnboardingContainerView(onCompleted: {})
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    OnboardingContainerView(onCompleted: {})
}
