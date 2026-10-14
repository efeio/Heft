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
}
