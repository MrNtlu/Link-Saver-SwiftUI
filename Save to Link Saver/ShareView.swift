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

    @AppStorage(LanguagePreferences.key, store: LanguagePreferences.store)
    private var languageRawValue: String = LanguagePreferences.defaultLanguage.rawValue

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
    @State private var errorKey: String?
    @State private var isFetching = false
    @State private var fetchedTitle: String?
    @State private var fetchedDescription: String?
    @State private var lastFetchedURL: URL?
    @State private var fetchTask: Task<Void, Never>?
    @State private var didUserEditTitle = false

    private var isValidURL: Bool {
        urlText.normalizedURL != nil
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? LanguagePreferences.defaultLanguage
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
            .navigationTitle("share.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        fetchTask?.cancel()
                        onCancel()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else if !showSuccess {
                        Button("common.save") {
                            saveLink()
                        }
                        .disabled(!isValidURL || isFetching)
                    }
                }
            }
        }
        .environment(\.locale, language.locale)
        .onAppear {
            urlText = url ?? ""
            titleText = title ?? ""
            didUserEditTitle = (title != nil && !(title ?? "").isEmpty)
            fetchPreviewIfPossible(force: false)
        }
        .onDisappear {
            fetchTask?.cancel()
        }
    }

    // MARK: - Content View
    private var contentView: some View {
        Form {
            // URL Input / Preview
            Section("common.url") {
                TextField("addLink.url.placeholder", text: $urlText)
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
                            Text("common.fetchPreview")
                            Spacer()
                            if isFetching {
                                ProgressView()
                            } else if lastFetchedURL == urlText.normalizedURL {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(!isValidURL || isFetching)
                }

                if isFetching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("common.fetchingPreview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                previewCard

                if let errorKey {
                    Text(LocalizedStringKey(errorKey))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("addLink.section.details") {
                TextField("common.title", text: $titleText) { isEditing in
                    if isEditing {
                        didUserEditTitle = true
                    }
                }

                TextField("common.notesOptional", text: $notesText, axis: .vertical)
                    .lineLimit(3...8)
            }

            // Folder Selection
            if !folders.isEmpty {
                Section {
                    Picker("addLink.folder.picker", selection: $selectedFolder) {
                        Text("common.none").tag(nil as Folder?)
                        ForEach(folders) { folder in
                            Label(folder.name, systemImage: folder.iconName)
                                .tag(folder as Folder?)
                        }
                    }
                } header: {
                    Text("common.folder")
                }
            }

            // Tags Selection
            if !allTags.isEmpty {
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
        }
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("share.success.title")
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
            errorKey = "error.invalidUrlToSave"
            return
        }

        isSaving = true
        fetchTask?.cancel()

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
            errorKey = "error.saveFailed"
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
        errorKey = nil
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
                errorKey = nil
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
                    if error is CancellationError || Task.isCancelled {
                        isFetching = false
                        return
                    }
                    errorKey = "error.previewFetchFailed"
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
