//
//  BackupService.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import Foundation
import SwiftData

@MainActor
enum BackupService {
    enum ImportError: Error {
        case unsupportedVersion
    }

    static func makeBackup(
        links: [Link],
        folders: [Folder],
        tags: [Tag]
    ) -> LinkSaverBackup {
        LinkSaverBackup(
            version: LinkSaverBackup.currentVersion,
            createdAt: Date(),
            folders: folders.map {
                FolderBackupRecord(
                    name: $0.name,
                    iconName: $0.iconName,
                    dateCreated: $0.dateCreated,
                    sortOrder: $0.sortOrder
                )
            },
            tags: tags.map {
                TagBackupRecord(
                    name: $0.name,
                    colorHex: $0.colorHex,
                    dateCreated: $0.dateCreated
                )
            },
            links: links.map { link in
                LinkBackupRecord(
                    url: link.url,
                    dateAdded: link.dateAdded,
                    title: link.title,
                    linkDescription: link.linkDescription,
                    notes: link.notes,
                    isFavorite: link.isFavorite,
                    isPinned: link.isPinned,
                    folderName: link.folder?.name,
                    tagNames: link.tags.map(\.name)
                )
            }
        )
    }

    static func importBackup(_ backup: LinkSaverBackup, into modelContext: ModelContext) throws {
        guard backup.version == LinkSaverBackup.currentVersion else {
            throw ImportError.unsupportedVersion
        }

        modelContext.autosaveEnabled = false

        let existingFolders = try modelContext.fetch(FetchDescriptor<Folder>())
        var folderByKey: [String: Folder] = Dictionary(
            uniqueKeysWithValues: existingFolders.map { (nameKey($0.name), $0) }
        )

        let existingTags = try modelContext.fetch(FetchDescriptor<Tag>())
        var tagByKey: [String: Tag] = Dictionary(
            uniqueKeysWithValues: existingTags.map { (nameKey($0.name), $0) }
        )

        let existingLinks = try modelContext.fetch(FetchDescriptor<Link>())
        var linkByURL: [String: Link] = Dictionary(
            uniqueKeysWithValues: existingLinks.map { (urlKey($0.url), $0) }
        )

        // Folders (skip if same name exists)
        for folderRecord in backup.folders {
            let key = nameKey(folderRecord.name)
            guard folderByKey[key] == nil else { continue }

            let created = Folder(
                name: folderRecord.name.trimmingCharacters(in: .whitespacesAndNewlines),
                iconName: folderRecord.iconName
            )
            created.dateCreated = folderRecord.dateCreated
            created.sortOrder = folderRecord.sortOrder
            modelContext.insert(created)
            folderByKey[key] = created
        }

        // Tags (skip if same name exists)
        for tagRecord in backup.tags {
            let key = nameKey(tagRecord.name)
            guard tagByKey[key] == nil else { continue }

            let created = Tag(
                name: tagRecord.name.trimmingCharacters(in: .whitespacesAndNewlines),
                colorHex: tagRecord.colorHex
            )
            created.dateCreated = tagRecord.dateCreated
            modelContext.insert(created)
            tagByKey[key] = created
        }

        // Links (skip if same URL exists)
        for linkRecord in backup.links {
            let key = urlKey(linkRecord.url)
            guard linkByURL[key] == nil else { continue }

            let created = Link(url: linkRecord.url)
            created.dateAdded = linkRecord.dateAdded
            created.title = linkRecord.title
            created.linkDescription = linkRecord.linkDescription
            created.notes = linkRecord.notes
            created.isFavorite = linkRecord.isFavorite
            created.isPinned = linkRecord.isPinned

            // Heavy assets are always local-only.
            created.favicon = nil
            created.previewImage = nil

            if let folderName = linkRecord.folderName {
                created.folder = folderByKey[nameKey(folderName)]
            }

            if !linkRecord.tagNames.isEmpty {
                created.tags = linkRecord.tagNames.compactMap { tagName in
                    tagByKey[nameKey(tagName)]
                }
            }

            modelContext.insert(created)
            linkByURL[key] = created
        }

        try modelContext.save()
    }

    private static func nameKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func urlKey(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.normalizedURL?.absoluteString ?? trimmed
    }
}

