//
//  Font+Heft.swift
//  Heft
//
//  Semantic typography tokens using Dynamic Type styles.
//

import SwiftUI

extension Font {
    static let heftHeroStat = Font.system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit()
    static let heftScreenTitle = Font.title.weight(.bold)
    static let heftSection = Font.title2.weight(.bold)
    static let heftCardTitle = Font.title3.weight(.bold)
    static let heftBody = Font.body
    static let heftBodySemibold = Font.body.weight(.semibold)
    static let heftListItem = Font.subheadline.weight(.semibold)
    static let heftMeta = Font.footnote
    static let heftMetaSemibold = Font.footnote.weight(.semibold).monospacedDigit()
    static let heftEyebrow = Font.caption.weight(.semibold)
    static let heftButton = Font.headline.weight(.bold)
    static let heftTab = Font.caption2.weight(.semibold)
    static let heftChartAxis = Font.caption2.weight(.bold)
}

extension View {
    /// Applies eyebrow typography with tracking 1.0
    func heftEyebrowStyle() -> some View {
        self.font(.heftEyebrow)
            .tracking(1.0)
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    VStack(alignment: .leading, spacing: 12) {
        Text("Hero Stat: 78.5 kg").font(.heftHeroStat)
        Text("Screen Title").font(.heftScreenTitle)
        Text("Section Title").font(.heftSection)
        Text("Card Title").font(.heftCardTitle)
        Text("Body Text").font(.heftBody)
        Text("Meta Text").font(.heftMeta)
        Text("Eyebrow").heftEyebrowStyle()
    }
    .padding()
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    VStack(alignment: .leading, spacing: 12) {
        Text("Hero Stat: 78.5 kg").font(.heftHeroStat)
        Text("Screen Title").font(.heftScreenTitle)
        Text("Section Title").font(.heftSection)
        Text("Card Title").font(.heftCardTitle)
        Text("Body Text").font(.heftBody)
        Text("Meta Text").font(.heftMeta)
        Text("Eyebrow").heftEyebrowStyle()
    }
    .padding()
}
