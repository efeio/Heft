//
//  HeftApp.swift
//  Heft
//
//  Main application entrypoint with SwiftData container and root theme.
//

import SwiftUI
import SwiftData

@main
struct HeftApp: App {
    @State private var container: ModelContainer?
    @State private var containerError: String?

    init() {
        let (c, err) = Self.createModelContainer()
        _container = State(initialValue: c)
        _containerError = State(initialValue: err)
    }

    private static func createModelContainer() -> (ModelContainer?, String?) {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        func purgeStoreFiles(at storeURL: URL) {
            let fm = FileManager.default
            let dir = storeURL.deletingLastPathComponent()
            let storeBase = storeURL.lastPathComponent
            if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for file in files {
                    let name = file.lastPathComponent
                    if name.hasPrefix(storeBase) || name.contains("default.store") {
                        try? fm.removeItem(at: file)
                    }
                }
            }
        }

        #if DEBUG
        if CommandLine.arguments.contains("--reset-db") {
            purgeStoreFiles(at: modelConfiguration.url)
        }
        #endif

        let storeDir = modelConfiguration.url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true, attributes: [
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ])
        try? FileManager.default.setAttributes([
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ], ofItemAtPath: storeDir.path)

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: HeftMigrationPlan.self,
                configurations: [modelConfiguration]
            )

            if FileManager.default.fileExists(atPath: modelConfiguration.url.path) {
                try? FileManager.default.setAttributes([
                    .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
                ], ofItemAtPath: modelConfiguration.url.path)
            }

            let context = container.mainContext
            var descriptor = FetchDescriptor<UserProfile>()
            descriptor.fetchLimit = 1
            _ = try context.fetch(descriptor)

            #if DEBUG
            if CommandLine.arguments.contains("--seed-demo") {
                let existingProfiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
                for p in existingProfiles { context.delete(p) }
                let existingEntries = (try? context.fetch(FetchDescriptor<WeightEntry>())) ?? []
                for e in existingEntries { context.delete(e) }

                let profile = UserProfile(
                    name: "Alex",
                    height: 180,
                    age: 28,
                    gender: .male,
                    initialWeight: 84.5,
                    targetWeight: 75.0,
                    goalType: .lose,
                    rawWeightUnit: "kg",
                    rawHeightUnit: "cm",
                    onboardingCompleted: true
                )
                context.insert(profile)

                let calendar = Calendar.current
                let now = Date()
                let weights: [Double] = [
                    84.5, 84.1, 83.8, 83.5, 83.1, 82.7, 82.9, 82.3,
                    81.9, 81.5, 81.1, 80.8, 80.2, 79.9, 79.4, 78.8, 78.2
                ]
                for (index, w) in weights.enumerated() {
                    let dayOffset = -(weights.count - 1 - index) * 2
                    if let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: now) {
                        let entry = WeightEntry(date: entryDate, weight: w)
                        context.insert(entry)
                    }
                }
                try? context.save()
            }
            #endif

            return (container, nil)
        } catch {
            print("Failed to create persistent ModelContainer: \(error)")
            return (nil, "Veritabanı başlatılamadı: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = container {
                ContentView()
                    .heftTheme()
                    .modelContainer(container)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(Color.heftError)

                    Text("Veritabanı Başlatılamadı")
                        .font(.heftScreenTitle)
                        .foregroundStyle(Color.primary)

                    if let error = containerError {
                        Text(error)
                            .font(.heftMeta)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    HeftPrimaryButton(title: "Yeniden Dene") {
                        let (c, err) = Self.createModelContainer()
                        self.container = c
                        self.containerError = err
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .heftTheme()
            }
        }
    }
}

