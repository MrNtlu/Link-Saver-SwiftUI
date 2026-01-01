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
            return sortPinnedFirst(links)
        }

        let result = links.filter { link in
            link.title?.localizedCaseInsensitiveContains(searchText) == true ||
            link.url.localizedCaseInsensitiveContains(searchText)
        }

        return sortPinnedFirst(result)
    }

    private func sortPinnedFirst(_ links: [Link]) -> [Link] {
        let pinned = links.filter(\.isPinned).sorted { $0.dateAdded > $1.dateAdded }
        let unpinned = links.filter { !$0.isPinned }.sorted { $0.dateAdded > $1.dateAdded }
        return pinned + unpinned
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
        .searchable(text: $searchText, prompt: Text("folderDetail.search.prompt \(folder.name)"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("folderDetail.edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("folderDetail.delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditFolderView(folder: folder)
        }
        .alert("folderDetail.delete.title", isPresented: $showDeleteAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("common.delete", role: .destructive) {
                deleteFolder()
            }
        } message: {
            Text("folderDetail.delete.message")
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("links.empty.title", systemImage: "link")
        } description: {
            Text("folderDetail.empty.message")
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
                        Label("common.remove", systemImage: "folder.badge.minus")
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
                Section("folder.section.name") {
                    TextField("common.name", text: $name)
                }

                Section("folder.section.icon") {
                    TextField("folder.icon.search", text: $iconSearchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                            if filteredIcons.isEmpty {
                                Text("folder.icon.empty")
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
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 320)
                }
            }
            .navigationTitle("folder.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
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
