//
//  BMICalculator.swift
//  Heft
//
//  BMI Calculation utility with division-by-zero guard.
//

import Foundation
import SwiftUI

enum BMICalculator {
    static func calculate(weightKg: Double, heightCm: Double) -> Double? {
        guard heightCm > 0 else { return nil }
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    /// Formats a BMI value to 1 decimal place (e.g., "24.3") or "—" if nil.
    static func formatted(weightKg: Double, heightCm: Double) -> String {
        guard let bmi = calculate(weightKg: weightKg, heightCm: heightCm) else {
            return "—"
        }
        return String(format: "%.1f", bmi)
    }

    /// Returns the localized category description.
    static func category(for bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return String(localized: "Düşük Kilolu", comment: "BMI category Underweight")
        case 18.5..<25.0:
            return String(localized: "Normal", comment: "BMI category Normal")
        case 25.0..<30.0:
            return String(localized: "Fazla Kilolu", comment: "BMI category Overweight")
        default:
            return String(localized: "Obez", comment: "BMI category Obese")
        }
    }

    /// Returns the design system token color for the BMI band.
    static func color(for bmi: Double) -> Color {
        switch bmi {
        case ..<18.5:
            return Color.heftBMIUnder
        case 18.5..<25.0:
            return Color.heftBMINormal
        case 25.0..<30.0:
            return Color.heftBMIOver
        default:
            return Color.heftBMIObese
        }
    }
}
