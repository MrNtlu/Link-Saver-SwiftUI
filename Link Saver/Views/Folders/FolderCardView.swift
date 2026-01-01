//
//  FolderCardView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct FolderCardView: View {
    let folder: Folder

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: folder.iconName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Group {
                    if folder.linkCount == 1 {
                        Text("folders.linkCount.one \(folder.linkCount)")
                    } else {
                        Text("folders.linkCount.other \(folder.linkCount)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        FolderCardView(folder: Folder(name: "Work", iconName: "briefcase"))
        FolderCardView(folder: Folder(name: "Personal", iconName: "person"))
        FolderCardView(folder: Folder(name: "Reading List", iconName: "book"))
    }
    .padding()
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
