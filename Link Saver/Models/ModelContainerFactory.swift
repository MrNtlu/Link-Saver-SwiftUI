//
//  ModelContainerFactory.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import SwiftData

enum ModelContainerFactory {
    /// Schema containing all app models
    static var schema: Schema {
        Schema([
            Link.self,
            Tag.self,
            Folder.self
        ])
    }

    enum SyncMode {
        case local
        case iCloud
    }

    enum StoreKind {
        case local
        case iCloud
    }

    /// URL for the database stored in this target's Documents directory (legacy, not shared with extensions).
    static func legacyDocumentsContainerURL(databaseName: String) -> URL {
        URL.documentsDirectory.appending(path: databaseName)
    }

    /// URL for the shared database container (App Groups), if App Groups are configured correctly.
    static func appGroupContainerURL(databaseName: String) -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID)?
            .appending(path: databaseName)
    }

    static func storeURL(for kind: StoreKind) -> URL {
        let databaseName: String = {
            switch kind {
            case .local: return AppConstants.databaseName
            case .iCloud: return AppConstants.iCloudDatabaseName
            }
        }()

        let legacy = legacyDocumentsContainerURL(databaseName: databaseName)
        return appGroupContainerURL(databaseName: databaseName) ?? legacy
    }

    static func cloudKitDatabase(for kind: StoreKind) -> ModelConfiguration.CloudKitDatabase {
        switch kind {
        case .local: return .none
        case .iCloud: return .private(AppConstants.iCloudContainerIdentifier)
        }
    }

    /// Creates a ModelContainer for production use (local or iCloud) stored in App Groups.
    static func createContainer(for mode: SyncMode) -> ModelContainer {
        let kind: StoreKind = (mode == .iCloud) ? .iCloud : .local

        if let appGroupURL = appGroupContainerURL(databaseName: {
            switch kind {
            case .local: return AppConstants.databaseName
            case .iCloud: return AppConstants.iCloudDatabaseName
            }
        }()) {
            migrateLegacyStoreIfNeeded(
                from: legacyDocumentsContainerURL(databaseName: {
                    switch kind {
                    case .local: return AppConstants.databaseName
                    case .iCloud: return AppConstants.iCloudDatabaseName
                    }
                }()),
                to: appGroupURL
            )
        }

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL(for: kind),
            allowsSave: true,
            cloudKitDatabase: cloudKitDatabase(for: kind)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Prefer a usable app without iCloud over crashing.
            if kind == .iCloud {
                print("[LinkSaver] Falling back to local store because iCloud container failed: \(error.localizedDescription)")
                return createContainer(for: .local)
            }
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }

    private static func migrateLegacyStoreIfNeeded(from legacyURL: URL, to sharedURL: URL) {
        guard legacyURL != sharedURL else { return }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: legacyURL.path) else { return }
        guard !fileManager.fileExists(atPath: sharedURL.path) else { return }

        do {
            try fileManager.createDirectory(
                at: sharedURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            for suffix in ["", "-shm", "-wal"] {
                let sourceURL = URL(fileURLWithPath: legacyURL.path + suffix)
                guard fileManager.fileExists(atPath: sourceURL.path) else { continue }

                let destinationURL = URL(fileURLWithPath: sharedURL.path + suffix)
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }
        } catch {
            print("[LinkSaver] Failed to migrate legacy store to App Group container: \(error.localizedDescription)")
        }
    }

    
    /// Creates a ModelContainer for SwiftUI previews (in-memory)
    @MainActor
    static func createPreviewContainer() -> ModelContainer {
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Add sample data for previews
            let context = container.mainContext

            // Sample folders
            let workFolder = Folder(name: "Work", iconName: "briefcase")
            let personalFolder = Folder(name: "Personal", iconName: "person")
            let readingFolder = Folder(name: "Reading List", iconName: "book")
            context.insert(workFolder)
            context.insert(personalFolder)
            context.insert(readingFolder)

            // Sample tags
            let importantTag = Tag(name: "Important", colorHex: "#FF3B30")
            let techTag = Tag(name: "Tech", colorHex: "#007AFF")
            let newsTag = Tag(name: "News", colorHex: "#34C759")
            context.insert(importantTag)
            context.insert(techTag)
            context.insert(newsTag)

            // Sample links
            let link1 = Link(url: "https://apple.com", title: "Apple", folder: workFolder)
            link1.linkDescription = "Apple's official website"
            link1.tags = [techTag]
            link1.metadataFetched = true

            let link2 = Link(url: "https://github.com", title: "GitHub", folder: workFolder)
            link2.linkDescription = "Where the world builds software"
            link2.tags = [techTag, importantTag]
            link2.isFavorite = true
            link2.metadataFetched = true

            let link3 = Link(url: "https://news.ycombinator.com", title: "Hacker News", folder: readingFolder)
            link3.linkDescription = "Social news website focusing on computer science"
            link3.tags = [newsTag, techTag]
            link3.metadataFetched = true

            context.insert(link1)
            context.insert(link2)
            context.insert(link3)

            return container
        } catch {
            fatalError("Could not create preview ModelContainer: \(error.localizedDescription)")
        }
    }
}
