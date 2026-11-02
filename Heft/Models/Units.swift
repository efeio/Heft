//
//  Units.swift
//  Heft
//
//  Measurement units and conversions for weight and height.
//

import Foundation

public enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg = "kg"
    case lbs = "lbs"

    public var id: String { rawValue }

    public var label: String { rawValue }

    public var localizedName: String {
        switch self {
        case .kg:
            return String(localized: "Kilogram (kg)", comment: "Weight unit kg")
        case .lbs:
            return String(localized: "Pound (lbs)", comment: "Weight unit lbs")
        }
    }

    public var shortName: String {
        switch self {
        case .kg:
            return String(localized: "kg", comment: "Short weight unit kg")
        case .lbs:
            return String(localized: "lbs", comment: "Short weight unit lbs")
        }
    }
}

public enum HeightUnit: String, Codable, CaseIterable, Identifiable {
    case cm = "cm"
    case ftIn = "ftIn"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .cm: return "cm"
        case .ftIn: return "ft / in"
        }
    }

    public var localizedName: String {
        switch self {
        case .cm:
            return String(localized: "Santimetre (cm)", comment: "Height unit cm")
        case .ftIn:
            return String(localized: "Fit & İnç (ft / in)", comment: "Height unit ft/in")
        }
    }
}

public enum UnitConverter {
    // 1 kg = 2.20462262185 lbs
    public static let lbsPerKg: Double = 2.20462262185
    public static let cmPerInch: Double = 2.54
    public static let inchesPerFoot: Double = 12.0

    public static func kgToLbs(_ kg: Double) -> Double {
        kg * lbsPerKg
    }

    public static func lbsToKg(_ lbs: Double) -> Double {
        lbs / lbsPerKg
    }

    public static func cmToInches(_ cm: Double) -> Double {
        cm / cmPerInch
    }

    public static func inchesToCm(_ inches: Double) -> Double {
        inches * cmPerInch
    }

    public static func cmToFtIn(_ cm: Double) -> (feet: Int, inches: Double) {
        let totalInches = cmToInches(cm)
        let feet = Int(totalInches / inchesPerFoot)
        let remainingInches = (totalInches.truncatingRemainder(dividingBy: inchesPerFoot) * 10).rounded() / 10.0
        return (feet, remainingInches)
    }

    public static func ftInToCm(feet: Int, inches: Double) -> Double {
        let totalInches = Double(feet) * inchesPerFoot + inches
        return inchesToCm(totalInches)
    }
}
