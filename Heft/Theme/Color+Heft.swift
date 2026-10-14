//
//  Color+Heft.swift
//  Heft
//
//  Design system color tokens adapted from Noom.
//

import SwiftUI

extension Color {
    // MARK: - Brand
    static let heftBlue = Color(red: 0.165, green: 0.365, blue: 0.965)
    static let heftBluePressed = Color(red: 0.118, green: 0.278, blue: 0.784)
    static let heftPink = Color(red: 0.847, green: 0.380, blue: 0.514)
    static let heftPinkPressed = Color(red: 0.722, green: 0.298, blue: 0.420)
    static let heftTeal = Color(red: 0.122, green: 0.761, blue: 0.608)
    static let heftNavy = Color(red: 0.047, green: 0.106, blue: 0.302)

    // MARK: - Canvas & Surfaces (Light)
    static let heftCanvas = Color(red: 0.984, green: 0.984, blue: 0.992)
    static let heftSurface = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let heftSurfaceSub = Color(red: 0.949, green: 0.953, blue: 0.969)
    static let heftDivider = Color(red: 0.902, green: 0.906, blue: 0.925)

    // MARK: - Canvas & Surfaces (Dark)
    static let heftDarkCanvas = Color(red: 0.071, green: 0.071, blue: 0.071)
    static let heftDarkSurface1 = Color(red: 0.110, green: 0.110, blue: 0.118)
    static let heftDarkSurface2 = Color(red: 0.149, green: 0.149, blue: 0.161)
    static let heftDarkDivider = Color(red: 0.180, green: 0.180, blue: 0.192)

    // MARK: - Text
    static let heftTextPrimary = Color(red: 0.102, green: 0.102, blue: 0.122)
    static let heftTextSecondary = Color(red: 0.416, green: 0.416, blue: 0.439)
    static let heftTextPrimaryDark = Color(red: 0.941, green: 0.941, blue: 0.949)
    static let heftTextSecondaryDark = Color(red: 0.604, green: 0.604, blue: 0.627)

    // MARK: - BMI Band Colors
    static let heftBMIUnder = heftBlue
    static let heftBMINormal = heftTeal
    static let heftBMIOver = Color(red: 1.000, green: 0.773, blue: 0.192)
    static let heftBMIObese = Color(red: 1.000, green: 0.353, blue: 0.322)

    // MARK: - Semantic
    static let heftSuccess = heftTeal
    static let heftWarning = Color(red: 1.000, green: 0.773, blue: 0.192)
    static let heftError = Color(red: 1.000, green: 0.353, blue: 0.322)
    static let heftNeutral = heftTextSecondary
}

// MARK: - Accent Environment
private struct HeftAccentKey: EnvironmentKey {
    static let defaultValue: Color = .heftBlue
}

private struct HeftAccentPressedKey: EnvironmentKey {
    static let defaultValue: Color = .heftBluePressed
}

extension EnvironmentValues {
    var heftAccent: Color {
        get { self[HeftAccentKey.self] }
        set { self[HeftAccentKey.self] = newValue }
    }
    var heftAccentPressed: Color {
        get { self[HeftAccentPressedKey.self] }
        set { self[HeftAccentPressedKey.self] = newValue }
    }
}
