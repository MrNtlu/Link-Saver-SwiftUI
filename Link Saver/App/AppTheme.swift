//
//  AppTheme.swift
//  Link Saver
//
//  Created by Codex on 2025/12/31.
//

import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum ThemePreferences {
    static let key = "linksaver.theme"
    static let store = UserDefaults(suiteName: AppConstants.appGroupID)
    static let defaultTheme: AppTheme = .light
}

