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
    @State private var faviconImage: UIImage?
    @State private var previewImage: UIImage?
    @State private var showCopiedIndicator = false
    @State private var hideCopiedIndicatorTask: Task<Void, Never>?
    
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
        .navigationTitle("linkDetail.title")
        .navigationBarTitleDisplayMode(.inline)
        .groupBoxStyle(DetailCardGroupBoxStyle())
        .overlay(alignment: .top) {
            if showCopiedIndicator {
                copiedIndicatorView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showCopiedIndicator)
        .task(id: link.id) {
            await loadAssets()
        }
        .task(id: link.lastMetadataFetchAttempt) {
            await loadAssets()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("common.edit", systemImage: "pencil")
                    }

                    Button {
                        togglePinned()
                    } label: {
                        let titleKey: LocalizedStringKey = link.isPinned ? "common.unpin" : "common.pin"
                        Label(
                            titleKey,
                            systemImage: link.isPinned ? "pin.slash" : "pin.fill"
                        )
                    }

                    Button {
                        toggleFavorite()
                    } label: {
                        let titleKey: LocalizedStringKey = link.isFavorite ? "linkDetail.favorites.remove" : "linkDetail.favorites.add"
                        Label(
                            titleKey,
                            systemImage: link.isFavorite ? "star.slash" : "star"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("common.delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditLinkView(link: link)
        }
        .alert("linkDetail.delete.title", isPresented: $showDeleteAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("common.delete", role: .destructive) {
                deleteLink()
            }
        } message: {
            Text("linkDetail.delete.message")
        }
        .onDisappear {
            hideCopiedIndicatorTask?.cancel()
        }
    }

    private var copiedIndicatorView: some View {
        Label("common.copied", systemImage: "checkmark.circle.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 8)
            .padding(.horizontal)
            .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Preview Card
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preview Image
            if let uiImage = previewImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 12) {
                // Favicon
                if let uiImage = faviconImage {
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
                Label("common.open", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                shareLink()
            } label: {
                Label("common.share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)

            Button {
                copyLink()
            } label: {
                Label("common.copy", systemImage: "doc.on.doc")
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

                Text("common.url")
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

                Text("common.tags")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)

                Group {
                    if sortedTags.isEmpty {
                        Text("common.notSet")
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

                Text("common.folder")
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
                    Text("common.notSet")
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
                LabeledContent("linkDetail.metadata.added") {
                    Text(link.dateAdded, style: .date)
                }

                LabeledContent("linkDetail.metadata.fetched") {
                    Text(link.metadataFetched ? LocalizedStringKey("common.yes") : LocalizedStringKey("common.no"))
                }

                if let lastAttempt = link.lastMetadataFetchAttempt {
                    LabeledContent("linkDetail.metadata.lastAttempt") {
                        Text(lastAttempt, style: .relative)
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } label: {
            HStack {
                DetailCardHeader(title: "linkDetail.metadata.title", systemImage: "info.circle")
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
        Haptics.impact(.light)
        openURL(url)
    }

    private func shareLink() {
        guard let url = URL(string: link.url) else { return }
        Haptics.impact(.light)
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
        Haptics.notification(.success)
        presentCopiedIndicator()
    }

    private func presentCopiedIndicator() {
        hideCopiedIndicatorTask?.cancel()
        withAnimation {
            showCopiedIndicator = true
        }
        hideCopiedIndicatorTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    showCopiedIndicator = false
                }
            }
        }
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

    private func loadAssets() async {
        let faviconData = await LinkAssetStore.shared.loadFavicon(linkID: link.id) ?? link.favicon
        let previewData = await LinkAssetStore.shared.loadPreviewImage(linkID: link.id) ?? link.previewImage

        faviconImage = await decodeImage(from: faviconData)
        previewImage = await decodeImage(from: previewData)
    }

    private func decodeImage(from data: Data?) async -> UIImage? {
        guard let data else { return nil }
        return await Task.detached(priority: .utility) { UIImage(data: data) }.value
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        GroupBox {
            Text(link.notes ?? "")
                .font(.callout)
                .textSelection(.enabled)
        } label: {
            DetailCardHeader(title: "linkDetail.notes.title", systemImage: "note.text")
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
    let title: LocalizedStringKey
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
    @Query(
        sort: [
            SortDescriptor(\Folder.sortOrder, order: .forward),
            SortDescriptor(\Folder.name, order: .forward)
        ]
    ) private var folders: [Folder]
    @Query private var allTags: [Tag]

    @State private var title: String = ""
    @State private var url: String = ""
    @State private var notes: String = ""
    @State private var selectedFolder: Folder?
    @State private var selectedTags: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("addLink.section.details") {
                    TextField("common.title", text: $title)
                    TextField("common.url", text: $url)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    TextField("common.notesOptional", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("common.folder") {
                    Picker("common.folder", selection: $selectedFolder) {
                        Text("common.none").tag(nil as Folder?)
                        ForEach(folders) { folder in
                            Label(folder.name, systemImage: folder.iconName)
                                .tag(folder as Folder?)
                        }
                    }
                }

                Section("common.tags") {
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
            .navigationTitle("editLink.title")
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
