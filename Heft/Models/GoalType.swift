//
//  GoalType.swift
//  Heft
//
//  Weight tracking goal direction (lose or gain).
//

import Foundation

enum GoalType: String, Codable, CaseIterable {
    case lose
    case gain
    case maintain

    var label: String {
        switch self {
        case .lose: return String(localized: "Kilo Vermek", comment: "Goal type lose weight")
        case .maintain: return String(localized: "Korumak", comment: "Goal type maintain weight")
        case .gain: return String(localized: "Kilo Almak", comment: "Goal type gain weight")
        }
    }

    var fullLabel: String {
        switch self {
        case .lose: return String(localized: "Kilo Vermek", comment: "Goal type lose weight full")
        case .maintain: return String(localized: "Kilo Korumak", comment: "Goal type maintain weight full")
        case .gain: return String(localized: "Kilo Almak", comment: "Goal type gain weight full")
        }
    }

    var explanation: String {
        switch self {
        case .lose:
            return String(localized: "Kilo verme modunda azalışlar başarı olarak değerlendirilir.", comment: "Goal lose explanation")
        case .maintain:
            return String(localized: "Kilo koruma modunda mevcut kilonu dengede tutman hedeflenir.", comment: "Goal maintain explanation")
        case .gain:
            return String(localized: "Kilo alma modunda artışlar pozitif olarak değerlendirilir.", comment: "Goal gain explanation")
        }
    }
}
