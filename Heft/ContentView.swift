//
//  ContentView.swift
//  Heft
//
//  Root router presenting Onboarding or MainTabView.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var profile: UserProfile? {
        profiles.first
    }

    private var isOnboardingCompleted: Bool {
        #if DEBUG
        if CommandLine.arguments.contains("--onboarding") {
            return false
        }
        if CommandLine.arguments.contains("--dashboard") || CommandLine.arguments.contains("--add-weight") || CommandLine.arguments.contains("--tab-history") || CommandLine.arguments.contains("--settings") {
            return true
        }
        #endif
        return profile?.onboardingCompleted == true
    }

    var body: some View {
        Group {
            if isOnboardingCompleted {
                MainTabView()
            } else {
                OnboardingContainerView {
                    // Onboarding sets profile.onboardingCompleted = true
                }
            }
        }
        .environment(\.heftAccent, profile?.gender == .female ? .heftPink : .heftBlue)
        .environment(\.heftAccentFill, profile?.gender == .female ? .heftPinkFill : .heftBlueFill)
        .environment(\.heftAccentPressed, profile?.gender == .female ? .heftPinkPressed : .heftBluePressed)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: isOnboardingCompleted)
    }
}

// MARK: - Previews
#Preview("Male Profile (Blue)") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, WeightEntry.self, configurations: config)
    let profile = UserProfile(
        name: "Efe",
        height: 180,
        age: 28,
        gender: .male,
        initialWeight: 85,
        targetWeight: 75,
        goalType: .lose,
        onboardingCompleted: true
    )
    container.mainContext.insert(profile)
    container.mainContext.insert(WeightEntry(date: Date(), weight: 82.0))
    return ContentView()
        .modelContainer(container)
}

#Preview("Female Profile (Pink)") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, WeightEntry.self, configurations: config)
    let profile = UserProfile(
        name: "Ayşe",
        height: 168,
        age: 26,
        gender: .female,
        initialWeight: 65,
        targetWeight: 58,
        goalType: .lose,
        onboardingCompleted: true
    )
    container.mainContext.insert(profile)
    container.mainContext.insert(WeightEntry(date: Date(), weight: 62.0))
    return ContentView()
        .modelContainer(container)
}

#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    ContentView()
        .modelContainer(for: [UserProfile.self, WeightEntry.self], inMemory: true)
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    ContentView()
        .modelContainer(for: [UserProfile.self, WeightEntry.self], inMemory: true)
}
