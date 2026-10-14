//
//  HeftTheme.swift
//  Heft
//
//  Theme modifiers and global styling for Heft.
//

import SwiftUI

struct HeftThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? Color.heftDarkCanvas : Color.heftCanvas)
            .foregroundStyle(colorScheme == .dark ? Color.heftTextPrimaryDark : Color.heftTextPrimary)
    }
}

struct HeftCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .body) var cornerRadius: CGFloat = 18
    @ScaledMetric(relativeTo: .body) var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(colorScheme == .dark ? Color.heftDarkSurface1 : Color.heftSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.heftDarkDivider : Color.heftDivider, lineWidth: 1)
            }
            .shadow(
                color: colorScheme == .dark ? Color.clear : Color.heftNavy.opacity(0.06),
                radius: colorScheme == .dark ? 0 : 14,
                x: 0,
                y: colorScheme == .dark ? 0 : 4
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
        scheme == .dark ? .heftDarkCanvas : .heftCanvas
    }

    static func heftAdaptiveSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .heftDarkSurface1 : .heftSurface
    }

    static func heftAdaptiveSurfaceSub(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .heftDarkSurface2 : .heftSurfaceSub
    }

    static func heftAdaptiveDivider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .heftDarkDivider : .heftDivider
    }

    static func heftAdaptiveTextPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .heftTextPrimaryDark : .heftTextPrimary
    }

    static func heftAdaptiveTextSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .heftTextSecondaryDark : .heftTextSecondary
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
