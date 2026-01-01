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

    @AppStorage(OnboardingPreferences.key, store: OnboardingPreferences.store)
    private var hasCompletedOnboarding: Bool = false

    @AppStorage(ThemePreferences.key, store: ThemePreferences.store)
    private var themeRawValue: String = ThemePreferences.defaultTheme.rawValue
    @AppStorage(LanguagePreferences.key, store: LanguagePreferences.store)
    private var languageRawValue: String = LanguagePreferences.defaultLanguage.rawValue

    private var selectedTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: themeRawValue) ?? ThemePreferences.defaultTheme },
            set: { themeRawValue = $0.rawValue }
        )
    }

    private var selectedLanguage: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: languageRawValue) ?? LanguagePreferences.defaultLanguage },
            set: { languageRawValue = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                // App Settings Section
                Section("settings.section.appSettings") {
                    Picker("settings.theme", selection: selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayNameKey).tag(theme)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Picker("settings.language", selection: selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayNameKey)
                                .tag(language)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        HStack {
                            Text("settings.showOnboarding")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                // Tags Section
                Section("settings.section.tags") {
                    NavigationLink {
                        TagManagementView()
                    } label: {
                        Label("settings.manageTags", systemImage: "tag")
                    }
                }

                // Statistics Section
                Section("settings.section.statistics") {
                    StatRow(title: "settings.stats.totalLinks", value: "\(links.count)", icon: "link")
                    StatRow(title: "settings.stats.folders", value: "\(folders.count)", icon: "folder")
                    StatRow(title: "settings.stats.tags", value: "\(tags.count)", icon: "tag")
                    StatRow(title: "settings.stats.favorites", value: "\(links.filter { $0.isFavorite }.count)", icon: "star.fill")
                }

                // About Section
                Section("settings.section.about") {
                    HStack {
                        Text("settings.version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    if #available(iOS 26, *) {
                        HStack {
                            Text("settings.design")
                            Spacer()
                            Text("settings.design.liquidGlass")
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
            .navigationTitle(Text("tab.settings"))
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: LocalizedStringKey
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
