//
//  FolderReorderView.swift
//  Link Saver
//
//  Created by Codex on 2026/01/01.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct FolderReorderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var orderedFolders: [Folder]
    @State private var draggingFolderID: UUID?

    init(folders: [Folder]) {
        _orderedFolders = State(initialValue: folders)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(orderedFolders) { folder in
                    FolderReorderRowView(folder: folder)
                        .background(.background)
                        .contentShape(Rectangle())
                        .onDrag {
                            draggingFolderID = folder.id
                            return NSItemProvider(object: folder.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [UTType.plainText],
                            delegate: FolderReorderDropDelegate(
                                targetFolder: folder,
                                orderedFolders: $orderedFolders,
                                draggingFolderID: $draggingFolderID
                            )
                        )

                    if folder.id != orderedFolders.last?.id {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.separator.opacity(0.35), lineWidth: 1)
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("folders.reorder.title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save") {
                    saveOrder()
                    dismiss()
                }
            }
        }
    }

    private func saveOrder() {
        for (index, folder) in orderedFolders.enumerated() {
            folder.sortOrder = index
        }

        do {
            try modelContext.save()
        } catch {
        }
    }
}

private struct FolderReorderRowView: View {
    let folder: Folder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.headline)
                .foregroundStyle(.tertiary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: folder.iconName)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Group {
                    if folder.linkCount == 1 {
                        Text("folders.linkCount.one \(folder.linkCount)")
                    } else {
                        Text("folders.linkCount.other \(folder.linkCount)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private struct FolderReorderDropDelegate: DropDelegate {
    let targetFolder: Folder
    @Binding var orderedFolders: [Folder]
    @Binding var draggingFolderID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggingFolderID else { return }
        guard draggingFolderID != targetFolder.id else { return }

        guard let fromIndex = orderedFolders.firstIndex(where: { $0.id == draggingFolderID }),
              let toIndex = orderedFolders.firstIndex(where: { $0.id == targetFolder.id })
        else { return }

        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.92)) {
            orderedFolders.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingFolderID = nil
        return true
    }
}

#Preview {
    NavigationStack {
        FolderReorderView(folders: [
            Folder(name: "Work", iconName: "briefcase"),
            Folder(name: "Personal", iconName: "person"),
            Folder(name: "Reading List", iconName: "book")
        ])
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
