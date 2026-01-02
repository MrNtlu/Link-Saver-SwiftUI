//
//  LinkAssetStore.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import Foundation

actor LinkAssetStore {
    static let shared = LinkAssetStore()

    private let baseURL: URL?

    private init() {
        baseURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID)?
            .appending(path: "LinkAssets", directoryHint: .isDirectory)
    }

    func saveAssets(linkID: UUID, favicon: Data?, previewImage: Data?) {
        guard let baseURL else { return }

        do {
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
            let folderURL = baseURL.appending(path: linkID.uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

            if let favicon {
                try favicon.write(to: folderURL.appending(path: "favicon.jpg"), options: [.atomic])
            }
            if let previewImage {
                try previewImage.write(to: folderURL.appending(path: "preview.jpg"), options: [.atomic])
            }
        } catch {
            print("[LinkSaver] Failed to save link assets: \(error.localizedDescription)")
        }
    }

    func loadFavicon(linkID: UUID) -> Data? {
        guard let baseURL else { return nil }
        let url = baseURL
            .appending(path: linkID.uuidString, directoryHint: .isDirectory)
            .appending(path: "favicon.jpg")
        return try? Data(contentsOf: url)
    }

    func loadPreviewImage(linkID: UUID) -> Data? {
        guard let baseURL else { return nil }
        let url = baseURL
            .appending(path: linkID.uuidString, directoryHint: .isDirectory)
            .appending(path: "preview.jpg")
        return try? Data(contentsOf: url)
    }
}

