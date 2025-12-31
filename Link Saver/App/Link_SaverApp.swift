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

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
