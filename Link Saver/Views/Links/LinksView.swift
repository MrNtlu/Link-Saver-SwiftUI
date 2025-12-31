//
//  LinksView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct LinksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Link.dateAdded, order: .reverse) private var links: [Link]
    @Query private var tags: [Tag]

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedTagFilter: Tag?
    @State private var sortOption: LinkSortOption = .dateAddedNewest
    @State private var showSortMenu = false

    var filteredLinks: [Link] {
        var result = links

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { link in
                link.title?.localizedCaseInsensitiveContains(searchText) == true ||
                link.url.localizedCaseInsensitiveContains(searchText) ||
                link.linkDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply tag filter
        if let tag = selectedTagFilter {
            result = result.filter { $0.tags.contains(where: { $0.id == tag.id }) }
        }

        // Apply sorting
        return sortLinksPinnedFirst(result)
    }

    private func sortLinksPinnedFirst(_ links: [Link]) -> [Link] {
        let pinned = links.filter(\.isPinned)
        let unpinned = links.filter { !$0.isPinned }
        return sortLinks(pinned) + sortLinks(unpinned)
    }

    private func sortLinks(_ links: [Link]) -> [Link] {
        switch sortOption {
        case .dateAddedNewest:
            return links.sorted { $0.dateAdded > $1.dateAdded }
        case .dateAddedOldest:
            return links.sorted { $0.dateAdded < $1.dateAdded }
        case .titleAZ:
            return links.sorted { ($0.title ?? $0.url) < ($1.title ?? $1.url) }
        case .titleZA:
            return links.sorted { ($0.title ?? $0.url) > ($1.title ?? $1.url) }
        case .favorites:
            return links.sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite {
                    return lhs.isFavorite && !rhs.isFavorite
                }
                return lhs.dateAdded > rhs.dateAdded
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if links.isEmpty {
                    emptyStateView
                } else {
                    linksList
                }
            }
            .navigationTitle("Links")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                isPresented: $isSearching,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search links"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenuButton
                }
            }
        }
    }

    @ViewBuilder
    private var filteredEmptyStateView: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if let tag = selectedTagFilter {
            ContentUnavailableView {
                Label("No Links", systemImage: "tag")
            } description: {
                Text("No links match the “\(tag.name)” tag.")
            }
        } else {
            ContentUnavailableView {
                Label("No Links", systemImage: "link")
            } description: {
                Text("No links match the current filters.")
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Links", systemImage: "link.badge.plus")
        } description: {
            Text("Save links from Safari or other apps using the Share button, or use + to add manually.")
        }
    }

    // MARK: - Links List
    private var linksList: some View {
        List {
            if !isSearching && !tags.isEmpty {
                Section {
                    TagFilterView(tags: tags, selectedTag: $selectedTagFilter)
                        .padding(.vertical, 6)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }

            if filteredLinks.isEmpty {
                filteredEmptyStateView
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            ForEach(filteredLinks) { link in
                NavigationLink(destination: LinkDetailView(link: link)) {
                    LinkRowView(link: link)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteLink(link)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
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
                        Label(
                            link.isFavorite ? "Unfavorite" : "Favorite",
                            systemImage: link.isFavorite ? "star.slash" : "star.fill"
                        )
                    }
                    .tint(.yellow)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Sort Menu
    private var sortMenuButton: some View {
        Menu {
            ForEach(LinkSortOption.allCases) { option in
                Button {
                    sortOption = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    // MARK: - Actions
    private func deleteLink(_ link: Link) {
        withAnimation {
            modelContext.delete(link)
        }
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
}

#Preview {
    LinksView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
