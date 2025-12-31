//
//  URL+Extensions.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import Foundation
  
extension URL {
    /// Returns true if the URL is a valid web URL (http or https)
    var isValidWebURL: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    /// Returns the favicon URL for this website
    var faviconURL: URL? {
        guard let host = host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128")
    }

    /// Returns the domain without www prefix
    var cleanHost: String? {
        guard var host = host else { return nil }
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        return host
    }
}

extension String {
    /// Returns true if the string is a valid URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.isValidWebURL
    }

    /// Attempts to create a valid URL from the string, adding https:// if needed
    var normalizedURL: URL? {
        var urlString = self.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add https:// if no scheme present
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            urlString = "https://" + urlString
        }

        guard let url = URL(string: urlString), url.isValidWebURL else {
            return nil
        }

        return url
    }

    /// Returns the domain from a URL string
    var extractedDomain: String? {
        normalizedURL?.cleanHost
    }
}
