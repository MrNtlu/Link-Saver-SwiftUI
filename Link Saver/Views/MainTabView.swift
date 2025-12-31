//
//  MainTabView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

enum AppTab: Int, CaseIterable {
    case links = 0
    case folders = 1
    case settings = 2
    case add = 3

    var title: String {
        switch self {
        case .links: return "Links"
        case .folders: return "Folders"
        case .settings: return "Settings"
        case .add: return "Add"
        }
    }

    var icon: String {
        switch self {
        case .links: return "link"
        case .folders: return "folder"
        case .settings: return "gear"
        case .add: return "plus"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .links

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                liquidGlassTabView
            } else {
                legacyTabView
            }
        }
    }

    // MARK: - iOS 26+ Liquid Glass Tab Bar
    @available(iOS 26, *)
    private var liquidGlassTabView: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.links.title, systemImage: AppTab.links.icon, value: AppTab.links) {
                LinksView()
            }

            Tab(AppTab.folders.title, systemImage: AppTab.folders.icon, value: AppTab.folders) {
                FoldersView()
            }

            Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: AppTab.settings) {
                SettingsView()
            }
            
            Tab(AppTab.add.title, systemImage: AppTab.add.icon, value: AppTab.add, role: .search) {
                AddLinkView(onSaved: { selectedTab = .links })
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    // MARK: - iOS 18-25 Legacy Tab Bar
    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            LinksView()
                .tabItem { Label(AppTab.links.title, systemImage: AppTab.links.icon) }
                .tag(AppTab.links)

            FoldersView()
                .tabItem { Label(AppTab.folders.title, systemImage: AppTab.folders.icon) }
                .tag(AppTab.folders)

            SettingsView()
                .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.icon) }
                .tag(AppTab.settings)

            AddLinkView(onSaved: { selectedTab = .links })
                .tabItem { Label(AppTab.add.title, systemImage: AppTab.add.icon) }
                .tag(AppTab.add)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
