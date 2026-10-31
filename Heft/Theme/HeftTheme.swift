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
