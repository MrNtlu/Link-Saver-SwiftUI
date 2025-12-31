//
//  FavoritesView.swift
//  Link Saver
//
//  Created by Codex on 2025/12/31.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Link> { $0.isFavorite },
        sort: \Link.dateAdded,
        order: .reverse
    ) private var favoriteLinks: [Link]

    @State private var searchText = ""

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
                    Label("No Favorites", systemImage: "star")
                } description: {
                    Text("Favorite links from the Links tab to see them here.")
                }
            } else if filteredLinks.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredLinks) { link in
                        NavigationLink(destination: LinkDetailView(link: link)) {
                            LinkRowView(link: link)
                        }
                    .swipeActions(edge: .leading) {
                        Button {
                            togglePinned(link)
                        } label: {
                            Label(
                                link.isPinned ? "Unpin" : "Pin",
                                systemImage: link.isPinned ? "pin.slash" : "pin.fill"
                            )
                        }
                        .tint(.orange)

                        Button {
                            toggleFavorite(link)
                        } label: {
                            Label("Unfavorite", systemImage: "star.slash")
                        }
                        .tint(.yellow)
                    }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteLink(link)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Favorites")
        .searchable(text: $searchText, prompt: "Search favorites")
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
