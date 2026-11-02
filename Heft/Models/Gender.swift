//
//  Gender.swift
//  Heft
//
//  Gender representation for user profile and health calculations.
//

import Foundation

enum Gender: String, Codable, CaseIterable {
    case male
    case female

    var label: String {
        switch self {
        case .male: return String(localized: "Erkek", comment: "Gender option male")
        case .female: return String(localized: "Kadın", comment: "Gender option female")
        }
    }
}
