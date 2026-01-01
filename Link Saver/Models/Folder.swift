//
//  Folder.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import SwiftData

@Model
final class Folder {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var dateCreated: Date
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Link.folder)
    var links: [Link]?

    // MARK: - Computed Properties
    var linkCount: Int {
        links?.count ?? 0
    }

    // MARK: - Initialization
    init(name: String, iconName: String = "folder") {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.dateCreated = Date()
        self.sortOrder = 0
    }
}

// MARK: - Predefined Folder Icons
extension Folder {
    static let availableIcons: [String] = [
        "folder",
        "folder.fill",
        "tray",
        "tray.fill",
        "archivebox",
        "archivebox.fill",
        "doc",
        "doc.fill",
        "doc.text",
        "doc.text.fill",
        "doc.richtext",
        "doc.plaintext",
        "doc.on.doc",
        "doc.on.doc.fill",
        "bookmark",
        "bookmark.fill",
        "tag",
        "tag.fill",
        "flag",
        "flag.fill",
        "star",
        "star.fill",
        "heart",
        "heart.fill",
        "briefcase",
        "briefcase.fill",
        "graduationcap",
        "graduationcap.fill",
        "book",
        "book.fill",
        "books.vertical",
        "books.vertical.fill",
        "newspaper",
        "newspaper.fill",
        "globe",
        "cart",
        "cart.fill",
        "creditcard",
        "creditcard.fill",
        "gift",
        "gift.fill",
        "gamecontroller",
        "gamecontroller.fill",
        "music.note",
        "film",
        "film.fill",
        "camera",
        "camera.fill",
        "photo",
        "photo.fill",
        "photo.on.rectangle",
        "photo.on.rectangle.angled",
        "paintbrush",
        "paintbrush.fill",
        "hammer",
        "hammer.fill",
        "wrench",
        "wrench.fill",
        "gearshape",
        "gearshape.fill",
        "house",
        "house.fill",
        "building.2",
        "building.2.fill",
        "airplane",
        "car",
        "car.fill",
        "leaf",
        "leaf.fill",
        "flame",
        "flame.fill",
        "bolt",
        "bolt.fill",
        "lightbulb",
        "lightbulb.fill",
        "link",
        "link.circle",
        "link.circle.fill",
        "safari",
        "safari.fill",
        "paperclip",
        "paperplane",
        "paperplane.fill",
        "tray.and.arrow.down",
        "tray.and.arrow.down.fill",
        "pin",
        "pin.fill",
        "clock",
        "clock.fill",
        "calendar",
        "calendar.circle",
        "calendar.circle.fill",
        "list.bullet",
        "list.bullet.rectangle",
        "checkmark.circle",
        "checkmark.circle.fill",
        "xmark.circle",
        "xmark.circle.fill",
        "exclamationmark.triangle",
        "exclamationmark.triangle.fill",
        "person",
        "person.fill",
        "person.2",
        "person.2.fill",
        "lock",
        "lock.fill",
        "sparkles",
        "wand.and.stars",
        "bolt.circle",
        "bolt.circle.fill"
    ]
}
