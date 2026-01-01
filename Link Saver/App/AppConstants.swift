//
//  AppConstants.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import SwiftUI

enum AppConstants {
    /// App Group identifier for sharing data with Share Extension
    static let appGroupID = "group.linksaver.share"

    /// Database file name
    static let databaseName = "LinkSaver.sqlite"

    /// Maximum preview image dimension
    static let maxPreviewImageSize: CGFloat = 300

    /// JPEG compression quality for cached images
    static let imageCompressionQuality: CGFloat = 0.7

    /// Metadata fetch timeout in seconds
    static let metadataFetchTimeout: TimeInterval = 15

    /// Default tag colors
    static let defaultTagColors: [String] = [
        "#007AFF", // Blue
        "#34C759", // Green
        "#FF9500", // Orange
        "#FF3B30", // Red
        "#AF52DE", // Purple
        "#FF2D55", // Pink
        "#5856D6", // Indigo
        "#00C7BE", // Teal
        "#FFD60A", // Yellow
        "#8E8E93"  // Gray
    ]
}

// MARK: - Sort Options
enum LinkSortOption: String, CaseIterable, Identifiable {
    case dateAddedNewest = "sort.dateAddedNewest"
    case dateAddedOldest = "sort.dateAddedOldest"
    case titleAZ = "sort.titleAZ"
    case titleZA = "sort.titleZA"
    case favorites = "sort.favoritesFirst"

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    var systemImage: String {
        switch self {
        case .dateAddedNewest: return "calendar.badge.clock"
        case .dateAddedOldest: return "calendar"
        case .titleAZ: return "textformat.abc"
        case .titleZA: return "textformat.abc"
        case .favorites: return "star.fill"
        }
    }
}
