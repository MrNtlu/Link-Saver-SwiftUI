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

    private var theme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? ThemePreferences.defaultTheme
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
