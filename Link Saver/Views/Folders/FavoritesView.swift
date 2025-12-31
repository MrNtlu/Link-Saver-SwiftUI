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
        guard !searchText.isEmpty else { return favoriteLinks }
        return favoriteLinks.filter { link in
            link.title?.localizedCaseInsensitiveContains(searchText) == true ||
            link.url.localizedCaseInsensitiveContains(searchText) ||
            link.linkDescription?.localizedCaseInsensitiveContains(searchText) == true ||
            link.notes?.localizedCaseInsensitiveContains(searchText) == true
        }
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

