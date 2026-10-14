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

    init(date: Date = Date(), weight: Double) {
        self.date = date
        self.weight = weight
    }
}
