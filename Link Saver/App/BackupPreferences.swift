//
//  BackupPreferences.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import Foundation

enum BackupPreferences {
    static let lastActionKey = "linksaver.backup.lastAction"
    static let minimumInterval: TimeInterval = 8
    static let store = UserDefaults(suiteName: AppConstants.appGroupID)

    static func canPerformAction(now: Date = Date()) -> Bool {
        guard let last = store?.object(forKey: lastActionKey) as? Date else { return true }
        return now.timeIntervalSince(last) >= minimumInterval
    }

    static func markActionPerformed(now: Date = Date()) {
        store?.set(now, forKey: lastActionKey)
    }
}

