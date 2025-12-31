//
//  LinkDetailView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct LinkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @Bindable var link: Link
    @Query private var folders: [Folder]
    @Query private var allTags: [Tag]

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var isRefreshingMetadata = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Preview Card
                previewCard

                // Actions
                actionButtons

                // Details Section
                detailsSection

                // Notes Section
                notesSection

                // Tags Section
                tagsSection

                // Folder Section
                folderSection

                // Metadata Section
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Link Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        toggleFavorite()
                    } label: {
                        Label(
                            link.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: link.isFavorite ? "star.slash" : "star"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditLinkView(link: link)
        }
        .alert("Delete Link", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteLink()
            }
        } message: {
            Text("Are you sure you want to delete this link?")
        }
    }

    // MARK: - Preview Card
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preview Image
            if let previewData = link.previewImage,
               let uiImage = UIImage(data: previewData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 12) {
                // Favicon
                if let faviconData = link.favicon,
                   let uiImage = UIImage(data: faviconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "globe")
                        .font(.title2)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(link.displayTitle)
                        .font(.headline)

                    if let domain = link.domain {
                        Text(domain)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if link.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }

            if let description = link.linkDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                openLink()
            } label: {
                Label("Open", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                shareLink()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                copyLink()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("URL")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(link.url)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }

    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.caption)
                .foregroundStyle(.secondary)

            if link.tags.isEmpty {
                Text("No tags")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(link.tags) { tag in
                        TagChip(tag: tag, isCompact: false)
                    }
                }
            }
        }
    }

    // MARK: - Folder Section
    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Folder")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let folder = link.folder {
                HStack {
                    Image(systemName: folder.iconName)
                    Text(folder.name)
                }
                .font(.subheadline)
            } else {
                Text("Not in a folder")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Metadata")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    refreshMetadata()
                } label: {
                    if isRefreshingMetadata {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshingMetadata)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Added:")
                    Spacer()
                    Text(link.dateAdded, style: .date)
                }

                HStack {
                    Text("Metadata fetched:")
                    Spacer()
                    Text(link.metadataFetched ? "Yes" : "No")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions
    private func openLink() {
        guard let url = URL(string: link.url) else { return }
        openURL(url)
    }

    private func shareLink() {
        guard let url = URL(string: link.url) else { return }
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = link.url
    }

    private func toggleFavorite() {
        withAnimation {
            link.isFavorite.toggle()
        }
    }

    private func deleteLink() {
        modelContext.delete(link)
        dismiss()
    }

    private func refreshMetadata() {
        isRefreshingMetadata = true
        Task {
            await MetadataService.shared.fetchAndUpdateMetadata(for: link)
            await MainActor.run {
                isRefreshingMetadata = false
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let notes = link.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .textSelection(.enabled)
            } else {
                Text("No notes")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }

}

// MARK: - Edit Link View
struct EditLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var link: Link
    @Query private var folders: [Folder]
    @Query private var allTags: [Tag]

    @State private var title: String = ""
    @State private var url: String = ""
    @State private var notes: String = ""
    @State private var selectedFolder: Folder?
    @State private var selectedTags: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("URL", text: $url)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Folder") {
                    Picker("Folder", selection: $selectedFolder) {
                        Text("None").tag(nil as Folder?)
                        ForEach(folders) { folder in
                            Label(folder.name, systemImage: folder.iconName)
                                .tag(folder as Folder?)
                        }
                    }
                }

                Section("Tags") {
                    ForEach(allTags) { tag in
                        Button {
                            toggleTag(tag)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 12, height: 12)
                                Text(tag.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedTags.contains(tag.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Link")
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
                }
            }
            .onAppear {
                title = link.title ?? ""
                url = link.url
                notes = link.notes ?? ""
                selectedFolder = link.folder
                selectedTags = Set(link.tags.map { $0.id })
            }
        }
    }

    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag.id) {
            selectedTags.remove(tag.id)
        } else {
            selectedTags.insert(tag.id)
        }
    }

    private func saveChanges() {
        link.title = title.isEmpty ? nil : title
        link.url = url
        link.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        link.folder = selectedFolder
        link.tags = allTags.filter { selectedTags.contains($0.id) }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        LinkDetailView(link: Link(url: "https://apple.com", title: "Apple"))
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
