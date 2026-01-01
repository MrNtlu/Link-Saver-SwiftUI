//
//  AddLinkView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct AddLinkView: View {
    @Environment(\.modelContext) private var modelContext
    let onSaved: (() -> Void)?

    @Query private var folders: [Folder]
    @Query private var allTags: [Tag]

    @State private var urlText = ""
    @State private var titleText = ""
    @State private var notesText = ""
    @State private var selectedFolder: Folder?
    @State private var selectedTags: Set<UUID> = []
    @State private var isFetching = false
    @State private var fetchedTitle: String?
    @State private var fetchedDescription: String?
    @State private var lastFetchedURL: URL?
    @State private var fetchTask: Task<Void, Never>?
    @State private var didUserEditTitle = false
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showAddTag = false

    private var isValidURL: Bool {
        urlText.normalizedURL != nil
    }

    init(onSaved: (() -> Void)? = nil) {
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                // URL Input
                Section {
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
                        .disabled(!isValidURL || isFetching)
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
                } header: {
                    Text("URL")
                } footer: {
                    Text("Enter a website URL to save")
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
                Section("Folder") {
                    Picker("Save to folder", selection: $selectedFolder) {
                        Text("None").tag(nil as Folder?)
                        ForEach(folders) { folder in
                            Label(folder.name, systemImage: folder.iconName)
                                .tag(folder as Folder?)
                        }
                    }
                }

                Section {
                    if allTags.isEmpty {
                        ContentUnavailableView {
                            Label("No Tags", systemImage: "tag")
                        } description: {
                            Text("Create tags to organize your links.")
                        } actions: {
                            Button("Create Tag") {
                                showAddTag = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    } else {
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

                        Button {
                            showAddTag = true
                        } label: {
                            Label("Create Tag", systemImage: "plus")
                        }
                    }
                } header: {
                    Text("Tags")
                }
            }
            .navigationTitle("Add Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveLink()
                        }
                        .disabled(!isValidURL || isFetching)
                    }
                }
            }
        }
        .onAppear {
            if urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = nil
            }
        }
        .onDisappear {
            fetchTask?.cancel()
        }
        .sheet(isPresented: $showAddTag) {
            AddTagView()
        }
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
                    if error is CancellationError || Task.isCancelled {
                        isFetching = false
                        return
                    }
                    errorMessage = "Could not fetch preview"
                    isFetching = false
                }
            }
        }
    }

    private func saveLink() {
        guard let url = urlText.normalizedURL else { return }

        isSaving = true
        errorMessage = nil
        fetchTask?.cancel()

        let link = Link(url: url.absoluteString)
        link.title = titleText.isEmpty ? fetchedTitle : titleText
        link.linkDescription = fetchedDescription
        link.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notesText
        link.folder = selectedFolder
        link.tags = allTags.filter { selectedTags.contains($0.id) }

        modelContext.insert(link)

        do {
            try modelContext.save()

            Task { @MainActor in
                await MetadataService.shared.fetchAndUpdateMetadata(for: link)
                try? modelContext.save()
            }

            resetForm()
            isSaving = false
            onSaved?()
        } catch {
            errorMessage = "Failed to save link: \(error.localizedDescription)"
            isSaving = false
        }
    }

    private func resetForm() {
        fetchTask?.cancel()
        urlText = ""
        titleText = ""
        notesText = ""
        selectedFolder = nil
        selectedTags = []
        isFetching = false
        fetchedTitle = nil
        fetchedDescription = nil
        lastFetchedURL = nil
        didUserEditTitle = false
        errorMessage = nil
        showAddTag = false
    }
}

#Preview {
    AddLinkView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
