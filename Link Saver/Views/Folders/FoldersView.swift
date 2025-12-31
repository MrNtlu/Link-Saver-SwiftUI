//
//  FoldersView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct FoldersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.dateCreated, order: .reverse) private var folders: [Folder]
    @Query(filter: #Predicate<Link> { $0.isFavorite }) private var favoriteLinks: [Link]

    @State private var showAddFolder = false

    var body: some View {
        NavigationStack {
            foldersContent
            .navigationTitle("Folders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFolder) {
                AddFolderView()
            }
        }
    }

    private var foldersContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                favoritesCard

                if folders.isEmpty {
                    emptyStateCard
                } else {
                    ForEach(folders) { folder in
                        NavigationLink(destination: FolderDetailView(folder: folder)) {
                            FolderCardView(folder: folder)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                // Edit action would go here
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                deleteFolder(folder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var favoritesCard: some View {
        NavigationLink(destination: FavoritesView()) {
            FavoritesCardView(count: favoriteLinks.count)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Favorites")
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Folders", systemImage: "folder")
        } description: {
            Text("Create folders to organize your saved links.")
        } actions: {
            Button("Create Folder") {
                showAddFolder = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyStateCard: some View {
        EmptyStateView(
            title: "No Folders",
            message: "Create folders to organize your saved links.",
            systemImage: "folder",
            actionTitle: "Create Folder"
        ) {
            showAddFolder = true
        }
        .padding(.vertical, 24)
    }

    private func deleteFolder(_ folder: Folder) {
        withAnimation {
            modelContext.delete(folder)
        }
    }
}

private struct FavoritesCardView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.18))
                    .frame(width: 56, height: 56)

                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Favorites")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(count) link\(count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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
    FoldersView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
