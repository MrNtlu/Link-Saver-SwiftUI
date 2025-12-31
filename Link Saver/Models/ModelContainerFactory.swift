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

    /// URL for the shared database container (App Groups)
    static var sharedContainerURL: URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupID
        ) else {
            // Fallback to app's documents directory if App Groups not configured
            return URL.documentsDirectory.appending(path: AppConstants.databaseName)
        }
        return containerURL.appending(path: AppConstants.databaseName)
    }

    /// Creates a ModelContainer for production use with App Groups
    static func createSharedContainer() -> ModelContainer {
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: sharedContainerURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
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
