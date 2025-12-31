//
//  Link.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import SwiftData

@Model
final class Link {
    // MARK: - Primary
    @Attribute(.unique) var id: UUID
    var url: String
    var dateAdded: Date

    // MARK: - Metadata
    var title: String?
    var linkDescription: String?
    var notes: String?
    @Attribute(.externalStorage) var favicon: Data?
    @Attribute(.externalStorage) var previewImage: Data?

    // MARK: - Organization
    var isFavorite: Bool
    var isPinned: Bool
    var folder: Folder?
    @Relationship(inverse: \Tag.links) var tags: [Tag]

    // MARK: - Status
    var metadataFetched: Bool
    var lastMetadataFetchAttempt: Date?

    // MARK: - Computed Properties
    var displayTitle: String {
        title ?? url
    }

    var domain: String? {
        URL(string: url)?.host
    }

    // MARK: - Initialization
    init(url: String) {
        self.id = UUID()
        self.url = url
        self.dateAdded = Date()
        self.isFavorite = false
        self.isPinned = false
        self.tags = []
        self.metadataFetched = false
    }

    init(url: String, title: String?, folder: Folder? = nil) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.dateAdded = Date()
        self.isFavorite = false
        self.isPinned = false
        self.folder = folder
        self.tags = []
        self.metadataFetched = false
    }
}
