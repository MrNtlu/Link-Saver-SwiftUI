//
//  FolderDetailView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct FolderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var folder: Folder

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var searchText = ""

    var filteredLinks: [Link] {
        let links = folder.links ?? []

        if searchText.isEmpty {
            return links.sorted { $0.dateAdded > $1.dateAdded }
        }

        return links.filter { link in
            link.title?.localizedCaseInsensitiveContains(searchText) == true ||
            link.url.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.dateAdded > $1.dateAdded }
    }

    var body: some View {
        Group {
            if filteredLinks.isEmpty && searchText.isEmpty {
                emptyStateView
            } else if filteredLinks.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                linksList
            }
        }
        .navigationTitle(folder.name)
        .searchable(text: $searchText, prompt: "Search in \(folder.name)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit Folder", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Folder", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditFolderView(folder: folder)
        }
        .alert("Delete Folder", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteFolder()
            }
        } message: {
            Text("Are you sure you want to delete this folder? Links in this folder will not be deleted.")
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Links", systemImage: "link")
        } description: {
            Text("This folder is empty. Add links from the Links tab or Share Extension.")
        }
    }

    // MARK: - Links List
    private var linksList: some View {
        List {
            ForEach(filteredLinks) { link in
                NavigationLink(destination: LinkDetailView(link: link)) {
                    LinkRowView(link: link)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeFromFolder(link)
                    } label: {
                        Label("Remove", systemImage: "folder.badge.minus")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private func removeFromFolder(_ link: Link) {
        withAnimation {
            link.folder = nil
        }
    }

    private func deleteFolder() {
        modelContext.delete(folder)
        dismiss()
    }
}

// MARK: - Edit Folder View
struct EditFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var folder: Folder

    @State private var name: String = ""
    @State private var selectedIcon: String = "folder"
    @State private var iconSearchText = ""

    private var filteredIcons: [String] {
        let trimmed = iconSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Folder.availableIcons }
        return Folder.availableIcons.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Folder Name") {
                    TextField("Name", text: $name)
                }

                Section("Icon") {
                    TextField("Search icons", text: $iconSearchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        if filteredIcons.isEmpty {
                            Text("No icons found")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(filteredIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedIcon == icon ?
                                            Color.accentColor.opacity(0.2) :
                                            Color.clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = folder.name
                selectedIcon = folder.iconName
            }
        }
    }

    private func saveChanges() {
        folder.name = name
        folder.iconName = selectedIcon
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FolderDetailView(folder: Folder(name: "Work", iconName: "briefcase"))
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
