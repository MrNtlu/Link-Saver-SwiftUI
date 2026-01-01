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

    var titleKey: LocalizedStringKey {
        switch self {
        case .links: return "tab.links"
        case .folders: return "tab.folders"
        case .settings: return "tab.settings"
        case .add: return "tab.add"
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
            Tab(AppTab.links.titleKey, systemImage: AppTab.links.icon, value: AppTab.links) {
                LinksView()
            }

            Tab(AppTab.folders.titleKey, systemImage: AppTab.folders.icon, value: AppTab.folders) {
                FoldersView()
            }

            Tab(AppTab.settings.titleKey, systemImage: AppTab.settings.icon, value: AppTab.settings) {
                SettingsView()
            }
            
            Tab(AppTab.add.titleKey, systemImage: AppTab.add.icon, value: AppTab.add, role: .search) {
                AddLinkView(onSaved: { selectedTab = .links })
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    // MARK: - iOS 18-25 Legacy Tab Bar
    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            LinksView()
                .tabItem { Label(AppTab.links.titleKey, systemImage: AppTab.links.icon) }
                .tag(AppTab.links)

            FoldersView()
                .tabItem { Label(AppTab.folders.titleKey, systemImage: AppTab.folders.icon) }
                .tag(AppTab.folders)

            SettingsView()
                .tabItem { Label(AppTab.settings.titleKey, systemImage: AppTab.settings.icon) }
                .tag(AppTab.settings)

            AddLinkView(onSaved: { selectedTab = .links })
                .tabItem { Label(AppTab.add.titleKey, systemImage: AppTab.add.icon) }
                .tag(AppTab.add)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
