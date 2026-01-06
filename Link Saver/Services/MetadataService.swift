//
//  MetadataService.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import LinkPresentation
import UIKit
import SwiftData

/// Thread-safe service for fetching link metadata
actor MetadataService {
    static let shared = MetadataService()

    private init() {}

    // MARK: - Public Methods

    /// Fetches metadata for a URL
    func fetchMetadata(for url: URL) async throws -> LinkMetadataResult {
        let provider = LPMetadataProvider()
        provider.timeout = AppConstants.metadataFetchTimeout

        let metadata = try await provider.startFetchingMetadata(for: url)

        var result = LinkMetadataResult(url: url)
        result.title = metadata.title
        result.description = metadata.value(forKey: "summary") as? String

        // Fetch favicon
        if let iconProvider = metadata.iconProvider {
            result.favicon = try? await loadImageData(from: iconProvider)
        }

        // Fetch preview image
        if let imageProvider = metadata.imageProvider {
            result.previewImage = try? await loadImageData(from: imageProvider)
        }

        return result
    }

    /// Fetches metadata and updates the Link model
    @MainActor
    func fetchAndUpdateMetadata(for link: Link) async {
        guard let url = URL(string: link.url) else { return }

        link.lastMetadataFetchAttempt = Date()

        do {
            let metadata = try await fetchMetadata(for: url)

            let existingTitle = link.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let fetchedTitle = metadata.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if existingTitle.isEmpty, !fetchedTitle.isEmpty {
                link.title = fetchedTitle
            }
            link.linkDescription = metadata.description
            await LinkAssetStore.shared.saveAssets(
                linkID: link.id,
                favicon: metadata.favicon,
                previewImage: metadata.previewImage
            )
            link.metadataFetched = true
        } catch {
            print("Failed to fetch metadata: \(error.localizedDescription)")
            // Don't mark as fetched if it failed
        }
    }

    // MARK: - Private Methods

    private func loadImageData(from provider: NSItemProvider) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { object, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let image = object as? UIImage else {
                    continuation.resume(returning: nil)
                    return
                }

                // Resize if needed
                let resized = self.resizeImage(image, maxDimension: AppConstants.maxPreviewImageSize)
                let data = resized.jpegData(compressionQuality: AppConstants.imageCompressionQuality)
                continuation.resume(returning: data)
            }
        }
    }

    private nonisolated func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized ?? image
    }
}

// MARK: - Result Type
struct LinkMetadataResult {
    var url: URL
    var title: String?
    var description: String?
    var favicon: Data?
    var previewImage: Data?
}

// MARK: - Favicon Service
actor FaviconService {
    static let shared = FaviconService()

    private init() {}

    /// Fetches favicon from Google's favicon service as a fallback
    func fetchFavicon(for url: URL) async -> Data? {
        guard let faviconURL = url.faviconURL else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: faviconURL)
            return data
        } catch {
            print("Failed to fetch favicon: \(error.localizedDescription)")
            return nil
        }
    }
}
