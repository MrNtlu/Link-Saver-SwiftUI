//
//  LinkImportService.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import SwiftData

/// Service for importing and validating links
actor LinkImportService {
    static let shared = LinkImportService()

    private init() {}

    // MARK: - URL Validation

    /// Validates and normalizes a URL string
    func normalizeURL(_ urlString: String) -> URL? {
        return urlString.normalizedURL
    }

    /// Checks if a URL string is valid
    func isValidURL(_ urlString: String) -> Bool {
        return urlString.isValidURL
    }

    // MARK: - Link Creation

    /// Creates a new Link from a URL string
    func createLink(
        from urlString: String,
        title: String? = nil,
        folder: Folder? = nil
    ) -> Link? {
        guard let url = normalizeURL(urlString) else { return nil }

        let link = Link(url: url.absoluteString, title: title, folder: folder)
        return link
    }

    // MARK: - Share Extension Support

    /// Extracts URL and title from share extension input
    func extractShareData(url: String?, title: String?) -> (url: String, title: String?)? {
        guard let urlString = url, let normalizedURL = normalizeURL(urlString) else {
            return nil
        }

        return (url: normalizedURL.absoluteString, title: title)
    }
}
