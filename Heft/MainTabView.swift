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
                    Label("Ana Sayfa", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("Geçmiş", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
        }
        .tint(accent)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .modifier(SidebarAdaptableTabModifier())
        #if DEBUG
        .task {
            if CommandLine.arguments.contains("--auto-record-demo") {
                startAutoRecordDemo()
            }
        }
        #endif
    }

    #if DEBUG
    private func startAutoRecordDemo() {
        Task { @MainActor in
            // 0.0s - 4.0s: Home Dashboard overview (app launched from SpringBoard)
            try? await Task.sleep(nanoseconds: 4_000_000_000)

            // 4.0s - 8.0s: Scroll down to reveal charts
            NotificationCenter.default.post(name: Notification.Name("heft_demo_scroll_charts"), object: nil)
            try? await Task.sleep(nanoseconds: 4_000_000_000)

            // 8.0s - 10.0s: Scroll back up to top
            NotificationCenter.default.post(name: Notification.Name("heft_demo_scroll_top"), object: nil)
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // 10.0s - 15.0s: Open Add Weight Sheet
            NotificationCenter.default.post(name: Notification.Name("heft_demo_open_add_weight"), object: nil)
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // Tap micro-stepper (+0.1 kg)
            NotificationCenter.default.post(name: Notification.Name("heft_demo_step_plus"), object: nil)
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            NotificationCenter.default.post(name: Notification.Name("heft_demo_step_plus"), object: nil)
            try? await Task.sleep(nanoseconds: 1_800_000_000)

            // 15.0s: Close Add Weight Sheet
            NotificationCenter.default.post(name: Notification.Name("heft_demo_close_add_weight"), object: nil)
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            // 16.5s - 21.5s: Switch to History Tab
            withAnimation(.easeInOut(duration: 0.35)) {
                selectedTab = 1
            }
            try? await Task.sleep(nanoseconds: 5_000_000_000)

            // 21.5s - 23.5s: Switch back to Dashboard Tab
            withAnimation(.easeInOut(duration: 0.35)) {
                selectedTab = 0
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // 23.5s - 29.5s: Open Settings
            NotificationCenter.default.post(name: Notification.Name("heft_demo_open_settings"), object: nil)
            try? await Task.sleep(nanoseconds: 6_000_000_000)

            // 29.5s - 32.0s: Dismiss Settings
            NotificationCenter.default.post(name: Notification.Name("heft_demo_close_settings"), object: nil)
            try? await Task.sleep(nanoseconds: 2_500_000_000)
        }
    }
    #endif
}

private struct SidebarAdaptableTabModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.tabViewStyle(.sidebarAdaptable)
        } else {
            content
        }
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
