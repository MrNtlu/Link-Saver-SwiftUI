//
//  LinkDetailView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData
import UIKit

struct LinkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @Bindable var link: Link

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var isRefreshingMetadata = false
    
    private var hasNotes: Bool {
        !(link.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

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
                if hasNotes {
                    notesSection
                }

                // Tags Section
                tagsSection

                // Folder Section
                folderSection

                // Metadata Section
                metadataSection
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Link Details")
        .navigationBarTitleDisplayMode(.inline)
        .groupBoxStyle(DetailCardGroupBoxStyle())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        togglePinned()
                    } label: {
                        Label(
                            link.isPinned ? "Unpin" : "Pin",
                            systemImage: link.isPinned ? "pin.slash" : "pin.fill"
                        )
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

                if link.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.orange)
                }

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
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 1)
                }
        )
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
            .tint(.blue)

            Button {
                copyLink()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        GroupBox {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                DetailCardIcon(systemImage: "link")

                Text("URL")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(link.url)
                    .font(.callout)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } label: {
            EmptyView()
        }
    }

    // MARK: - Tags Section
    private var tagsSection: some View {
        GroupBox {
            let sortedTags = link.tags.sorted { left, right in
                left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                DetailCardIcon(systemImage: "tag")

                Text("Tags")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)

                Group {
                    if sortedTags.isEmpty {
                        Text("Not set")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 6) {
                                ForEach(sortedTags) { tag in
                                    DetailTagChip(tag: tag)
                                }
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 6) {
                                    ForEach(sortedTags) { tag in
                                        DetailTagChip(tag: tag)
                                    }
                                }
                            }
                            .defaultScrollAnchor(.trailing)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        } label: {
            EmptyView()
        }
    }

    // MARK: - Folder Section
    private var folderSection: some View {
        GroupBox {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                DetailCardIcon(systemImage: "folder")

                Text("Folder")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)

                if let folder = link.folder {
                    NavigationLink {
                        FolderDetailView(folder: folder)
                    } label: {
                        FolderChip(iconName: folder.iconName, name: folder.name)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text("Not set")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        } label: {
            EmptyView()
        }
    }

    

    // MARK: - Metadata Section
    private var metadataSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Added") {
                    Text(link.dateAdded, style: .date)
                }

                LabeledContent("Metadata fetched") {
                    Text(link.metadataFetched ? "Yes" : "No")
                }

                if let lastAttempt = link.lastMetadataFetchAttempt {
                    LabeledContent("Last attempt") {
                        Text(lastAttempt, style: .relative)
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } label: {
            HStack {
                DetailCardHeader(title: "Metadata", systemImage: "info.circle")
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
            .padding(.bottom, 6)
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

    private func togglePinned() {
        withAnimation {
            link.isPinned.toggle()
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
        GroupBox {
            Text(link.notes ?? "")
                .font(.callout)
                .textSelection(.enabled)
        } label: {
            DetailCardHeader(title: "Notes", systemImage: "note.text")
        }
    }

}

private struct DetailCardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
                .font(.callout.weight(.semibold))
                .foregroundStyle(.primary)

            configuration.content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 1)
                }
        )
    }
}

private struct DetailCardIcon: View {
    let systemImage: String
    var tint: Color = .primary

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: 28, height: 28)

            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
        }
        .accessibilityHidden(true)
    }
}

private struct DetailCardHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            DetailCardIcon(systemImage: systemImage)
            Text(title)
        }
    }
}

private struct FolderChip: View {
    let iconName: String
    let name: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))

            Text(name)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(uiColor: .tertiarySystemFill))
        .clipShape(Capsule())
    }
}

private struct DetailTagChip: View {
    let tag: Tag

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tag.color)
                .frame(width: 8, height: 8)

            Text(tag.name)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(uiColor: .tertiarySystemFill))
        .clipShape(Capsule())
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
