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
                        .font(.system(size: 48))
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

