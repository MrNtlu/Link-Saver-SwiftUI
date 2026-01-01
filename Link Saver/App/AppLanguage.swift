//
//  AppLanguage.swift
//  Link Saver
//
//  Created by Codex on 2026/01/01.
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case spanishSpain = "es-ES"
    case spanishLatinAmerica = "es-419"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case turkish = "tr"
    case german = "de"
    case portugueseBrazil = "pt-BR"
    case french = "fr"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        default:
            return Locale(identifier: rawValue)
        }
    }

    var displayNameKey: LocalizedStringKey {
        switch self {
        case .system: return "language.option.system"
        case .english: return "language.option.english"
        case .japanese: return "language.option.japanese"
        case .korean: return "language.option.korean"
        case .spanishSpain: return "language.option.spanishSpain"
        case .spanishLatinAmerica: return "language.option.spanishLatinAmerica"
        case .chineseSimplified: return "language.option.chineseSimplified"
        case .chineseTraditional: return "language.option.chineseTraditional"
        case .turkish: return "language.option.turkish"
        case .german: return "language.option.german"
        case .portugueseBrazil: return "language.option.portugueseBrazil"
        case .french: return "language.option.french"
        }
    }
}

enum LanguagePreferences {
    static let key = "linksaver.language"
    static let store = UserDefaults(suiteName: AppConstants.appGroupID)
    static let defaultLanguage: AppLanguage = .system
}

