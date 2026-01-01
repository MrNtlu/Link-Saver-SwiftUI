//
//  FavoritesView.swift
//  Link Saver
//
//  Created by Codex on 2025/12/31.
//

import SwiftUI
import SwiftData
import UIKit

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(
        filter: #Predicate<Link> { $0.isFavorite },
        sort: \Link.dateAdded,
        order: .reverse
    ) private var favoriteLinks: [Link]

    @State private var searchText = ""
    @State private var linkToEdit: Link?
    @State private var linkPendingDelete: Link?

    private var filteredLinks: [Link] {
        let base: [Link]
        if searchText.isEmpty {
            base = favoriteLinks
        } else {
            base = favoriteLinks.filter { link in
            link.title?.localizedCaseInsensitiveContains(searchText) == true ||
            link.url.localizedCaseInsensitiveContains(searchText) ||
            link.linkDescription?.localizedCaseInsensitiveContains(searchText) == true ||
            link.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        let pinned = base.filter(\.isPinned)
        let unpinned = base.filter { !$0.isPinned }
        return pinned + unpinned
    }

    var body: some View {
        Group {
            if favoriteLinks.isEmpty {
                ContentUnavailableView {
                    Label("favorites.empty.title", systemImage: "star")
                } description: {
                    Text("favorites.empty.message")
                }
            } else if filteredLinks.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredLinks) { link in
                        NavigationLink(destination: LinkDetailView(link: link)) {
                            LinkRowView(link: link)
                        }
                        .contextMenu {
                            linkContextMenu(for: link)
                        }
                    .swipeActions(edge: .leading) {
                        Button {
                            togglePinned(link)
                        } label: {
                            let titleKey: LocalizedStringKey = link.isPinned ? "common.unpin" : "common.pin"
                            Label(
                                titleKey,
                                systemImage: link.isPinned ? "pin.slash" : "pin.fill"
                            )
                        }
                        .tint(.orange)

                        Button {
                            toggleFavorite(link)
                        } label: {
                            Label("common.unfavorite", systemImage: "star.slash")
                        }
                        .tint(.yellow)
                    }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                linkPendingDelete = link
                            } label: {
                                Label("common.delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("folders.favorites.title")
        .searchable(text: $searchText, prompt: "favorites.search.prompt")
        .sheet(item: $linkToEdit) { link in
            EditLinkView(link: link)
        }
        .alert("linkDetail.delete.title", isPresented: Binding(
            get: { linkPendingDelete != nil },
            set: { isPresented in
                if !isPresented {
                    linkPendingDelete = nil
                }
            }
        )) {
            Button("common.cancel", role: .cancel) {
                linkPendingDelete = nil
            }
            Button("common.delete", role: .destructive) {
                guard let linkPendingDelete else { return }
                deleteLink(linkPendingDelete)
                self.linkPendingDelete = nil
            }
        } message: {
            Text("linkDetail.delete.message")
        }
    }

    @ViewBuilder
    private func linkContextMenu(for link: Link) -> some View {
        Button {
            openLink(link)
        } label: {
            Label("common.open", systemImage: "safari")
        }

        Button {
            copyLink(link)
        } label: {
            Label("common.copy", systemImage: "doc.on.doc")
        }

        Button {
            toggleFavorite(link)
        } label: {
            Label("common.unfavorite", systemImage: "star.slash")
        }

        Button {
            togglePinned(link)
        } label: {
            let titleKey: LocalizedStringKey = link.isPinned ? "common.unpin" : "common.pin"
            Label(
                titleKey,
                systemImage: link.isPinned ? "pin.slash" : "pin.fill"
            )
        }

        Button {
            linkToEdit = link
        } label: {
            Label("common.edit", systemImage: "pencil")
        }

        Divider()

        Button(role: .destructive) {
            linkPendingDelete = link
        } label: {
            Label("common.delete", systemImage: "trash")
        }
    }

    private func openLink(_ link: Link) {
        guard let url = link.url.normalizedURL else { return }
        openURL(url)
    }

    private func copyLink(_ link: Link) {
        UIPasteboard.general.string = link.url
    }

    private func toggleFavorite(_ link: Link) {
        withAnimation {
            link.isFavorite.toggle()
        }
    }

    private func togglePinned(_ link: Link) {
        withAnimation {
            link.isPinned.toggle()
        }
    }

    private func deleteLink(_ link: Link) {
        withAnimation {
            modelContext.delete(link)
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
