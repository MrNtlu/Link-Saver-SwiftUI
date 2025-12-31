//
//  ShareView.swift
//  Save to Link Saver
//
//  Created by Burak on 2025/12/31.
//

import SwiftUI
import SwiftData

struct ShareView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var folders: [Folder]
    @Query private var allTags: [Tag]

    let url: String?
    let title: String?
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var urlText = ""
    @State private var titleText = ""
    @State private var notesText = ""
    @State private var selectedFolder: Folder?
    @State private var selectedTags: Set<UUID> = []
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var isFetching = false
    @State private var fetchedTitle: String?
    @State private var fetchedDescription: String?
    @State private var lastFetchedURL: URL?
    @State private var fetchTask: Task<Void, Never>?
    @State private var didUserEditTitle = false

    private var isValidURL: Bool {
        urlText.normalizedURL != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showSuccess {
                    successView
                } else {
                    contentView
                }
            }
            .navigationTitle("Save Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        fetchTask?.cancel()
                        onCancel()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else if !showSuccess {
                        Button("Save") {
                            saveLink()
                        }
                        .disabled(!isValidURL || isFetching)
                    }
                }
            }
        }
        .onAppear {
            urlText = url ?? ""
            titleText = title ?? ""
            didUserEditTitle = (title != nil && !(title ?? "").isEmpty)
            fetchPreviewIfPossible(force: false)
        }
    }

    // MARK: - Content View
    private var contentView: some View {
        Form {
            // URL Input / Preview
            Section("URL") {
                TextField("Enter URL", text: $urlText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onChange(of: urlText) { _, newValue in
                        handleURLChange(newValue)
                    }
                    .onSubmit {
                        fetchPreviewIfPossible(force: true)
                    }

                if isValidURL {
                    Button {
                        fetchPreviewIfPossible(force: true)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Fetch Preview")
                            Spacer()
                            if isFetching {
                                ProgressView()
                            } else if lastFetchedURL == urlText.normalizedURL {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(isFetching)
                }

                if isFetching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Fetching preview...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                previewCard

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Details") {
                TextField("Title", text: $titleText) { isEditing in
                    if isEditing {
                        didUserEditTitle = true
                    }
                }

                TextField("Notes (optional)", text: $notesText, axis: .vertical)
                    .lineLimit(3...8)
            }

            // Folder Selection
            if !folders.isEmpty {
                Section {
                    Picker("Save to folder", selection: $selectedFolder) {
                        Text("None").tag(nil as Folder?)
                        ForEach(folders) { folder in
                            Label(folder.name, systemImage: folder.iconName)
                                .tag(folder as Folder?)
                        }
                    }
                } header: {
                    Text("Folder")
                }
            }

            // Tags Selection
            if !allTags.isEmpty {
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
        }
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Link Saved!")
                .font(.title2)
                .fontWeight(.semibold)

            if !titleText.isEmpty {
                Text(titleText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Auto-dismiss after success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onSave()
            }
        }
    }

    // MARK: - Save Link
    private func saveLink() {
        guard let normalizedURL = urlText.normalizedURL else {
            errorMessage = "No valid URL to save"
            return
        }

        isSaving = true

        // Create and save the link
        let link = Link(url: normalizedURL.absoluteString)
        link.title = titleText.isEmpty ? fetchedTitle : titleText
        link.linkDescription = fetchedDescription
        link.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notesText
        link.folder = selectedFolder
        link.tags = allTags.filter { selectedTags.contains($0.id) }
        modelContext.insert(link)

        do {
            try modelContext.save()

            // Fetch metadata in background
            Task { @MainActor in
                await MetadataService.shared.fetchAndUpdateMetadata(for: link)
                do {
                    try modelContext.save()
                } catch {
                    print("[ShareExtension] Failed to save metadata: \(error.localizedDescription)")
                }
            }

            withAnimation {
                showSuccess = true
            }
        } catch {
            errorMessage = "Failed to save link: \(error.localizedDescription)"
        }

        isSaving = false
    }

    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag.id) {
            selectedTags.remove(tag.id)
        } else {
            selectedTags.insert(tag.id)
        }
    }

    @ViewBuilder
    private var previewCard: some View {
        if fetchedTitle != nil || fetchedDescription != nil {
            VStack(alignment: .leading, spacing: 6) {
                if let title = fetchedTitle, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                }
                if let description = fetchedDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func handleURLChange(_ newValue: String) {
        errorMessage = nil
        fetchedTitle = nil
        fetchedDescription = nil

        fetchTask?.cancel()

        if !didUserEditTitle {
            titleText = ""
        }

        fetchPreviewIfPossible(force: false)
    }

    private func fetchPreviewIfPossible(force: Bool) {
        guard let url = urlText.normalizedURL else { return }

        if !force, lastFetchedURL == url {
            return
        }

        fetchTask?.cancel()
        fetchTask = Task {
            if !force {
                try? await Task.sleep(nanoseconds: 450_000_000)
                if Task.isCancelled { return }
            }

            await MainActor.run {
                isFetching = true
                errorMessage = nil
            }

            do {
                let metadata = try await MetadataService.shared.fetchMetadata(for: url)
                await MainActor.run {
                    lastFetchedURL = url
                    fetchedTitle = metadata.title
                    fetchedDescription = metadata.description
                    if !didUserEditTitle, titleText.isEmpty {
                        titleText = metadata.title ?? ""
                    }
                    isFetching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not fetch preview"
                    isFetching = false
                }
            }
        }
    }
}

#if DEBUG
struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView(
            url: "https://apple.com",
            title: "Apple",
            onSave: { },
            onCancel: { }
        )
        .modelContainer(ModelContainerFactory.createPreviewContainer())
    }
}
#endif
