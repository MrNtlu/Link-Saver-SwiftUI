//
//  LinkDomainGroupDetailView.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import SwiftUI
import SwiftData
import UIKit

struct LinkDomainGroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \Link.dateAdded, order: .reverse) private var links: [Link]
    @Query private var tags: [Tag]

    let domain: String?

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedTagFilter: Tag?
    @State private var sortOption: LinkSortOption = .dateAddedNewest
    @State private var linkToEdit: Link?
    @State private var linkPendingDelete: Link?

    private var domainLinks: [Link] {
        let normalizedDomain = domain?.lowercased()
        return links.filter { $0.domain?.lowercased() == normalizedDomain }
    }

    private var filteredLinks: [Link] {
        var result = domainLinks

        if !searchText.isEmpty {
            result = result.filter { link in
                link.title?.localizedCaseInsensitiveContains(searchText) == true ||
                link.url.localizedCaseInsensitiveContains(searchText) ||
                link.linkDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        if let tag = selectedTagFilter {
            result = result.filter { $0.tags.contains(where: { $0.id == tag.id }) }
        }

        return sortLinksPinnedFirst(result)
    }

    var body: some View {
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

            if domainLinks.isEmpty {
                ContentUnavailableView {
                    Label("links.empty.title", systemImage: "link")
                } description: {
                    Text("links.empty.filtered")
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else if filteredLinks.isEmpty {
                filteredEmptyStateView
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(filteredLinks) { link in
                    NavigationLink(destination: LinkDetailView(link: link)) {
                        LinkRowView(link: link)
                    }
                    .contextMenu {
                        linkContextMenu(for: link)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            linkPendingDelete = link
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
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
                            let titleKey: LocalizedStringKey = link.isFavorite ? "common.unfavorite" : "common.favorite"
                            Label(
                                titleKey,
                                systemImage: link.isFavorite ? "star.slash" : "star.fill"
                            )
                        }
                        .tint(.yellow)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(domain ?? String(localized: "links.groupByDomain.unknown"))
        .searchable(
            text: $searchText,
            isPresented: $isSearching,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "links.search.prompt"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenuButton
            }
        }
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
    private var filteredEmptyStateView: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if let tag = selectedTagFilter {
            ContentUnavailableView {
                Label("links.empty.title", systemImage: "tag")
            } description: {
                Text("links.empty.filteredByTag \(tag.name)")
            }
        } else {
            ContentUnavailableView {
                Label("links.empty.title", systemImage: "link")
            } description: {
                Text("links.empty.filtered")
            }
        }
    }

    // MARK: - Sorting
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

    // MARK: - Sort Menu
    private var sortMenuButton: some View {
        Menu {
            ForEach(LinkSortOption.allCases) { option in
                Button {
                    sortOption = option
                } label: {
                    HStack {
                        Text(option.titleKey)
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
            let titleKey: LocalizedStringKey = link.isFavorite ? "common.unfavorite" : "common.favorite"
            Label(
                titleKey,
                systemImage: link.isFavorite ? "star.slash" : "star"
            )
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

    // MARK: - Actions
    private func deleteLink(_ link: Link) {
        withAnimation {
            modelContext.delete(link)
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
}

#Preview {
    NavigationStack {
        LinkDomainGroupDetailView(domain: "apple.com")
            .modelContainer(ModelContainerFactory.createPreviewContainer())
    }
}
