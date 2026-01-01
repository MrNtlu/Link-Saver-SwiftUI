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
    @Query(
        sort: [
            SortDescriptor(\Folder.sortOrder, order: .forward),
            SortDescriptor(\Folder.dateCreated, order: .reverse)
        ]
    ) private var folders: [Folder]
    @Query(filter: #Predicate<Link> { $0.isFavorite }) private var favoriteLinks: [Link]

    @State private var showAddFolder = false
    @State private var folderToEdit: Folder?
    @State private var folderPendingDelete: Folder?
    @State private var showReorderFolders = false

    var body: some View {
        NavigationStack {
            foldersContent
                .navigationTitle(Text("tab.folders"))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showReorderFolders = true
                        } label: {
                            Label("folders.reorder.button", systemImage: "arrow.up.arrow.down")
                        }
                    }
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
                .sheet(item: $folderToEdit) { folder in
                    EditFolderView(folder: folder)
                }
                .navigationDestination(isPresented: $showReorderFolders) {
                    FolderReorderView(folders: folders)
                }
                .alert("folderDetail.delete.title", isPresented: Binding(
                    get: { folderPendingDelete != nil },
                    set: { isPresented in
                        if !isPresented {
                            folderPendingDelete = nil
                        }
                    }
                )) {
                    Button("common.cancel", role: .cancel) {
                        folderPendingDelete = nil
                    }
                    Button("common.delete", role: .destructive) {
                        guard let folderPendingDelete else { return }
                        deleteFolder(folderPendingDelete)
                        self.folderPendingDelete = nil
                    }
                } message: {
                    Text("folderDetail.delete.message")
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
                                folderToEdit = folder
                            } label: {
                                Label("common.edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                folderPendingDelete = folder
                            } label: {
                                Label("common.delete", systemImage: "trash")
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
        .accessibilityLabel(Text("folders.favorites.title"))
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("folders.empty.title", systemImage: "folder")
        } description: {
            Text("folders.empty.message")
        } actions: {
            Button("folders.create") {
                showAddFolder = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyStateCard: some View {
        EmptyStateView(
            title: "folders.empty.title",
            message: "folders.empty.message",
            systemImage: "folder",
            actionTitle: "folders.create"
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
                Text("folders.favorites.title")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Group {
                    if count == 1 {
                        Text("folders.favorites.linkCount.one \(count)")
                    } else {
                        Text("folders.favorites.linkCount.other \(count)")
                    }
                }
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
