//
//  TagManagementView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var showAddTag = false
    @State private var tagToEdit: Tag?

    var body: some View {
        Group {
            if tags.isEmpty {
                emptyStateView
            } else {
                tagsList
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTag = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTag) {
            AddTagView()
        }
        .sheet(item: $tagToEdit) { tag in
            EditTagView(tag: tag)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
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
    }

    // MARK: - Tags List
    private var tagsList: some View {
        List {
            ForEach(tags) { tag in
                Button {
                    tagToEdit = tag
                } label: {
                    HStack {
                        Circle()
                            .fill(tag.color)
                            .frame(width: 16, height: 16)

                        Text(tag.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(tag.linkCount) link\(tag.linkCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteTag(tag)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func deleteTag(_ tag: Tag) {
        withAnimation {
            modelContext.delete(tag)
        }
    }
}

// MARK: - Add Tag View
struct AddTagView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = AppConstants.defaultTagColors[0]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Name") {
                    TextField("Name", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(AppConstants.defaultTagColors, id: \.self) { colorHex in
                            Button {
                                selectedColor = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex) ?? .blue)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if selectedColor == colorHex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Preview
                Section("Preview") {
                    HStack {
                        Spacer()
                        TagChip(
                            tag: Tag(name: name.isEmpty ? "Tag" : name, colorHex: selectedColor),
                            isCompact: false
                        )
                        Spacer()
                    }
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTag()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func createTag() {
        let tag = Tag(name: name, colorHex: selectedColor)
        modelContext.insert(tag)
        dismiss()
    }
}

// MARK: - Edit Tag View
struct EditTagView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var tag: Tag

    @State private var name = ""
    @State private var selectedColor = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Name") {
                    TextField("Name", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(AppConstants.defaultTagColors, id: \.self) { colorHex in
                            Button {
                                selectedColor = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex) ?? .blue)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if selectedColor == colorHex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Preview
                Section("Preview") {
                    HStack {
                        Spacer()
                        TagChip(
                            tag: Tag(name: name.isEmpty ? "Tag" : name, colorHex: selectedColor),
                            isCompact: false
                        )
                        Spacer()
                    }
                }
            }
            .navigationTitle("Edit Tag")
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
                name = tag.name
                selectedColor = tag.colorHex
            }
        }
    }

    private func saveChanges() {
        tag.name = name
        tag.colorHex = selectedColor
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TagManagementView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
