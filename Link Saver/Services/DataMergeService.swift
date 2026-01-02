//
//  DataMergeService.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import Foundation
import SwiftData

@MainActor
enum DataMergeService {
    static func merge(from sourceContainer: ModelContainer, to destinationContainer: ModelContainer) throws {
        let sourceContext = ModelContext(sourceContainer)
        sourceContext.autosaveEnabled = false

        let destinationContext = ModelContext(destinationContainer)
        destinationContext.autosaveEnabled = false

        // Preload destination state for fast lookups
        let existingFolders = try destinationContext.fetch(FetchDescriptor<Folder>())
        var destinationFolderByKey: [String: Folder] = Dictionary(
            uniqueKeysWithValues: existingFolders.map { (folderKey($0.name), $0) }
        )
        var destinationFolderById: [UUID: Folder] = Dictionary(
            uniqueKeysWithValues: existingFolders.map { ($0.id, $0) }
        )

        let existingTags = try destinationContext.fetch(FetchDescriptor<Tag>())
        var destinationTagByKey: [String: Tag] = Dictionary(
            uniqueKeysWithValues: existingTags.map { (tagKey($0.name), $0) }
        )
        var destinationTagById: [UUID: Tag] = Dictionary(
            uniqueKeysWithValues: existingTags.map { ($0.id, $0) }
        )

        let existingLinks = try destinationContext.fetch(FetchDescriptor<Link>())
        var destinationLinkByURL: [String: Link] = Dictionary(
            uniqueKeysWithValues: existingLinks.map { (linkURLKey($0.url), $0) }
        )
        let destinationLinkById: [UUID: Link] = Dictionary(
            uniqueKeysWithValues: existingLinks.map { ($0.id, $0) }
        )

        // Build source->destination maps so relationships can be recreated.
        var folderMap: [UUID: Folder] = [:]
        var tagMap: [UUID: Tag] = [:]

        // 1) Merge folders (skip if same name exists)
        let sourceFolders = try sourceContext.fetch(FetchDescriptor<Folder>())
        for sourceFolder in sourceFolders {
            if let existing = destinationFolderByKey[folderKey(sourceFolder.name)] {
                folderMap[sourceFolder.id] = existing
                continue
            }

            if let existingById = destinationFolderById[sourceFolder.id] {
                folderMap[sourceFolder.id] = existingById
                continue
            }

            let created = Folder(name: sourceFolder.name, iconName: sourceFolder.iconName)
            created.id = sourceFolder.id
            created.dateCreated = sourceFolder.dateCreated
            created.sortOrder = sourceFolder.sortOrder

            destinationContext.insert(created)
            folderMap[sourceFolder.id] = created
            destinationFolderByKey[folderKey(created.name)] = created
            destinationFolderById[created.id] = created
        }

        // 2) Merge tags (skip if same name exists)
        let sourceTags = try sourceContext.fetch(FetchDescriptor<Tag>())
        for sourceTag in sourceTags {
            if let existing = destinationTagByKey[tagKey(sourceTag.name)] {
                tagMap[sourceTag.id] = existing
                continue
            }

            if let existingById = destinationTagById[sourceTag.id] {
                tagMap[sourceTag.id] = existingById
                continue
            }

            let created = Tag(name: sourceTag.name, colorHex: sourceTag.colorHex)
            created.id = sourceTag.id
            created.dateCreated = sourceTag.dateCreated

            destinationContext.insert(created)
            tagMap[sourceTag.id] = created
            destinationTagByKey[tagKey(created.name)] = created
            destinationTagById[created.id] = created
        }

        // 3) Merge links (skip if same URL exists)
        let sourceLinks = try sourceContext.fetch(FetchDescriptor<Link>())
        for sourceLink in sourceLinks {
            let urlKey = linkURLKey(sourceLink.url)

            if destinationLinkByURL[urlKey] != nil {
                continue
            }

            if destinationLinkById[sourceLink.id] != nil {
                // Link exists by ID; treat as existing and keep it.
                continue
            }

            let created = Link(url: sourceLink.url)
            created.id = sourceLink.id
            created.dateAdded = sourceLink.dateAdded
            created.title = sourceLink.title
            created.linkDescription = sourceLink.linkDescription
            created.notes = sourceLink.notes
            created.isFavorite = sourceLink.isFavorite
            created.isPinned = sourceLink.isPinned
            created.metadataFetched = sourceLink.metadataFetched
            created.lastMetadataFetchAttempt = sourceLink.lastMetadataFetchAttempt

            // Heavy assets are always local-only.
            created.favicon = nil
            created.previewImage = nil

            if let sourceFolder = sourceLink.folder {
                created.folder = folderMap[sourceFolder.id] ?? destinationFolderByKey[folderKey(sourceFolder.name)]
            }

            if !sourceLink.tags.isEmpty {
                created.tags = sourceLink.tags.compactMap { sourceTag in
                    tagMap[sourceTag.id] ?? destinationTagByKey[tagKey(sourceTag.name)]
                }
            }

            destinationContext.insert(created)
            destinationLinkByURL[urlKey] = created
        }

        try destinationContext.save()
    }

    private static func folderKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tagKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func linkURLKey(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.normalizedURL?.absoluteString ?? trimmed
    }
}

