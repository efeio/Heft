//
//  UserProfile.swift
//  Heft
//
//  Single-record SwiftData model storing user profile, targets, and reminder schedule.
//

import Foundation
import SwiftData

enum WeighInFrequency: String, CaseIterable, Identifiable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case custom = "custom"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily: return "Her Gün"
        case .weekly: return "Haftada 1 Gün"
        case .custom: return "Belirli Günler"
        }
    }
}

@Model
final class UserProfile {
    var name: String = ""
    var height: Double
    var age: Int
    var rawGender: String = "male"
    var initialWeight: Double
    var targetWeight: Double
    var rawGoalType: String = "lose"
    var weighInDay: Int
    var weighInHour: Int
    var weighInMinute: Int
    var rawWeighInFrequency: String = "weekly"
    var rawWeighInDays: String = "2"
    var onboardingCompleted: Bool

    var isGainGoal: Bool {
        goalType == .gain
    }

    var isMaintainGoal: Bool {
        goalType == .maintain
    }

    @Transient
    var gender: Gender {
        get {
            Gender(rawValue: rawGender) ?? .male
        }
        set {
            rawGender = newValue.rawValue
        }
    }

    @Transient
    var goalType: GoalType {
        get {
            GoalType(rawValue: rawGoalType) ?? .lose
        }
        set {
            rawGoalType = newValue.rawValue
        }
    }

    @Transient
    var weighInFrequency: WeighInFrequency {
        get {
            WeighInFrequency(rawValue: rawWeighInFrequency) ?? .weekly
        }
        set {
            rawWeighInFrequency = newValue.rawValue
        }
    }

    @Transient
    var weighInDaysList: [Int] {
        get {
            let list = rawWeighInDays.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            return list.isEmpty ? [weighInDay] : list
        }
        set {
            rawWeighInDays = newValue.map(String.init).joined(separator: ",")
            if let first = newValue.first {
                weighInDay = first
            }
        }
    }

    init(
        name: String = "",
        height: Double,
        age: Int,
        gender: Gender = .male,
        initialWeight: Double,
        targetWeight: Double,
        goalType: GoalType = .lose,
        weighInDay: Int = 2, // Default: Pazartesi (Monday = 2 in Calendar)
        weighInHour: Int = 9,
        weighInMinute: Int = 0,
        rawWeighInFrequency: String = "weekly",
        rawWeighInDays: String = "2",
        onboardingCompleted: Bool = false
    ) {
        self.name = name
        self.height = height
        self.age = age
        self.rawGender = gender.rawValue
        self.initialWeight = initialWeight
        self.targetWeight = targetWeight
        self.rawGoalType = goalType.rawValue
        self.weighInDay = weighInDay
        self.weighInHour = weighInHour
        self.weighInMinute = weighInMinute
        self.rawWeighInFrequency = rawWeighInFrequency
        self.rawWeighInDays = rawWeighInDays
        self.onboardingCompleted = onboardingCompleted
    }
}

