//
//  MainTabView.swift
//  Heft
//
//  Root TabView wrapping DashboardView and HistoryView.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.heftAccent) private var accent
    @State private var selectedTab: Int = {
        #if DEBUG
        if CommandLine.arguments.contains("--tab-history") { return 1 }
        #endif
        return 0
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(
                        "Ana Sayfa",
                        systemImage: selectedTab == 0 ? "house.fill" : "house"
                    )
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("Geçmiş", systemImage: "list.bullet")
                }
                .tag(1)
        }
        .tint(accent)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

// MARK: - Previews
#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    MainTabView()
        .modelContainer(for: [UserProfile.self, WeightEntry.self], inMemory: true)
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    MainTabView()
        .modelContainer(for: [UserProfile.self, WeightEntry.self], inMemory: true)
}
