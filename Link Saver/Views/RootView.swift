//
//  RootView.swift
//  Link Saver
//
//  Created by Codex on 2026/01/01.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage(OnboardingPreferences.key, store: OnboardingPreferences.store)
    private var hasCompletedOnboarding: Bool = false

    var body: some View {
        MainTabView()
            .fullScreenCover(
                isPresented: Binding(
                    get: { !hasCompletedOnboarding },
                    set: { isPresented in
                        if !isPresented {
                            hasCompletedOnboarding = true
                        }
                    }
                )
            ) {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
    }
}

#Preview {
    RootView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
