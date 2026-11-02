//
//  HeftTheme.swift
//  Heft
//
//  Theme modifiers and global styling for Heft.
//

import SwiftUI

struct HeftThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.heftCanvas)
            .foregroundStyle(Color.heftTextPrimary)
    }
}

struct HeftCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .body) var cornerRadius: CGFloat = 18
    @ScaledMetric(relativeTo: .body) var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.heftSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.heftDivider,
                        lineWidth: contrast == .increased ? 1.5 : 1.0
                    )
            }
            .shadow(
                color: (colorScheme == .dark || contrast == .increased) ? Color.clear : Color.heftNavy.opacity(0.05),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

extension View {
    /// Applies Heft root theme background and text colors
    func heftTheme() -> some View {
        self.modifier(HeftThemeModifier())
    }

    /// Wraps content in a standardized Heft Card container
    func heftCard(cornerRadius: CGFloat = 18, padding: CGFloat = 16) -> some View {
        self.modifier(HeftCardStyle(cornerRadius: cornerRadius, padding: padding))
    }
}

extension Color {
    static func heftAdaptiveCanvas(_ scheme: ColorScheme) -> Color {
        .heftCanvas
    }

    static func heftAdaptiveSurface(_ scheme: ColorScheme) -> Color {
        .heftSurface
    }

    static func heftAdaptiveSurfaceSub(_ scheme: ColorScheme) -> Color {
        .heftSurfaceSub
    }

    static func heftAdaptiveDivider(_ scheme: ColorScheme) -> Color {
        .heftDivider
    }

    static func heftAdaptiveTextPrimary(_ scheme: ColorScheme) -> Color {
        .heftTextPrimary
    }

    static func heftAdaptiveTextSecondary(_ scheme: ColorScheme) -> Color {
        .heftTextSecondary
    }
}

// MARK: - Locale-Aware Number Formatting & Parsing
enum HeftFormat {
    static var locale: Locale { Locale.autoupdatingCurrent }

    static var decimalSeparator: String {
        locale.decimalSeparator ?? "."
    }

    private static func createOneDecimalFormatter(for locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = false
        return formatter
    }

    private static func createIntegerFormatter(for locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter
    }

    private static var cachedLocaleId: String = ""
    private static var cachedOneDecimalFormatter: NumberFormatter = createOneDecimalFormatter(for: Locale.autoupdatingCurrent)
    private static var cachedIntegerFormatter: NumberFormatter = createIntegerFormatter(for: Locale.autoupdatingCurrent)

    private static var oneDecimalFormatter: NumberFormatter {
        let currentId = Locale.autoupdatingCurrent.identifier
        if cachedLocaleId != currentId {
            cachedLocaleId = currentId
            cachedOneDecimalFormatter = createOneDecimalFormatter(for: Locale.autoupdatingCurrent)
            cachedIntegerFormatter = createIntegerFormatter(for: Locale.autoupdatingCurrent)
        }
        return cachedOneDecimalFormatter
    }

    private static var integerFormatter: NumberFormatter {
        let currentId = Locale.autoupdatingCurrent.identifier
        if cachedLocaleId != currentId {
            cachedLocaleId = currentId
            cachedOneDecimalFormatter = createOneDecimalFormatter(for: Locale.autoupdatingCurrent)
            cachedIntegerFormatter = createIntegerFormatter(for: Locale.autoupdatingCurrent)
        }
        return cachedIntegerFormatter
    }

    static func weight(_ value: Double) -> String {
        oneDecimalFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    static func weightKg(_ value: Double) -> String {
        "\(weight(value)) kg"
    }

    static func signedWeight(_ delta: Double, showZeroSign: Bool = false) -> String {
        let absFormatted = weight(abs(delta))
        if abs(delta) < 0.05 {
            return showZeroSign ? "+\(weight(0))" : weight(0)
        }
        return delta > 0 ? "+\(absFormatted)" : "−\(absFormatted)"
    }

    static func signedWeightKg(_ delta: Double, showZeroSign: Bool = false) -> String {
        "\(signedWeight(delta, showZeroSign: showZeroSign)) kg"
    }

    static func integer(_ value: Double) -> String {
        integerFormatter.string(from: NSNumber(value: value.rounded())) ?? String(format: "%.0f", value)
    }

    static func parseDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let number = oneDecimalFormatter.number(from: trimmed) {
            return number.doubleValue
        }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    VStack {
        Text("Sample Card Content")
            .font(.heftBody)
            .heftCard()
    }
    .padding()
    .heftTheme()
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    VStack {
        Text("Sample Card Content")
            .font(.heftBody)
            .heftCard()
    }
    .padding()
    .heftTheme()
}
