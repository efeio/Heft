//
//  WeightEntry.swift
//  Heft
//
//  SwiftData model for weight entries.
//  Note: No computed BMI property on model. BMI is computed dynamically at the view layer.
//

import Foundation
import SwiftData

@Model
final class WeightEntry {
    var date: Date
    var weight: Double
    var healthKitUUID: UUID?

    init(date: Date = Date(), weight: Double, healthKitUUID: UUID? = nil) {
        self.date = date
        self.weight = weight
        self.healthKitUUID = healthKitUUID
    }
}
