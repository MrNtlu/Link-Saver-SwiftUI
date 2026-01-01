//
//  AddFolderView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct AddFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]

    @State private var name = ""
    @State private var selectedIcon = "folder"
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
            .navigationTitle("folder.add.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.create") {
                        createFolder()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func createFolder() {
        let folder = Folder(name: name, iconName: selectedIcon)
        folder.sortOrder = (folders.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(folder)
        dismiss()
    }
}

#Preview {
    AddFolderView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
