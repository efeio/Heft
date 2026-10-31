//
//  Color+Heft.swift
//  Heft
//
//  Design system color tokens with dynamic Light, Dark, and Increased Contrast support.
//

import SwiftUI
import UIKit

extension Color {
    private static func dynamicColor(
        light: UIColor,
        dark: UIColor,
        highContrastLight: UIColor? = nil,
        highContrastDark: UIColor? = nil
    ) -> Color {
        Color(UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let isHigh = traits.accessibilityContrast == .high
            if isDark {
                return (isHigh ? highContrastDark : nil) ?? dark
            } else {
                return (isHigh ? highContrastLight : nil) ?? light
            }
        })
    }

    // MARK: - Brand (Foreground / Accent)
    static let heftBlue = dynamicColor(
        light: UIColor(red: 0.114, green: 0.306, blue: 0.847, alpha: 1.0),              // #1D4ED8 (6.70:1 on white, 5.30:1 on 15% pill)
        dark: UIColor(red: 0.420, green: 0.588, blue: 1.000, alpha: 1.0),               // #6B96FF (6.02:1 on #1C1C1E, 4.77:1 on 15% pill)
        highContrastLight: UIColor(red: 0.075, green: 0.220, blue: 0.680, alpha: 1.0),  // 9.45:1 on white
        highContrastDark: UIColor(red: 0.560, green: 0.710, blue: 1.000, alpha: 1.0)    // 8.22:1 on #1C1C1E
    )

    static let heftPink = dynamicColor(
        light: UIColor(red: 0.745, green: 0.094, blue: 0.365, alpha: 1.0),              // #BE185D (6.04:1 on white, 4.69:1 on 15% pill)
        dark: UIColor(red: 0.957, green: 0.447, blue: 0.714, alpha: 1.0),               // #F472B6 (6.42:1 on #1C1C1E, 5.08:1 on 15% pill)
        highContrastLight: UIColor(red: 0.580, green: 0.055, blue: 0.278, alpha: 1.0),  // 8.55:1 on white
        highContrastDark: UIColor(red: 0.980, green: 0.580, blue: 0.800, alpha: 1.0)    // 8.35:1 on #1C1C1E
    )

    // MARK: - Brand Solid Fills (Guaranteed >= 6.0:1 with White Text in Light & Dark)
    static let heftBlueFill = dynamicColor(
        light: UIColor(red: 0.114, green: 0.306, blue: 0.847, alpha: 1.0),              // #1D4ED8 (6.70:1 with white)
        dark: UIColor(red: 0.114, green: 0.306, blue: 0.847, alpha: 1.0),               // #1D4ED8 (6.70:1 with white)
        highContrastLight: UIColor(red: 0.075, green: 0.220, blue: 0.680, alpha: 1.0),  // 9.45:1 with white
        highContrastDark: UIColor(red: 0.075, green: 0.220, blue: 0.680, alpha: 1.0)
    )

    static let heftBluePressed = dynamicColor(
        light: UIColor(red: 0.118, green: 0.251, blue: 0.686, alpha: 1.0),              // #1E40AF (8.72:1 with white)
        dark: UIColor(red: 0.118, green: 0.251, blue: 0.686, alpha: 1.0),               // #1E40AF (8.72:1 with white)
        highContrastLight: UIColor(red: 0.059, green: 0.176, blue: 0.549, alpha: 1.0),  // 11.5:1 with white
        highContrastDark: UIColor(red: 0.059, green: 0.176, blue: 0.549, alpha: 1.0)
    )

    static let heftPinkFill = dynamicColor(
        light: UIColor(red: 0.745, green: 0.094, blue: 0.365, alpha: 1.0),              // #BE185D (6.04:1 with white)
        dark: UIColor(red: 0.745, green: 0.094, blue: 0.365, alpha: 1.0),               // #BE185D (6.04:1 with white)
        highContrastLight: UIColor(red: 0.580, green: 0.055, blue: 0.278, alpha: 1.0),  // 8.55:1 with white
        highContrastDark: UIColor(red: 0.580, green: 0.055, blue: 0.278, alpha: 1.0)
    )

    static let heftPinkPressed = dynamicColor(
        light: UIColor(red: 0.616, green: 0.090, blue: 0.302, alpha: 1.0),              // #9D174D (7.86:1 with white)
        dark: UIColor(red: 0.616, green: 0.090, blue: 0.302, alpha: 1.0),               // #9D174D (7.86:1 with white)
        highContrastLight: UIColor(red: 0.480, green: 0.045, blue: 0.230, alpha: 1.0),  // 10.4:1 with white
        highContrastDark: UIColor(red: 0.480, green: 0.045, blue: 0.230, alpha: 1.0)
    )

    static let heftTeal = dynamicColor(
        light: UIColor(red: 0.051, green: 0.431, blue: 0.400, alpha: 1.0),              // #0D6E66 (6.11:1 on white, 4.90:1 on 15% pill)
        dark: UIColor(red: 0.176, green: 0.831, blue: 0.749, alpha: 1.0),               // #2DD4BF (9.14:1 on #1C1C1E, 6.76:1 on 15% pill)
        highContrastLight: UIColor(red: 0.031, green: 0.345, blue: 0.318, alpha: 1.0),  // 8.19:1 on white
        highContrastDark: UIColor(red: 0.369, green: 0.918, blue: 0.831, alpha: 1.0)    // 11.28:1 on #1C1C1E
    )

    static let heftNavy = Color(red: 0.047, green: 0.106, blue: 0.302)

    // MARK: - Canvas & Surfaces (Dynamic)
    static let heftCanvas = dynamicColor(
        light: UIColor(red: 0.969, green: 0.973, blue: 0.980, alpha: 1.0),              // #F7F8FA
        dark: UIColor(red: 0.067, green: 0.071, blue: 0.078, alpha: 1.0),               // #111214
        highContrastLight: UIColor(red: 0.949, green: 0.957, blue: 0.969, alpha: 1.0),
        highContrastDark: UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.0)
    )

    static let heftSurface = dynamicColor(
        light: UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.0),              // #FFFFFF
        dark: UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1.0),               // #1C1C1E
        highContrastLight: UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.0),
        highContrastDark: UIColor(red: 0.086, green: 0.086, blue: 0.094, alpha: 1.0)
    )

    static let heftSurfaceSub = dynamicColor(
        light: UIColor(red: 0.949, green: 0.953, blue: 0.969, alpha: 1.0),              // #F2F3F7
        dark: UIColor(red: 0.149, green: 0.149, blue: 0.161, alpha: 1.0),               // #262629
        highContrastLight: UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1.0),
        highContrastDark: UIColor(red: 0.173, green: 0.173, blue: 0.188, alpha: 1.0)
    )

    static let heftDivider = dynamicColor(
        light: UIColor(red: 0.886, green: 0.898, blue: 0.925, alpha: 1.0),              // #E2E5EC
        dark: UIColor(red: 0.173, green: 0.176, blue: 0.196, alpha: 1.0),               // #2C2D32
        highContrastLight: UIColor(red: 0.612, green: 0.639, blue: 0.686, alpha: 1.0),
        highContrastDark: UIColor(red: 0.388, green: 0.388, blue: 0.400, alpha: 1.0)
    )

    // MARK: - Legacy Dark Surface Aliases
    static let heftDarkCanvas = Color(red: 0.067, green: 0.071, blue: 0.078)
    static let heftDarkSurface1 = Color(red: 0.110, green: 0.110, blue: 0.118)
    static let heftDarkSurface2 = Color(red: 0.149, green: 0.149, blue: 0.161)
    static let heftDarkDivider = Color(red: 0.173, green: 0.176, blue: 0.196)

    // MARK: - Text (Dynamic)
    static let heftTextPrimary = dynamicColor(
        light: UIColor(red: 0.078, green: 0.086, blue: 0.098, alpha: 1.0),              // #141619 (18.1:1 on white)
        dark: UIColor(red: 0.949, green: 0.953, blue: 0.961, alpha: 1.0),               // #F2F3F5 (16.8:1 on #111214)
        highContrastLight: UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.0),
        highContrastDark: UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.0)
    )

    static let heftTextSecondary = dynamicColor(
        light: UIColor(red: 0.322, green: 0.337, blue: 0.376, alpha: 1.0),              // #525660 (7.24:1 on white)
        dark: UIColor(red: 0.620, green: 0.624, blue: 0.659, alpha: 1.0),               // #9E9FA8 (6.55:1 on #1C1C1E)
        highContrastLight: UIColor(red: 0.204, green: 0.216, blue: 0.239, alpha: 1.0),
        highContrastDark: UIColor(red: 0.780, green: 0.784, blue: 0.820, alpha: 1.0)
    )

    static let heftTextPrimaryDark = Color(red: 0.949, green: 0.953, blue: 0.961)
    static let heftTextSecondaryDark = Color(red: 0.620, green: 0.624, blue: 0.659)

    // MARK: - BMI Band Colors
    static let heftBMIUnder = heftBlue
    static let heftBMINormal = heftTeal

    static let heftBMIOver = dynamicColor(
        light: UIColor(red: 0.604, green: 0.259, blue: 0.024, alpha: 1.0),              // #9A4206 (6.65:1 on white, 5.28:1 on 15% pill)
        dark: UIColor(red: 0.984, green: 0.749, blue: 0.141, alpha: 1.0),               // #FBBF24 (10.19:1 on #1C1C1E, 7.31:1 on 15% pill)
        highContrastLight: UIColor(red: 0.486, green: 0.176, blue: 0.020, alpha: 1.0),  // 9.12:1 on white
        highContrastDark: UIColor(red: 0.992, green: 0.847, blue: 0.353, alpha: 1.0)    // 12.18:1 on #1C1C1E
    )

    static let heftBMIObese = dynamicColor(
        light: UIColor(red: 0.725, green: 0.110, blue: 0.110, alpha: 1.0),              // #B91C1C (6.47:1 on white, 5.01:1 on 15% pill)
        dark: UIColor(red: 1.000, green: 0.420, blue: 0.420, alpha: 1.0),               // #FF6B6B (6.13:1 on #1C1C1E, 4.92:1 on 15% pill)
        highContrastLight: UIColor(red: 0.600, green: 0.059, blue: 0.059, alpha: 1.0),  // 8.47:1 on white
        highContrastDark: UIColor(red: 1.000, green: 0.560, blue: 0.560, alpha: 1.0)    // 7.92:1 on #1C1C1E
    )

    // MARK: - Semantic
    static let heftSuccess = heftTeal
    static let heftWarning = heftBMIOver
    static let heftError = heftBMIObese
    static let heftNeutral = heftTextSecondary
}

// MARK: - Accent Environment
private struct HeftAccentKey: EnvironmentKey {
    static let defaultValue: Color = .heftBlue
}

private struct HeftAccentFillKey: EnvironmentKey {
    static let defaultValue: Color = .heftBlueFill
}

private struct HeftAccentPressedKey: EnvironmentKey {
    static let defaultValue: Color = .heftBluePressed
}

extension EnvironmentValues {
    var heftAccent: Color {
        get { self[HeftAccentKey.self] }
        set { self[HeftAccentKey.self] = newValue }
    }
    var heftAccentFill: Color {
        get { self[HeftAccentFillKey.self] }
        set { self[HeftAccentFillKey.self] = newValue }
    }
    var heftAccentPressed: Color {
        get { self[HeftAccentPressedKey.self] }
        set { self[HeftAccentPressedKey.self] = newValue }
    }
}
