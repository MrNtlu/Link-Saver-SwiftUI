//
//  SettingsView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var persistenceController: PersistenceController
    @Query private var links: [Link]
    @Query private var folders: [Folder]
    @Query private var tags: [Tag]

    @AppStorage(OnboardingPreferences.key, store: OnboardingPreferences.store)
    private var hasCompletedOnboarding: Bool = false

    @AppStorage(ThemePreferences.key, store: ThemePreferences.store)
    private var themeRawValue: String = ThemePreferences.defaultTheme.rawValue
    @AppStorage(LanguagePreferences.key, store: LanguagePreferences.store)
    private var languageRawValue: String = LanguagePreferences.defaultLanguage.rawValue

    @State private var isExportingBackup = false
    @State private var backupDocument: BackupDocument?
    @State private var isImportingBackup = false
    @State private var settingsAlert: SettingsAlert?

    private enum SettingsAlert: Identifiable {
        case confirmRestore
        case success(messageKey: String)
        case failure(messageKey: String)

        var id: String {
            switch self {
            case .confirmRestore: return "confirmRestore"
            case .success(let key): return "success.\(key)"
            case .failure(let key): return "failure.\(key)"
            }
        }
    }

    private var hasICloudAccount: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    private var canUseBackupActions: Bool {
        BackupPreferences.canPerformAction()
    }

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

                Section("settings.section.icloud") {
                    Toggle(
                        "settings.icloud.sync",
                        isOn: Binding(
                            get: { persistenceController.isICloudSyncEnabled },
                            set: { newValue in
                                Task { await persistenceController.setICloudSyncEnabled(newValue) }
                            }
                        )
                    )
                    .disabled(!hasICloudAccount || persistenceController.isSwitchingSyncMode)

                    if !hasICloudAccount {
                        Text("settings.icloud.unavailable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if persistenceController.isSwitchingSyncMode {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.9)
                            Text("settings.icloud.switching")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("settings.section.backup") {
                    Button("settings.backup.export") {
                        backupDocument = BackupDocument(
                            backup: BackupService.makeBackup(
                                links: links,
                                folders: folders,
                                tags: tags
                            )
                        )
                        isExportingBackup = true
                    }
                    .disabled(persistenceController.isSwitchingSyncMode || !canUseBackupActions)

                    Button("settings.backup.restore") {
                        settingsAlert = .confirmRestore
                    }
                    .disabled(persistenceController.isSwitchingSyncMode || !canUseBackupActions)

                    if !canUseBackupActions {
                        Text("settings.backup.cooldown")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
            .fileExporter(
                isPresented: $isExportingBackup,
                document: backupDocument,
                contentType: .json,
                defaultFilename: "LinkSaver-Backup"
            ) { result in
                switch result {
                case .success:
                    BackupPreferences.markActionPerformed()
                    settingsAlert = .success(messageKey: "settings.backup.success.exported")
                case .failure:
                    settingsAlert = .failure(messageKey: "settings.backup.error.exportFailed")
                }
            }
            .fileImporter(
                isPresented: $isImportingBackup,
                allowedContentTypes: [.json]
            ) { result in
                do {
                    let url = try result.get()
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let backup = try decoder.decode(LinkSaverBackup.self, from: data)
                    try BackupService.importBackup(backup, into: modelContext)
                    BackupPreferences.markActionPerformed()
                    settingsAlert = .success(messageKey: "settings.backup.success.restored")
                } catch BackupService.ImportError.unsupportedVersion {
                    settingsAlert = .failure(messageKey: "settings.backup.error.unsupportedVersion")
                } catch {
                    settingsAlert = .failure(messageKey: "settings.backup.error.importFailed")
                }
            }
            .alert(item: $settingsAlert) { alert in
                switch alert {
                case .confirmRestore:
                    Alert(
                        title: Text("settings.backup.restore"),
                        message: Text("settings.backup.restore.message"),
                        primaryButton: .default(Text("settings.backup.restore.confirm")) {
                            isImportingBackup = true
                        },
                        secondaryButton: .cancel(Text("common.cancel"))
                    )
                case .success(let messageKey):
                    Alert(
                        title: Text("settings.backup.success.title"),
                        message: Text(LocalizedStringKey(messageKey)),
                        dismissButton: .cancel(Text("common.ok"))
                    )
                case .failure(let messageKey):
                    Alert(
                        title: Text("settings.backup.error.title"),
                        message: Text(LocalizedStringKey(messageKey)),
                        dismissButton: .cancel(Text("common.ok"))
                    )
                }
            }
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
        .environmentObject(PersistenceController())
}
