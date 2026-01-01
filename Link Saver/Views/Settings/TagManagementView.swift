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
        .navigationTitle("tags.title")
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
            Label("tags.empty.title", systemImage: "tag")
        } description: {
            Text("tags.empty.message")
        } actions: {
            Button("tags.create") {
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

                        Group {
                            if tag.linkCount == 1 {
                                Text("tags.linkCount.one \(tag.linkCount)")
                            } else {
                                Text("tags.linkCount.other \(tag.linkCount)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteTag(tag)
                    } label: {
                        Label("common.delete", systemImage: "trash")
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
                Section("tags.section.name") {
                    TextField("common.name", text: $name)
                }

                Section("common.color") {
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
                Section("common.preview") {
                    HStack {
                        Spacer()
                        TagPreviewChip(name: name, colorHex: selectedColor)
                        Spacer()
                    }
                }
            }
            .navigationTitle("tags.add.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.create") {
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
                Section("tags.section.name") {
                    TextField("common.name", text: $name)
                }

                Section("common.color") {
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
                Section("common.preview") {
                    HStack {
                        Spacer()
                        TagPreviewChip(name: name, colorHex: selectedColor)
                        Spacer()
                    }
                }
            }
            .navigationTitle("tags.edit.title")
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

private struct TagPreviewChip: View {
    let name: String
    let colorHex: String

    private var displayNameIsEmpty: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var chipColor: Color {
        Color(hex: colorHex) ?? .blue
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(chipColor)
                .frame(width: 8, height: 8)

            if displayNameIsEmpty {
                Text("tags.preview.placeholder")
            } else {
                Text(verbatim: name)
            }
        }
        .font(.caption)
        .fontWeight(.medium)
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        TagManagementView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
