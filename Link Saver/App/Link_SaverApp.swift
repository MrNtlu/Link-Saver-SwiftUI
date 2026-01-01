//
//  Link_SaverApp.swift
//  Link Saver
//
//  Created by Burak on 2025/12/29.
//

import SwiftUI
import SwiftData

@main
struct Link_SaverApp: App {
    var sharedModelContainer: ModelContainer = ModelContainerFactory.createSharedContainer()
    @AppStorage(ThemePreferences.key, store: ThemePreferences.store)
    private var themeRawValue: String = ThemePreferences.defaultTheme.rawValue
    @AppStorage(LanguagePreferences.key, store: LanguagePreferences.store)
    private var languageRawValue: String = LanguagePreferences.defaultLanguage.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? ThemePreferences.defaultTheme
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? LanguagePreferences.defaultLanguage
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(theme.colorScheme)
                .environment(\.locale, language.locale)
        }
        .modelContainer(sharedModelContainer)
    }
}
