//
//  SettingsView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var links: [Link]
    @Query private var folders: [Folder]
    @Query private var tags: [Tag]

    @AppStorage(ThemePreferences.key, store: ThemePreferences.store)
    private var themeRawValue: String = ThemePreferences.defaultTheme.rawValue

    private var selectedTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: themeRawValue) ?? ThemePreferences.defaultTheme },
            set: { themeRawValue = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                // Statistics Section
                Section("Statistics") {
                    StatRow(title: "Total Links", value: "\(links.count)", icon: "link")
                    StatRow(title: "Folders", value: "\(folders.count)", icon: "folder")
                    StatRow(title: "Tags", value: "\(tags.count)", icon: "tag")
                    StatRow(title: "Favorites", value: "\(links.filter { $0.isFavorite }.count)", icon: "star.fill")
                }

                // Organization Section
                Section("Organization") {
                    NavigationLink {
                        TagManagementView()
                    } label: {
                        Label("Manage Tags", systemImage: "tag")
                    }
                }

                // Appearance Section
                Section("Appearance") {
                    Picker("Theme", selection: selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    if #available(iOS 26, *) {
                        HStack {
                            Text("Design")
                            Spacer()
                            Text("Liquid Glass")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Support Section
                // TODO: Replace with actual Privacy Policy and Terms of Service URLs
                // Section {
                //     Link(destination: URL(string: "https://your-privacy-policy-url.com")!) {
                //         Label("Privacy Policy", systemImage: "hand.raised")
                //     }
                //
                //     Link(destination: URL(string: "https://your-terms-url.com")!) {
                //         Label("Terms of Service", systemImage: "doc.text")
                //     }
                // }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
