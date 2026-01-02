//
//  LinkDomainGroupsView.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import SwiftUI
import SwiftData
import UIKit

struct LinkDomainGroupsView: View {
    @Query(sort: \Link.dateAdded, order: .reverse) private var links: [Link]
    @Query private var tags: [Tag]

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedTagFilter: Tag?

    private var filteredLinks: [Link] {
        var result = links

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

        return result
    }

    private var domainGroups: [LinkDomainGroup] {
        filteredLinks.groupedByDomain()
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

            if links.isEmpty {
                ContentUnavailableView {
                    Label("links.empty.title", systemImage: "link.badge.plus")
                } description: {
                    Text("links.empty.message")
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else if domainGroups.isEmpty {
                filteredEmptyStateView
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(domainGroups) { group in
                    NavigationLink(destination: LinkDomainGroupDetailView(domain: group.domain)) {
                        LinkDomainGroupRowView(domain: group.domain, links: group.links)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("links.groupByDomain.title")
        .searchable(
            text: $searchText,
            isPresented: $isSearching,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "links.groupByDomain.search.prompt"
        )
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
                Label("links.empty.title", systemImage: "folder")
            } description: {
                Text("links.empty.filtered")
            }
        }
    }
}

private struct LinkDomainGroupRowView: View {
    let domain: String?
    let links: [Link]

    @State private var faviconImage: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            groupIcon
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                domainText
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("\(links.count)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .task(id: domain ?? "__unknown__") {
            await loadFavicon()
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var domainText: some View {
        if let domain {
            Text(domain)
        } else {
            Text("links.groupByDomain.unknown")
        }
    }

    @ViewBuilder
    private var groupIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary)

            Image(systemName: "folder.fill")
                .font(.title3)
                .foregroundStyle(.secondary.opacity(0.8))

            if let faviconImage {
                Image(uiImage: faviconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "globe")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadFavicon() async {
        for link in links.prefix(12) {
            let faviconData = await LinkAssetStore.shared.loadFavicon(linkID: link.id) ?? link.favicon
            if let faviconData, let uiImage = UIImage(data: faviconData) {
                faviconImage = uiImage
                return
            }
        }
        faviconImage = nil
    }
}

#Preview {
    NavigationStack {
        LinkDomainGroupsView()
            .modelContainer(ModelContainerFactory.createPreviewContainer())
    }
}

