//
//  LinkRowView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct LinkRowView: View {
    let link: Link
    @State private var faviconImage: UIImage?
    @State private var previewUIImage: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            // Favicon
            faviconView
                .frame(width: 40, height: 40)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(link.displayTitle)
                        .font(.headline)
                        .lineLimit(1)

                    if link.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if link.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                if let description = link.linkDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    // Domain
                    if let domain = link.domain {
                        Text(domain)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Tags
                    if !link.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(link.tags.prefix(2)) { tag in
                                TagChip(tag: tag, isCompact: true)
                            }
                            if link.tags.count > 2 {
                                Text("+\(link.tags.count - 2)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Preview Image
            if let uiImage = previewUIImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
        .task(id: link.favicon) {
            faviconImage = await decodeImage(from: link.favicon)
        }
        .task(id: link.previewImage) {
            previewUIImage = await decodeImage(from: link.previewImage)
        }
    }

    // MARK: - Favicon View
    @ViewBuilder
    private var faviconView: some View {
        if let uiImage = faviconImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                Image(systemName: "globe")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func decodeImage(from data: Data?) async -> UIImage? {
        guard let data else { return nil }
        return await Task.detached(priority: .utility) { UIImage(data: data) }.value
    }
}

#Preview {
    let container = ModelContainerFactory.createPreviewContainer()
    let link = Link(url: "https://apple.com", title: "Apple")
    link.linkDescription = "Apple's official website with all the latest products and services."

    return List {
        LinkRowView(link: link)
        LinkRowView(link: link)
    }
    .modelContainer(container)
}
