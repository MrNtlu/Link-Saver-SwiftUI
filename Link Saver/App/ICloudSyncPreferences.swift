//
//  ICloudSyncPreferences.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import Foundation

enum ICloudSyncPreferences {
    static let enabledKey = "linksaver.icloud.sync.enabled"
    static let store = UserDefaults(suiteName: AppConstants.appGroupID)

    static var isEnabled: Bool {
        get { store?.bool(forKey: enabledKey) ?? false }
        set { store?.set(newValue, forKey: enabledKey) }
    }
}

