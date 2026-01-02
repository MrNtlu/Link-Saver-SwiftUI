//
//  BackupModels.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import Foundation

struct LinkSaverBackup: Codable {
    static let currentVersion = 1

    var version: Int
    var createdAt: Date
    var folders: [FolderBackupRecord]
    var tags: [TagBackupRecord]
    var links: [LinkBackupRecord]
}

struct FolderBackupRecord: Codable {
    var name: String
    var iconName: String
    var dateCreated: Date
    var sortOrder: Int
}

struct TagBackupRecord: Codable {
    var name: String
    var colorHex: String
    var dateCreated: Date
}

struct LinkBackupRecord: Codable {
    var url: String
    var dateAdded: Date
    var title: String?
    var linkDescription: String?
    var notes: String?
    var isFavorite: Bool
    var isPinned: Bool
    var folderName: String?
    var tagNames: [String]
}

