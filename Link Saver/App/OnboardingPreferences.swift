//
//  OnboardingPreferences.swift
//  Link Saver
//
//  Created by Codex on 2026/01/01.
//

import Foundation

enum OnboardingPreferences {
    static let key = "linksaver.onboarding.completed"
    static let store = UserDefaults(suiteName: AppConstants.appGroupID)
}

